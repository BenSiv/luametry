stl = require("stl")
script_path = string.match(debug.getinfo(1).source, "@(.*[\\/])") or "./"
package.cpath = package.cpath .. ";" .. script_path .. "?.so"
csg = require("csg.manifold")

cad = {}

-- Internal Scene Graph Node Builders

function make_shape(type, params)
    return { type = "shape", shape = type, params = params or {} }
end

function make_transform(type, node, params)
    return { type = "transform", transform = type, params = params or {}, child = node }
end

function make_op(type, nodes)
    return { type = "op", op = type, children = nodes }
end

function make_trim(node, nx, ny, nz, offset)
    return { type = "trim", child = node, nx=nx, ny=ny, nz=nz, offset=offset }
end

function make_manifold_node(m)
    return { type = "manifold", manifold = m }
end

-- ============================================================================
-- 1. Create (Generators)
-- ============================================================================
cad.create = {}

function cad.create.cube(size, center)
    if type(size) == "table" then return make_shape("cube", size) end
    params = { size = size, center = center }
    return make_shape("cube", params)
end

function cad.create.cylinder(params)
    return make_shape("cylinder", params)
end

function cad.create.sphere(r, fn)
    if type(r) == "table" then return make_shape("sphere", r) end
    params = { r = r, fn = fn }
    return make_shape("sphere", params)
end

function cad.create.tetrahedron()
    return make_shape("tetrahedron", {})
end

function cad.create.torus(major, minor, major_segs, minor_segs)
    if type(major) == "table" then return make_shape("torus", major) end
    params = { major_r=major, minor_r=minor, major_segs=major_segs, minor_segs=minor_segs }
    return make_shape("torus", params)
end

function cad.create.extrude(points, height, params)
    if type(points) == "table" and points.points != nil then
         return { type = "extrude", points = points.points, height = points.height, params = points or {} }
    end
    return {
        type = "extrude",
        points = points,
        height = height,
        params = params or {}
    }
end

function cad.create.revolve(points, params)
    if type(points) == "table" and points.points != nil then
         return { type = "revolve", points = points.points, params = points or {} }
    end
    return {
        type = "revolve",
        points = points,
        params = params or {}
    }
end

-- ============================================================================
-- 2. Modify (Transforms)
-- ============================================================================
cad.modify = {}

function cad.modify.translate(node, v)
    return make_transform("translate", node, v)
end

function cad.modify.rotate(node, v)
    return make_transform("rotate", node, v)
end

function cad.modify.scale(node, v)
    return make_transform("scale", node, v)
end

function cad.modify.mirror(node, v)
    return make_transform("mirror", node, v)
end


function cad.modify.warp(node, func)
    return { type = "warp", child = node, warp_func = func }
end

function cad.modify.round(node, r, fn)
    params = { r = r, fn = fn }
    s = make_shape("sphere", params)
    return make_op("minkowski", {node, s})
end

-- ============================================================================
-- 3. Combine (Booleans & Topology)
-- ============================================================================
cad.combine = {}

function cad.combine.union(nodes)
    return make_op("union", nodes)
end

function cad.combine.difference(a, b)
    if type(a) == "table" and a.type != nil and type(b) == "table" and b.type != nil then
        return make_op("difference", {a, b})
    else
         -- Fallback if user passes list? No, explicit API takes 2 args usually
         -- But strict difference takes list in scene graph logic? 
         -- Let's support list if passed
         if type(a) == "table" and a.type == nil then return make_op("difference", a) end
         return make_op("difference", {a, b})
    end
end

function cad.combine.intersection(nodes)
    return make_op("intersection", nodes)
end

function cad.combine.hull(nodes)
    return make_op("hull", nodes)
end

function cad.combine.minkowski(nodes)
    return make_op("minkowski", nodes)
end

function cad.combine.trim(node, plane, offset)
    -- plane is {nx, ny, nz}
    return make_trim(node, plane[1], plane[2], plane[3], offset or 0)
end

-- ============================================================================
-- 4. Query & Render Logic
-- ============================================================================
cad.query = {}

-- Forward declaration
-- render_node is global now
-- function render_node(node) ... defined below

-- Helper: Render to Manifold
function cad.render(node)
    return render_node(node)
end

function cad.query.volume(node)
    m = render_node(node)
    return csg.volume(m)
end

function cad.query.surface_area(node)
    m = render_node(node)
    return csg.surface_area(m)
end

-- Split and Decompose require immediate rendering to return multiple nodes
function cad.combine.split(node, plane, offset)
    m = render_node(node)
    nx, ny, nz = plane[1], plane[2], plane[3]
    off = offset or 0
    -- split returns 2 manifold objects
    m1, m2 = csg.split_by_plane(m, nx, ny, nz, off)
    return { make_manifold_node(m1), make_manifold_node(m2) }
end

function cad.combine.decompose(node)
    m = render_node(node)
    parts = csg.decompose(m) -- returns table of manifolds
    results = {}
    for i, part in ipairs(parts) do
        table.insert(results, make_manifold_node(part))
    end
    return results
end


-- ============================================================================
-- Renderer Implementation
-- ============================================================================

function render_node(node)
    if node.type == "shape" then
        if node.shape == "cube" then
            p = node.params
            -- Handle size variants
            sz = p.size
            x = p.x or p.width or 1
            y = p.y or p.depth or 1
            z = p.z or p.height or 1
            
            if sz != nil then
                if type(sz) == "number" then
                    x, y, z = sz, sz, sz
                else
                    x, y, z = sz[1], sz[2], sz[3]
                end
            end
            
            c = p.center and 1 or 0
            return csg.cube(x, y, z, c)
            
        elseif node.shape == "cylinder" then
            p = node.params
            h = p.h or p.height or 1
            r = p.r or p.radius or 1
            r1 = p.r1 or p.radius_bottom or r
            r2 = p.r2 or p.radius_top or r
            fn = p.fn or 32
            c = p.center and 1 or 0
            return csg.cylinder(h, r1, r2, fn, c)
            
        elseif node.shape == "sphere" then
            p = node.params
            r = p.r or p.radius or 1
            fn = p.fn or 32
            return csg.sphere(r, fn)
            
        elseif node.shape == "tetrahedron" then
            return csg.tetrahedron()

        elseif node.shape == "torus" then
            p = node.params
            maj = p.major_r or 3
            min = p.minor_r or 1
            seg_maj = p.major_segs or 32
            seg_min = p.minor_segs or 16
            return csg.torus(maj, min, seg_maj, seg_min)
        end
        
    elseif node.type == "transform" then
        child = render_node(node.child)
        t = node.transform
        v = node.params
        if t == "translate" then return csg.translate(child, v[1], v[2], v[3]) end
        if t == "rotate" then return csg.rotate(child, v[1], v[2], v[3]) end
        if t == "scale" then return csg.scale(child, v[1], v[2], v[3]) end
        if t == "mirror" then return csg.mirror(child, v[1], v[2], v[3]) end
        return child
        
    elseif node.type == "warp" then
        return csg.warp(render_node(node.child), node.warp_func)
    
    elseif node.type == "trim" then
        return csg.trim_by_plane(render_node(node.child), node.nx, node.ny, node.nz, node.offset)
        
    elseif node.type == "manifold" then
        -- This node wraps an already computed Manifold object
        return node.manifold

    elseif node.type == "op" or node.type == "union" or node.type == "union_batch" or node.type == "difference" or node.type == "intersection" or node.type == "hull" or node.type == "minkowski" then
        -- Handle both old and new style op nodes
        op = node.op or node.type
        children = node.children
        
        if #children == 0 then return csg.cube(0,0,0,0) end
        
        if op == "union" or op == "union_batch" then
             rendered = {}
             for _, c in ipairs(children) do table.insert(rendered, render_node(c)) end
             return csg.union_batch(rendered)
             
        elseif op == "intersection" then
             res = render_node(children[1])
             for i=2,#children do res = csg.intersection(res, render_node(children[i])) end
             return res
             
        elseif op == "difference" then
             res = render_node(children[1])
             for i=2,#children do res = csg.difference(res, render_node(children[i])) end
             return res

        elseif op == "minkowski" then
             res = render_node(children[1])
             for i=2,#children do res = csg.minkowski(res, render_node(children[i])) end
             return res

        elseif op == "hull" then
             rendered = {}
             for _, c in ipairs(children) do table.insert(rendered, render_node(c)) end
             return csg.hull(rendered)
        end
        
    elseif node.type == "extrude" then
         return csg.extrude(node.points, node.height, node.params.slices or 0, node.params.twist or 0, node.params.scale_x or 1, node.params.scale_y or 1)
         
    elseif node.type == "revolve" then
         return csg.revolve(node.points, node.params.circular_segments or 0, node.params.revolve_degrees or 360)
    end
    
    error("Unknown node type: " .. tostring(node.type))
end

-- ============================================================================
-- Export
-- ============================================================================
function geometry_to_stl_solid(mesh)
    solid = stl.create_solid("csg_export")
    vertices = mesh.verts
    faces = mesh.faces
    
    for i, face in ipairs(faces) do
        v1 = vertices[face[1]]
        v2 = vertices[face[2]]
        v3 = vertices[face[3]]
        
        -- Normal calc
        ux, uy, uz = v2[1]-v1[1], v2[2]-v1[2], v2[3]-v1[3]
        vx, vy, vz = v3[1]-v1[1], v3[2]-v1[2], v3[3]-v1[3]
        nx, ny, nz = uy*vz - uz*vy, uz*vx - ux*vz, ux*vy - uy*vx
        
        len = math.sqrt(nx*nx + ny*ny + nz*nz)
        if len > 0 then nx=nx/len; ny=ny/len; nz=nz/len end
        
        solid = stl.add_facet(solid, {nx, ny, nz}, v1, v2, v3)
    end
    return solid
end

function cad.export(node, filename)
    man = render_node(node)
    mesh = csg.to_mesh(man)
    if mesh == nil then return false end
    
    solid = geometry_to_stl_solid(mesh)
    content = stl.encode_solid(solid)
    
    f = io.open(filename, "w")
    if f != nil then
        io.write(f, content)
        io.close(f)
        return true
    end
    return false
end

-- ============================================================================
-- Flat Aliases (Backward Compatibility)
-- ============================================================================
cad.cube = cad.create.cube
cad.cylinder = cad.create.cylinder
cad.sphere = cad.create.sphere
cad.tetrahedron = cad.create.tetrahedron
cad.torus = cad.create.torus
cad.extrude = cad.create.extrude
cad.revolve = cad.create.revolve

cad.translate = cad.modify.translate
cad.rotate = cad.modify.rotate
cad.scale = cad.modify.scale
cad.warp = cad.modify.warp
cad.mirror = cad.modify.mirror
cad.round = cad.modify.round

cad.union = cad.combine.union
cad.union_batch = function(nodes) return cad.combine.union(nodes) end
cad.difference = cad.combine.difference
cad.intersection = cad.combine.intersection
cad.hull = cad.combine.hull
cad.minkowski = cad.combine.minkowski
-- Legacy helpers
cad.create_legacy = make_shape
cad.transform_legacy = make_transform
cad.boolean_legacy = make_op

return cad

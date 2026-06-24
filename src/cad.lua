stl = require("stl")
step = require("step")
obj = require("obj")
threemf = require("threemf")
font = require("font")
script_path = string.match(debug.getinfo(1).source, "@(.*[\\/])") or "./"
package.cpath = package.cpath .. ";" .. script_path .. "?.so"
csg = require("csg.manifold")

cad = {}
cad.file_cache = {}

function get_source_line(source, line_num)
    if source == nil or line_num == nil or line_num < 1 then return nil end
    
    -- Strip '@' prefix if present
    if string.sub(source, 1, 1) == "@" then
        source = string.sub(source, 2)
    end
    
    if cad.file_cache[source] == nil then
        f = io.open(source, "r")
        if f == nil then 
            return nil 
        end
        lines = {}
        for line in io.lines(source) do
            table.insert(lines, line)
        end
        io.close(f)
        cad.file_cache[source] = lines
    end
    
    return cad.file_cache[source][line_num]
end

function infer_name(line)
    if line == nil then return nil end
    -- Look for assignment: var = ...
    -- Pattern: optional spaces, word, optional spaces, =, optional spaces
    name = string.match(line, "^%s*([%w_]+)%s*=")
    return name
end

-- Internal Scene Graph Node Builders

function get_source_info()
    -- Look up the stack to find the first frame outside of cad.lua
    for i = 2, 10 do
        info = debug.getinfo(i, "Sl")
        if info != nil then
            source = info.source
            if string.find(source, "cad") == nil and info.what != "C" and string.find(source, "tail call") == nil then
                s_info = {
                    source = source,
                    line = info.currentline
                }
                
                -- Try to infer name
                line_text = get_source_line(source, info.currentline)
                s_info.name = infer_name(line_text)
                
                return s_info
            end
        else
            break
        end
    end
    return nil
end

function set_meta(node)
    s_info = get_source_info()
    node.source_info = s_info
    if node.label == nil and s_info != nil and s_info.name != nil then
        node.label = s_info.name
    end
    return node
end

function make_shape(type, params)
    node = { type = "shape", shape = type, params = params or {} }
    set_meta(node)
    return node
end

function make_transform(type, node, params)
    t_node = { type = "transform", transform = type, params = params or {}, child = node }
    set_meta(t_node)
    return t_node
end

function make_op(type, nodes)
    op_node = { type = "op", op = type, children = nodes }
    set_meta(op_node)
    return op_node
end

function make_trim(node, nx, ny, nz, offset)
    trim_node = { type = "trim", child = node, nx=nx, ny=ny, nz=nz, offset=offset }
    set_meta(trim_node)
    return trim_node
end

function make_manifold_node(m)
    m_node = { type = "manifold", manifold = m }
    set_meta(m_node)
    return m_node
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

function cad.create.from_mesh(verts, faces)
    return set_meta({ type = "from_mesh", verts = verts, faces = faces })
end

function cad.create.from_stl(filename)
    -- Load STL
    solid = stl.load_ascii(filename)
    if solid == nil then error("Failed to load STL: " .. filename) end
    
    verts = {}
    faces = {}
    vert_map = {} -- dedup vertices
    next_idx = 1
    
    get_vert_idx = function(v)
        key = string.format("%.6f,%.6f,%.6f", v.x, v.y, v.z)
        if vert_map[key] != nil then return vert_map[key] end
        
        table.insert(verts, {v.x, v.y, v.z})
        vert_map[key] = next_idx
        next_idx = next_idx + 1
        return next_idx - 1
    end
    
    for _, facet in ipairs(solid.facets) do
        v1 = get_vert_idx(facet.vertices[1])
        v2 = get_vert_idx(facet.vertices[2])
        v3 = get_vert_idx(facet.vertices[3])
        table.insert(faces, {v1, v2, v3})
    end
    
    return cad.create.from_mesh(verts, faces)
end

function cad.create.from_obj(filename)
    f = io.open(filename, "r")
    if f == nil then error("Could not open file: " .. filename) end
    io.input(f)
    content = io.read("*a")
    io.close(f)
    
    mesh = obj.decode(content)
    return cad.create.from_mesh(mesh.verts, mesh.faces)
end

function cad.create.extrude(points, height, params)
    if type(points) == "table" and points.points != nil then
         return set_meta({ type = "extrude", points = points.points, height = points.height, params = points or {} })
    end
    return set_meta({
        type = "extrude",
        points = points,
        height = height,
        params = params or {}
    })
end

function cad.create.revolve(points, params)
    if type(points) == "table" and points.points != nil then
         return set_meta({ type = "revolve", points = points.points, params = points or {} })
    end
    return set_meta({
        type = "revolve",
        points = points,
        params = params or {}
    })
end

function cad.create.text(text_str, params)
    return font.create_text(text_str, params)
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
    return set_meta({ type = "warp", child = node, warp_func = func })
end

function cad.modify.fillet(node, r, fn)
    params = { r = r, fn = fn }
    s = make_shape("sphere", params)
    return make_op("minkowski", {node, s})
end

cad.modify.round = cad.modify.fillet

function cad.modify.chamfer(node, size)
    -- Minkowski with a small octahedron/tetrahedron/cube for flat bevels
    -- Using a cube (center=true) creates a chamfer-like effect
    s = make_shape("cube", {size = size, center = true})
    return make_op("minkowski", {node, s})
end

cad.modify.bevel = cad.modify.chamfer

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

-- Split and Decompose

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
            sz = p.size or p.s
            x = p.x or p.width or p.w or 1
            y = p.y or p.depth or p.d or 1
            z = p.z or p.height or p.h or 1
            
            if sz != nil then
                if type(sz) == "number" then
                    x, y, z = sz, sz, sz
                else
                    x, y, z = sz[1], sz[2], sz[3]
                end
            end
            
            c = not not (p.center or p.c)
            return csg.cube(x, y, z, c)
            
        elseif node.shape == "cylinder" then
            p = node.params
            h = p.h or p.height or 1
            r = p.r or p.radius or 1
            r1 = p.r1 or p.radius_bottom or p.radius1 or r
            r2 = p.r2 or p.radius_top or p.radius2 or r
            fn = p.fn or p.segments or 32
            c = not not (p.center or p.c)
            return csg.cylinder(h, r1, r2, fn, c)
            
        elseif node.shape == "sphere" then
            p = node.params
            r = p.r or p.radius or 1
            fn = p.fn or p.segments or 32
            return csg.sphere(r, fn)
            
        elseif node.shape == "tetrahedron" then
            return csg.tetrahedron()

        elseif node.shape == "torus" then
            p = node.params
            maj = p.major_r or p.major_radius or p.R or 3
            min = p.minor_r or p.minor_radius or p.r or 1
            seg_maj = p.major_segs or p.major_segments or 32
            seg_min = p.minor_segs or p.minor_segments or 16
            return csg.torus(maj, min, seg_maj, seg_min)
        end
        
    elseif node.type == "from_mesh" then
        return csg.from_mesh(node.verts, node.faces)

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

    elseif node.type == "op" or node.type == "difference" or node.type == "intersection" or node.type == "hull" or node.type == "minkowski" then
        -- Handle both old and new style op nodes
        op = node.op or node.type
        children = node.children
        
        if #children == 0 then return csg.cube(0,0,0,0) end
        
        if op == "union" then
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
    
    content = nil
    if (string.match(filename, "%.step$") != nil) or (string.match(filename, "%.stp$") != nil) then
        content = step.encode_mesh(mesh)
    elseif string.match(filename, "%.obj$") != nil then
        content = obj.encode_mesh(mesh)
    elseif string.match(filename, "%.3mf$") != nil then
        return threemf.export(mesh, filename)
    else
        solid = geometry_to_stl_solid(mesh)
        content = stl.encode_solid(solid)
    end
    
    f = io.open(filename, "w")
    if f != nil then
        io.write(f, content)
        io.close(f)
        return true
    end
    return false
end

-- ============================================================================
-- 5. Semantic Manifest Export
-- ============================================================================

function serialize_json(obj)
    if type(obj) == "string" then return string.format("%q", obj) end
    if type(obj) == "number" then return tostring(obj) end
    if type(obj) == "boolean" then return tostring(obj) end
    if type(obj) == "table" then
        is_array = #obj > 0
        parts = {}
        if is_array then
            for _, v in ipairs(obj) do table.insert(parts, serialize_json(v)) end
            return "[" .. table.concat(parts, ",") .. "]"
        else
            for k, v in pairs(obj) do
                -- Filter out functions and large data like mesh verts
                if type(v) != "function" and k != "verts" and k != "faces" and k != "manifold" then
                    table.insert(parts, string.format("%q:%s", k, serialize_json(v)))
                end
            end
            return "{" .. table.concat(parts, ",") .. "}"
        end
    end
    return "null"
end

function cad.export_manifest(node, filename)
    json = serialize_json(node)
    f = io.open(filename, "w")
    if f != nil then
        io.write(f, json)
        io.close(f)
        return true
    end
    return false
end

function cad.set_name(node, name)
    node.label = name
    return node
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
cad.from_mesh = cad.create.from_mesh
cad.from_stl = cad.create.from_stl
cad.from_obj = cad.create.from_obj
cad.text = cad.create.text

cad.translate = cad.modify.translate
cad.rotate = cad.modify.rotate
cad.scale = cad.modify.scale
cad.warp = cad.modify.warp
cad.mirror = cad.modify.mirror
cad.fillet = cad.modify.fillet
cad.round = cad.modify.fillet
cad.chamfer = cad.modify.chamfer
cad.bevel = cad.modify.chamfer

cad.union = cad.combine.union
cad.difference = cad.combine.difference
cad.intersection = cad.combine.intersection
cad.hull = cad.combine.hull
cad.minkowski = cad.combine.minkowski

cad.set_name = cad.set_name
cad.name = cad.set_name

return cad

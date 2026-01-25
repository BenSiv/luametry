
const stl = require("stl")

-- Load CSG extension
script_path = string.match(debug.getinfo(1).source, "@(.*[\\/])") or "./"
package.cpath = package.cpath .. ";" .. script_path .. "?.so"
const csg = require("csg.manifold")

const cad = {}

-- Scene Graph Node Creators

function create(type, params)
    return {
        type = "shape",
        shape = type,
        params = params or {}
    }
end

function transform(type, node, params)
    return {
        type = "transform",
        transform = type,
        params = params or {},
        child = node
    }
end


function extrude(points, height, params)
    return {
        type = "extrude",
        points = points,
        height = height,
        params = params or {}
    }
end

function union(nodes)
    return {
        type = "union",
        children = nodes
    }
end

function union_batch(nodes)
    return {
        type = "union_batch",
        children = nodes
    }
end

function intersection(nodes)
    return {
        type = "intersection",
        children = nodes
    }
end

function difference(nodes)
    return {
        type = "difference",
        children = nodes
    }
end

function minkowski(nodes)
    return {
        type = "minkowski",
        children = nodes
    }
end

function boolean(action, nodes)
    if type(action) != "string" then
        error("Action must be a string.")
    end
    if type(nodes) != "table" then
        error("Nodes must be a table.")
    end
    
    if action == "union" then
        return union(nodes)
    elseif action == "intersection" then
        return intersection(nodes)
    elseif action == "difference" then
        return difference(nodes)
    elseif action == "minkowski" then
        return minkowski(nodes)
    elseif action == "hull" then
        return {
             type = "hull",
             children = nodes
        }
    else
        error("Unknown boolean action: " .. action)
    end
end

-- Render to Manifold Object

function render_node(node)
    if node.type == "shape" then
        if node.shape == "cube" then
            -- Aliases
            x = node.params.x or node.params.width or 1
            y = node.params.y or node.params.depth or 1
            z = node.params.z or node.params.height or 1
            
            size = node.params.size
            if size != nil then
                if type(size) == "number" then
                    x, y, z = size, size, size
                else
                    x, y, z = size[1], size[2], size[3]
                end
            end
            
            center = node.params.center or false
            c_int = 0
            if center then c_int = 1 end
            return csg.cube(x, y, z, c_int)
        
        elseif node.shape == "cylinder" then
            h = node.params.h or node.params.height or 1
            r = node.params.r or node.params.radius or 1
            r1 = node.params.r1 or node.params.radius_bottom or r
            r2 = node.params.r2 or node.params.radius_top or r
            
            fn = node.params.fn or 32
            center = node.params.center or false
            c_int = 0
            if center then c_int = 1 end
            return csg.cylinder(h, r1, r2, fn, c_int)
            
        elseif node.shape == "sphere" then
            r = node.params.r or node.params.radius or 1
            fn = node.params.fn or 32
            return csg.sphere(r, fn)
            
        elseif node.shape == "tetrahedron" then
            return csg.tetrahedron()
            
        elseif node.shape == "torus" then
            major = node.params.major_r or node.params.major_radius or 3
            minor = node.params.minor_r or node.params.minor_radius or 1
            major_segs = node.params.major_segs or 32
            minor_segs = node.params.minor_segs or 16
            return csg.torus(major, minor, major_segs, minor_segs)
        end
        
    elseif node.type == "transform" then
        child_node = render_node(node.child)
        if node.transform == "translate" then
             v = node.params
             return csg.translate(child_node, v[1], v[2], v[3])
        elseif node.transform == "rotate" then
             v = node.params
             return csg.rotate(child_node, v[1], v[2], v[3])
        elseif node.transform == "scale" then
             v = node.params
             return csg.scale(child_node, v[1], v[2], v[3])
        end
        return child_node
    
    elseif node.type == "union" then
        if #node.children == 0 then return csg.cube(0,0,0,0) end -- Empty fallback
        -- Optimization: Use batch union if available
        rendered_children = {}
        for i, child in ipairs(node.children) do
             table.insert(rendered_children, render_node(child))
        end
        return csg.union_batch(rendered_children)

    elseif node.type == "union_batch" then
        if #node.children == 0 then return csg.cube(0,0,0,0) end
        rendered_children = {}
        for i, child in ipairs(node.children) do
            table.insert(rendered_children, render_node(child))
        end
        return csg.union_batch(rendered_children)

    elseif node.type == "intersection" then
        if #node.children == 0 then return csg.cube(0,0,0,0) end
        res = render_node(node.children[1])
        for i = 2, #node.children do
            next_node = render_node(node.children[i])
            res = csg.intersection(res, next_node)
        end
        return res

    elseif node.type == "difference" then
        if #node.children == 0 then return csg.cube(0,0,0,0) end
        res = render_node(node.children[1])
        for i = 2, #node.children do
            next_node = render_node(node.children[i])
            res = csg.difference(res, next_node)
        end
        return res

    elseif node.type == "minkowski" then
        if #node.children == 0 then return csg.cube(0,0,0,0) end
        res = render_node(node.children[1])
        for i = 2, #node.children do
            next_node = render_node(node.children[i])
            res = csg.minkowski(res, next_node)
        end
        return res
        

    elseif node.type == "hull" then
        if #node.children == 0 then return csg.cube(0,0,0,0) end
        rendered_children = {}
        for i, child in ipairs(node.children) do
            table.insert(rendered_children, render_node(child))
        end
        return csg.hull(rendered_children)

    elseif node.type == "extrude" then
        points = node.points
        height = node.height
        slices = node.params.slices or 0
        twist = node.params.twist or 0
        scale_x = node.params.scale_x or 1.0
        scale_y = node.params.scale_y or 1.0
        
        return csg.extrude(points, height, slices, twist, scale_x, scale_y)
    end
    
    error("Unknown node type: " .. tostring(node.type))
end

function geometry_to_stl_solid(mesh)
    solid = stl.create_solid("csg_export")
    vertices = mesh.verts
    faces = mesh.faces
    
    for i, face in ipairs(faces) do
        -- face is {i1, i2, i3} (1-based indices)
        i1 = face[1]
        i2 = face[2]
        i3 = face[3]
        
        v1 = vertices[i1]
        v2 = vertices[i2]
        v3 = vertices[i3]
        
        -- Calculate normal
        ux = v2[1] - v1[1]
        uy = v2[2] - v1[2]
        uz = v2[3] - v1[3]
        vx = v3[1] - v1[1]
        vy = v3[2] - v1[2]
        vz = v3[3] - v1[3]
        
        nx = uy*vz - uz*vy
        ny = uz*vx - ux*vz
        nz = ux*vy - uy*vx
        
        -- Normalize
        len = math.sqrt(nx*nx + ny*ny + nz*nz)
        if len > 0 then
            nx = nx/len; ny = ny/len; nz = nz/len
        end
        
        solid = stl.add_facet(solid, {nx, ny, nz}, v1, v2, v3)
    end
    return solid
end

function export(node, filename)
    man = render_node(node)
    mesh = csg.to_mesh(man)
    
    if mesh == nil then
        return false
    end
    
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

function round(shape, r, fn)
    s = create("sphere", {r=r, fn=fn})
    return boolean("minkowski", {shape, s})
end



cad.create = create
cad.transform = transform
cad.boolean = boolean
cad.export = export
cad.round = round
cad.extrude = extrude
cad.union = union
cad.union_batch = union_batch


return cad

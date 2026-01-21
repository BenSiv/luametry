
const stl = require("stl")

-- Load CSG extension
script_path = string.match(debug.getinfo(1).source, "@(.*[\\/])") or "./"
package.cpath = package.cpath .. ";" .. script_path .. "?.so"
const csg = require("csg_manifold")

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

function union(nodes)
    return {
        type = "union",
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

-- Render to Manifold Object

function render_node(node)
    if node.type == "shape" then
        if node.shape == "cube" then
            size = node.params.size or {1, 1, 1}
            if type(size) == "number" then
                size = {size, size, size}
            end
            center = node.params.center or false
            c_int = 0
            if center then c_int = 1 end
            return csg.cube(size[1], size[2], size[3], c_int)
        
        elseif node.shape == "cylinder" then
            h = node.params.h or 1
            r = node.params.r or 1
            r1 = node.params.r1 or r
            r2 = node.params.r2 or r
            fn = node.params.fn or 32
            center = node.params.center or false
            c_int = 0
            if center then c_int = 1 end
            return csg.cylinder(h, r1, r2, fn, c_int)
            
        elseif node.shape == "sphere" then
            r = node.params.r or 1
            fn = node.params.fn or 32
            return csg.sphere(r, fn)
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
        res = render_node(node.children[1])
        for i = 2, #node.children do
            next_node = render_node(node.children[i])
            res = csg.union(res, next_node)
        end
        return res

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

cad.create = create
cad.transform = transform
cad.union = union
cad.intersection = intersection
cad.difference = difference
cad.export = export

return cad

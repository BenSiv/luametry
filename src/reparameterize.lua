-- reparameterize.lua
csg = require("csg.manifold")
re = {}

function re.get_bounding_box(mesh)
    if mesh == nil or mesh.verts == nil or #mesh.verts == 0 then return nil end
    
    min_x, min_y, min_z = math.huge, math.huge, math.huge
    max_x, max_y, max_z = -math.huge, -math.huge, -math.huge
    
    for _, v in ipairs(mesh.verts) do
        min_x = math.min(min_x, v[1])
        min_y = math.min(min_y, v[2])
        min_z = math.min(min_z, v[3])
        max_x = math.max(max_x, v[1])
        max_y = math.max(max_y, v[2])
        max_z = math.max(max_z, v[3])
    end
    
    return {
        min = {min_x, min_y, min_z},
        max = {max_x, max_y, max_z},
        size = {max_x - min_x, max_y - min_y, max_z - min_z},
        center = {(min_x + max_x) / 2, (min_y + max_y) / 2, (min_z + max_z) / 2}
    }
end

function re.analyze(node, cad_module)
    cad = cad_module or _G.cad
    man = cad.render(node)
    mesh = csg.to_mesh(man)
    vol = csg.volume(man)
    bbox = re.get_bounding_box(mesh)
    
    if bbox == nil then return { type = "empty" } end
    
    bbox_vol = bbox.size[1] * bbox.size[2] * bbox.size[3]
    
    -- Heuristic for Cube
    if bbox_vol > 0 and math.abs(vol - bbox_vol) < 0.01 * bbox_vol then
        return {
            type = "cube",
            size = bbox.size,
            translate = bbox.min
        }
    end
    
    -- Heuristic for Sphere
    max_dim = math.max(bbox.size[1], bbox.size[2], bbox.size[3])
    min_dim = math.min(bbox.size[1], bbox.size[2], bbox.size[3])
    if max_dim > 0 and (max_dim - min_dim) / max_dim < 0.05 then
        r = max_dim / 2
        sphere_vol = (4/3) * math.pi * (r^3)
        if math.abs(vol - sphere_vol) < 0.05 * vol then
            return {
                type = "sphere",
                r = r,
                translate = bbox.center
            }
        end
    end
    
    return {
        type = "mesh",
        verts = #mesh.verts,
        faces = #mesh.faces,
        bbox = bbox
    }
end

function re.to_code(analysis)
    if analysis.type == "cube" then
        return string.format("cad.translate(cad.cube({size={%.3f, %.3f, %.3f}, center=false}), {%.3f, %.3f, %.3f})", 
            analysis.size[1], analysis.size[2], analysis.size[3],
            analysis.translate[1], analysis.translate[2], analysis.translate[3])
    elseif analysis.type == "sphere" then
         return string.format("cad.translate(cad.sphere(%.3f), {%.3f, %.3f, %.3f})", 
            analysis.r,
            analysis.translate[1], analysis.translate[2], analysis.translate[3])
    elseif analysis.type == "mesh" then
        return string.format("-- Detected complex mesh with %d vertices, %d faces", analysis.verts, analysis.faces)
    end
    return "-- Could not reparameterize"
end

return re

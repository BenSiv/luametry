-- src/obj.lua
-- OBJ format encoder/decoder

obj = {}

function obj.encode_mesh(mesh)
    lines = {
        "# Luametry OBJ Export",
        "o Model"
    }
    
    -- Vertices
    for _, v in ipairs(mesh.verts) do
        table.insert(lines, string.format("v %.6f %.6f %.6f", v[1], v[2], v[3]))
    end
    
    -- Faces (OBJ is 1-indexed, same as our internal mesh)
    for _, f in ipairs(mesh.faces) do
        table.insert(lines, string.format("f %d %d %d", f[1], f[2], f[3]))
    end
    
    return table.concat(lines, "\n")
end

function obj.decode(content)
    mesh = { verts = {}, faces = {} }
    
    for line in string.gmatch(content, "[^\n]+") do
        -- Trim whitespace
        line = string.match(line, "^%s*(.-)%s*$")
        
        if string.find(line, "^v%s+") != nil then
            vx, vy, vz = string.match(line, "v%s+([%d%.%-e]+)%s+([%d%.%-e]+)%s+([%d%.%-e]+)")
            if vx != nil then
                table.insert(mesh.verts, {tonumber(vx), tonumber(vy), tonumber(vz)})
            end
        elseif string.find(line, "^f%s+") != nil then
            -- Handle simple faces like f 1 2 3 or f 1/2/3
            -- We only care about vertices
            f1, f2, f3 = string.match(line, "f%s+(%d+)[^%s]*%s+(%d+)[^%s]*%s+(%d+)")
            if f1 != nil then
                table.insert(mesh.faces, {tonumber(f1), tonumber(f2), tonumber(f3)})
            end
        end
    end
    
    return mesh
end

return obj

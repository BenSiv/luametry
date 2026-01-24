
const stl = {}

function create_solid(name)
    solid = {
        name = name,
        facets = {}
    }
    return solid
end

function add_facet(solid, orientation, v1, v2, v3)
    facet = {
        orientation = {
            x = orientation[1],
            y = orientation[2],
            z = orientation[3]
        },
        vertices = {
            [1] = {
                x = v1[1],
                y = v1[2],
                z = v1[3]
            },
            [2] = {
                x = v2[1],
                y = v2[2],
                z = v2[3]
            },
            [3] = {
                x = v3[1],
                y = v3[2],
                z = v3[3]
            }
        }
    }
    table.insert(solid.facets, facet)
    return solid
end

function encode_solid(solid)
    encoded_tbl = {}
    
    facet_orientation = nil
    vertex_position = nil

    table.insert(encoded_tbl, "solid " .. solid.name)
    for _, fct in pairs(solid.facets) do
        facet_orientation = {"\tfacet", "normal", fct.orientation.x, fct.orientation.y, fct.orientation.z}
        table.insert(encoded_tbl, table.concat(facet_orientation, " "))
        table.insert(encoded_tbl, "\t\touter loop")
        for _, vtx in pairs(fct.vertices) do
            vertex_position = {"\t\t\tvertex", vtx.x, vtx.y, vtx.z}
            table.insert(encoded_tbl, table.concat(vertex_position, " "))
        end
        table.insert(encoded_tbl, "\t\tendloop")
        table.insert(encoded_tbl, "\tendfacet")
    end
    table.insert(encoded_tbl, "endsolid")

    encoded_str = table.concat(encoded_tbl, "\n")
    return encoded_str
end

function load_ascii(filename)
    -- Verify file exists
    f = io.open(filename, "r")
    if f == nil then return nil end
    io.close(f)
    
    solid = {
        name = "imported",
        facets = {}
    }
    
    current_facet = nil
    current_verts = {}
    
    for line in io.lines(filename) do
        -- Trim whitespace
        line = string.match(line, "^%s*(.-)%s*$")
        
        if string.find(line, "^solid") != nil then
            solid.name = string.match(line, "^solid%s+(.*)") or "imported"
            
        elseif string.find(line, "^facet normal") != nil then
            nx, ny, nz = string.match(line, "normal%s+([%d%.%-e]+)%s+([%d%.%-e]+)%s+([%d%.%-e]+)")
            current_facet = {
                orientation = {x=tonumber(nx), y=tonumber(ny), z=tonumber(nz)},
                vertices = {}
            }
            
        elseif string.find(line, "^vertex") != nil then
            vx, vy, vz = string.match(line, "vertex%s+([%d%.%-e]+)%s+([%d%.%-e]+)%s+([%d%.%-e]+)")
            table.insert(current_facet.vertices, {
                x=tonumber(vx), y=tonumber(vy), z=tonumber(vz)
            })
            
        elseif string.find(line, "^endfacet") != nil then
            table.insert(solid.facets, current_facet)
            current_facet = nil
        end
    end
    
    return solid
end

stl.create_solid = create_solid
stl.add_facet = add_facet
stl.encode_solid = encode_solid
stl.load_ascii = load_ascii

return stl

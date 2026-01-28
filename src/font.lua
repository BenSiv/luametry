-- src/font.lua
-- Simplified Vector Font for Luametry

font = {}

-- Each glyph is a list of strokes. 
-- Each stroke is a list of {x, y} points.
-- Coordinate system: 0-10 unit height.
font.glyphs = {
    ['A'] = { {{0,0}, {5,10}, {10,0}}, {{2.5,5}, {7.5,5}} },
    ['B'] = { {{0,0}, {0,10}, {7,10}, {10,8}, {10,6}, {7,5}, {0,5}}, {{7,5}, {10,4}, {10,2}, {7,0}, {0,0}} },
    ['C'] = { {{10,2}, {8,0}, {2,0}, {0,2}, {0,8}, {2,10}, {8,10}, {10,8}} },
    ['D'] = { {{0,0}, {0,10}, {7,10}, {10,7}, {10,3}, {7,0}, {0,0}} },
    ['E'] = { {{10,0}, {0,0}, {0,10}, {10,10}}, {{0,5}, {7,5}} },
    ['F'] = { {{0,0}, {0,10}, {10,10}}, {{0,5}, {7,5}} },
    ['G'] = { {{10,8}, {8,10}, {2,10}, {0,8}, {0,2}, {2,0}, {8,0}, {10,2}, {10,5}, {6,5}} },
    ['H'] = { {{0,0}, {0,10}}, {{10,0}, {10,10}}, {{0,5}, {10,5}} },
    ['I'] = { {{5,0}, {5,10}}, {{2,0}, {8,0}}, {{2,10}, {8,10}} },
    ['J'] = { {{10,10}, {10,2}, {8,0}, {2,0}, {0,2}} },
    ['K'] = { {{0,0}, {0,10}}, {{0,5}, {10,10}}, {{0,5}, {10,0}} },
    ['L'] = { {{0,10}, {0,0}, {10,0}} },
    ['M'] = { {{0,0}, {0,10}, {5,5}, {10,10}, {10,0}} },
    ['N'] = { {{0,0}, {0,10}, {10,0}, {10,10}} },
    ['O'] = { {{2,0}, {0,2}, {0,8}, {2,10}, {8,10}, {10,8}, {10,2}, {8,0}, {2,0}} },
    ['P'] = { {{0,0}, {0,10}, {7,10}, {10,8.5}, {10,6.5}, {7,5}, {0,5}} },
    ['Q'] = { {{2,0}, {0,2}, {0,8}, {2,10}, {8,10}, {10,8}, {10,2}, {8,0}, {2,0}}, {{6,3}, {10,-1}} },
    ['R'] = { {{0,0}, {0,10}, {7,10}, {10,8.5}, {10,6.5}, {7,5}, {0,5}}, {{5,5}, {10,0}} },
    ['S'] = { {{0,2}, {2,0}, {8,0}, {10,2}, {10,4}, {8,6}, {2,4}, {0,6}, {0,8}, {2,10}, {8,10}, {10,8}} },
    ['T'] = { {{5,0}, {5,10}}, {{0,10}, {10,10}} },
    ['U'] = { {{0,10}, {0,2}, {2,0}, {8,0}, {10,2}, {10,10}} },
    ['V'] = { {{0,10}, {5,0}, {10,10}} },
    ['W'] = { {{0,10}, {2,0}, {5,5}, {8,0}, {10,10}} },
    ['X'] = { {{0,0}, {10,10}}, {{0,10}, {10,0}} },
    ['Y'] = { {{0,10}, {5,5}, {10,10}}, {{5,5}, {5,0}} },
    ['Z'] = { {{0,10}, {10,10}, {0,0}, {10,0}} },
    [' '] = { },
    ['0'] = { {{2,0}, {0,2}, {0,8}, {2,10}, {8,10}, {10,8}, {10,2}, {8,0}, {2,0}}, {{0,0}, {10,10}} },
    ['1'] = { {{2,8}, {5,10}, {5,0}}, {{2,0}, {8,0}} },
    ['2'] = { {{0,8}, {2,10}, {8,10}, {10,8}, {10,6}, {0,0}, {10,0}} },
    ['3'] = { {{0,8}, {2,10}, {8,10}, {10,8}, {10,6}, {6,5}, {10,4}, {10,2}, {8,0}, {2,0}, {0,2}} },
    ['4'] = { {{7,0}, {7,10}, {0,3}, {10,3}} },
    ['5'] = { {{10,10}, {0,10}, {0,5}, {8,5}, {10,3}, {10,2}, {8,0}, {2,0}, {0,2}} },
    ['6'] = { {{10,8}, {8,10}, {2,10}, {0,8}, {0,2}, {2,0}, {8,0}, {10,2}, {10,4}, {8,6}, {0,6}} },
    ['7'] = { {{0,10}, {10,10}, {4,0}} },
    ['8'] = { {{2,0}, {0,2}, {0,4}, {2,6}, {8,6}, {10,8}, {10,10}, {8,11}, {2,11}, {0,10}, {0,8}, {2,6}, {8,4}, {10,2}, {8,0}, {2,0}} },
    ['9'] = { {{0,2}, {2,0}, {8,0}, {10,2}, {10,8}, {8,10}, {2,10}, {0,8}, {0,6}, {2,4}, {10,4}} },
    ['-'] = { {{2,5}, {8,5}} },
    ['.'] = { {{4,0}, {5,1}, {6,0}, {5,-1}, {4,0}} },
    ['!'] = { {{5,10}, {5,3}}, {{5,1}, {6,0.5}, {5,0}, {4,0.5}, {5,1}} }
}

-- Default parameters
font.defaults = {
    h = 10,       -- Cap height
    t = 1.0,      -- Stroke thickness
    z = 2.0,      -- Extrusion depth
    spacing = 2.0 -- Letter spacing
}

function font.create_text(text_str, params)
    params = params or {}
    h = params.h or font.defaults.h
    t = params.t or font.defaults.t
    z = params.z or font.defaults.z
    spacing = params.spacing or font.defaults.spacing
    
    scale = h / 10
    
    cad = require("cad")
    letters = {}
    cursor_x = 0
    
    for i = 1, #text_str do
        char = string.upper(string.sub(text_str, i, i))
        glyph = font.glyphs[char] or font.glyphs[' ']
        
        pieces = {}
        
        for _, stroke in ipairs(glyph) do
            for j = 1, #stroke - 1 do
                p1 = stroke[j]
                p2 = stroke[j+1]
                
                -- Create a segment
                dx = p2[1] - p1[1]
                dy = p2[2] - p1[2]
                len = math.sqrt(dx*dx + dy*dy)
                
                if len > 0 then
                    angle = math.deg(math.atan2(dy, dx))
                    
                    seg = cad.create.cube({size=1, center=true})
                    seg = cad.modify.scale(seg, {len * scale, t * scale, z})
                    seg = cad.modify.rotate(seg, {0, 0, angle})
                    
                    mid_x = (p1[1] + p2[1]) / 2 * scale
                    mid_y = (p1[2] + p2[2]) / 2 * scale
                    seg = cad.modify.translate(seg, {cursor_x + mid_x, mid_y, 0})
                    
                    table.insert(pieces, seg)
                end
            end
            
            if params.rounded == true then
                 for j = 1, #stroke do
                    p = stroke[j]
                    dot = cad.create.cylinder({r=t*scale/2, h=z, fn=16, center=true})
                    dot = cad.modify.translate(dot, {cursor_x + p[1]*scale, p[2]*scale, 0})
                    table.insert(pieces, dot)
                end
            end
        end
        
        if #pieces > 0 then
            table.insert(letters, cad.combine.union(pieces))
        end
        
        cursor_x = cursor_x + (10 + spacing) * scale
    end
    
    if #letters == 0 then return nil end
    if #letters == 1 then return letters[1] end
    return cad.combine.union(letters)
end

return font

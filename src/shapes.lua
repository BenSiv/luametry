const cad = require("cad")

const shapes = {}

-- Create an arch (cube + cylinder top)
function arch(w, d, h, fn)
    r = w / 2
    hc = h - r
    cube_part = cad.create("cube", {size={w, d, hc}, center=true})
    cube_part = cad.transform("translate", cube_part, {0, 0, hc/2})
    cyl_part = cad.create("cylinder", {h=d, r=r, fn=fn, center=true})
    cyl_part = cad.transform("rotate", cyl_part, {90, 0, 0})
    cyl_part = cad.transform("translate", cyl_part, {0, 0, hc})
    return cad.boolean("union", {cube_part, cyl_part})
end

-- Create a rounded cube (box with rounded edges)
function rounded_cube(size, r, fn)
    if type(size) == "number" then
        size = {size, size, size}
    end
    
    x = size[1]
    y = size[2]
    z = size[3]
    
    if 2*r > x or 2*r > y or 2*r > z then
        error("Radius is too large for the cube dimensions.")
    end
    
    parts = {}
    
    -- Inner box (center)
    internal = cad.create("cube", {size={x - 2*r, y - 2*r, z - 2*r}, center=true})
    internal = cad.transform("translate", internal, {0, 0, z/2}) -- Center Z=z/2 to match bottom-aligned behavior?
    -- No, standard cube with center=true is centered on Origin.
    -- If we assume the user wants the same behavior as create("cube", {center=true}), then result should be centered on Origin.
    
    -- Let's make it centered on origin first.
    
    -- 1. Center Box
    box_c = cad.create("cube", {size={x - 2*r, y - 2*r, z}, center=true})
    table.insert(parts, box_c)
    
    -- 2. X-facing Plates (left/right fillers, not touching corners)
    box_x = cad.create("cube", {size={x, y - 2*r, z - 2*r}, center=true})
    table.insert(parts, box_x)
    
    -- 3. Y-facing Plates (front/back fillers)
    box_y = cad.create("cube", {size={x - 2*r, y, z - 2*r}, center=true})
    table.insert(parts, box_y)
    
    -- 4. Edge Cylinders (4 Z-axis, 4 X-axis, 4 Y-axis)
    
    -- Z-axis edges
    for _, dx in ipairs({-1, 1}) do
        for _, dy in ipairs({-1, 1}) do
             c = cad.create("cylinder", {h=z - 2*r, r=r, fn=fn, center=true})
             c = cad.transform("translate", c, {dx * (x/2 - r), dy * (y/2 - r), 0})
             table.insert(parts, c)
        end
    end
    
    -- X-axis edges
    for _, dy in ipairs({-1, 1}) do
        for _, dz in ipairs({-1, 1}) do
             c = cad.create("cylinder", {h=x - 2*r, r=r, fn=fn, center=true})
             c = cad.transform("rotate", c, {0, 90, 0})
             c = cad.transform("translate", c, {0, dy * (y/2 - r), dz * (z/2 - r)})
             table.insert(parts, c)
        end
    end
    
    -- Y-axis edges
     for _, dx in ipairs({-1, 1}) do
        for _, dz in ipairs({-1, 1}) do
             c = cad.create("cylinder", {h=y - 2*r, r=r, fn=fn, center=true})
             c = cad.transform("rotate", c, {90, 0, 0})
             c = cad.transform("translate", c, {dx * (x/2 - r), 0, dz * (z/2 - r)})
             table.insert(parts, c)
        end
    end
    
    -- 5. Corner Spheres
    for _, dx in ipairs({-1, 1}) do
        for _, dy in ipairs({-1, 1}) do
            for _, dz in ipairs({-1, 1}) do
                s = cad.create("sphere", {r=r, fn=fn})
                s = cad.transform("translate", s, {dx * (x/2 - r), dy * (y/2 - r), dz * (z/2 - r)})
                table.insert(parts, s)
            end
        end
    end
    
    return cad.boolean("union", parts)
end

shapes.arch = arch
shapes.rounded_cube = rounded_cube

return shapes

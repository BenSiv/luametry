
package.path = "src/?.lua;" .. package.path
const cad = require("cad")

function test_cad()
    print("Creating transform hierarchy...")
    
    -- Cube: 10x10x10 centered
    c = cad.create("cube", {size=10, center=true})
    
    -- Cylinder: r=2, h=20 centered
    cyl = cad.create("cylinder", {r=2, h=20, center=true})
    
    -- Rotate cylinder 90 deg on Y
    cyl_rot = cad.transform("rotate", cyl, {0, 90, 0})
    
    -- Union them
    u = cad.boolean("union", {c, cyl_rot})
    
    -- Translate whole thing up by 5
    final = cad.transform("translate", u, {0, 0, 5})
    
    print("Exporting to output.stl...")
    cad.export(final, "output.stl")
    print("Done.")
end

test_cad()

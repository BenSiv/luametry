package.path = "src/?.lua;" .. package.path
cad = require("cad")

-- Create 3D labels easily
label = cad.text("LUAMETRY", {
    h = 10,       -- Height
    t = 1.5,      -- Stroke thickness
    z = 2.0,      -- Extrusion depth
    rounded = true -- Smooth joints
})

return label

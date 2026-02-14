cad = require("cad")

shaft = cad.translate(
    cad.cylinder({r=3.000, h=89.325, center=true}), 
    {0.000, 0.000, 101.337}
)

handle_hull = cad.translate(
    cad.cylinder({r=11.490, h=109.175, center=true}), 
    {0.000, 0.000, 2.087}
)

remnant1_hull = cad.translate(
    cad.cylinder({r=11.490, h=107.068, center=true}), 
    {0.000, 0.000, 3.141}
)

remnant2_hull = cad.translate(
    cad.cylinder({r=11.490, h=107.068, center=true}), 
    {0.000, 0.000, 3.141}
)

filler = cad.translate(cad.cube(1), {0,0,0})

-- Mesh = Hull - (Hull_Remnant1 - (Hull_Remnant2 - Remnant3))
diff3 = cad.difference(remnant2_hull, filler)
diff2 = cad.difference(remnant1_hull, diff3)
handle = cad.difference(handle_hull, diff2)

model = cad.union({shaft, handle})

cad.export(model, "screwdriver_re_adv.stl")
return model

cad = require("cad")
model = cad.translate(cad.cube({size={10.000, 20.000, 30.000}, center=false}), {5.000, 5.000, 5.000})
cad.export(model, "test_cube_re.stl")
return model

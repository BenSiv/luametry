cad = require("cad")
model = cad.translate(cad.sphere(12.500), {10.000, 20.000, 30.000})
cad.export(model, "test_sphere_re.stl")
return model

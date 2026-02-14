-- test_sphere.lua
cad = require("cad")
s = cad.translate(cad.sphere(12.5), {10, 20, 30})
cad.export(s, "test_sphere.stl")
print("Exported test_sphere.stl")

-- test_reverse.lua
cad = require("cad")
c = cad.translate(cad.cube({size={10, 20, 30}, center=false}), {5, 5, 5})
cad.export(c, "test_cube.stl")
print("Exported test_cube.stl")


cad = require("cad")
cube = cad.cube(10, {center=true})
cad.export(cube, "out/test_cube.step")
print("Exported out/test_cube.step")

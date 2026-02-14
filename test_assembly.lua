-- test_assembly.lua
cad = require("cad")
c1 = cad.cylinder({r=5, h=20, center=true})
c2 = cad.translate(cad.cube({size=10, center=true}), {20, 0, 0})
assembly = cad.union({c1, c2})
cad.export(assembly, "test_assembly.stl")
print("Exported test_assembly.stl")

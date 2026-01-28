
cad = require("cad")
tet = cad.create.tetrahedron()
-- Scale up to be visible easily
tet = cad.modify.scale(tet, {10, 10, 10})
cad.export(tet, "out/simple.step")
print("Exported out/simple.step")

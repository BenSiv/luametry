cad = require("cad")
parts = {}
table.insert(parts, cad.translate(cad.cylinder({r=3.000, h=89.325, center=true}), {0.000, 0.000, 101.337}))
-- Handle and Tip were detected as complex meshes and are omitted from parametric reconstruction for now.
model = cad.union(parts)
cad.export(model, "screwdriver_re.stl")
return model

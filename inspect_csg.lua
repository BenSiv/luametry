cad = require("cad")
csg = require("csg.manifold")
for k, v in pairs(csg) do
    print(k, type(v))
end

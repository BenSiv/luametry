cad = require("cad")
csg = require("csg.manifold")
c = cad.cube({size={10, 20, 30}, center=false})
m = cad.render(c)
mesh = csg.to_mesh(m)
min_x, min_y, min_z = 1000, 1000, 1000
max_x, max_y, max_z = -1000, -1000, -1000
for _, v in ipairs(mesh.verts) do
    min_x = math.min(min_x, v[1])
    min_y = math.min(min_y, v[2])
    min_z = math.min(min_z, v[3])
    max_x = math.max(max_x, v[1])
    max_y = math.max(max_y, v[2])
    max_z = math.max(max_z, v[3])
end
print("Min:", min_x, min_y, min_z)
print("Max:", max_x, max_y, max_z)

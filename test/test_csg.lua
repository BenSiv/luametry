package.cpath = package.cpath .. ";./src/?.so"
csg = require("csg_manifold")
print("Loaded csg_manifold")

c = csg.cube(10, 10, 10, true)
print("Created cube")
s = csg.sphere(6, 30)
print("Created sphere")

x = csg.intersection(c, s)
print("Intersected")

mesh = csg.to_mesh(x)
print("Mesh verts: " .. #mesh.verts)
print("Mesh faces: " .. #mesh.faces)

-- Simple check of content
if #mesh.verts > 0 and #mesh.faces > 0 then
    print("Verification Passed: Mesh generated")
else
    print("Verification Failed: Empty mesh")
end

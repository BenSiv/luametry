package.path = package.path .. ";./src/?.lua"
cad = require("cad")

print("Testing CSG operations...")

-- 1. Intersection: Cube intersect Sphere
c = cad.create("cube", {size={10,10,10}, center=true})
s = cad.create("sphere", {r=6.5, fn=32})
i = cad.intersection({c, s})
if cad.export(i, "output_intersection.stl") then
    print("Exported output_intersection.stl")
else
    print("Failed to export intersection")
end

-- 2. Difference: Plate with hole
base = cad.create("cube", {size={20, 20, 5}, center=true})
hole = cad.create("cylinder", {h=10, r=5, center=true})
d = cad.difference({base, hole})
if cad.export(d, "output_difference.stl") then
    print("Exported output_difference.stl")
else
    print("Failed to export difference")
end

-- 3. Union: Two cylinders cross
cyl1 = cad.create("cylinder", {h=20, r=3, center=true})
-- Rotate second cylinder
cyl2_base = cad.create("cylinder", {h=20, r=3, center=true})
cyl2 = cad.transform("rotate", cyl2_base, {90, 0, 0})
u = cad.union({cyl1, cyl2})
if cad.export(u, "output_union.stl") then
    print("Exported output_union.stl")
else
    print("Failed to export union")
end

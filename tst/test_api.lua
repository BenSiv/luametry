package.path = "src/?.lua;" .. package.path
cad = require("cad")

-- 1. Test Create & Modify
print("Testing Create & Modify...")
c1 = cad.create.cube(10, true)
c2 = cad.modify.translate(c1, {15, 0, 0})
c3 = cad.modify.mirror(c1, {1, 0, 0}) -- Mirror across X plane
full_scene = cad.combine.union({c1, c2, c3})

cad.export(full_scene, "out/test_api_basic.stl")

-- 2. Test Trim
print("Testing Trim...")
cube = cad.create.cube(20, true)
-- Cut top half (Normal Z=1, Keep below?)
-- Manifold trim keeps the side pointed to by normal? Or removes it?
-- Usually trim keeps the "in" side. Manifold "TrimByPlane": "The new mesh is the part of the original mesh that lies on the negative side of the plane."
-- So normal points to REMOVED side.
-- Verify: if normal=(0,0,1), it removes Z>0.
trimmed = cad.combine.trim(cube, {0, 0, 1}, 0) 
cad.export(trimmed, "out/test_api_trim.stl")

-- 3. Test Query (Volume/Area)
print("Testing Query...")
vol = cad.query.volume(c1)
area = cad.query.surface_area(c1)
print("Cube 10x10x10 Volume: " .. vol .. " (Exp: 1000)")
print("Cube 10x10x10 Area: " .. area .. " (Exp: 600)")

if math.abs(vol - 1000) > 0.1 then error("Volume calculation failed!") end
if math.abs(area - 600) > 0.1 then error("Area calculation failed!") end

-- 4. Test Split & Decompose
print("Testing Split & Decompose...")
-- Create disjoint object
d1 = cad.create.sphere(5, 32)
d2 = cad.modify.translate(cad.create.sphere(5, 32), {20, 0, 0})
disjoint = cad.combine.union({d1, d2})

parts = cad.combine.decompose(disjoint)
print("Decomposed parts: " .. #parts .. " (Exp: 2)")
if not (#parts == 2) then error("Decompose failed!") end

-- Export parts individually
cad.export(parts[1], "out/test_api_part1.stl")
cad.export(parts[2], "out/test_api_part2.stl")

-- Test Split
split_cube = cad.create.cube(10, true)
-- Split by X plane
split_res = cad.combine.split(split_cube, {1, 0, 0}, 0)
print("Split result count: " .. #split_res .. " (Exp: 2)")
cad.export(split_res[1], "out/test_api_split1.stl") -- Kept (Negative side)
cad.export(split_res[2], "out/test_api_split2.stl") -- Removed (Positive side)

print("All API tests passed!")

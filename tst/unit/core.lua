
-- tst/unit_core.lua
-- Unit tests for core features and shorthand aliases

cad = require("cad")

function test_revolve()
    print("Testing Revolve...")
    pts = {}
    r = 2
    for i = 0, 16 do
        a = math.rad(i * 360 / 16)
        table.insert(pts, { 10 + math.cos(a) * r, math.sin(a) * r })
    end
    
    tor = cad.create.revolve(pts, {circular_segments=32, revolve_degrees=360})
    tor2 = cad.revolve(pts) -- Hit the alias
    
    vol = cad.query.volume(tor)
    print(string.format("Revolve Torus Volume: %.2f", vol))
    if math.abs(vol - 789.6) > 50 then 
        error("Revolve volume check failed: " .. vol)
    end
end

function test_mirror()
    print("Testing Mirror (Alias)...")
    c = cad.cube({size=10, center=false})
    c = cad.translate(c, {5, 5, 5})
    m = cad.mirror(c, {0, 1, 0})
    
    vol = cad.query.volume(m)
    if math.abs(vol - 1000) > 0.01 then error("Mirror volume check failed") end
end

function test_minkowski()
    print("Testing Minkowski (Aliases)...")
    c = cad.cube({size=1, center=true})
    s = cad.sphere({r=0.5, fn=8})
    
    res = cad.minkowski({c, s})
    res2 = cad.combine.minkowski({c, s}) -- Hit specific path
    
    vol = cad.query.volume(res)
    print(string.format("Minkowski Volume: %.2f", vol))
    if vol < 1 then error("Minkowski volume too small") end
end

function test_topology_aliases()
    print("Testing Topology Aliases...")
    c1 = cad.cube(10)
    c2 = cad.translate(c1, {5, 0, 0})
    
    u = cad.union({c1, c2})
    d = cad.difference(c1, c2)
    i = cad.intersection({c1, c2})
    h = cad.hull({c1, c2})
    
    -- Primitive aliases
    cyl = cad.cylinder(5, 10)
    sph = cad.sphere(5)
    tet = cad.tetrahedron()
    tor = cad.torus({major_r=10, minor_r=2})
    
    if cad.query.volume(u) <= 1000 then error("Union alias failed") end
end

function test_mesh_and_stl()
    print("Testing Mesh and STL import/export...")
    verts = {
        {0,0,0}, {1,0,0}, {1,1,0}, {0,1,0},
        {0,0,1}, {1,0,1}, {1,1,1}, {0,1,1}
    }
    faces = {
        {1,3,2}, {1,4,3}, -- Bottom
        {5,6,7}, {5,7,8}, -- Top
        {1,2,6}, {1,6,5}, -- Front
        {2,3,7}, {2,7,6}, -- Right
        {3,4,8}, {3,8,7}, -- Back
        {4,1,5}, {4,5,8}  -- Left
    }
    mesh_node = cad.from_mesh(verts, faces)
    vol = cad.query.volume(mesh_node)
    if math.abs(vol - 1) > 0.01 then error("from_mesh volume failed: " .. vol) end
    
    cad.export(mesh_node, "out/temp_unit.stl")
    stl_node = cad.from_stl("out/temp_unit.stl")
    
    -- OBJ Import/Export
    cad.export(mesh_node, "out/temp_unit.obj")
    obj_node = cad.create.from_obj("out/temp_unit.obj")
    obj_alias = cad.from_obj("out/temp_unit.obj")
    -- 3MF Export
    cad.export(mesh_node, "out/temp_unit.3mf")
end

function test_remaining_transforms()
    print("Testing Rotate and Scale aliases...")
    c = cad.cube(1)
    c1 = cad.rotate(c, {45, 45, 0})
    c2 = cad.scale(c, {2, 2, 2})
    c3 = cad.warp(c, function(x,y,z) return x,y,z end)
    
    if math.abs(cad.query.volume(c2) - 8) > 0.01 then error("Scale alias failed") end
end

function test_render()
    print("Testing Render and Round...")
    c1 = cad.cube(10)
    man = cad.render(c1)
    if man == nil then error("cad.render failed") end
    
    c_round = cad.round(c1, 1, 8)
end

function test_advanced_ops()
    print("Testing Trim, Split, Decompose...")
    c = cad.cube(10, true)
    
    -- Trim
    t = cad.combine.trim(c, {0, 0, 1}, 0)
    if math.abs(cad.query.volume(t) - 500) > 0.01 then error("Trim failed") end
    
    -- Split
    s_parts = cad.combine.split(c, {0, 0, 1}, 0)
    s1, s2 = s_parts[1], s_parts[2]
    if math.abs(cad.query.volume(s1) - 500) > 0.01 then error("Split failed") end
    
    -- Decompose
    c2 = cad.translate(c, {20, 0, 0})
    both = cad.union({c, c2})
    parts = cad.combine.decompose(both)
    if #parts != 2 then error("Decompose failed") end
end

function test_queries()
    print("Testing Query Area...")
    c = cad.cube(10)
    area = cad.query.surface_area(c)
    if math.abs(area - 600) > 0.01 then error("Surface area failed: " .. area) end
end

function test_all_variants()
    print("Ensuring all API variants are covered...")
    -- Generators
    v = cad.create.cube(1)
    v = cad.create.cylinder(1, 1)
    v = cad.create.sphere(1)
    v = cad.create.tetrahedron()
    v = cad.create.torus(1, 0.1)
    v = cad.create.extrude({{0,0},{1,0},{0,1}}, 1)
    v = cad.create.revolve({{10,0},{11,0},{10,1}})
    v = cad.create.from_obj("out/temp_unit.obj")
    v = cad.create.from_stl("out/temp_unit.stl")
    v = cad.create.text("ABC")
    v = cad.fillet(v, 0.1)
    v = cad.chamfer(v, 0.1)
    v = cad.modify.fillet(v, 0.1)
    v = cad.modify.chamfer(v, 0.1)
    
    -- Cleanup
    os.remove("out/temp_unit.stl")
    os.remove("out/temp_unit.obj")
    os.remove("out/temp_unit.3mf")
    
    -- Modifiers
    v = cad.modify.translate(v, {1,0,0})
    v = cad.modify.rotate(v, {0,0,0})
    v = cad.modify.scale(v, {1,1,1})
    v = cad.modify.mirror(v, {1,0,0})
    v = cad.modify.warp(v, function(x,y,z) return x,y,z end)
    v = cad.modify.round(v, 0.1)
end

function test_text()
    print("Testing Text Extrusion...")
    t = cad.text("CAD", {h=10, t=1, z=2})
    if t == nil then error("cad.text failed") end
    vol = cad.query.volume(t)
    if vol <= 0 then error("cad.text volume too small") end
end

-- Run them
test_revolve()
test_mirror()
test_minkowski()
test_topology_aliases()
test_mesh_and_stl()
test_remaining_transforms()
test_render()
test_advanced_ops()
test_queries()
test_all_variants()
test_text()

print("\nUnit core tests completed successfully.")
return true

package.path = "src/?.lua;" .. package.path
cad = require("cad")

function verify()
    print("Testing Tetrahedron...")
    tet = cad.create("tetrahedron")
    cad.export(tet, "out/tetrahedron.stl")

    print("Testing Torus...")
    tor = cad.create.torus( {major_r=5, minor_r=1, major_segs=32, minor_segs=16})
    cad.export(tor, "out/torus.stl")

    print("Testing Batch Hull...")
    s1 = cad.create.sphere( {r=1})
    s2 = cad.create.sphere( {r=1})
    s2 = cad.modify.translate( s2, {5, 0, 0})
    capsule = cad.combine.hull( {s1, s2})
    cad.export(capsule, "out/hull_capsule.stl")

    print("Testing Aliases...")
    c = cad.create.cube( {width=10, depth=5, height=2, center=true})
    cad.export(c, "out/cube_alias.stl")
    
    print("All verification exports complete.")
end

verify()

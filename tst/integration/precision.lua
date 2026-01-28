
package.path = "src/?.lua;" .. package.path
const cad = require("cad")
const stl = require("stl")

function verify()
    print("Generating test shapes...")
    -- Shape A: Cube 10x10x10 at 0,0,0
    a = cad.create.cube({size=10, center=true}) -- -5 to 5
    
    -- Shape B: Cube 10x10x10 at 5,0,0
    -- Overlap should be from 0 to 5 in X, width 5.
    -- Overlap volume: 5 * 10 * 10 = 500
    tmp_b = cad.create.cube({size=10, center=true})
    b = cad.modify.translate(tmp_b, {5, 0, 0}) -- 0 to 10
    
    print("Exporting temporary STLs...")
    cad.export(a, "temp_a.stl")
    cad.export(b, "temp_b.stl")
    
    print("Loading STLs back as manifolds...")
    ma = cad.create.from_stl("temp_a.stl")
    mb = cad.create.from_stl("temp_b.stl")
    
    print("Calculating Volumes...")
    vol_a = cad.query.volume(ma)
    vol_b = cad.query.volume(mb) 
    
    print(string.format("Volume A: %.2f (Expected ~1000)", vol_a))
    print(string.format("Volume B: %.2f (Expected ~1000)", vol_b))
    
    print("Calculating Intersection...")
    -- i = Intersection(ma, mb)
    i = cad.combine.intersection({ma, mb})
    vol_i = cad.query.volume(i)
    
    print(string.format("Intersection Volume: %.2f (Expected ~500)", vol_i))
    
    -- IOU
    union_vol = vol_a + vol_b - vol_i
    iou = vol_i / union_vol
    print(string.format("IOU: %.4f", iou))
    
    -- Cleanup
    os.remove("temp_a.stl")
    os.remove("temp_b.stl")
    
    if math.abs(vol_i - 500) < 1.0 then
        print("SUCCESS: Volume overlap is correct.")
    else
        print("FAILURE: Volume overlap mismatch.")
        os.exit(1)
    end
end

verify()

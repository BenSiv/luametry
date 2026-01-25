package.path = "src/?.lua;" .. package.path
const cad = require("cad")

function verify()
    print("Creating base cube 10x10x10...")
    c = cad.create("cube", {size=10, center=true})
    
    print("Applying round(1)...")
    -- Rounding with radius 1 adds 1 to all sides, so final size approx 12x12x12
    r = cad.round(c, 2, 50)
    
    print("Exporting to out/verify_round.stl...")
    res = cad.export(r, "out/verify_round.stl")
    
    if res then
        print("Export successful.")
    else
        print("Export failed.")
        os.exit(1)
    end
end

verify()

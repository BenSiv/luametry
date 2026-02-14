-- tst/unit/feedback.lua
-- Unit tests for Semantic Feedback Loop

cad = require("cad")

function test_source_attribution()
    print("Testing Source Attribution")
    -- Line 8
    c = cad.cube(10)
    
    if c.source_info == nil then error("Source info missing") end
    if string.find(c.source_info.source, "feedback.lua") == nil then 
        error("Incorrect source file: " .. tostring(c.source_info.source)) 
    end
    if c.source_info.line != 9 then 
        error("Incorrect line number: expected 9, got " .. tostring(c.source_info.line)) 
    end
    
    -- Op attribution (Line 18)
    u = cad.union({c, cad.cube(5)})
    if u.source_info.line != 20 then 
        error("Incorrect op line number: expected 20, got " .. tostring(u.source_info.line)) 
    end
end

function test_naming()
    print("Testing Naming API")
    c = cad.cube(10)
    cad.name(c, "my_box")
    if c.label != "my_box" then error("cad.name failed") end
end

function test_manifest_export()
    print("Testing Manifest Export")
    c = cad.cube(10)
    cad.name(c, "root")
    u = cad.union({c, cad.cube(5)})
    cad.name(u, "assembly")
    
    manifest_file = "out/test_manifest.json"
    cad.export_manifest(u, manifest_file)
    
    f = io.open(manifest_file, "r")
    if f == nil then error("Manifest file not created") end
    content = io.read(f, "*a")
    io.close(f)
    
    if string.find(content, "\"label\":\"assembly\"") == nil then error("Label 'assembly' missing in manifest") end
    if string.find(content, "\"label\":\"root\"") == nil then error("Label 'root' missing in manifest") end
    
    os.remove(manifest_file)
end

test_source_attribution()
test_naming()
test_manifest_export()

print("\nFeedback loop tests completed successfully.")
return true

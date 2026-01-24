-- analyze_benchy.lua
-- Analyze the reference Benchy STL by slicing it and measuring dimensions

-- Add src to package path
package.path = "src/?.lua;" .. package.path

const stl = require("stl")
const slicer = require("slicer")
const cad = require("cad")

-- Load reference mesh
print("Loading tst/benchy_ref.stl...")
mesh = stl.load_ascii("tst/benchy_ref.stl")

if mesh == nil then
    print("Error: Could not load tst/benchy_ref.stl")
    return
end

print("Loaded mesh: " .. mesh.name .. " with " .. #mesh.facets .. " facets")

-- Define slice locations
slices = {
    {name="Hull Z", axis="z", pos=2.0},
    {name="Deck Z", axis="z", pos=7.5},
    {name="Cabin Z", axis="z", pos=20.0},
    {name="Roof Z", axis="z", pos=32.0},
    
    {name="Center X", axis="x", pos=0.0},
    {name="Cabin X", axis="x", pos=11.0},
    
    {name="Center Y", axis="y", pos=0.0},
}

visual_shapes = {}

print("\n--- Cross-Section Analysis ---")

for _, sl in ipairs(slices) do
    segments = slicer.slice_mesh(mesh, sl.pos, sl.axis)
    
    if #segments > 0 then
        -- Measure
        bounds = slicer.measure_bounds(segments)
        width = bounds[1]
        length = bounds[2]
        cx = bounds[3]
        cy = bounds[4]
        
        print(string.format("Slice: %-15s %s=%.1f  Dims: %.2f x %.2f  Center: (%.2f, %.2f)", 
            sl.name, sl.axis, sl.pos, width, length, cx, cy))
            
        -- Visualize
        shape = slicer.segments_to_shape(segments, 0.2)
        table.insert(visual_shapes, shape)
        
        -- Add marker
        marker_size = 0.5
        marker = cad.create("cube", {marker_size, marker_size, marker_size, center=true})
        
        if sl.axis == "z" then
             marker = cad.transform("translate", marker, {cx, cy, sl.pos})
        elseif sl.axis == "y" then
             marker = cad.transform("translate", marker, {cx, sl.pos, cy}) -- swapped Y->Z
        elseif sl.axis == "x" then
             marker = cad.transform("translate", marker, {sl.pos, cx, cy}) -- swapped X->Z
        end
        
        table.insert(visual_shapes, marker)
    else
        print(string.format("Slice: %-15s %s=%.1f  (Empty)", sl.name, sl.axis, sl.pos))
    end
end

print("\nGenerating Projections...")
print("- Top View (Z)...")
top_proj = slicer.project_mesh(mesh, "z", 1.0)
table.insert(visual_shapes, top_proj)

print("- Side View (Y)...")
side_proj = slicer.project_mesh(mesh, "y", 1.0)
table.insert(visual_shapes, side_proj)

print("- Front View (X)...")
front_proj = slicer.project_mesh(mesh, "x", 1.0)
table.insert(visual_shapes, front_proj)

-- Create composite visualization
if #visual_shapes > 0 then
    final_shape = cad.boolean("union", visual_shapes)
    print("\nExporting visualization to out/benchy_projections.stl...")
    cad.export(final_shape, "out/benchy_projections.stl")
end

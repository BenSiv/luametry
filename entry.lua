-- entry.lua
-- Main entry point for lstl

args = {...}

-- Ensure standard libraries are loaded (if not automatically)
-- In static build, we need to make sure 'cad', 'shapes', 'stl' are available via require.
-- luastatic typically preloads them.

print("LSTL 1.0")

if #args == 0 then
    print("Usage: lstl <script.lua>")
    print("Available modules: cad, shapes, stl, csg_manifold")
    os.exit(0)
end

script_file = args[1]
f = io.open(script_file, "r")
if f == nil then
    print("Error: Could not open script: " .. script_file)
    os.exit(1)
end
io.close(f)

-- Execute the user script
dofile(script_file)

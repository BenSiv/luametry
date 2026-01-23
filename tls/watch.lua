lfs = require("lfs")

-- Configuration
watch_files = {
    "src/cad.lua",
    "src/shapes.lua",
    "src/stl.lua",
    "tst/benchy.lua",
    "tst/test_cad.lua",
    "tst/test_stl.lua"
}

build_command = "./lstl tst/benchy.lua"

-- Helper to get mtimes
function get_file_mtimes(paths)
    mtimes = {}
    for _, path in ipairs(paths) do
        attr = lfs.attributes(path)
        if attr != nil then
            mtimes[path] = attr.modification
        end
    end
    return mtimes
end

print("Watching " .. #watch_files .. " files...")
print("Command: " .. build_command)

last_mtimes = get_file_mtimes(watch_files)

while true do
    -- Sleep implementation using os.execute("sleep") since standard Lua has no sleep
    os.execute("sleep 1")
    
    current_mtimes = get_file_mtimes(watch_files)
    changed = false
    
    for path, mtime in pairs(current_mtimes) do
        if last_mtimes[path] != mtime then
            print("File changed: " .. path)
            changed = true
            break
        end
    end
    
    -- Check if new files appeared (not strictly needed for this fixed list, but good practice)
    -- For fixed list, just checking modify is enough.
    
    if changed then
        print("Running: " .. build_command)
        os.execute(build_command)
        last_mtimes = current_mtimes
    end
end

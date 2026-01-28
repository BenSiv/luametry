-- cli.lua
-- Command-line interface for Luametry

lfs = require("lfs")

cli = {}

-- Default configuration
cli.config = {
    viewer = os.getenv("LUAMETRY_VIEWER") or "f3d",
    viewer_args = "--up +Z --resolution 1200,800"
}

-- Helper to get the real home directory (handles sudo)
function cli.get_real_home()
    h = os.getenv("HOME")
    su = os.getenv("SUDO_USER")
    if su != nil and su != "" then
        tmp = "/tmp/luam_home"
        os.execute("getent passwd " .. su .. " | cut -d: -f6 > " .. tmp)
        f = io.open(tmp, "r")
        if f != nil then
            io.input(f)
            rh = io.read("*l")
            io.close(f)
            os.remove(tmp)
            if rh != nil and rh != "" then
                return rh
            end
        end
    end
    return h
end

-- Load config file
function cli.load_config()
    paths = {
        cli.get_real_home() .. "/.config/luametry/settings.lua",
        ".luametry.conf"
    }
    for _, path in ipairs(paths) do
        f = io.open(path, "r")
        if f != nil then
            io.close(f)
            cfg = dofile(path)
            if type(cfg) == "table" then
                for k, v in pairs(cfg) do
                    cli.config[k] = v
                end
            end
        end
    end
end
cli.load_config()

-- Help strings for each command
cli.help_strings = {
    ["luametry"] = """
Usage: luametry <command> [options]

luametry run <file>
luametry live <file> [-v viewer]

defaults:
run  -> execute script, generate STL
live -> run + watch + viewer

luametry <command> -h for more info
    """,
    ["luametry run"] = """
Description:
Runs a CAD script and generates an STL file.

Required:
<file>  Path to the Lua CAD script.

Examples:
luametry run tst/benchy.lua
    """,
    ["luametry live"] = """
Description:
Live preview mode: runs the script, watches for changes, 
and opens a 3D viewer that reloads on file changes.

Required:
<file>  Path to the Lua CAD script.

Optional:
-v --viewer <cmd>  3D viewer command (default: f3d)

Examples:
luametry live tst/benchy.lua
luametry live tst/benchy.lua -v meshlab
    """,
    ["luametry export"] = """
Description:
Runs a script and exports the returned shape to a file.

Required:
<file>         Path to the Lua CAD script.
-o, --output   Path to the output file (STL or STEP).

Examples:
luametry export tst/benchy.lua -o out/result.stl
luametry export tst/bolt.lua -o out/bolt.step
    """,
    ["luametry install"] = """
Description:
Installs the luametry binary to /usr/local/bin/luametry.
Requires sudo/administrative privileges.

Examples:
sudo luametry install
    """,
    ["luametry update"] = """
Description:
Updates Luametry by pulling latest from git and rebuilding.
Does not automatically install to system path.

Examples:
luametry update
    """,
    ["luametry preview"] = """
Description:
Generates an ASCII art preview of a CAD script in the terminal.

Required:
<file>  Path to the Lua CAD script.

Optional:
--width <n>   Preview width (default: 80)
--height <n>  Preview height (default: 40)

Examples:
luametry preview tst/examples/hex_bolt.lua
luametry preview tst/examples/hex_bolt.lua --width 100 --height 50
    """
}

function cli.get_help(command)
    return cli.help_strings[command] or cli.help_strings["luametry"]
end

-- Helper to recursively find all .lua files in a directory
function cli.scan_dir(dir, results)
    for entry in lfs.dir(dir) do
        if entry != "." and entry != ".." then
            path = dir .. "/" .. entry
            attr = lfs.attributes(path)
            if attr.mode == "directory" then
                cli.scan_dir(path, results)
            elseif string.match(entry, "%.lua$") != nil then
                table.insert(results, path)
            end
        end
    end
end

-- Helper to collect all files that should trigger a rebuild
function cli.get_watch_files(script)
    files = {}
    -- 1. Core source files
    if lfs.attributes("src") != nil then
        cli.scan_dir("src", files)
    end
    
    -- 2. Script directory
    if script != nil then
        script_dir = string.match(script, "(.*)/") or "."
        if script_dir != "src" then -- Avoid double scan
            for entry in lfs.dir(script_dir) do
                if string.match(entry, "%.lua$") != nil then
                    table.insert(files, script_dir .. "/" .. entry)
                end
            end
        end
    end
    
    -- 3. Config
    conf = cli.get_real_home() .. "/.config/luametry/settings.lua"
    if lfs.attributes(conf) != nil then
        table.insert(files, conf)
    end
    
    return files
end

function cli.get_mtimes(paths)
    mtimes = {}
    for _, path in ipairs(paths) do
        attr = lfs.attributes(path)
        if attr != nil then
            mtimes[path] = attr.modification
        end
    end
    return mtimes
end

-- Watch files and call callback on change
function cli.watch_loop(script, on_change)
    print("Watching for changes...")
    
    last_files = cli.get_watch_files(script)
    last_mtimes = cli.get_mtimes(last_files)
    
    while true do
        os.execute("sleep 1")
        
        current_files = cli.get_watch_files(script)
        current_mtimes = cli.get_mtimes(current_files)
        
        changed = false
        
        -- Check for changes in mtimes or new/deleted files
        for path, mtime in pairs(current_mtimes) do
            if last_mtimes[path] != mtime then
                if last_mtimes[path] != nil then
                    print("Changed: " .. path)
                else
                    print("New file detected: " .. path)
                end
                changed = true
                break
            end
        end
        
        -- Check for deleted files
        if changed == false then
            for path, _ in pairs(last_mtimes) do
                if current_mtimes[path] == nil then
                    print("File removed: " .. path)
                    changed = true
                    break
                end
            end
        end

        if changed then
            on_change()
            last_mtimes = current_mtimes
        end
    end
end

-- Custom error handler for xpcall
function cli.error_handler(err)
    return debug.traceback(err, 2)
end

function cli.safe_dofile(path)
    ok, res = xpcall(function() return dofile(path) end, cli.error_handler)
    if not ok then
        print("\n" .. string.rep("-", 40))
        print("LUAMETRY SCRIPT ERROR")
        print(string.rep("-", 40))
        print(res)
        print(string.rep("-", 40) .. "\n")
        return nil, res
    end
    return res
end

-- Run a script
function cli.do_run(cmd_args)
    -- Check for help flags first
    for _, a in ipairs(cmd_args) do
        if a == "-h" or a == "--help" then
            print(cli.get_help("luametry run"))
            return "success"
        end
    end
    
    script = nil
    output_path = nil
    
    i = 1
    while i <= #cmd_args do
        a = cmd_args[i]
        if a == "-o" or a == "--output" then
            output_path = cmd_args[i + 1]
            i = i + 2
        else
            if script == nil then
                script = a
            end
            i = i + 1
        end
    end
    
    if script == nil then
        print("Error: No script specified")
        print(cli.get_help("luametry run"))
        return "error"
    end

    res = cli.safe_dofile(script)
    if res == nil then return "error" end
    
    -- If script returns a shape, export it
    if type(res) == "table" and res.type != nil then
        if output_path == nil then
            basename = string.match(script, "([^/]+)%.lua$") or "output"
            output_path = "out/" .. basename .. ".stl"
        end
        cad_mod = require("cad")
        print("Exporting to " .. output_path .. "...")
        if cad_mod.export(res, output_path) == false then
            return "error"
        end
        print("Success.")
    end
    
    return "success"
end

-- Live preview
function cli.do_live(cmd_args)
    -- Check for help flags first
    for _, a in ipairs(cmd_args) do
        if a == "-h" or a == "--help" then
            print(cli.get_help("luametry live"))
            return "success"
        end
    end
    
    -- Parse optional viewer flag
    viewer = cli.config.viewer
    script = nil
    i = 1
    while i <= #cmd_args do
        a = cmd_args[i]
        if a == "-v" or a == "--viewer" then
            viewer = cmd_args[i + 1]
            i = i + 2
        else
            if script == nil then
                script = a
            end
            i = i + 1
        end
    end
    
    if script == nil then
        print("Error: No script specified")
        print(cli.get_help("luametry live"))
        return "error"
    end
    
    print("Luametry Live Mode")
    print("Script: " .. script)
    print("Viewer: " .. viewer)
    
    basename = string.match(script, "([^/]+)%.lua$") or "output"
    output_file = "out/" .. basename .. ".stl"
    
    -- Function to build and export
    function build_and_export()
        res = cli.safe_dofile(script)
        if type(res) == "table" and res.type != nil then
            cad_mod = require("cad")
            cad_mod.export(res, output_file)
        end
    end

    -- Initial build
    build_and_export()
    
    -- Launch viewer in background
    viewer_cmd = viewer .. " " .. cli.config.viewer_args .. " " .. output_file .. " &"
    print("Tip: Press R in f3d to reload after changes.")
    os.execute(viewer_cmd)
    
    -- Give viewer time to start
    os.execute("sleep 0.5")
    
    function viewer_running()
        ret = os.execute("pgrep -x " .. viewer .. " > /dev/null 2>&1")
        return ret == 0 or ret == true
    end
    
    print("Watching for changes... (Ctrl+C or close viewer to stop)")
    last_files = cli.get_watch_files(script)
    last_mtimes = cli.get_mtimes(last_files)
    
    while viewer_running() do
        os.execute("sleep 1")
        
        current_files = cli.get_watch_files(script)
        current_mtimes = cli.get_mtimes(current_files)
        
        changed = false
        for path, mtime in pairs(current_mtimes) do
            if last_mtimes[path] != mtime then
                print("Changed: " .. path .. " - Rebuilding...")
                build_and_export()
                changed = true
                break
            end
        end
        
        if changed == false then
             for path, _ in pairs(last_mtimes) do
                if current_mtimes[path] == nil then
                    print("File removed - Rebuilding...")
                    build_and_export()
                    changed = true
                    break
                end
            end
        end

        if changed then
            last_mtimes = current_mtimes
        end
    end
    
    print("Live mode stopped.")
    print("Live mode stopped.")
    return "success"
end

-- Export command
function cli.do_export(cmd_args)
    -- Check for help flags first
    for _, a in ipairs(cmd_args) do
        if a == "-h" or a == "--help" then
            print(cli.get_help("luametry export"))
            return "success"
        end
    end
    
    script = nil
    output_path = nil
    
    i = 1
    while i <= #cmd_args do
        a = cmd_args[i]
        if a == "-o" or a == "--output" then
            output_path = cmd_args[i + 1]
            i = i + 2
        else
            if script == nil then
                script = a
            end
            i = i + 1
        end
    end
    
    if script == nil then
        print("Error: No script specified")
        print(cli.get_help("luametry export"))
        return "error"
    end
    
    if output_path == nil then
        print("Error: No output file specified (-o/--output)")
        print(cli.get_help("luametry export"))
        return "error"
    end
    
    -- Execute script and get result
    -- We assume the script returns the shape
    result = dofile(script)
    
    if result == nil then
        print("Error: Script did not return a shape.")
        print("Ensure your script ends with 'return my_shape'")
        return "error"
    end
    
    cad_mod = require("cad")
    print("Exporting to " .. output_path .. "...")
    success = cad_mod.export(result, output_path)
    
    if success then
        print("Success.")
        return "success"
    else
        print("Export failed.")
        return "error"
    end
end

-- Install command
function cli.do_install(cmd_args)
    -- Check for help flags first
    for _, a in ipairs(cmd_args) do
        if a == "-h" or a == "--help" then
            print(cli.get_help("luametry install"))
            return "success"
        end
    end

    print("Installing Luametry to /usr/local/bin/luametry...")
    -- Ensure you are in the project root
    source = "bin/luametry"
    if lfs.attributes(source) == nil then
        print("Error: Could not find binary at " .. source)
        print("Ensure you are running this from the project root.")
        return "error"
    end

    -- 1. Setup global config
    home = cli.get_real_home()
    if home != nil then
        config_dir = home .. "/.config/luametry"
        settings_file = config_dir .. "/settings.lua"
        
        -- Create directory
        os.execute("mkdir -p " .. config_dir)
        
        -- Create default settings if missing
        if lfs.attributes(settings_file) == nil then
            print("Initializing config: " .. settings_file)
            f = io.open(settings_file, "w")
            if f != nil then
                io.write(f, "return {\n")
                io.write(f, "    -- Default 3D viewer\n")
                io.write(f, "    viewer = \"f3d\",\n")
                io.write(f, "    -- Arguments passed to viewer in live mode\n")
                io.write(f, "    viewer_args = \"--up +Z --resolution 1200,800\"\n")
                io.write(f, "}\n")
                io.close(f)
            end
        else
            print("Config already exists: " .. settings_file)
        end
    end

    -- 2. Install binary
    cmd = "cp " .. source .. " /usr/local/bin/luametry"
    print("Running: " .. cmd)
    ret = os.execute(cmd)
    
    if ret == 0 or ret == true then
        print("Successfully installed luametry.")
        return "success"
    else
        print("Installation failed. Did you run with sudo?")
        return "error"
    end
end

-- Update command
function cli.do_update(cmd_args)
    print("Updating Luametry...")
    
    -- Check for git
    if lfs.attributes(".git") == nil then
        print("Error: Not a git repository. Update command only works inside the source repo.")
        return "error"
    end
    
    print("Pulling latest changes...")
    os.execute("git pull")
    
    print("Rebuilding...")
    ret = os.execute("bash bld/build.sh")
    
    if ret == 0 or ret == true then
        print("\nUpdate complete. New binary at bin/luametry")
        print("Run 'sudo luametry install' to update your system-wide installation.")
        return "success"
    else
        print("\nBuild failed during update.")
        return "error"
    end
end

-- Preview command
function cli.do_preview(cmd_args)
    -- Check for help flags first
    for _, a in ipairs(cmd_args) do
        if a == "-h" or a == "--help" then
            print(cli.get_help("luametry preview"))
            return "success"
        end
    end
    
    script = nil
    width = 80
    height = 40
    
    i = 1
    while i <= #cmd_args do
        a = cmd_args[i]
        if a == "--width" then
            width = tonumber(cmd_args[i + 1])
            i = i + 2
        elseif a == "--height" then
            height = tonumber(cmd_args[i + 1])
            i = i + 2
        else
            if script == nil then
                script = a
            end
            i = i + 1
        end
    end
    
    if script == nil then
        print("Error: No script specified")
        print(cli.get_help("luametry preview"))
        return "error"
    end
    
    res = cli.safe_dofile(script)
    if res == nil then return "error" end
    
    if type(res) == "table" and res.type != nil then
        cad_mod = require("cad")
        print(cad_mod.query.preview(res, width, height))
        return "success"
    else
        print("Error: Script did not return a shape.")
        return "error"
    end
end

-- Main entry point
function cli.main()
    command_funcs = {
        ["run"] = cli.do_run,
        ["live"] = cli.do_live,
        ["export"] = cli.do_export,
        ["install"] = cli.do_install,
        ["update"] = cli.do_update,
        ["preview"] = cli.do_preview
    }
    
    command = arg[1]
    
    -- Check for help flags at top level
    if command == nil or command == "-h" or command == "--help" then
        print(cli.get_help("luametry"))
        return
    end
    
    -- Update arg[0] for subcommand help
    arg[0] = "luametry " .. command
    
    -- Collect remaining arguments
    cmd_args = {}
    for i = 2, #arg do
        table.insert(cmd_args, arg[i])
    end
    cmd_args[0] = arg[0]
    
    func = command_funcs[command]
    if func == nil then
        print("'" .. command .. "' is not a valid command\n")
        print(cli.get_help("luametry"))
        return
    end
    
    status = func(cmd_args)
    if status != "success" then
        os.exit(1)
    end
end

return cli

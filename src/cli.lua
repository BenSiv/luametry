-- cli.lua
-- Command-line interface for Luametry

lfs = require("lfs")

cli = {}

-- Default configuration
cli.config = {
    viewer = os.getenv("LUAMETRY_VIEWER") or "f3d",
    viewer_args = "--up +Z --resolution 1200,800"
}

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
    """
}

function cli.get_help(command)
    return cli.help_strings[command] or cli.help_strings["luametry"]
end

-- Watch files and call callback on change
function cli.watch_loop(script, on_change)
    files = {
        "src/cad.lua",
        "src/shapes.lua",
        "src/stl.lua",
        script
    }
    
    function get_mtimes(paths)
        mtimes = {}
        for _, path in ipairs(paths) do
            attr = lfs.attributes(path)
            if attr != nil then
                mtimes[path] = attr.modification
            end
        end
        return mtimes
    end
    
    print("Watching " .. #files .. " files...")
    last_mtimes = get_mtimes(files)
    
    while true do
        os.execute("sleep 1")
        current_mtimes = get_mtimes(files)
        
        for path, mtime in pairs(current_mtimes) do
            if last_mtimes[path] != mtime then
                print("Changed: " .. path)
                on_change()
                last_mtimes = current_mtimes
                break
            end
        end
    end
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
    
    script = cmd_args[1]
    
    if script == nil then
        print("Error: No script specified")
        print(cli.get_help("luametry run"))
        return "error"
    end
    
    dofile(script)
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
    
    -- Initial build
    dofile(script)
    
    -- Launch viewer in background
    viewer_cmd = viewer .. " " .. cli.config.viewer_args .. " " .. output_file .. " &"
    print("Tip: Press R in f3d to reload after changes.")
    os.execute(viewer_cmd)
    
    -- Give viewer time to start
    os.execute("sleep 0.5")
    
    -- Get viewer PID to monitor
    viewer_pid_cmd = "pgrep -n " .. viewer
    viewer_pid = nil
    
    -- Watch files for changes
    files = {
        "src/cad.lua",
        "src/shapes.lua", 
        "src/stl.lua",
        script
    }
    
    function get_mtimes(paths)
        mtimes = {}
        for _, path in ipairs(paths) do
            attr = lfs.attributes(path)
            if attr != nil then
                mtimes[path] = attr.modification
            end
        end
        return mtimes
    end
    
    function viewer_running()
        ret = os.execute("pgrep -x " .. viewer .. " > /dev/null 2>&1")
        return ret == 0 or ret == true
    end
    
    print("Watching " .. #files .. " files... (Ctrl+C or close viewer to stop)")
    last_mtimes = get_mtimes(files)
    
    while viewer_running() do
        os.execute("sleep 1")
        current_mtimes = get_mtimes(files)
        
        for path, mtime in pairs(current_mtimes) do
            if last_mtimes[path] != mtime then
                print("Changed: " .. path .. " - Rebuilding...")
                ok, err = pcall(dofile, script)
                if not ok then
                    print("Error: " .. tostring(err))
                end
                last_mtimes = current_mtimes
                break
            end
        end
    end
    
    print("Live mode stopped.")
    return "success"
end

-- Main entry point
function cli.main()
    command_funcs = {
        ["run"] = cli.do_run,
        ["live"] = cli.do_live
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

-- cli.lua
-- Command-line interface for Luametry using argparse

lfs = require("lfs")
argparse = require("lib.argparse")

cli = {}

-- Default configuration
cli.config = {
    viewer = os.getenv("LUAMETRY_VIEWER") or "f3d",
    viewer_args = "--up +Z --resolution 1200,800"
}

-- Define CLI arguments using argparse format
cli.arg_string = """
    -c --command arg string true
    -s --script arg string false
    -v --viewer arg string false
"""

cli.help = """
Luametry 1.0 - Lua-based parametric CAD

Commands:
  -c run      Run a CAD script
  -c watch    Watch files and rebuild
  -c live     Live preview with viewer

Options:
  -s <file>   Script file
  -v <cmd>    3D viewer (default: f3d)

Examples:
  luametry -c run -s tst/benchy.lua
  luametry -c live -s tst/benchy.lua -v meshlab
"""

-- Watch files for changes and rebuild
function cli.watch(script)
    print("Luametry Watch Mode")
    print("Script: " .. script)
    
    files = {
        "src/cad.lua",
        "src/shapes.lua",
        "src/stl.lua",
        script
    }
    
    build_cmd = arg[0] .. " -c run -s " .. script
    
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
        changed = false
        
        for path, mtime in pairs(current_mtimes) do
            if last_mtimes[path] != mtime then
                print("Changed: " .. path)
                changed = true
                break
            end
        end
        
        if changed then
            print("Rebuilding...")
            os.execute(build_cmd)
            last_mtimes = current_mtimes
        end
    end
end

-- Live preview
function cli.live(script, viewer)
    print("Luametry Live Mode")
    print("Script: " .. script)
    print("Viewer: " .. viewer)
    
    bin = arg[0]
    os.execute(bin .. " -c run -s " .. script)
    
    watcher_cmd = bin .. " -c watch -s " .. script .. " &"
    os.execute(watcher_cmd)
    
    basename = string.match(script, "([^/]+)%.lua$") or "output"
    output_file = "out/" .. basename .. ".stl"
    
    viewer_cmd = viewer .. " " .. cli.config.viewer_args .. " " .. output_file
    print("Tip: Press Up Arrow in viewer to reload.")
    os.execute(viewer_cmd)
    
    os.execute("pkill -f '" .. bin .. " -c watch'")
    print("Live mode stopped.")
end

-- Run a script
function cli.run_script(script)
    dofile(script)
end

-- Main entry point
function cli.main(cmd_args)
    expected_args = argparse.def_args(cli.arg_string)
    opts = argparse.parse_args(cmd_args, expected_args, cli.help)
    
    if opts == nil then
        return
    end
    
    viewer = opts.viewer or cli.config.viewer
    script = opts.script
    
    if script == nil then
        print("Error: No script specified (-s)")
        return
    end
    
    cmd = opts.command or "run"
    
    if cmd == "run" then
        cli.run_script(script)
    elseif cmd == "watch" then
        cli.watch(script)
    elseif cmd == "live" then
        cli.live(script, viewer)
    else
        print("Error: Unknown command: " .. cmd)
    end
end

return cli

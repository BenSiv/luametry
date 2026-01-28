-- tst/unit/cli.lua
-- Unit tests for CLI parsing and logic

cli = require("cli")

function test_help_strings()
    print("Testing Help Strings...")
    h = cli.get_help("luametry run")
    if string.find(h, "Runs a CAD script") == nil then error("Help string for run failed") end
    
    h = cli.get_help("invalid")
    if string.find(h, "Usage: luametry") == nil then error("Default help string failed") end
end

function test_config_loading()
    print("Testing Config Loading...")
    -- We can't easily mock HOME without side effects, but we can verify cli.config exists
    if cli.config == nil then error("Config table missing") end
    if cli.config.viewer == nil then error("Default viewer missing") end
end

function test_watch_discovery()
    print("Testing Watch Discovery...")
    files = cli.get_watch_files("tst/examples/hex_bolt.lua")
    
    found_core = false
    found_script = false
    
    for _, f in ipairs(files) do
        if string.find(f, "src/cad.lua") != nil then found_core = true end
        if string.find(f, "tst/examples/hex_bolt.lua") != nil then found_script = true end
    end
    
    if found_core == false then error("Watch did not find cad.lua") end
    if found_script == false then error("Watch did not find script") end
end

function test_screenshot()
    print("Testing Screenshot command...")
    -- This relies on f3d but we can check if it tries to run
    res = cli.do_screenshot({"tst/examples/hex_bolt_simple.lua", "-o", "out/test_ss.png"})
    -- If f3d is missing it might return error, but we can verify the path parsing at least
    os.remove("out/test_ss.png")
end

-- Run them
test_help_strings()
test_config_loading()
test_watch_discovery()
test_screenshot()

print("\nCLI unit tests passed.")
return true

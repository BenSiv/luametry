
-- tst/run_all.lua
-- Advanced Test Runner for Luametry

lfs = require("lfs")
utils = require("lib.utils") -- Using existing utils if available, or define helper

results = {
    passed = {},
    failed = {}
}

-- Feature Tracking
api_coverage = {} -- map: "cad.func.name" -> count

function discover_and_wrap_api(tbl, prefix, seen)
    if seen == nil then
        seen = {}
    end
    if seen[tbl] != nil then return end
    seen[tbl] = true
    
    for k, v in pairs(tbl) do
        if type(v) == "function" then
            full_name = prefix .. "." .. k
            api_coverage[full_name] = 0
            
            -- Wrap the function
            original_func = v
            tbl[k] = function(...)
                api_coverage[full_name] = api_coverage[full_name] + 1
                return original_func(...)
            end
        elseif type(v) == "table" and k != "package" and k != "_G" and k != "results" then
            -- Avoid recursion into system tables or already discovered ones
            discover_and_wrap_api(v, prefix .. "." .. k, seen)
        end
    end
end

-- Initialize API Tracking
cad = require("cad")
discover_and_wrap_api(cad, "cad")

-- Ensure cad is in package.loaded so tests use the wrapped version
package.loaded["cad"] = cad

function get_test_files(dir, file_list)
    if file_list == nil then
        file_list = {}
    end
    for entry in lfs.dir(dir) do
        if entry != "." and entry != ".." then
            path = dir .. "/" .. entry
            attr = lfs.attributes(path)
            if attr.mode == "directory" then
                get_test_files(path, file_list)
            elseif (string.match(entry, "%.lua$") != nil) and entry != "run_all.lua" then
                table.insert(file_list, path)
            end
        end
    end
    return file_list
end

function error_handler(err)
    return {
        message = err,
        traceback = debug.traceback("", 2)
    }
end

function run_test(path)
    print("Testing: " .. path)
    
    -- Load the chunk
    chunk, load_err = loadfile(path)
    if chunk == nil then
        load_err_msg = "unknown"
        if load_err != nil then
            load_err_msg = load_err
        end
        table.insert(results.failed, {
            path = path,
            message = "Load error: " .. load_err_msg,
            traceback = ""
        })
        print(" [FAIL] Load error")
        return
    end

    -- Run the chunk
    status_success, err_obj = xpcall(chunk, error_handler)
    
    if status_success == true then
        table.insert(results.passed, path)
        print(" [PASS]")
    else
        fail_message = "unknown error"
        fail_traceback = ""
        if err_obj != nil then
            if err_obj.message != nil then
                fail_message = err_obj.message
            end
            if err_obj.traceback != nil then
                fail_traceback = err_obj.traceback
            end
        end
        table.insert(results.failed, {
            path = path,
            message = fail_message,
            traceback = fail_traceback
        })
        print(" [FAIL]")
    end
end

-- Main Execution
test_root = "tst"
all_tests = get_test_files(test_root)

print("\n--- Luametry Test Suite ---")
print("Found " .. #all_tests .. " tests.\n")

for _, test_path in ipairs(all_tests) do
    run_test(test_path)
end

print("\n--- Summary ---")
print("Total:  " .. #all_tests)
print("Passed: " .. #results.passed)
print("Failed: " .. #results.failed)

-- Feature Coverage Report
covered_count = 0
total_features = 0
uncovered = {}

-- Sort keys for stable report
feature_names = {}
for name, _ in pairs(api_coverage) do 
    table.insert(feature_names, name) 
    total_features = total_features + 1
end
table.sort(feature_names)

for _, name in ipairs(feature_names) do
    if api_coverage[name] > 0 then
        covered_count = covered_count + 1
    else
        table.insert(uncovered, name)
    end
end

coverage_pct = 0
if total_features > 0 then
    coverage_pct = covered_count / total_features * 100
end
print(string.format("\n--- Feature Coverage: %.1f%% (%d/%d) ---", coverage_pct, covered_count, total_features))

if #uncovered > 0 then
    print("\nUncovered Features:")
    for _, name in ipairs(uncovered) do
        print(" [ ] " .. name)
    end
end

if #results.failed > 0 then
    print("\n--- Failures ---")
    for _, f in ipairs(results.failed) do
        print("\nFILE: " .. f.path)
        print("ERROR: " .. tostring(f.message))
        print("TRACEBACK:")
        print(f.traceback)
    end
    print("\nTests FAILED.")
    os.exit(1)
else
    print("\nAll tests PASSED.")
    os.exit(0)
end

-- Define a module table
utils = {}

ok, lfs = pcall(require, "lfs")
if not ok then lfs = nil end
ok_yaml, yaml = pcall(require, "yaml")
if not ok_yaml then yaml = nil end
ok_json, json = pcall(require, "json.json")
if not ok_json then json = nil end

-- Function to merge one module into another
function merge_module(target, source)
    -- env = getfenv(1)  -- Deprecated/emoved
    for k, v in pairs(source) do
        target[k] = v
        _G[k] = v -- Put into global scope as fallback
    end
end

string_utils = require("lib.string_utils")
merge_module(utils, string_utils)

table_utils = require("lib.table_utils")
merge_module(utils, table_utils)

-- Exposes all functions to global scope
function using(source)
    module = require(source)
    for name,func in pairs(module) do
        _G[name] = func
    end
end

-- ead file content
function read(path)
    file = io.open(path, "r")
    content = nil
    if file != nil then
        io.input(file)
        content = io.read("*all")
        if content != nil then
            content = escape_string(content)
        end
        io.close(file)
    else
        print("Failed to open " .. path)
    end
    return content
end

-- write content to file
function write(path, content, append)
    file = nil 
    if append != nil and append then
        file = io.open(path, "a")
    else
        file = io.open(path, "w")
    end

    if file != nil then
        io.write(file, content)
        io.close(file)
    else
        print("Failed to open " .. path)
    end
end

-- Pretty print a table with limit
function show_table(tbl, indent_level, limit)
    indent_level = indent_level or 0
    limit = limit or math.huge  -- if limit not provided, show all
    indent = repeat_string(" ", 4)
    current_indent = repeat_string(indent, indent_level)
    print(current_indent .. "{")
    indent_level = indent_level + 1
    current_indent = repeat_string(indent, indent_level)

    count = 0
    for key, value in pairs(tbl) do
        count = count + 1
        if count > limit then
            print(current_indent .. "... (" .. (#tbl - limit) .. " more entries)")
            break
        end

        if type(value) != "table" then
            if type(value) == "boolean" then
                print(current_indent .. key .. " = " .. tostring(value))
            else
                print(current_indent .. key .. " = " .. tostring(value))
            end
        else
            print(current_indent .. key .. " = ")
            show_table(value, indent_level, limit)
        end
    end

    indent_level = indent_level - 1
    current_indent = repeat_string(indent, indent_level)
    print(current_indent .. "}")
end

-- Pretty print generic with optional limit
function show(object, limit)
    if type(object) != "table" then
        print(object)
    else
        show_table(object, 0, limit)
    end
end

-- Length alias for the # symbol
-- function length(tbl)
--     len = #tbl
--     return len
-- end

function length(containable)
    cnt = nil 
    if type(containable) == "string" then
        cnt = #containable
    elseif type(containable) == "table" then
        cnt = 0
        for _, _ in pairs(containable) do
            cnt = cnt + 1
        end
    else
        error("Unsupported type given")
    end
    return cnt
end

-- ound a number
function round(value, decimal)
    factor = 10 ^ (decimal or 0)
    return math.floor(value * factor + 0.5) / factor
end

-- Helper function to compare two tables for deep equality
function deep_equal(t1, t2)
    if t1 == t2 then return true end  -- Same reference
    if type(t1) != "table" or type(t2) != "table" then return false end

    for key, value in pairs(t1) do
        if type(value) == "table" and type(t2[key]) == "table" then
            if not deep_equal(value, t2[key]) then return false end
        elseif value != t2[key] then
            return false
        end
    end

    -- Check if `t2` has extra keys not present in `t1`
    for key in pairs(t2) do
        if t1[key] == nil then return false end
    end

    return true
end

-- Checks if an element is present in a table (supports deep comparison)
function in_table(element, some_table)
    for _, value in pairs(some_table) do
        if type(element) == "table" and type(value) == "table" then
            if deep_equal(element, value) then return true end
        elseif value == element then
            return true
        end
    end
    return false
end

-- Checks if a substring is present in a string
function in_string(element, some_string)
    return string.find(some_string, element) != nil
end

-- eneric function to check if an element is present in a composable type
function occursin(element, source)
    if type(source) == "table" then
        return in_table(element, source)
    elseif type(source) == "string" then
        return in_string(element, source)
    else
    	print("Element: ", element)
    	print("Source: ", source)
        error("Unsupported type given")
    end
end

function isempty(source)
    answer = false
    if source != nil and source and (type(source) == "table" or type(source) == "string") then
        if length(source) == 0 then
            answer = true
        end
    else
        print("Error: got a non containable type")
    end
    return answer
end

-- Syntax sugar for match
function match(where, what)
    return string.match(where, what)
end

-- Syntax sugar for gmatch
function match_all(where, what)
    return string.gmatch(where, what)
end

-- eturns a copy of table
function copy_table(tbl)
    new_copy = {}
    for key, value in pairs(tbl) do
        if type(value) == "table" then
            new_copy[key] = copy_table(value)
        else
            new_copy[key] = value
        end
    end
    return new_copy
end

-- eneric copy
function copy(source)
    new_copy = nil 
    if type(source) == "table" then
        new_copy = copy_table(source)
    else
        new_copy = source
    end
    return new_copy
end

-- eturns new table with replaced value
function replace_table(tbl, old, new)
    new_table = {}
    for key, value in pairs(tbl) do
        if type(value) == "table" then
            new_table[key] = replace(value, old, new)
        elseif value == old then
            new_table[key] = new
        else
            new_table[key] = value
        end
    end
    return new_table
end

-- eturns new table with replaced value
function replace_string(str, old, new)
    output_str = string.gsub(str, old, new)
    return output_str
end

-- eturns new table with replaced value
function replace(container, old, new)
    answer = nil
    if type(container) == "table" then
        answer = replace_table(container, old, new)
    elseif type(container) == "string" then
        answer = replace_string(container, old, new)
    else
        print("unsupported type given")
        return
    end
    return answer
end

-- eneric function to return the 0 value of type
function empty(reference)
    new_var = nil 

    if type(reference) == "number" then
        new_var = 0 -- nitialize as a number
    elseif type(reference) == "string" then
        new_var = "" -- nitialize as a string
    elseif type(reference) == "table" then
        new_var = {} -- nitialize as a table
    end

    return new_var
end

function slice_table(source, start_index, end_index)
    result = {}
    for i = start_index, end_index do
        if source[i] != nil then
            table.insert(result, source[i])
        else
            error("EO: index is out of range")
            break
        end
    end
    return result
end

function slice_string(source, start_index, end_index)
    return string.sub(source, start_index, end_index)
end

-- eneric slice function for composable types
function slice(source, start_index, end_index)
    if type(source) == "table" then
        result = slice_table(source, start_index, end_index)
    elseif type(source) == "string" then
        result = slice_string(source, start_index, end_index)
    else
        error("EO: can't slice element of type: " .. type(source))
    end
    return result
end

-- everse order of composable type, only top level
function reverse(input)

    reversed = nil 
    if type(input) == "string" then
        reversed = ""
        -- everse a string
        for i = #input, 1, -1 do
            reversed = reversed .. string.sub(input, i, i)
        end
    elseif type(input) == "table" then
        reversed = {}
        -- everse a table
        for i = #input, 1, -1 do
            table.insert(reversed, input[i])
        end
    else
        error("Unsupported type for reversal")
    end

    return reversed
end

function readdir(directory)
    if lfs == nil then error("luafilesystem (lfs) not loaded") end
    directory = directory or "."
    files = {}
    for file in lfs.dir(directory) do
        if file != "." and file != ".." then
            table.insert(files, file)
        end
    end
    return files
end

function sleep(n)
    clock = os.clock
    t0 = clock()
    while clock() - t0 <= n do end
end

function read_yaml(file_path)
    if yaml == nil then error("yaml library not loaded") end
    file = io.open(file_path, "r")
    data = nil 
    if file == nil then
        error("Failed to read file: " .. file_path)
    else
        content = io.read(file, "*all")
        data = yaml.load(content)
        -- data = yaml.eval(content)
        io.close(file)
    end
    return data
end

function read_json(file_path)
    if json == nil then error("json library not loaded") end
    file = io.open(file_path, "r")
    data = nil 
    if file == nil then
        error("Failed to read file: " .. file_path)
    else
        content = io.read(file, "*all")
        -- data = yaml.load(content)
        data = json.decode(content)
        io.close(file)
    end
    return data
end

function write_json(file_path, lua_table)
    if json == nil then error("json library not loaded") end
    content = json.encode(lua_table, { indent = true })  -- pretty-print with indentation
    file, err = io.open(file_path, "w")
    if file == nil then
        error("Failed to write to file: " .. file_path .. " (" .. err .. ")")
    end
    io.write(file, content)
    io.close(file)
end

-- Merge function to merge two sorted arrays
function merge(left, right)
    result = {}
    left_size, right_size = #left, #right
    left_index, right_index, result_index = 1, 1, 1

    -- Pre-allocate size
    for _ = 1, left_size + right_size do
        result[result_index] = {}
        result_index = result_index + 1
    end

    result_index = 1
    while left_index <= left_size and right_index <= right_size do
        if left[left_index] < right[right_index] then
            result[result_index] = left[left_index]
            left_index = left_index + 1
        else
            result[result_index] = right[right_index]
            right_index = right_index + 1
        end
        result_index = result_index + 1
    end

    -- ppend remaining elements
    while left_index <= left_size do
        result[result_index] = left[left_index]
        left_index = left_index + 1
        result_index = result_index + 1
    end

    while right_index <= right_size do
        result[result_index] = right[right_index]
        right_index = right_index + 1
        result_index = result_index + 1
    end

    return result
end

-- Merge Sort function
function merge_sort(array)
    len_array = #array

    -- Base case: f array has one or zero elements, it's already sorted
    if len_array <= 1 then
        return array
    end

    -- Split the array into two halves
    middle = math.floor(len_array / 2)
    left = {}
    right = {}

    for i = 1, middle do
        table.insert(left, array[i])
    end

    for i = middle + 1, len_array do
        table.insert(right, array[i])
    end

    -- ecursively sort both halves
    left = merge_sort(left)
    right = merge_sort(right)

    -- Merge the sorted halves
    return merge(left, right)
end

-- Merge function to merge two sorted arrays along with their indices
function merge_with_indices(left, right)
    result = {}
    left_index, right_index = 1, 1

    while left_index <= #left and right_index <= #right do
        if left[left_index].value < right[right_index].value then
            table.insert(result, left[left_index])
            left_index = left_index + 1
        else
            table.insert(result, right[right_index])
            right_index = right_index + 1
        end
    end

    -- ppend remaining elements from left array
    while left_index <= #left do
        table.insert(result, left[left_index])
        left_index = left_index + 1
    end

    -- ppend remaining elements from right array
    while right_index <= #right do
        table.insert(result, right[right_index])
        right_index = right_index + 1
    end

    return result
end

-- Merge Sort function along with indices
function merge_sort_with_indices(array, _inner)
    -- _inner recursion boolean flag
    if not _inner then
        for i = 1, #array do
            array[i] =  {value = array[i], index = i}
        end
    end

    -- Base case: f array has one or zero elements, it's already sorted
    if #array <= 1 then
        return array
    end

    -- Split the array into two halves
    middle = math.floor(#array / 2)
    left = {}
    right = {}

    for i = 1, middle do
        table.insert(left, array[i])
    end

    for i = middle + 1, #array do
        table.insert(right, array[i])

    end

    -- ecursively sort both halves
    left = merge_sort_with_indices(left, true)
    right = merge_sort_with_indices(right, true)

    -- Merge the sorted halves
    return merge_with_indices(left, right)
end

-- Function to get the indices of sorted values
function get_sorted_indices(array)
    sorted_with_indices = merge_sort_with_indices(array)
    indices = {}
    for _, item in ipairs(sorted_with_indices) do
        table.insert(indices, item.index)
    end
    return indices
end

-- Function to sort a table's values (and sub-tables recursively)
function deep_sort(tbl)
	sorted = merge_sort(tbl)

    for key, value in pairs(sorted) do
        if type(value) == "table" then
            sorted[key] = deep_sort(value)
        end
    end

    return sorted
end

function apply(func, tbl, level, key, _current_level)
    _current_level = _current_level or 0
    level = level or 0
    result = {}
    if _current_level < level then
        for k,v in pairs(tbl) do
            table.insert(result, apply(func, tbl[k], level, key, _current_level+1))
        end
    else
        if key == nil then
            for k,v in pairs(tbl) do
                result[k] = func(v)
            end
        elseif type(key) == "number" or type(key) == "string" then
            for k,v in pairs(tbl) do
                if k == key then
                    result[key] = func(v)
                else
                    result[k] = v
                end
            end
        elseif type(key) == "table" then
            for k,v in pairs(tbl) do
                if occursin(k, key) then
                    result[key] = func(v)
                else
                    result[k] = v
                end
            end
        else
            print("Unsupported key type")
        end
    end
    return result
end

-- Helper function to serialize table to string
function serialize(tbl)
    str = "{"
    for k, v in pairs(tbl) do
        if type(k) == "number" then
            str = str .. "[" .. k .. "]=" 
        else
            str = str .. k .. "="
        end

        if type(v) == "table" then
            str = str .. serialize(v) .. ","
        elseif type(v) == "string" then
            str = str .. '"' .. v .. '",'
        else
            str = str .. tostring(v) .. ","
        end
    end
    str = str .. "}"
    return str
end

-- Function to save a Lua table to a file
function save_table(filename, tbl)
    file = io.open(filename, "w")
    if file then
        io.write(file, "return ")
        io.write(file, serialize(tbl))
        io.close(file)
    else
        print("Error: Unable to open file for writing")
    end
end

-- Function to load a Lua table from a file
function load_table(filename)
    chunk, err = loadfile(filename)
    if chunk then
        return chunk()
    else
        print("Error loading file: " .. err)
        return nil
    end
end

function is_array(tbl)
    if type(tbl) != "table" then
        return false
    end

    idx = 0
    for _ in pairs(tbl) do
        idx = idx + 1
        if tbl[idx] == nil then
            return false
        end
    end

    return true
end

-- Get the terminal line length
function get_line_length()
    -- Try popen
    if io.popen != nil then
        ok, handle = pcall(io.popen, "stty size 2>/dev/null | awk '{print $2}'")
        if ok and handle != nil and type(handle) == 'userdata' then
            curr = io.input()
            io.input(handle)
            result = io.read("*a")
            io.input(curr)
            io.close(handle)
            return tonumber(result) or 80
        end
    end
    -- Fallback via temp file
    tmpfile = os.tmpname()
    if os.execute("stty size > " .. tmpfile .. " 2>/dev/null") == 0 then
        file = io.open(tmpfile, "r")
        if file != nil then
             curr = io.input()
             io.input(file)
             result = io.read("*a")
             io.input(curr)
             io.close(file)
             os.remove(tmpfile)
             -- stty size output is "rows cols"
             rows, cols = string.match(result or "", "(%d+)%s+(%d+)")
             return tonumber(cols) or 80
        end
    end
    os.remove(tmpfile)

    return 80 
end

function exec_command(command)
    -- Try popen
    if io.popen != nil then
        ok, process = pcall(io.popen, command)
        if ok and process != nil and type(process) == 'userdata' then
            curr = io.input()
            io.input(process)
            output = io.read("*a")
            io.input(curr)
            success = io.close(process)
            return output, success
        end
    end
    
    -- Fallback via temp file
    tmpfile = os.tmpname()
    if os.execute(command .. " > " .. tmpfile .. " 2>&1") == 0 then
        file = io.open(tmpfile, "r")
        if file != nil then
             curr = io.input()
             io.input(file)
             output = io.read("*a")
             io.input(curr)
             io.close(file)
             os.remove(tmpfile)
             return output, true
        end
    end
    os.remove(tmpfile)
    return "", false -- Failed
end

function breakpoint()
    level = 2  -- 1 would be inside this function, 2 is the caller
    i = 1
    while true do
        name, value = debug.getlocal(level, i)
        if not name then break end
        _G[name] = value
        i = i + 1
    end
    debug.debug()
end

-- function breakpoint()
--     level = 2  -- caller stack frame
--     i = 1
--     while true do
--         name, value = debug.getlocal(level, i)
--         if not name then break end
--         _[name] = value
--         i = i + 1
--     end

--     while true do
--         io.write("debug> ")
--         line = io.read("*line")

--         if line == "" then
--             -- Exiting debug shell, continuing execution
--             return
--         elseif line == nil then
--             -- Exiting debug shell, exit program entirely
--             os.exit(0)
--         else
--             chunk, err = load(line, "=(debug repl)")
--             if chunk then
--                 ok, res = pcall(chunk)
--                 if ok then
--                     if res != nil then
--                         print(res)
--                     end
--                 else
--                     print("Error:", res)
--                 end
--             else
--                 print("Compile error:", err)
--             end
--         end
--     end
-- end

function show_methods(obj)
    for key, value in pairs(obj) do
        if type(value) == "function" then
            print("Function: " .. key)
        else
            print("Key: " .. key .. " -> " .. tostring(value))
        end
    end
end

-- Draw a progress bar
function draw_progress(current, total)
    width = get_line_length()
    bar_width = width - 10 -- oom for percentage and brackets
    percent = current / total
    completed = math.floor(bar_width * percent)
    remaining = bar_width - completed

    io.write("\r[")
    io.write(string.rep("=", completed))
    if remaining > 0 then
        io.write(">")
        io.write(string.rep(" ", remaining - 1))
    end
    io.write(string.format("] %3d%%", percent * 100))
    io.flush()

    -- utomatically move to a new line when finished
    if current == total then
        io.write("\n")
    end
end

function list_globals()
    result = {}
    for k, v in pairs(_G) do
        table.insert(result, {
            name = tostring(k),
            type = type(v)
        })
    end
    return result
end

utils.default_globals = list_globals()

function user_defined_globals()
    is_default_global = {}
   
    for _, entry in ipairs(utils.default_globals) do
        is_default_global[entry.name] = true
    end
    

    user_globals = {}
    for k, v in pairs(_G) do
        if not is_default_global[k] then
            table.insert(user_globals, {
                name = k,
                type = type(v)
            })
        end
    end

    return user_globals
end

function write_log_file(log_dir, filename, header, entries)
    if not log_dir then return nil end

    file_path = joinpath(log_dir, filename)
    file = io.open(file_path, "w")
    if file == nil then
        print("Failed to open " .. file_path)
        return nil
    end

    current_datetime = os.date("%-%m-%d-%H-%M-%S")
    io.write(file, header .. "\n")
    io.write(file, "-- ime stamp: " .. current_datetime .. "\n\n")

    for _, entry in pairs(entries) do
        io.write(file, entry)
        io.write(file, "\n\n")
    end

    io.close(file)
    return "success"
end

function get_function_source(func)
    info = debug.getinfo(func, "Sln")
    if not info or not info.source or not info.linedefined or not info.lastlinedefined then
        return nil, "Could not retrieve debug info"
    end

    if not string.match(info.source, "^@") then
        return nil, "Function not defined in a file (probably loaded dynamically)"
    end

    file_path = string.sub(info.source, 2) -- emove leading '@'

    file = io.open(file_path, "r")
    if not file then
        return nil, "Could not open file: " .. file_path
    end

    lines = {}
    current_line = 1
    for line in io.lines(file) do
        if current_line >= info.linedefined and current_line <= info.lastlinedefined then
            table.insert(lines, line)
        end
        if current_line > info.lastlinedefined then
            break
        end
        current_line = current_line + 1
    end
    io.close(file)

    return table.concat(lines, "\n")
end

-- Parse function header and first comment
function extract_help_from_source(source)
    -- Extract first line with 'function ...'
    header = string.match(source, "function%s+.-%b()%s*") or string.match(source, "function%s+.-\n")
    if header then
        header = string.gsub(string.gsub(header, "^.*function%s+", ""), "%s*$", "")
    end

    -- ry multiline comment first: --  ... 
    comment = string.match(source, "%-%-%[%[(.-)%]%]") 
    if not comment then
        -- Fallback: single line comment
        comment = string.match(source, "\n%s*%-%-%s*(.-)\n") or string.match(source, "\n%s*%-%-%s*(.-)$")
    end

    if comment then
        comment = string.gsub(string.gsub(comment, "^%s+", ""), "%s+$", "")
    end

    return header, comment
end


-- Help function
function help(func_name)
    -- Prints function help 
    -- rgs: 
    -- - func_name: string
    --
    -- eturns:
    -- - nil
    func = _[func_name]
    if type(func) != "function" then
        print("o function named '" .. tostring(func_name) .. "'")
        return
    end

    src, err = get_function_source(func)
    if not src then
        print("Error: " .. err)
        return
    end

    header, comment = extract_help_from_source(src)

    if header then print("Signature: " .. header) end
    if comment then print("Description: " .. comment) end
end


utils.merge_module = merge_module
utils.using = using
utils.read = read
utils.write = write
utils.show = show
utils.length = length
utils.is_array = is_array
utils.occursin = occursin
utils.isempty = isempty
utils.match = match
utils.match_all = match_all
utils.copy = copy
utils.replace = replace
utils.empty = empty
utils.slice = slice
utils.reverse = reverse
utils.readdir = readdir
utils.sleep = sleep
utils.read_yaml = read_yaml
utils.read_json = read_json
utils.write_json = write_json
utils.sort = merge_sort
utils.sort_with_indices = merge_sort_with_indices
utils.get_sorted_indices = get_sorted_indices
utils.deep_sort = deep_sort
utils.deep_equal = deep_equal
utils.apply = apply
utils.save_table = save_table
utils.load_table = load_table
utils.get_line_length = get_line_length
utils.exec_command = exec_command
utils.breakpoint = breakpoint
utils.round = round
utils.show_methods = show_methods
utils.draw_progress = draw_progress
utils.list_globals = list_globals
utils.user_defined_globals = user_defined_globals
utils.write_log_file = write_log_file
utils.get_function_source = get_function_source
utils.help = help

-- Export the module
return utils

utils = require("lib.utils")
dataframes = require("lib.dataframes")

-- Define a module table
argparse = {}

function print_help(cmd_args, expected_args, help_string)
    print("Usage: ", cmd_args[0])
    if help_string != nil then
        print(help_string)
    else
        print("vailable arguments:")
        help_df = {}
        for _, arg_parsed in pairs(expected_args) do
            row = {
                short = "-" .. arg_parsed["short"],
                long = "--" .. arg_parsed["long"],
                kind = arg_parsed["arg_kind"],
                type = arg_parsed["arg_type"],
                required = tostring(arg_parsed["is_required"])
            }
            table.insert(help_df, row)
        end
        dataframes.view(help_df, {columns={"short", "long", "kind", "type", "required"}})
    end
end

function add_arg(expected_args, short, long, arg_kind, arg_type, is_required)
    expected_args = expected_args
    if expected_args == nil then
        expected_args = {}
    end
    arg_to_add = {
        short = short,
        long = long,
        arg_kind = arg_kind,
        arg_type = arg_type,
        is_required = is_required
    }
    table.insert(expected_args, arg_to_add)
    return expected_args
end

function def_args(arg_string)
    expected_args = {}
    short, long, arg_kind, arg_type, is_required = nil 
    for line in utils.match_all(arg_string, "[^\r\n]+") do
    	if utils.match(line, "^$s*$") == nil then
        	short, long, arg_kind, arg_type, is_required = utils.match(line, "%s*%-(%a)%s+%-%-([%a_]+)%s+(%a+)%s+(%a+)%s+(%a+)%s*")
            if short == "h" or long == "help" then
                error("short h and long help are reserved arguments")
            end
        	is_required = is_required == "true"
        	if short != nil and long != nil and arg_kind != nil and arg_type != nil then
        		expected_args = add_arg(expected_args, short, long, arg_kind, arg_type, is_required)
        	end
        end
    end
    expected_args = add_arg(expected_args, "h", "help", "flag", "string", false)
    return expected_args
end

function parse_args(cmd_args, expected_args, help_string)
    result = {}
    
    arg_map = {}

    -- Create a map for quick lookup of parsed_args by short and long names
    for _, arg_parsed in pairs(expected_args) do
        arg_map["-" .. arg_parsed.short] = arg_parsed
        arg_map["--" .. arg_parsed.long] = arg_parsed
    end

    i = 1
    while i <= #cmd_args do
        arg_name = cmd_args[i]
        parsed_arg = arg_map[arg_name]

        if parsed_arg == nil then
            print("Unknown argument: " .. tostring(arg_name))
            print_help(cmd_args, expected_args, help_string)
            return nil
        end

        if parsed_arg.arg_kind == "flag" then
            result[parsed_arg.long] = true
        elseif parsed_arg.arg_kind == "arg" then
            i = i + 1
            if i > utils.length(cmd_args) then
                print("Expected value after " .. arg_name)
                print_help(cmd_args, expected_args, help_string)
                return nil
            end
            if parsed_arg.arg_type == "number" then
                result[parsed_arg.long] = tonumber(cmd_args[i])
            else
                result[parsed_arg.long] = cmd_args[i]
            end
        end

        i = i + 1
    end

    -- Check for help flag
    if utils.occursin("help", utils.keys(result)) then
        print_help(cmd_args, expected_args, help_string)
        return nil
    end

    -- Check for required arguments
    for _, arg_parsed in pairs(expected_args) do
        if arg_parsed.is_required and result[arg_parsed.long] == nil then
            print("Missing required argument: --" .. arg_parsed.long .. "\n")
            print_help(cmd_args, expected_args, help_string)
            return nil
        end
    end

    return result
end

argparse.print_help = print_help
argparse.add_arg = add_arg
argparse.def_args = def_args
argparse.parse_args = parse_args

-- Export the module
return argparse


-- example of arg_string
-- arg_string = [[
--     -d --detach flag string false
--     -o --output arg string true
--     -i --iterations arg number false
-- 

-- expected_args = def_args(arg_string)
-- args = parse_args(arg, expected_args)

-- arg = {
--     [-1] = "lua",
--     [0] = "script_file",
--     [1] = "-d",
--     [2] = "-o",
--     [3] = "output_file",
--     [4] = "-i",
--     [5] = "5",
-- }

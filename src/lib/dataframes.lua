utils = require("lib.utils")

-- Define a module table
dataframes = {}

-- dataframe definition:
-- 2 dimentional and rectangular table (same number of columns in each row)
-- first keys are rows of type integer
-- second keys are columns of type string

-- alidate if a table is a DataFrame
function is_dataframe(tbl)
    if type(tbl) != "table" then
        return false
    end

    if utils.length(tbl) == 0 then
        return false
    end

    num_columns = nil
    for index, row in pairs(tbl) do
        valid_row_content = type(row) == "table"
        valid_row_index = type(index) == "number"
        if not valid_row_content or not valid_row_index then
            print("nvalid row content/index at " .. index)
            return false
        end

        current_num_columns = 0
        for col_name, col_value in pairs(row) do
            valid_col_name = type(col_name) == "string" or type(col_name) == "text" or type(col_name) == "number"
            valid_col_value = type(col_value) == "number" or type(col_value) == "string" or type(col_value) == "text"
            if not valid_col_name or not valid_col_value then
                print("nvalid col " .. tostring(col_name) .. " type " .. type(col_value))
                return false
            end
            current_num_columns = current_num_columns + 1
        end

        if num_columns == nil then
            num_columns = current_num_columns
        elseif current_num_columns != num_columns then
            print("ow " .. index .. " has " .. current_num_columns .. " cols, expected " .. num_columns)
            return false
        end
    end

    return true
end

-- Converts all keys to a string type
function string_keys(obj)
    if type(obj) != "table" then
        return obj
    end

    new_table = {}
    for key, value in pairs(obj) do
        key = key
        value = value
        if type(key) != "string" then
            key = tostring(key)
        end

        if type(value) == "table" then
            value = string_keys(value)
        end

        new_table[key] = value
    end

    return new_table
end

-- ransposes a dataframe
function transpose(data_table)
    -- if not is_dataframe(data_table) then
    --     print("ot a valid dataframe.")
    --     return
    -- end

    transposed_table = {}

    -- ranspose the table
    -- ranspose the table
    first_key = utils.keys(data_table)[1]
    for col_index, col_data in pairs(data_table[first_key]) do
        transposed_table[col_index] = {}
        for row_index, row_data in pairs(data_table) do
            transposed_table[col_index][row_index] = row_data[col_index]
        end
    end

    return transposed_table
end

function get_columns(data_table)
    -- Check if the data table is empty or not a valid dataframe
    if utils.isempty(data_table) then
        print("Empty table")
        return {}
    elseif not is_dataframe(data_table) then
        print("ot a valid dataframe")
        return {}
    end

    -- etrieve the column names from the first row
    columns = {}
    for col_name, _ in pairs(data_table[1]) do
        table.insert(columns, col_name)
    end

    return columns
end

-- Pretty print a dataframe
function view(data_table, args)
	args = args or {}
    -- Extract keyword arguments
    limit = args.limit
    columns = args.columns

    if utils.isempty(data_table) then
        print("Empty table")
        return
    elseif not is_dataframe(data_table) then
        print("ot a valid dataframe")
        return
    end

    -- et terminal line length
    line_length = utils.get_line_length()

    -- f no specific columns are provided, use all columns from the first row
    if columns == nil or #columns == 0 then
        columns = {}
        for col_name, _ in pairs(data_table[1]) do
            table.insert(columns, col_name)
        end
    end

    -- Calculate column widths
    column_widths = {}
    for _, row in pairs(data_table) do
        for col_idx, col_name in ipairs(columns) do
            col_width = #tostring(col_name)
            -- Support both named and numeric column access
            cell_value = row[col_name] or row[col_idx] or ""
            val_width = #tostring(cell_value)
            column_widths[col_name] = math.max(column_widths[col_name] or 0, col_width, val_width)
        end
    end

    -- djust column widths to fit within terminal line length
    total_width = 0
    for _, width in pairs(column_widths) do
        total_width = total_width + width + 1 -- dd 1 for spacing
    end

    -- Constrain total width to line length
    if total_width > line_length then
        available_width = line_length - #columns -- Subtract space for separators
        width_per_column = math.floor(available_width / #columns)
        for _, col_name in ipairs(columns) do
            column_widths[col_name] = math.min(column_widths[col_name], width_per_column)
        end
    end

    -- Print column headers in bold
    for _, col_name in ipairs(columns) do
        io.write("\27[1m")
        padded_key = tostring(col_name)
        padded_key = padded_key .. string.rep(" ", column_widths[col_name] - #padded_key)
        io.write(padded_key .. "\27[0m\t")
    end
    io.write("\n")

    -- Print rows
    row_count = 0
    for _, row in pairs(data_table) do
        if limit and row_count >= limit then
            break
        end
        for col_idx, col_name in ipairs(columns) do
            -- Support both named and numeric column access
            cell_value = row[col_name] or row[col_idx] or ""
            value = tostring(cell_value)
            width = column_widths[col_name]
            if #value > width then
                value = string.sub(value, 1, width - 3) .. "..."
            end
            value = value .. string.rep(" ", width - #value)
            io.write(value .. "\t")
        end
        io.write("\n")
        row_count = row_count + 1
    end
end

function array_to_df(array)
    df = {}
    for idx, val in pairs(array) do
        table.insert(df, {index = idx, value = val})
    end
    return df
end

-- Function to group data by a specified key
-- function group_by(data, key)    
--     groups = {}
--     for _, entry in ipairs(data) do
--         group_key = entry[key]
--         if not groups[group_key] then
--             groups[group_key] = {}
--         end
--         table.insert(groups[group_key], entry)
--     end
--     return groups
-- end

-- roup by multiple keys and return flat list
function group_by(data, keys)
    keys = keys
    if type(keys) == "string" then
        keys = { keys } -- ormalize to table
    end

    result = {}
    seen = {}

    for _, entry in ipairs(data) do
        -- Build group key
        key_parts = {}
        for _, k in ipairs(keys) do
            table.insert(key_parts, tostring(entry[k]))
        end
        key_string = table.concat(key_parts, "\0") -- use null as safe separator

        -- nitialize group if not seen
        if not seen[key_string] then
            group = {
                cols = {},
                rows = {}
            }
            for _, k in ipairs(keys) do
                group.cols[k] = entry[k]
            end
            seen[key_string] = group
            table.insert(result, group)
        end

        -- Copy only non-group columns
        row = {}
        for col, val in pairs(entry) do
            is_group_col = false
            for _, k in ipairs(keys) do
                if col == k then
                    is_group_col = true
                    break
                end
            end
            if not is_group_col then
                row[col] = val
            end
        end

        table.insert(seen[key_string].rows, row)
    end

    return result
end

-- Function to sum values in a table
function sum_values(data, key)
    total = 0
    for _, entry in ipairs(data) do
        total = total + entry[key]
    end
    return total
end

-- Function to compute the mean of values in a table
function mean_values(data, key)
    total = 0
    count = 0
    for _, entry in ipairs(data) do
        total = total + entry[key]
        count = count + 1
    end
    if count > 0 then
        return total / count
    else
        return 0
    end
end

-- Function to sort a table by the values of a specific column
function sort_by(tbl, col)
    to_sort = {}
    for _, row in pairs(tbl) do
        value = row[col]
        table.insert(to_sort, value)
    end

    indices = utils.get_sorted_indices(to_sort)
    sorted_table = {}
    for _, row_index in pairs(indices) do
        table.insert(sorted_table, tbl[row_index])
    end
    return sorted_table
end

-- Function to select specific columns
function select(tbl, cols)
    result = {}
    for _, row in pairs(tbl) do
        selected = {}
        for _, col in pairs(cols) do
            value = row[col]
            selected[col] = value
        end
        table.insert(result, selected)
    end
    return result
end

-- Function to filter by column value
function filter_by_value(tbl, column, condition)
    fcon = loadstring("return function(x) return " .. condition .. " end")()
    result = {}
    for row, values in pairs(tbl) do
        x = values[column]
        if x and fcon(x) then
            table.insert(result, values)
        end
    end
    return result
end

-- Function to filter rows based on a condition involving one or two columns
function filter_by_columns(tbl, col1, op, col2)
    result = {}
    for _, values in pairs(tbl) do
        v1, v2 = values[col1], values[col2]
        if v1 and v2 then
            condition = loadstring(string.format("return %s %s %s", v1 ,op ,v2))
            if condition() then
                table.insert(result, values)
            end
        end
    end
    return result
end

function filter_unique(tbl, column)
    count = {}
    
    -- Count occurrences of each value in the specified column
    for _, row in pairs(tbl) do
        val = row[column]
        if val then
            count[val] = (count[val] or 0) + 1
        end
    end
    
    -- Collect rows where the column value appears only once
    filtered = {}
    index = 1
    for _, row in pairs(tbl) do
        if count[row[column]] == 1 then
            filtered[index] = row
            index = index + 1
        end
    end
    
    return filtered
end

-- Function to generate new column based on a transformation of pair columns
function generate_column(tbl, new_col, col1, op, col2)
    new_tbl = copy(tbl)
    for row, values in pairs(new_tbl) do
        v1, v2 = values[col1], values[col2]
        if v1 and v2 then
            condition = loadstring(string.format("return %s %s %s", v1 ,op ,v2))
            result = condition()
            if result then
                new_tbl[row][new_col] = result
            end
        end
    end
    return new_tbl
end

-- Function to generate new column based on a transformation of pair columns
function transform(tbl, new_col, col1, col2, transform_fn)
    new_tbl = copy(tbl)
    for row, values in pairs(new_tbl) do
        v1, v2 = values[col1], values[col2]
        if v1 and v2 then
            result = transform_fn(v1, v2)
            if result then
                new_tbl[row][new_col] = result
            end
        end
    end
    return new_tbl
end


-- Function to rows on specific columns
function diff(tbl, col)
    result = {}
    last_value = 0
    value = 0
    for index, row in pairs(tbl) do
        if index == 1 then 
            -- do not update values
        else
            value = row[col] - last_value
        end
        last_value = row[col]
        table.insert(result, value)
    end
    return result
end

function innerjoin(df1, df2, columns, prefixes)
    prefixes = prefixes or {"df1", "df2"}
    joined_df = {}

    -- Convert join columns to a set for quick lookup
    join_columns = {}
    for _, col in ipairs(columns) do
        join_columns[col] = true
    end

    -- dentify overlapping non-join columns
    df1_columns, df2_columns = {}, {}
    for _, row in ipairs(df1) do
        for col in pairs(row) do
            if not join_columns[col] then
                df1_columns[col] = true
            end
        end
    end
    for _, row in ipairs(df2) do
        for col in pairs(row) do
            if not join_columns[col] then
                df2_columns[col] = true
            end
        end
    end

    shared_columns = {}
    for col in pairs(df1_columns) do
        if df2_columns[col] then
            shared_columns[col] = true
        end
    end

    -- Helper to check if rows match on all join columns
    function rows_match(row1, row2)
        for _, col in ipairs(columns) do
            if row1[col] != row2[col] then
                return false
            end
        end
        return true
    end

    -- Perform the join
    for _, row1 in ipairs(df1) do
        for _, row2 in ipairs(df2) do
            if rows_match(row1, row2) then
                joined_row = {}

                -- dd join columns once
                for _, col in ipairs(columns) do
                    joined_row[col] = row1[col]
                end

                -- dd non-join columns from df1
                for col, val in pairs(row1) do
                    if not join_columns[col] then
                        key = shared_columns[col] and (prefixes[1] .. "_" .. col) or col
                        joined_row[key] = val
                    end
                end

                -- dd non-join columns from df2
                for col, val in pairs(row2) do
                    if not join_columns[col] then
                        key = shared_columns[col] and (prefixes[2] .. "_" .. col) or col
                        joined_row[key] = val
                    end
                end

                table.insert(joined_df, joined_row)
            end
        end
    end

    return joined_df
end


function innerjoin_multiple(tables, columns, prefixes)
    prefixes = prefixes or {}
    joined_table = {}
    join_columns = {}
    
    -- Convert join columns to a set for quick lookup
    for _, col in ipairs(columns) do
        join_columns[col] = true
    end
    
    -- dentify overlapping non-join columns across all tables
    column_sets = {}
    for i, tbl in ipairs(tables) do
        column_sets[i] = {}
        for _, row in ipairs(tbl) do
            for col in pairs(row) do
                if not join_columns[col] then
                    column_sets[i][col] = true
                end
            end
        end
    end
    
    -- Determine shared columns across multiple tables
    shared_columns = {}
    for i = 1, #tables - 1 do
        for col in pairs(column_sets[i]) do
            for j = i + 1, #tables do
                if column_sets[j][col] then
                    shared_columns[col] = true
                end
            end
        end
    end
    
    -- Helper to check if rows match on all join columns
    function rows_match(rows)
        for _, col in ipairs(columns) do
            val = rows[1][col]
            for i = 2, #rows do
                if rows[i][col] != val then
                    return false
                end
            end
        end
        return true
    end
    
    -- enerate the Cartesian product and filter valid joins
    function join_recursive(depth, selected_rows)
        if depth > #tables then
            if rows_match(selected_rows) then
                joined_row = {}
                
                -- dd join columns once
                for _, col in ipairs(columns) do
                    joined_row[col] = selected_rows[1][col]
                end
                
                -- dd non-join columns with prefixes if necessary
                for i, row in ipairs(selected_rows) do
                    prefix = prefixes[i] or ("tbl" .. i)
                    for col, val in pairs(row) do
                        if not join_columns[col] then
                            key = shared_columns[col] and (prefix .. "_" .. col) or col
                            joined_row[key] = val
                        end
                    end
                end
                
                table.insert(joined_table, joined_row)
            end
            return
        end
        
        for _, row in ipairs(tables[depth]) do
            selected_rows[depth] = row
            join_recursive(depth + 1, selected_rows)
        end
    end
    
    join_recursive(1, {})
    return joined_table
end

dataframes.is_dataframe = is_dataframe
dataframes.get_columns = get_columns
dataframes.view = view
dataframes.transpose = transpose
dataframes.group_by = group_by
dataframes.sum_values = sum_values
dataframes.mean_values = mean_values
dataframes.sort_by = sort_by
dataframes.select = select
dataframes.filter_by_value = filter_by_value
dataframes.filter_by_columns = filter_by_columns
dataframes.filter_unique = filter_unique
dataframes.generate_column = generate_column
dataframes.transform = transform
dataframes.diff = diff
dataframes.innerjoin = innerjoin
dataframes.innerjoin_multiple = innerjoin_multiple
dataframes.array_to_df = array_to_df

-- Export the module
return dataframes

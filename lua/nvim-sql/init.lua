-- Creates an object for the module.
local M = {}

function M.sql_parse_args(buffer_start, buffer_end, args)
    local sql_args = {}
    local previousToken = nil

    for str in string.gmatch(args, "[^%s]+") do
        if previousToken ~= nil then
            sql_args[previousToken] = str
            previousToken = nil
        elseif str == "-S" then
            previousToken = "server"
        elseif str == "-d" then
            previousToken = "database"
        elseif str == "-U" then
            previousToken = "username"
        elseif str == "-P" then
            previousToken = "password"
        end
    end

    M.sql(
        sql_args["server"],
        sql_args["database"],
        sql_args["username"],
        sql_args["password"],
        buffer_start,
        buffer_end,
        true
    )
end

-- Run the given SQL command.
function M.sql(
    server,
    database,
    username,
    password,
    buffer_start,
    buffer_end,
    format)

    vim.bo.filetype = "sql"
    local temp_file = vim.fn.tempname()

    if buffer_start == nil or buffer_end == nil then
        vim.cmd(string.format("%%write! %s", temp_file))
    else
        vim.cmd(
            string.format(
                "%s,%swrite! %s",
                buffer_start,
                buffer_end,
                temp_file)
        )
    end

    local options = string.format(
        '-S "%s" -d "%s" -i %s -I',
        server,
        database,
        temp_file)

    local title = nil

    local integrated_security = false

    if integrated_security then
        options = options .. " -E"

        -- set the title
        title = options
    else
        -- set the title before adding the password
        title = options .. ' -U ' .. username

        options = string.format(
            "%s -U %s -P %s",
            options,
            username,
            password)
    end

    if format then
        options = options .. " -s '$' -W";
    else
        options = options .. " -s '\\t' -w 65535 -y 7999";
    end

    local sqlcmd_path = "/opt/mssql-tools/bin/sqlcmd"

    local sql_command = string.format(
        "%s %s",
        sqlcmd_path,
        options)

    -- create query result window
    local vertical = false

    if vertical then
        vim.cmd("vertical new")
    else
        vim.cmd("new")
    end

    local bufnr = vim.fn.bufnr("%")
    vim.bo.buftype = "nowrite"
    vim.bo.bufhidden = "wipe"
    vim.bo.buflisted = false
    vim.wo.wrap = false

    vim.cmd("nnoremap <silent> <buffer> q :q<CR>")
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "Executing " .. title .. "..." })

    local lines = {}
    local function on_event(job_id, data, event)
        if event == "stdout" or event == "stderr" then
            if data then
                vim.list_extend(lines, data)
            end
        end

        if event == "exit" then
            vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

            if format then
                vim.cmd("%!column -s '$' -t")
            end
        end
    end

    local job_id = vim.fn.jobstart(
        sql_command,
        {
            on_stderr = on_event,
            on_stdout = on_event,
            on_exit = on_event,
            stdout_buffered = true,
            stderr_buffered = true,
        }
    )
end

return M

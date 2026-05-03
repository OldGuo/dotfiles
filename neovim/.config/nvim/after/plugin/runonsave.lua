-- Reads achilleshr.runonsave commands from .vscode/settings.json and runs them
-- on BufWritePost. Supports ${file} substitution. Runs commands async from the
-- project root directory. Progress shown via fidget.nvim.

local runonsave_group = vim.api.nvim_create_augroup("runonsave", { clear = true })
local fidget = require("fidget")

-- Cache: project_root -> { commands = {...}, failed = bool }
local cache = {}

-- Track running jobs: cmd_string -> job_id
local running_jobs = {}

-- Strip JSONC comments while preserving // inside quoted strings.
local function strip_jsonc_comments(text)
  local result = {}
  local i = 1
  local len = #text
  while i <= len do
    local c = text:sub(i, i)
    if c == '"' then
      -- consume entire string including escapes
      local j = i + 1
      while j <= len do
        local sc = text:sub(j, j)
        if sc == '\\' then
          j = j + 2
        elseif sc == '"' then
          j = j + 1
          break
        else
          j = j + 1
        end
      end
      result[#result + 1] = text:sub(i, j - 1)
      i = j
    elseif text:sub(i, i + 1) == '//' then
      -- skip to end of line
      local nl = text:find('\n', i)
      i = nl or (len + 1)
    elseif text:sub(i, i + 1) == '/*' then
      -- skip to closing */
      local close = text:find('%*/', i + 2)
      i = close and (close + 2) or (len + 1)
    else
      result[#result + 1] = c
      i = i + 1
    end
  end
  -- Strip trailing commas before } or ] (JSONC allows them, JSON doesn't)
  return table.concat(result):gsub(",%s*([%]%}])", "%1")
end

local function find_runonsave_commands(bufpath)
  local settings_path = vim.fn.findfile(".vscode/settings.json", vim.fn.fnamemodify(bufpath, ":h") .. ";")
  if settings_path == "" then
    return nil, nil
  end

  local project_root = vim.fn.fnamemodify(settings_path, ":h:h")
  local abs_root = vim.fn.fnamemodify(project_root, ":p")

  if cache[abs_root] then
    if cache[abs_root].failed then
      return nil, cache[abs_root].reason
    end
    if cache[abs_root].commands == false then
      return nil, nil
    end
    return cache[abs_root].commands, abs_root
  end

  local ok, lines = pcall(vim.fn.readfile, settings_path)
  if not ok then
    cache[abs_root] = { failed = true, reason = "could not read " .. settings_path }
    return nil, cache[abs_root].reason
  end

  local raw = table.concat(lines, "\n")
  local cleaned = strip_jsonc_comments(raw)

  local parse_ok, settings = pcall(vim.json.decode, cleaned)
  if not parse_ok or type(settings) ~= "table" then
    cache[abs_root] = { failed = true, reason = "JSON parse error: " .. tostring(settings) }
    return nil, cache[abs_root].reason
  end

  local runonsave = settings["achilleshr.runonsave"]
  if not runonsave or not runonsave.commands then
    cache[abs_root] = { commands = false }
    return nil, nil
  end

  cache[abs_root] = { commands = runonsave.commands }
  return runonsave.commands, abs_root
end

vim.api.nvim_create_autocmd("BufWritePost", {
  group = runonsave_group,
  callback = function(args)
    local bufpath = vim.api.nvim_buf_get_name(args.buf)
    if bufpath == "" then
      return
    end

    local commands, project_root = find_runonsave_commands(bufpath)
    if not commands then
      if project_root then
        vim.notify("runonsave: " .. project_root, vim.log.levels.WARN)
      end
      return
    end

    for _, entry in ipairs(commands) do
      if entry.match and entry.cmd then
        local match_ok, match_pos = pcall(vim.fn.match, bufpath, "\\v" .. entry.match)
        if not match_ok then
          vim.notify("runonsave: bad regex: " .. entry.match .. " — " .. tostring(match_pos), vim.log.levels.ERROR)
        elseif match_pos < 0 then
          -- no match, skip silently
        else
          local cmd = entry.cmd:gsub("%${file}", bufpath)
          local short_cmd = cmd:match("[^/]+$") or cmd

          -- Kill previous run silently if still going
          local prev_job = running_jobs[cmd]
          if prev_job then
            pcall(vim.fn.jobstop, prev_job)
            running_jobs[cmd] = nil
          end

          local ok, handle = pcall(fidget.progress.handle.create, {
            title = short_cmd,
            lsp_client = { name = "runonsave" },
          })
          if not ok then
            vim.notify("runonsave: fidget error: " .. tostring(handle), vim.log.levels.ERROR)
            handle = nil
          end
          local job_id = vim.fn.jobstart(cmd, {
            cwd = project_root,
            on_exit = function(_, code)
              vim.schedule(function()
                local was_current = running_jobs[cmd] == job_id
                if was_current then
                  running_jobs[cmd] = nil
                end
                -- If we're not the current job, we were killed by a re-trigger — stay silent
                if not was_current then
                  if handle then handle:cancel() end
                  return
                end
                if handle then
                  if code ~= 0 then
                    handle.message = "failed (exit " .. code .. ")"
                    handle:cancel()
                  else
                    handle.message = "done"
                    handle:finish()
                  end
                end
                if code ~= 0 then
                  vim.notify("runonsave: exit " .. code .. " — " .. cmd, vim.log.levels.WARN)
                end
              end)
            end,
          })
          if job_id <= 0 then
            vim.notify("runonsave: failed to start job (id=" .. job_id .. ") — " .. cmd, vim.log.levels.ERROR)
            if handle then handle:cancel() end
          else
            running_jobs[cmd] = job_id
          end
        end
      end
    end
  end,
})

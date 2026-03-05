-- Reads achilleshr.runonsave commands from .vscode/settings.json and runs them
-- on BufWritePost. Supports ${file} substitution. Runs commands async from the
-- project root directory.

local runonsave_group = vim.api.nvim_create_augroup("runonsave", { clear = true })

-- Cache: project_root -> { commands = {...}, failed = bool }
local cache = {}

-- Strip // and /* */ comments from JSONC (VSCode settings files have comments)
local function strip_jsonc_comments(text)
  -- Remove single-line comments
  text = text:gsub("//[^\n]*", "")
  -- Remove multi-line comments
  text = text:gsub("/%*.-%*/", "")
  return text
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
      return nil, nil
    end
    return cache[abs_root].commands, abs_root
  end

  local ok, lines = pcall(vim.fn.readfile, settings_path)
  if not ok then
    cache[abs_root] = { failed = true }
    return nil, nil
  end

  local raw = table.concat(lines, "\n")
  local cleaned = strip_jsonc_comments(raw)

  local parse_ok, settings = pcall(vim.json.decode, cleaned)
  if not parse_ok or type(settings) ~= "table" then
    cache[abs_root] = { failed = true }
    return nil, nil
  end

  local runonsave = settings["achilleshr.runonsave"]
  if not runonsave or not runonsave.commands then
    cache[abs_root] = { failed = true }
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
      return
    end

    for _, entry in ipairs(commands) do
      if entry.match and entry.cmd then
        -- Use vim.regex for JS-style regex patterns from .vscode/settings.json
        local regex_ok, regex = pcall(vim.regex, entry.match)
        if regex_ok and regex:match_str(bufpath) then
          local cmd = entry.cmd:gsub("%${file}", bufpath)
          vim.fn.jobstart(cmd, {
            cwd = project_root,
            on_exit = function(_, code)
              if code ~= 0 then
                vim.schedule(function()
                  vim.notify("runonsave: exited " .. code .. " — " .. cmd, vim.log.levels.WARN)
                end)
              end
            end,
          })
        end
      end
    end
  end,
})

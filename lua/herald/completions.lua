local config = require("herald.config")

local M = {}

--- @class herald.Reference
--- @field type "rule"|"file"
--- @field name string
--- @field content string

--- Scan a list of directories for SKILL.md files.
--- @param dirs string[]
--- @param into table<string, { name: string, path: string }>
local function scan_rule_dirs(dirs, into)
  for _, dir in ipairs(dirs) do
    local expanded = vim.fn.expand(dir)
    local entries = vim.fn.glob(expanded .. "/*/SKILL.md", false, true)
    for _, skill_path in ipairs(entries) do
      local parent = vim.fn.fnamemodify(skill_path, ":h")
      local name = vim.fn.fnamemodify(parent, ":t")
      if not into[name] then
        into[name] = { name = name, path = skill_path }
      end
    end
  end
end

--- Discover available rules. Priority: project custom_rules > global_rules.
--- @return { name: string, path: string }[]
function M.discover_rules()
  local by_name = {}

  -- Project-level rules first (higher priority)
  scan_rule_dirs(config.values.completion.custom_rules, by_name)

  -- Global rules (only if not already found by name)
  scan_rule_dirs(config.values.completion.global_rules, by_name)

  local rules = {}
  for _, r in pairs(by_name) do
    table.insert(rules, r)
  end
  table.sort(rules, function(a, b) return a.name < b.name end)
  return rules
end

--- Discover project files via git ls-files, falling back to glob.
--- @return string[]
function M.discover_files()
  local cwd = vim.uv.cwd()
  if not cwd then
    return {}
  end

  -- Try git ls-files first
  local result = vim.fn.systemlist("git ls-files 2>/dev/null")
  if vim.v.shell_error == 0 and #result > 0 then
    return result
  end

  -- Fallback: glob (limited depth)
  local files = vim.fn.glob("**/*", false, true)
  local filtered = {}
  for _, f in ipairs(files) do
    if vim.fn.isdirectory(f) == 0 then
      table.insert(filtered, f)
    end
  end
  return filtered
end

--- Read the content of a rule file.
--- @param path string
--- @return string|nil
local function read_file(path)
  local file = io.open(path, "r")
  if not file then
    return nil
  end
  local content = file:read("*a")
  file:close()
  return content
end

--- Parse a prompt string and resolve all #rule and @file references.
--- Returns the cleaned prompt text and a list of resolved references.
--- @param text string
--- @return string cleaned_text, herald.Reference[] refs
function M.resolve(text)
  local refs = {}
  local rules = M.discover_rules()
  local rules_by_name = {}
  for _, r in ipairs(rules) do
    rules_by_name[r.name] = r.path
  end

  -- Resolve #rules
  local cleaned = text:gsub("#([%w_%-]+)", function(name)
    local path = rules_by_name[name]
    if path then
      local content = read_file(path)
      if content then
        table.insert(refs, {
          type = "rule",
          name = name,
          content = string.format("<rule name=\"%s\">\n%s\n</rule>", name, content),
        })
        return "" -- remove the token from the prompt
      end
    end
    return "#" .. name -- leave unresolved tokens as-is
  end)

  -- Resolve @files
  cleaned = cleaned:gsub("@([%S]+)", function(filepath)
    local content = read_file(filepath)
    if content then
      table.insert(refs, {
        type = "file",
        name = filepath,
        content = string.format("<file path=\"%s\">\n%s\n</file>", filepath, content),
      })
      return ""
    end
    return "@" .. filepath
  end)

  cleaned = vim.trim(cleaned)
  return cleaned, refs
end

--- Set up completion for a prompt buffer.
--- @param buf number
function M.attach(buf)
  local rules_cache = nil
  local files_cache = nil

  vim.api.nvim_buf_set_option(buf, "omnifunc", "v:lua.require'herald.completions'._omnifunc")

  -- Store caches on the buffer so omnifunc can access them
  vim.b[buf].herald_completions = {
    get_rules = function()
      if not rules_cache then
        rules_cache = M.discover_rules()
      end
      return rules_cache
    end,
    get_files = function()
      if not files_cache then
        files_cache = M.discover_files()
      end
      return files_cache
    end,
  }

  -- Trigger completion on # and @
  vim.keymap.set("i", "#", "#<C-x><C-o>", { buffer = buf, noremap = true })
  vim.keymap.set("i", "@", "@<C-x><C-o>", { buffer = buf, noremap = true })
end

--- Omnifunc implementation for the prompt buffer.
--- @param findstart number
--- @param base string
--- @return number|table
function M._omnifunc(findstart, base)
  if findstart == 1 then
    local line = vim.api.nvim_get_current_line()
    local col = vim.fn.col(".") - 1

    -- Walk backwards to find # or @
    local i = col
    while i > 0 do
      local ch = line:sub(i, i)
      if ch == "#" or ch == "@" then
        return i -- return position after the trigger char
      end
      if ch == " " or ch == "\t" then
        break
      end
      i = i - 1
    end
    return -3 -- cancel completion
  end

  local line = vim.api.nvim_get_current_line()
  local col = vim.fn.col(".") - 1
  local start = col - #base

  -- Find the trigger character
  local trigger = nil
  if start > 0 then
    trigger = line:sub(start, start)
  end

  local buf = vim.api.nvim_get_current_buf()
  local cmp = vim.b[buf].herald_completions
  if not cmp then
    return {}
  end

  local items = {}

  if trigger == "#" then
    local rules = cmp.get_rules()
    for _, r in ipairs(rules) do
      if r.name:find(base, 1, true) == 1 or base == "" then
        table.insert(items, {
          word = r.name,
          menu = "[rule]",
          info = r.path,
        })
      end
    end
  elseif trigger == "@" then
    local files = cmp.get_files()
    for _, f in ipairs(files) do
      if f:find(base, 1, true) or base == "" then
        table.insert(items, {
          word = f,
          menu = "[file]",
        })
      end
    end
  end

  return items
end

return M

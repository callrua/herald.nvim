local config = require("herald.config")

local M = {}

M.system = {
  search = [[
You are a code search tool. Your ONLY job is to find relevant locations in the project and output them in a machine-parseable format.

CRITICAL: Your entire response must be ONLY lines in this exact format, nothing else:
/absolute/path/to/file.ext:LINE:COL,COUNT,NOTES

Where:
- LINE = 1-based line number
- COL = 1-based column number
- COUNT = number of lines to highlight
- NOTES = brief description of why this location is relevant

Example valid output:
/Users/foo/src/main.go:42:1,5,Entry point for the application
/Users/foo/src/config.go:10:1,3,Configuration loading

RULES:
- Do NOT write prose, explanations, or markdown
- Do NOT use code fences
- Do NOT prefix output with any text
- Every line must match the format above or it will be discarded
- Paths must be absolute
- If you find nothing relevant, output nothing]],

  visual = [[
You receive a code selection and a prompt. Return ONLY the replacement code.
No markdown fences. No explanation. No commentary. Just the code that should
replace the selection. Preserve the indentation level of the original code.]],

  agent = [[
You are working on a task in this project. Use the available tools to read files,
make edits, and run commands as needed. Provide a brief summary of what you changed
when done.]],
}

--- Walk up the directory tree from `start_dir` to `root`, collecting md_files.
--- @param start_path string absolute path of the current file
--- @return string collected context from md files
function M.collect_md_context(start_path)
  local cwd = vim.uv.cwd()
  if not cwd then
    return ""
  end

  local dir = vim.fn.fnamemodify(start_path, ":h")
  local parts = {}

  while dir:find(cwd, 1, true) == 1 do
    for _, md_name in ipairs(config.values.md_files) do
      local md_path = dir .. "/" .. md_name
      local file = io.open(md_path, "r")
      if file then
        local content = file:read("*a")
        file:close()
        table.insert(parts, content)
      end
    end

    if dir == cwd then
      break
    end
    dir = vim.fn.fnamemodify(dir, ":h")
  end

  return table.concat(parts, "\n\n")
end

--- Build the full system prompt for an operation, including md file context.
--- @param operation "search"|"visual"|"agent"
--- @return string
function M.build_system_prompt(operation)
  local base = M.system[operation] or ""
  local current_file = vim.api.nvim_buf_get_name(0)
  local md_context = M.collect_md_context(current_file)

  if md_context ~= "" then
    return base .. "\n\n" .. md_context
  end
  return base
end

--- Format a visual selection for inclusion in the user prompt.
--- @param selection_text string
--- @param file_path string
--- @param start_line number
--- @param end_line number
--- @param surrounding_context string
--- @return string
function M.format_visual_prompt(user_prompt, selection_text, file_path, start_line, end_line, surrounding_context)
  return string.format(
    [[<FILE>%s</FILE>
<SELECTION lines="%d-%d">
%s
</SELECTION>
<SURROUNDING_CONTEXT>
%s
</SURROUNDING_CONTEXT>
<PROMPT>
%s
</PROMPT>]],
    file_path,
    start_line,
    end_line,
    selection_text,
    surrounding_context,
    user_prompt
  )
end

return M

local cli = require("herald.cli")
local parse = require("herald.parse")
local config = require("herald.config")
local prompt = require("herald.prompt")

local M = {}

local spinner_frames = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }

--- Get surrounding context lines around a range.
--- @param buf number
--- @param start_line number 0-indexed
--- @param end_line number 0-indexed (exclusive)
--- @param context_lines number
--- @return string
local function get_surrounding(buf, start_line, end_line, context_lines)
  local total = vim.api.nvim_buf_line_count(buf)
  local from = math.max(start_line - context_lines, 0)
  local to = math.min(end_line + context_lines, total)
  local lines = vim.api.nvim_buf_get_lines(buf, from, to, false)
  return table.concat(lines, "\n")
end

--- Start an inline spinner above a line using virtual text.
--- @param buf number
--- @param ns number
--- @param line number 0-indexed
--- @return { stop: fun() }
local function start_inline_spinner(buf, ns, line)
  local frame_idx = 0
  local spinner_mark = nil

  local function update()
    if not vim.api.nvim_buf_is_valid(buf) then
      return
    end

    frame_idx = (frame_idx % #spinner_frames) + 1
    local text = spinner_frames[frame_idx] .. " herald"

    if spinner_mark then
      pcall(vim.api.nvim_buf_del_extmark, buf, ns, spinner_mark)
    end

    -- Re-read the current position of mark_start to follow edits
    spinner_mark = vim.api.nvim_buf_set_extmark(buf, ns, line, 0, {
      virt_lines_above = true,
      virt_lines = { { { text, "Comment" } } },
    })
  end

  update()

  local timer = vim.uv.new_timer()
  timer:start(80, 80, vim.schedule_wrap(update))

  return {
    stop = function()
      timer:stop()
      timer:close()
      if spinner_mark then
        pcall(vim.api.nvim_buf_del_extmark, buf, ns, spinner_mark)
      end
    end,
  }
end

--- Run a visual replacement operation.
--- Extmarks must already be placed by the caller (init.lua).
--- @param user_prompt string
--- @param buf number
--- @param start_line number 1-indexed
--- @param end_line number 1-indexed
--- @param ns number extmark namespace
--- @param mark_start number extmark id for selection start
--- @param mark_end number extmark id for selection end
function M.run(user_prompt, buf, start_line, end_line, ns, mark_start, mark_end)
  local completions = require("herald.completions")
  local cleaned, refs = completions.resolve(user_prompt)

  local file_path = vim.api.nvim_buf_get_name(buf)

  -- Get the selected text
  local lines = vim.api.nvim_buf_get_lines(buf, start_line - 1, end_line, false)
  local selection_text = table.concat(lines, "\n")

  -- Get surrounding context (50 lines above and below)
  local surrounding = get_surrounding(buf, start_line - 1, end_line, 50)

  local full_prompt = prompt.format_visual_prompt(
    cleaned, selection_text, file_path, start_line, end_line, surrounding
  )

  -- Append resolved references
  for _, ref in ipairs(refs) do
    full_prompt = full_prompt .. "\n" .. ref.content
  end

  -- Inline spinner above the selection
  local spinner = start_inline_spinner(buf, ns, start_line - 1)

  local request_id = cli.run(full_prompt, {
    system_prompt = prompt.build_system_prompt("visual"),
    disallowed_tools = "Bash Edit Write Read Glob Grep",
    bare = config.values.visual.bare,
    no_session = true,
  }, function(result)
    spinner.stop()

    -- Read extmark positions and clean up
    local ok_start, cur_start = pcall(vim.api.nvim_buf_get_extmark_by_id, buf, ns, mark_start, {})
    local ok_end, cur_end = pcall(vim.api.nvim_buf_get_extmark_by_id, buf, ns, mark_end, {})
    vim.api.nvim_buf_del_extmark(buf, ns, mark_start)
    vim.api.nvim_buf_del_extmark(buf, ns, mark_end)

    if result.is_error then
      vim.notify("Herald visual failed: " .. (result.error or "unknown error"), vim.log.levels.ERROR)
      return
    end

    if not ok_start or not ok_end or #cur_start == 0 or #cur_end == 0 then
      vim.notify("Herald: selection marks lost, cannot apply replacement", vim.log.levels.ERROR)
      return
    end

    local new_start_line = cur_start[1] -- 0-indexed
    local new_end_line = cur_end[1] + 1 -- 0-indexed, exclusive

    local replacement_lines = vim.split(result.text, "\n", { plain = true })
    replacement_lines = parse.fix_first_indent(replacement_lines, lines[1])
    vim.api.nvim_buf_set_lines(buf, new_start_line, new_end_line, false, replacement_lines)

    local cost = result.cost_usd and string.format(" ($%.4f)", result.cost_usd) or ""
    vim.notify(string.format("Herald: replaced %d lines%s", #replacement_lines, cost), vim.log.levels.INFO)
  end)

  _ = request_id
end

return M

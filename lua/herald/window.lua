local M = {}

--- @class herald.CaptureOpts
--- @field title string
--- @field callback fun(ok: boolean, text: string)

--- Open a centered floating window for prompt input.
--- :w submits, q cancels.
--- @param opts herald.CaptureOpts
function M.capture_input(opts)
  local width = math.floor(vim.o.columns * 2 / 3)
  local height = math.floor(vim.o.lines / 3)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "herald"

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = string.format(" %s  (w submit, q cancel) ", opts.title),
    title_pos = "center",
  })

  vim.wo[win].wrap = true
  vim.wo[win].cursorline = true

  local done = false

  local function finish(ok, text)
    if done then
      return
    end
    done = true
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    opts.callback(ok, text)
  end

  local function submit()
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local text = vim.trim(table.concat(lines, "\n"))
    finish(text ~= "", text)
  end

  -- Submit on w (normal mode)
  vim.keymap.set("n", "w", submit, { buffer = buf, nowait = true })

  -- Cancel on q
  vim.keymap.set("n", "q", function()
    finish(false, "")
  end, { buffer = buf, nowait = true })

  -- Cancel if window is closed externally
  vim.api.nvim_create_autocmd("WinClosed", {
    pattern = tostring(win),
    once = true,
    callback = function()
      finish(false, "")
    end,
  })

  -- Attach completions for #rules and @files
  require("herald.completions").attach(buf)

  vim.cmd("startinsert")
end

--- Display text in a vertical split (used for agent results).
--- @param lines string[]
--- @param title string|nil
function M.display_split(lines, title)
  vim.cmd("vnew")
  local buf = vim.api.nvim_get_current_buf()
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "markdown"

  if title then
    vim.api.nvim_buf_set_name(buf, title)
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
end

return M

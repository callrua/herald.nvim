local config = require("herald.config")
local session = require("herald.session")
local cli = require("herald.cli")
local window = require("herald.window")

local M = {}

--- @param opts herald.Config|nil
function M.setup(opts)
  config.setup(opts)
  session.load()

  vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
      cli.stop()
      session.save()
    end,
  })
end

--- Open a prompt window and run a search operation.
function M.search()
  window.capture_input({
    title = "Herald Search",
    callback = function(ok, text)
      if not ok then
        return
      end
      require("herald.ops.search").run(text)
    end,
  })
end

--- Open a prompt window and replace the current visual selection.
function M.visual()
  -- Exit visual mode first so '< '> marks are set
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "x", false)

  -- Capture selection info on the original buffer
  local buf = vim.api.nvim_get_current_buf()
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  local start_line = start_pos[2]
  local end_line = end_pos[2]

  -- Place extmarks now while we're still in the right buffer
  local ns = vim.api.nvim_create_namespace("herald_visual")
  local mark_start = vim.api.nvim_buf_set_extmark(buf, ns, start_line - 1, 0, {})
  local mark_end = vim.api.nvim_buf_set_extmark(buf, ns, end_line - 1, 0, {})

  window.capture_input({
    title = "Herald Visual",
    callback = function(ok, text)
      if not ok then
        vim.api.nvim_buf_del_extmark(buf, ns, mark_start)
        vim.api.nvim_buf_del_extmark(buf, ns, mark_end)
        return
      end
      require("herald.ops.visual").run(text, buf, start_line, end_line, ns, mark_start, mark_end)
    end,
  })
end

--- Open a prompt window and run an agentic task.
function M.agent()
  window.capture_input({
    title = "Herald Agent",
    callback = function(ok, text)
      if not ok then
        return
      end
      require("herald.ops.agent").run(text)
    end,
  })
end

--- Stop the current in-flight request.
function M.stop()
  cli.stop()
end

--- Start a new session (next request will create a fresh one).
function M.new_session()
  session.new_session()
  vim.notify("Herald: new session started", vim.log.levels.INFO)
end

--- Name the current session.
--- @param name string
function M.name_session(name)
  session.name_session(name)
  vim.notify("Herald: session named '" .. name .. "'", vim.log.levels.INFO)
end

--- Show a picker to resume a previous session.
function M.resume_session()
  local items = session.list_sessions()
  if #items == 0 then
    vim.notify("Herald: no sessions found", vim.log.levels.INFO)
    return
  end

  local display_items = {}
  for _, item in ipairs(items) do
    table.insert(display_items, item.display)
  end

  vim.ui.select(display_items, { prompt = "Resume session:" }, function(_, idx)
    if not idx then
      return
    end
    session.resume(items[idx].id)
    vim.notify("Herald: resumed session " .. items[idx].display, vim.log.levels.INFO)
  end)
end

--- Show info about the current session.
function M.session_info()
  local info = session.current_info()
  if not info then
    vim.notify("Herald: no active session", vim.log.levels.INFO)
    return
  end

  local name = info.name or "(unnamed)"
  local created = os.date("%Y-%m-%d %H:%M", info.created_at)
  vim.notify(
    string.format("Session: %s\nID: %s\nCreated: %s", name, info.id, created),
    vim.log.levels.INFO
  )
end

return M

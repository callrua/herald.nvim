local cli = require("herald.cli")
local config = require("herald.config")
local prompt = require("herald.prompt")
local window = require("herald.window")

local M = {}

--- Run an agentic task.
--- @param user_prompt string
function M.run(user_prompt)
  local completions = require("herald.completions")
  local cleaned, refs = completions.resolve(user_prompt)

  -- Append resolved references
  local full_prompt = cleaned
  for _, ref in ipairs(refs) do
    full_prompt = full_prompt .. "\n" .. ref.content
  end

  local progress = nil
  local has_fidget, fidget = pcall(require, "fidget")
  if has_fidget then
    progress = fidget.progress.handle.create({
      title = "",
      message = "",
      lsp_client = { name = "" },
    })
  end

  cli.run(full_prompt, {
    system_prompt = prompt.build_system_prompt("agent"),
    permission_mode = config.values.permission_mode,
  }, function(result)
    if progress then
      progress:finish()
    end

    if result.is_error then
      vim.notify("Herald agent failed: " .. (result.error or "unknown error"), vim.log.levels.ERROR)
      return
    end

    local lines = vim.split(result.text, "\n", { plain = true })
    window.display_split(lines, "Herald Agent Result")

    local cost = result.cost_usd and string.format(" ($%.4f)", result.cost_usd) or ""
    local duration = result.duration_ms and string.format(" in %.1fs", result.duration_ms / 1000) or ""
    vim.notify(
      string.format("Herald: agent complete%s%s", duration, cost),
      vim.log.levels.INFO
    )
  end)
end

return M

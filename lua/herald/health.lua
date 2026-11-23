local M = {}

function M.check()
  local health = vim.health
  local config = require("herald.config").values

  health.start("herald.nvim")

  if vim.fn.has("nvim-0.10") == 1 then
    health.ok("Neovim " .. tostring(vim.version()))
  else
    health.error("Neovim 0.10 or later is required (vim.system, vim.uv)")
  end

  if vim.fn.executable("claude") == 1 then
    local version = vim.fn.system({ "claude", "--version" })
    health.ok("claude found: " .. vim.trim(version))
  else
    health.error("claude not found on PATH", {
      "Install Claude Code: https://docs.anthropic.com/en/docs/claude-code",
    })
  end

  if config.visual.bare then
    if vim.env.ANTHROPIC_API_KEY and vim.env.ANTHROPIC_API_KEY ~= "" then
      health.ok("visual.bare is on and ANTHROPIC_API_KEY is set")
    else
      health.warn("visual.bare is on but ANTHROPIC_API_KEY is not set", {
        "--bare ignores subscription logins. Set ANTHROPIC_API_KEY or set visual.bare = false.",
      })
    end
  end

  if pcall(require, "fidget") then
    health.ok("fidget.nvim found (search and agent spinners)")
  else
    health.info("fidget.nvim not found. Search and agent run without a spinner.")
  end

  for _, key in ipairs({ "custom_rules", "global_rules" }) do
    for _, dir in ipairs(config.completion[key]) do
      local expanded = vim.fn.expand(dir)
      if vim.fn.isdirectory(expanded) == 1 then
        local count = #vim.fn.glob(expanded .. "/*/SKILL.md", false, true)
        health.ok(string.format("completion.%s: %s (%d rules)", key, dir, count))
      else
        health.warn(string.format("completion.%s: %s does not exist", key, dir))
      end
    end
  end
end

return M

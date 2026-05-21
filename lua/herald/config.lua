--- @class herald.Config
--- @field model string
--- @field effort string|nil
--- @field permission_mode string
--- @field max_budget_usd number|nil
--- @field md_files string[]
--- @field system_prompt string|nil
--- @field completion herald.CompletionConfig

--- @class herald.CompletionConfig
--- @field custom_rules string[]
--- @field global_rules string[]
--- @field files { enabled: boolean }

--- @type herald.Config
local defaults = {
  model = "sonnet",
  effort = nil,
  permission_mode = "auto",
  max_budget_usd = nil,
  md_files = { "AGENT.md", "CLAUDE.md" },
  system_prompt = nil,
  completion = {
    custom_rules = {},
    global_rules = {},
    files = { enabled = true },
  },
}

local M = {}

--- @type herald.Config
M.values = vim.deepcopy(defaults)

--- @param opts herald.Config|nil
function M.setup(opts)
  M.values = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})
end

return M

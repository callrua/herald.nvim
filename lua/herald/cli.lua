local config = require("herald.config")
local parse = require("herald.parse")
local session = require("herald.session")

local M = {}

--- @type table<number, vim.SystemObj>
M._procs = {}

local next_id = 0

--- Build the base claude CLI arguments shared across all operations.
--- @return string[]
local function base_args()
  local args = { "claude", "--print", "--output-format", "json", "--model", config.values.model }

  if config.values.effort then
    vim.list_extend(args, { "--effort", config.values.effort })
  end

  if config.values.max_budget_usd then
    vim.list_extend(args, { "--max-budget-usd", tostring(config.values.max_budget_usd) })
  end

  return args
end

--- @class herald.RunOpts
--- @field system_prompt string|nil
--- @field allowed_tools string|nil
--- @field disallowed_tools string|nil
--- @field bare boolean|nil
--- @field permission_mode string|nil
--- @field no_session boolean|nil
--- @field title string|nil

--- Run a claude CLI command.
--- @param prompt string
--- @param opts herald.RunOpts|nil
--- @param callback fun(result: herald.Result)
--- @return number request_id
function M.run(prompt, opts, callback)
  opts = opts or {}

  next_id = next_id + 1
  local request_id = next_id

  local args = base_args()

  if not opts.no_session then
    local sid = session.current_id()
    if sid then
      vim.list_extend(args, { "--resume", sid })
    end
  end

  if opts.bare then
    table.insert(args, "--bare")
  end

  if opts.allowed_tools then
    vim.list_extend(args, { "--allowedTools", opts.allowed_tools })
  elseif opts.disallowed_tools then
    vim.list_extend(args, { "--disallowedTools", opts.disallowed_tools })
  end

  if opts.permission_mode then
    vim.list_extend(args, { "--permission-mode", opts.permission_mode })
  end

  local system_prompt = opts.system_prompt
  if config.values.system_prompt then
    if system_prompt then
      system_prompt = system_prompt .. "\n\n" .. config.values.system_prompt
    else
      system_prompt = config.values.system_prompt
    end
  end
  if system_prompt then
    vim.list_extend(args, { "--append-system-prompt", system_prompt })
  end

  -- "--" separates flags from the positional prompt arg.
  -- Without this, vim.system() can misattribute the prompt to a flag.
  vim.list_extend(args, { "--", prompt })

  local stdout_chunks = {}

  local proc = vim.system(
    args,
    {
      text = true,
      stdout = function(_, data)
        if data then
          table.insert(stdout_chunks, data)
        end
      end,
    },
    vim.schedule_wrap(function(obj)
      M._procs[request_id] = nil

      local raw = table.concat(stdout_chunks, "")

      if obj.code ~= 0 then
        callback({
          text = "",
          is_error = true,
          error = string.format("claude exited with code %d: %s", obj.code, obj.stderr or raw),
        })
        return
      end

      local result = parse.json_result(raw)

      if result.session_id then
        session.capture(result.session_id)
        session.save()
      end

      callback(result)
    end)
  )

  M._procs[request_id] = proc
  return request_id
end

--- Stop a specific request by ID.
--- @param request_id number
function M.stop_one(request_id)
  local proc = M._procs[request_id]
  if proc then
    proc:kill(15)
    M._procs[request_id] = nil
  end
end

--- Stop all in-flight requests.
function M.stop()
  local count = 0
  for id, proc in pairs(M._procs) do
    proc:kill(15)
    M._procs[id] = nil
    count = count + 1
  end
  if count > 0 then
    vim.notify(string.format("Cancelled %d request(s)", count), vim.log.levels.INFO)
  else
    vim.notify("No requests in flight", vim.log.levels.INFO)
  end
end

return M

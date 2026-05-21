local cli = require("herald.cli")
local parse = require("herald.parse")
local prompt = require("herald.prompt")

local M = {}

--- Run a search operation.
--- @param user_prompt string
function M.run(user_prompt)
  local completions = require("herald.completions")
  local cleaned, refs = completions.resolve(user_prompt)

  -- Append resolved references to the prompt
  local ref_context = ""
  for _, ref in ipairs(refs) do
    ref_context = ref_context .. "\n" .. ref.content
  end
  local full_prompt = cleaned .. ref_context

  -- Fidget spinner for search
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
    system_prompt = prompt.build_system_prompt("search"),
    allowed_tools = "Read Bash(grep:*,find:*,rg:*,git:*,ls:*)",
  }, function(result)
    if progress then
      progress:finish()
    end

    if result.is_error then
      vim.notify("Herald search failed: " .. (result.error or "unknown error"), vim.log.levels.ERROR)
      return
    end

    local locations = parse.search_locations(result.text)

    if #locations == 0 then
      vim.notify("Herald: no results parsed. Raw response:\n" .. result.text:sub(1, 500), vim.log.levels.WARN)
      return
    end

    local qf_items = {}
    for _, loc in ipairs(locations) do
      table.insert(qf_items, {
        filename = loc.filename,
        lnum = loc.lnum,
        col = loc.col,
        text = loc.text,
      })
    end

    vim.fn.setqflist({}, "r", { title = "Herald Search", items = qf_items })
    vim.cmd("copen")

    local cost = result.cost_usd and string.format(" ($%.4f)", result.cost_usd) or ""
    vim.notify(
      string.format("Herald: %d result(s) found%s", #locations, cost),
      vim.log.levels.INFO
    )
  end)
end

return M

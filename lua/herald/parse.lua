local M = {}

--- @class herald.Result
--- @field text string
--- @field session_id string|nil
--- @field is_error boolean
--- @field cost_usd number|nil
--- @field duration_ms number|nil
--- @field num_turns number|nil
--- @field stop_reason string|nil
--- @field error string|nil
--- @field raw string|nil

--- Parse the JSON response from claude --print --output-format json
--- @param raw_stdout string
--- @return herald.Result
function M.json_result(raw_stdout)
  local ok, decoded = pcall(vim.json.decode, raw_stdout)
  if not ok then
    return {
      text = "",
      is_error = true,
      error = "JSON parse failed",
      raw = raw_stdout,
    }
  end

  return {
    text = decoded.result or "",
    session_id = decoded.session_id,
    is_error = decoded.is_error or false,
    cost_usd = decoded.total_cost_usd,
    duration_ms = decoded.duration_ms,
    num_turns = decoded.num_turns,
    stop_reason = decoded.stop_reason,
  }
end

--- @class herald.SearchLocation
--- @field filename string
--- @field lnum number
--- @field col number
--- @field count number
--- @field text string

--- Parse search result text into quickfix-compatible entries
--- Format: /path/to/file.ext:LINE:COL,COUNT,NOTES
--- @param text string
--- @return herald.SearchLocation[]
function M.search_locations(text)
  local results = {}
  for line in text:gmatch("[^\n]+") do
    local filepath, lnum, col, count, notes =
      line:match("^(.-):(%d+):(%d+),(%d+),(.*)$")
    if filepath then
      table.insert(results, {
        filename = filepath,
        lnum = tonumber(lnum),
        col = tonumber(col),
        count = tonumber(count),
        text = notes or "",
      })
    end
  end
  return results
end

return M

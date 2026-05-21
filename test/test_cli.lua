-- Test cli module with a real claude call
local config = require("herald.config")
local cli = require("herald.cli")
local session = require("herald.session")

config.setup({ model = "sonnet" })

local done = false

print("Running real claude CLI test...")

cli.run("respond with just the word 'pong'", {
  disable_tools = true,
  bare = true,
}, function(result)
  if result.is_error then
    print("FAIL: request errored - " .. (result.error or "unknown"))
    done = true
    return
  end

  local has_pong = result.text:lower():find("pong") ~= nil
  if has_pong then
    print("OK: got response containing 'pong'")
  else
    print("FAIL: expected 'pong' in response, got: " .. result.text)
  end

  if result.session_id then
    print("OK: session_id captured: " .. result.session_id:sub(1, 8) .. "...")
  else
    print("FAIL: no session_id in response")
  end

  if session.current_id() == result.session_id then
    print("OK: session module captured the id")
  else
    print("FAIL: session module didn't capture id")
  end

  if result.cost_usd and result.cost_usd > 0 then
    print(string.format("OK: cost reported: $%.6f", result.cost_usd))
  else
    print("WARN: no cost info")
  end

  done = true
end)

-- Wait for async completion (up to 30s)
vim.wait(30000, function() return done end, 100)

if not done then
  print("FAIL: timed out waiting for claude response")
end

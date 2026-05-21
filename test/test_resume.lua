-- Test that session resume works: second request remembers the first
local config = require("herald.config")
local cli = require("herald.cli")
local session = require("herald.session")

config.setup({ model = "sonnet" })

local step = 0

print("Test 1: initial request...")
cli.run("Remember the secret word: banana. Reply with just 'ok'.", {
  bare = true,
  disallowed_tools = "Bash Edit Write Read Glob Grep",
}, function(result)
  if result.is_error then
    print("FAIL: first request errored - " .. (result.error or ""))
    step = 99
    return
  end

  print("  Response: " .. result.text:sub(1, 50))
  print("  Session: " .. (session.current_id() or "nil"):sub(1, 8) .. "...")

  step = 1
end)

vim.wait(30000, function() return step >= 1 end, 100)
if step == 99 then return end

print("Test 2: resume and recall...")
cli.run("What was the secret word I told you? Reply with just the word.", {
  bare = true,
  disallowed_tools = "Bash Edit Write Read Glob Grep",
}, function(result)
  if result.is_error then
    print("FAIL: second request errored - " .. (result.error or ""))
    step = 99
    return
  end

  local has_banana = result.text:lower():find("banana") ~= nil
  if has_banana then
    print("  OK: Claude remembered 'banana' across requests")
  else
    print("  FAIL: expected 'banana', got: " .. result.text)
  end

  step = 2
end)

vim.wait(30000, function() return step >= 2 end, 100)
if step < 2 then
  print("FAIL: timed out")
end

-- Test session module
local session = require("herald.session")

local passed = 0
local failed = 0

local function assert_eq(name, got, expected)
  if got == expected then
    passed = passed + 1
  else
    failed = failed + 1
    print(string.format("FAIL: %s\n  expected: %s\n  got:      %s", name, vim.inspect(expected), vim.inspect(got)))
  end
end

-- Initially no session
assert_eq("initial: no session", session.current_id(), nil)
assert_eq("initial: no info", session.current_info(), nil)

-- Capture a session
session.capture("test-uuid-1234")
assert_eq("capture: current_id", session.current_id(), "test-uuid-1234")
assert_eq("capture: info exists", session.current_info() ~= nil, true)
assert_eq("capture: info id", session.current_info().id, "test-uuid-1234")

-- Name it
session.name_session("my test session")
assert_eq("name: info name", session.current_info().name, "my test session")

-- List sessions
local items = session.list_sessions()
assert_eq("list: count", #items, 1)

-- Capture another session
session.capture("test-uuid-5678")
assert_eq("second: current_id", session.current_id(), "test-uuid-5678")
local items2 = session.list_sessions()
assert_eq("list2: count", #items2, 2)

-- New session clears current
session.new_session()
assert_eq("new: current_id", session.current_id(), nil)
-- But sessions are still in the list
local items3 = session.list_sessions()
assert_eq("new: list still has 2", #items3, 2)

-- Resume
session.resume("test-uuid-1234")
assert_eq("resume: current_id", session.current_id(), "test-uuid-1234")
assert_eq("resume: name preserved", session.current_info().name, "my test session")

-- Resume nonexistent (should notify error, not crash)
local notify = vim.notify
local notified = false
vim.notify = function() notified = true end
session.resume("nonexistent")
vim.notify = notify
assert_eq("bad resume: notified", notified, true)
-- current should remain unchanged
assert_eq("bad resume: current unchanged", session.current_id(), "test-uuid-1234")

print(string.format("\n%d passed, %d failed", passed, failed))
if failed > 0 then
  vim.cmd("cquit 1")
end
os.exit(failed > 0 and 1 or 0)

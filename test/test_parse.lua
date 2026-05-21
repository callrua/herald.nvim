-- Test parse module
local parse = require("herald.parse")

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

-- Test json_result parsing
local sample_json = '{"type":"result","subtype":"success","is_error":false,"duration_ms":1817,"num_turns":1,"result":"hello","stop_reason":"end_turn","session_id":"22fbcb47-07d2-45b4-803d-b1c5eba6a859","total_cost_usd":0.001206}'

local result = parse.json_result(sample_json)
assert_eq("json: text", result.text, "hello")
assert_eq("json: session_id", result.session_id, "22fbcb47-07d2-45b4-803d-b1c5eba6a859")
assert_eq("json: is_error", result.is_error, false)
assert_eq("json: cost", result.cost_usd, 0.001206)
assert_eq("json: duration", result.duration_ms, 1817)
assert_eq("json: stop_reason", result.stop_reason, "end_turn")

-- Test json_result with bad input
local bad = parse.json_result("not json")
assert_eq("bad json: is_error", bad.is_error, true)
assert_eq("bad json: error set", bad.error ~= nil, true)

-- Test search location parsing
local search_text = [[/Users/foo/src/main.go:42:1,5,The main entry point
/Users/foo/src/handler.go:100:8,3,Handles the request]]

local locations = parse.search_locations(search_text)
assert_eq("search: count", #locations, 2)
assert_eq("search: file1", locations[1].filename, "/Users/foo/src/main.go")
assert_eq("search: lnum1", locations[1].lnum, 42)
assert_eq("search: col1", locations[1].col, 1)
assert_eq("search: count1", locations[1].count, 5)
assert_eq("search: notes1", locations[1].text, "The main entry point")
assert_eq("search: file2", locations[2].filename, "/Users/foo/src/handler.go")
assert_eq("search: lnum2", locations[2].lnum, 100)

-- Test empty search
local empty = parse.search_locations("")
assert_eq("empty search", #empty, 0)

-- Test search with non-matching lines mixed in
local mixed = parse.search_locations("Some preamble text\n/foo/bar.go:10:1,2,actual result\nMore noise")
assert_eq("mixed: count", #mixed, 1)
assert_eq("mixed: file", mixed[1].filename, "/foo/bar.go")

-- Test notes with commas
local comma_notes = parse.search_locations("/foo.go:1:1,3,Notes with, commas, inside")
assert_eq("comma notes: count", #comma_notes, 1)
assert_eq("comma notes: text", comma_notes[1].text, "Notes with, commas, inside")

print(string.format("\n%d passed, %d failed", passed, failed))
if failed > 0 then
  vim.cmd("cquit 1")
end

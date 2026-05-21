local M = {}

--- @class herald.Session
--- @field name string|nil
--- @field created_at number
--- @field last_used number

--- @class herald.SessionState
--- @field current_session_id string|nil
--- @field sessions table<string, herald.Session>

--- @type herald.SessionState
local state = {
  current_session_id = nil,
  sessions = {},
}

local function data_dir()
  return vim.fn.stdpath("data") .. "/herald"
end

local function data_file()
  return data_dir() .. "/sessions.json"
end

--- @return string|nil
function M.current_id()
  return state.current_session_id
end

--- Store the session_id from a response. Called after every successful request.
--- @param session_id string
function M.capture(session_id)
  if not session_id then
    return
  end

  state.current_session_id = session_id

  if not state.sessions[session_id] then
    state.sessions[session_id] = {
      name = nil,
      created_at = os.time(),
      last_used = os.time(),
    }
  else
    state.sessions[session_id].last_used = os.time()
  end
end

--- Clear the current session so the next request starts fresh.
function M.new_session()
  state.current_session_id = nil
end

--- Name the current session.
--- @param name string
function M.name_session(name)
  if not state.current_session_id then
    vim.notify("No active session to name", vim.log.levels.WARN)
    return
  end

  local session = state.sessions[state.current_session_id]
  if session then
    session.name = name
  end
end

--- Get a display list of all sessions for picker UI.
--- @return { id: string, display: string }[]
function M.list_sessions()
  local items = {}
  for id, session in pairs(state.sessions) do
    local display = session.name or id:sub(1, 8)
    local age = os.difftime(os.time(), session.last_used)
    local ago
    if age < 3600 then
      ago = string.format("%dm ago", math.floor(age / 60))
    elseif age < 86400 then
      ago = string.format("%dh ago", math.floor(age / 3600))
    else
      ago = string.format("%dd ago", math.floor(age / 86400))
    end
    display = string.format("%s (%s)", display, ago)
    if id == state.current_session_id then
      display = display .. " *"
    end
    table.insert(items, { id = id, display = display, last_used = session.last_used })
  end

  table.sort(items, function(a, b)
    return a.last_used > b.last_used
  end)

  return items
end

--- Resume a specific session by ID.
--- @param session_id string
function M.resume(session_id)
  if not state.sessions[session_id] then
    vim.notify("Session not found: " .. session_id, vim.log.levels.ERROR)
    return
  end
  state.current_session_id = session_id
end

--- Persist sessions to disk.
function M.save()
  local dir = data_dir()
  if not vim.uv.fs_stat(dir) then
    vim.fn.mkdir(dir, "p")
  end

  local json = vim.json.encode(state)
  local file = io.open(data_file(), "w")
  if file then
    file:write(json)
    file:close()
  end
end

--- Load sessions from disk.
function M.load()
  local file = io.open(data_file(), "r")
  if not file then
    return
  end

  local content = file:read("*a")
  file:close()

  local ok, decoded = pcall(vim.json.decode, content)
  if ok and decoded then
    state.current_session_id = decoded.current_session_id
    state.sessions = decoded.sessions or {}
  end
end

--- Get info about the current session.
--- @return { id: string, name: string|nil, created_at: number, last_used: number }|nil
function M.current_info()
  if not state.current_session_id then
    return nil
  end

  local session = state.sessions[state.current_session_id]
  if not session then
    return nil
  end

  return {
    id = state.current_session_id,
    name = session.name,
    created_at = session.created_at,
    last_used = session.last_used,
  }
end

return M

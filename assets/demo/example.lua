local M = {}

--- Collect the name of every item.
function M.names(items)
  local names = {}
  for _, item in ipairs(items) do
    table.insert(names, item.name)
  end
  return names
end

return M

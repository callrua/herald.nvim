if vim.g.loaded_herald then
  return
end
vim.g.loaded_herald = true

vim.api.nvim_create_user_command("HeraldSearch", function()
  require("herald").search()
end, { desc = "Herald: semantic search" })

vim.api.nvim_create_user_command("HeraldAgent", function(opts)
  if opts.args ~= "" then
    require("herald.ops.agent").run(opts.args)
  else
    require("herald").agent()
  end
end, { nargs = "?", desc = "Herald: agentic task" })

vim.api.nvim_create_user_command("HeraldStop", function()
  require("herald").stop()
end, { desc = "Herald: cancel in-flight request" })

vim.api.nvim_create_user_command("HeraldNewSession", function()
  require("herald").new_session()
end, { desc = "Herald: start a new session" })

vim.api.nvim_create_user_command("HeraldSession", function(opts)
  require("herald").name_session(opts.args)
end, { nargs = 1, desc = "Herald: name the current session" })

vim.api.nvim_create_user_command("HeraldResume", function()
  require("herald").resume_session()
end, { desc = "Herald: resume a previous session" })

vim.api.nvim_create_user_command("HeraldSessionInfo", function()
  require("herald").session_info()
end, { desc = "Herald: show current session info" })

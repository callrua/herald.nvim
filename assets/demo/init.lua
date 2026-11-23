-- Minimal config for recording assets/demo.tape. Loads herald from this checkout
-- and nothing from your own config or installed plugins.
local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h:h")
vim.opt.runtimepath = { root, vim.env.VIMRUNTIME }
vim.opt.packpath = { vim.env.VIMRUNTIME }

vim.g.mapleader = " "
vim.o.number = true
vim.o.termguicolors = true
vim.o.laststatus = 0
vim.o.tabstop = 4
vim.o.shortmess = vim.o.shortmess .. "I"
vim.cmd.colorscheme("habamax")

local herald = require("herald")
herald.setup({ model = "sonnet" })
vim.keymap.set("v", "<leader>hv", herald.visual)

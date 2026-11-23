-- Minimal config for recording assets/demo.tape. Loads herald from this checkout.
local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h:h")
vim.opt.rtp:prepend(root)

vim.g.mapleader = " "
vim.o.number = true
vim.o.termguicolors = true
vim.o.laststatus = 0
vim.o.shortmess = vim.o.shortmess .. "I"
vim.cmd.colorscheme("habamax")

local herald = require("herald")
herald.setup({ model = "sonnet" })
vim.keymap.set("v", "<leader>hv", herald.visual)

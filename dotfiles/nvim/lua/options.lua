-- ── options.lua ──────────────────────────────────────────────────────────────
-- Sensible editor defaults (kickstart-derived).

local opt = vim.opt

opt.number = true
opt.relativenumber = false
opt.mouse = "a"
opt.showmode = false          -- lualine already shows the mode
opt.clipboard = "unnamedplus" -- share the system clipboard (wl-clipboard on Wayland)
opt.breakindent = true
opt.undofile = true
opt.ignorecase = true
opt.smartcase = true
opt.signcolumn = "yes"
opt.updatetime = 250
opt.timeoutlen = 400
opt.splitright = true
opt.splitbelow = true
opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
opt.inccommand = "split"      -- live preview of :substitute
opt.cursorline = true
opt.scrolloff = 8
opt.termguicolors = true      -- 24-bit colour (required for the theme)

-- Indentation: 2 spaces by default.
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.smartindent = true

-- Clear search highlight on <Esc>.
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Briefly highlight yanked text.
vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight on yank",
  group = vim.api.nvim_create_augroup("highlight-yank", { clear = true }),
  callback = function() vim.highlight.on_yank() end,
})

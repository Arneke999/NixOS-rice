-- ── init.lua ─────────────────────────────────────────────────────────────────
-- Entry point. Seeded from kickstart.nvim, reorganised into modules.
-- Leader must be set before lazy loads. Order: options → keymaps → plugins → theme.

vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.g.have_nerd_font = true

require("options")
require("keymaps")

-- Bootstrap lazy.nvim. It clones itself on first launch and installs plugins
-- into ~/.local/share/nvim — NOT into this repo — so the exact same config is
-- portable to Arch (or anywhere) with no Nix packaging of plugins.
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local repo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", repo, lazypath })
  if vim.v.shell_error ~= 0 then
    error("Failed to clone lazy.nvim:\n" .. out)
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = { { import = "plugins" } },
  install = { colorscheme = { "habamax" } },
  ui = { border = "rounded" },
  checker = { enabled = false }, -- don't nag about plugin updates
})

-- Apply the matugen-derived theme LAST so it overrides plugin defaults.
require("theme").apply()

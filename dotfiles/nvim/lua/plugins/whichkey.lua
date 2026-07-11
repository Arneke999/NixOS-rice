-- which-key: popup that shows pending keybindings after leader.
return {
  "folke/which-key.nvim",
  event = "VimEnter",
  opts = {
    delay = 300,
    icons = { mappings = vim.g.have_nerd_font },
    spec = {
      { "<leader>s", group = "Search" },
      { "<leader>h", group = "Git hunk" },
      { "<leader>r", group = "Rename/Refactor" },
      { "<leader>c", group = "Code" },
      { "<leader>d", group = "Document/Diagnostic" },
    },
  },
}

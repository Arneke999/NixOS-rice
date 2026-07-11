-- Telescope: fuzzy finder over files, grep, buffers, help, etc.
-- Needs ripgrep (grep) and fd (files) on PATH — provided via Nix.
return {
  "nvim-telescope/telescope.nvim",
  event = "VimEnter",
  dependencies = {
    "nvim-lua/plenary.nvim",
    { -- native fzf sorter, compiled with make (gcc provided via Nix)
      "nvim-telescope/telescope-fzf-native.nvim",
      build = "make",
      cond = function() return vim.fn.executable("make") == 1 end,
    },
    "nvim-telescope/telescope-ui-select.nvim",
    "nvim-tree/nvim-web-devicons",
  },
  config = function()
    local telescope = require("telescope")
    telescope.setup({
      extensions = {
        ["ui-select"] = { require("telescope.themes").get_dropdown() },
      },
    })
    pcall(telescope.load_extension, "fzf")
    pcall(telescope.load_extension, "ui-select")

    local builtin = require("telescope.builtin")
    local map = vim.keymap.set
    map("n", "<leader>sf", builtin.find_files, { desc = "Search files" })
    map("n", "<leader>sg", builtin.live_grep, { desc = "Search by grep" })
    map("n", "<leader>sw", builtin.grep_string, { desc = "Search current word" })
    map("n", "<leader>sh", builtin.help_tags, { desc = "Search help" })
    map("n", "<leader>sd", builtin.diagnostics, { desc = "Search diagnostics" })
    map("n", "<leader>sk", builtin.keymaps, { desc = "Search keymaps" })
    map("n", "<leader>sr", builtin.resume, { desc = "Resume last search" })
    map("n", "<leader><leader>", builtin.buffers, { desc = "Find open buffers" })
    map("n", "<leader>/", builtin.current_buffer_fuzzy_find, { desc = "Fuzzy find in buffer" })
  end,
}

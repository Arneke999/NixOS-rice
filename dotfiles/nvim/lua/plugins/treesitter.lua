-- Treesitter: better syntax highlighting, indentation, text objects.
-- Parsers compile on install; requires a C compiler (gcc, provided via Nix).
return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  main = "nvim-treesitter.configs",
  opts = {
    ensure_installed = {
      "bash", "c", "lua", "luadoc", "markdown", "markdown_inline",
      "nix", "python", "vim", "vimdoc", "json", "yaml", "toml", "kdl",
    },
    auto_install = true,
    highlight = { enable = true },
    indent = { enable = true },
  },
}

-- LSP: language servers via nvim-lspconfig.
-- NO mason — mason downloads prebuilt binaries that break on NixOS. Instead the
-- servers are installed with the system package manager (Nix here, pacman on
-- Arch) and nvim uses whatever is on PATH. Add a server: install its package,
-- then add an entry to `servers` below.
return {
  "neovim/nvim-lspconfig",
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",
    { "j-hui/fidget.nvim", opts = {} }, -- LSP progress in the corner
  },
  config = function()
    -- Keymaps applied when a server attaches to a buffer.
    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
      callback = function(event)
        local map = function(keys, fn, desc)
          vim.keymap.set("n", keys, fn, { buffer = event.buf, desc = "LSP: " .. desc })
        end
        local builtin = require("telescope.builtin")
        map("gd", builtin.lsp_definitions, "Goto definition")
        map("gr", builtin.lsp_references, "Goto references")
        map("gI", builtin.lsp_implementations, "Goto implementation")
        map("<leader>D", builtin.lsp_type_definitions, "Type definition")
        map("<leader>ds", builtin.lsp_document_symbols, "Document symbols")
        map("K", vim.lsp.buf.hover, "Hover docs")
        map("<leader>rn", vim.lsp.buf.rename, "Rename")
        map("<leader>ca", vim.lsp.buf.code_action, "Code action")
        map("gD", vim.lsp.buf.declaration, "Goto declaration")
      end,
    })

    local capabilities = require("cmp_nvim_lsp").default_capabilities()

    -- Servers to enable IF their binary is on PATH.
    local servers = {
      lua_ls = {
        settings = {
          Lua = {
            completion = { callSnippet = "Replace" },
            diagnostics = { globals = { "vim" } },
          },
        },
      },
      nixd = {}, -- Nix language server
    }

    local lspconfig = require("lspconfig")
    for name, opts in pairs(servers) do
      opts.capabilities = capabilities
      lspconfig[name].setup(opts)
    end
  end,
}

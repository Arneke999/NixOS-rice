-- ── diagnostics.lua ──────────────────────────────────────────────────────────
-- Error Lens-style diagnostics, built on nvim's own vim.diagnostic (NO plugin, so
-- it's portable to the Arch machine and adds nothing to lazy-lock):
--   • the message shown INLINE at the end of every line that has one, coloured by
--     severity (the signature Error Lens feature — no hover needed);
--   • a subtle whole-line background tint for errors + warnings only (info/hint stay
--     quiet, so the screen doesn't get noisy);
--   • coloured line numbers + pretty Nerd Font gutter icons;
--   • rounded diagnostic float (K-hover style) showing the source.
--
-- Toggle the inline text on/off with <leader>ud (e.g. when a line is very long).
--
-- MUST be require()d from init.lua AFTER theme.apply(), because the theme does a
-- `highlight clear` on apply — the custom groups below have to be set last to survive.
local M = {}

local icons = {
  [vim.diagnostic.severity.ERROR] = "",
  [vim.diagnostic.severity.WARN]  = "",
  [vim.diagnostic.severity.INFO]  = "",
  [vim.diagnostic.severity.HINT]  = "",
}

function M.setup()
  vim.diagnostic.config({
    severity_sort = true,
    update_in_insert = false,
    underline = true,
    -- Inline message on every diagnostic line. The gutter carries the icon, so the
    -- inline text stays clean (just the message, coloured by DiagnosticVirtualText*).
    virtual_text = {
      spacing = 2,
      prefix = "",
      format = function(d) return d.message end,
    },
    signs = {
      text = icons,
      numhl = {
        [vim.diagnostic.severity.ERROR] = "DiagnosticError",
        [vim.diagnostic.severity.WARN]  = "DiagnosticWarn",
        [vim.diagnostic.severity.INFO]  = "DiagnosticInfo",
        [vim.diagnostic.severity.HINT]  = "DiagnosticHint",
      },
      linehl = {
        [vim.diagnostic.severity.ERROR] = "ErrorLensErrorLine",
        [vim.diagnostic.severity.WARN]  = "ErrorLensWarnLine",
      },
    },
    float = { border = "rounded", source = true, header = "", prefix = "" },
  })

  -- Custom highlights (set after theme.apply(); see header note).
  local ok, c = pcall(require, "theme-colors")
  if not ok then
    c = { error = "#f38ba8", secondary = "#cba6f7", tertiary = "#b4befe", on_surface_variant = "#a6adc8" }
  end
  local hl = function(g, s) vim.api.nvim_set_hl(0, g, s) end
  -- Subtle whole-line washes over the near-black base (#0f0f11).
  hl("ErrorLensErrorLine", { bg = "#241519" })
  hl("ErrorLensWarnLine",  { bg = "#231f14" })
  -- Inline message: severity colour + italic, no bg (sits on the line wash).
  hl("DiagnosticVirtualTextError", { fg = c.error,              italic = true })
  hl("DiagnosticVirtualTextWarn",  { fg = c.secondary,          italic = true })
  hl("DiagnosticVirtualTextInfo",  { fg = c.tertiary,           italic = true })
  hl("DiagnosticVirtualTextHint",  { fg = c.on_surface_variant, italic = true })

  -- <leader>ud — toggle the inline diagnostic text (line tint/gutter stay).
  vim.keymap.set("n", "<leader>ud", function()
    local shown = vim.diagnostic.config().virtual_text
    vim.diagnostic.config({
      virtual_text = shown and false or { spacing = 2, prefix = "", format = function(d) return d.message end },
    })
    vim.notify("Inline diagnostics " .. (shown and "off" or "on"), vim.log.levels.INFO)
  end, { desc = "Toggle inline diagnostics (Error Lens)" })
end

return M

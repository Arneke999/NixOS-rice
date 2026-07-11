-- ── theme.lua ────────────────────────────────────────────────────────────────
-- A fully wallpaper-driven colorscheme. Every foreground/accent comes from the
-- matugen palette (lua/matugen-colors.lua, regenerated on each wallpaper change).
-- Only the BACKGROUND ramp is pinned near-black so nvim matches kitty and the
-- rest of the rice (the "fixed background" rule).
--
-- ⚠️ MUDDY-COLOUR ESCAPE HATCH: because the palette is near-monochrome, git and
-- diagnostic colours below can be hard to tell apart. If that bothers you, flip
-- `local semantic = false` to `true` to use fixed red/green/yellow for those
-- groups only (everything else stays wallpaper-driven).
local semantic = false

local M = {}

function M.apply()
  -- Fallback palette (used before the first matugen render exists).
  local ok, c = pcall(require, "matugen-colors")
  if not ok then
    c = {
      primary = "#ffb2b9", on_primary = "#0f0f11", primary_container = "#5a2b34",
      secondary = "#e5bdbf", tertiary = "#e8c08e", error = "#ffb4ab",
      on_surface = "#f0dedf", on_surface_variant = "#c8c8ce",
      surface_variant = "#2a2a30", outline = "#6e6e76",
    }
  end

  -- Pinned near-black surfaces (match kitty #0f0f11).
  local bg      = "#0f0f11"
  local bg_dark = "#0b0b0d"
  local bg_alt  = "#141416"
  local bg_sel  = "#1e1e22"
  local border  = "#26262c"

  -- Semantic (diff/diagnostic) colours: wallpaper-driven by default.
  local ok_c, warn_c, err_c = c.tertiary, c.secondary, c.error
  local add_c, chg_c, del_c = c.secondary, c.tertiary, c.error
  if semantic then
    ok_c, warn_c, err_c = "#98c379", "#e5c07b", "#e06c75"
    add_c, chg_c, del_c = "#98c379", "#e5c07b", "#e06c75"
  end

  vim.o.background = "dark"
  vim.cmd.highlight("clear")
  if vim.g.colors_name then vim.cmd.highlight("clear") end
  vim.g.colors_name = "matugen"

  local hl = function(group, spec) vim.api.nvim_set_hl(0, group, spec) end

  local groups = {
    -- Editor UI
    Normal       = { fg = c.on_surface, bg = bg },
    NormalFloat  = { fg = c.on_surface, bg = bg_dark },
    FloatBorder  = { fg = border, bg = bg_dark },
    FloatTitle   = { fg = c.primary, bg = bg_dark, bold = true },
    ColorColumn  = { bg = bg_alt },
    Cursor       = { fg = bg, bg = c.primary },
    CursorLine   = { bg = bg_alt },
    CursorLineNr = { fg = c.primary, bold = true },
    LineNr       = { fg = c.outline },
    SignColumn   = { bg = bg },
    Visual       = { bg = bg_sel },
    VisualNOS    = { bg = bg_sel },
    Search       = { fg = bg, bg = c.tertiary },
    IncSearch    = { fg = bg, bg = c.primary },
    CurSearch    = { fg = bg, bg = c.primary },
    MatchParen   = { fg = c.primary, bold = true },
    WinSeparator = { fg = border },
    VertSplit    = { fg = border },
    Folded       = { fg = c.outline, bg = bg_alt },
    NonText      = { fg = "#3a3a40" },
    Whitespace   = { fg = "#2a2a30" },
    EndOfBuffer  = { fg = bg },
    Directory    = { fg = c.primary },
    Title        = { fg = c.primary, bold = true },

    -- Popup menu / completion
    Pmenu        = { fg = c.on_surface_variant, bg = bg_dark },
    PmenuSel     = { fg = bg, bg = c.primary, bold = true },
    PmenuSbar    = { bg = bg_alt },
    PmenuThumb   = { bg = c.outline },

    -- Statusline / tabline (lualine themes itself; these cover the fallbacks)
    StatusLine   = { fg = c.on_surface_variant, bg = bg_alt },
    StatusLineNC = { fg = c.outline, bg = bg_dark },
    TabLineFill  = { bg = bg_dark },
    TabLine      = { fg = c.outline, bg = bg_dark },
    TabLineSel   = { fg = bg, bg = c.primary },

    -- Messages
    ErrorMsg   = { fg = c.error },
    WarningMsg = { fg = warn_c },
    ModeMsg    = { fg = c.on_surface_variant },
    MoreMsg    = { fg = c.primary },
    Question   = { fg = c.primary },

    -- Syntax (classic groups)
    Comment    = { fg = c.outline, italic = true },
    Constant   = { fg = c.tertiary },
    String     = { fg = c.secondary },
    Character  = { fg = c.secondary },
    Number     = { fg = c.tertiary },
    Boolean    = { fg = c.tertiary },
    Float      = { fg = c.tertiary },
    Identifier = { fg = c.on_surface },
    Function   = { fg = c.primary },
    Statement  = { fg = c.primary },
    Keyword    = { fg = c.primary, italic = true },
    Conditional= { fg = c.primary },
    Repeat     = { fg = c.primary },
    Operator   = { fg = c.on_surface_variant },
    Exception  = { fg = c.error },
    PreProc    = { fg = c.secondary },
    Include    = { fg = c.secondary },
    Define     = { fg = c.secondary },
    Type       = { fg = c.tertiary },
    StorageClass = { fg = c.tertiary },
    Structure  = { fg = c.tertiary },
    Special    = { fg = c.secondary },
    Delimiter  = { fg = c.on_surface_variant },
    Todo       = { fg = bg, bg = c.tertiary, bold = true },
    Error      = { fg = c.error },
    Underlined = { fg = c.primary, underline = true },

    -- Treesitter (@-groups). Most link to the classics above; a few overrides.
    ["@variable"]          = { fg = c.on_surface },
    ["@variable.builtin"]  = { fg = c.error },
    ["@variable.member"]   = { fg = c.on_surface_variant },
    ["@property"]          = { fg = c.on_surface_variant },
    ["@parameter"]         = { fg = c.on_surface, italic = true },
    ["@function"]          = { fg = c.primary },
    ["@function.builtin"]  = { fg = c.primary },
    ["@function.call"]     = { fg = c.primary },
    ["@method"]            = { fg = c.primary },
    ["@constructor"]       = { fg = c.tertiary },
    ["@keyword"]           = { fg = c.primary, italic = true },
    ["@keyword.return"]    = { fg = c.error, italic = true },
    ["@string"]            = { fg = c.secondary },
    ["@type"]              = { fg = c.tertiary },
    ["@type.builtin"]      = { fg = c.tertiary, italic = true },
    ["@constant"]          = { fg = c.tertiary },
    ["@constant.builtin"]  = { fg = c.tertiary },
    ["@tag"]               = { fg = c.primary },
    ["@tag.attribute"]     = { fg = c.tertiary },
    ["@punctuation"]       = { fg = c.on_surface_variant },
    ["@comment"]           = { fg = c.outline, italic = true },

    -- LSP
    ["@lsp.type.namespace"] = { fg = c.tertiary },
    ["@lsp.type.parameter"] = { fg = c.on_surface, italic = true },
    LspInlayHint            = { fg = c.outline, bg = bg_alt },
    LspReferenceText        = { bg = bg_sel },
    LspReferenceRead        = { bg = bg_sel },
    LspReferenceWrite       = { bg = bg_sel },

    -- Diagnostics
    DiagnosticError = { fg = err_c },
    DiagnosticWarn  = { fg = warn_c },
    DiagnosticInfo  = { fg = c.secondary },
    DiagnosticHint  = { fg = c.on_surface_variant },
    DiagnosticOk    = { fg = ok_c },
    DiagnosticUnderlineError = { undercurl = true, sp = err_c },
    DiagnosticUnderlineWarn  = { undercurl = true, sp = warn_c },
    DiagnosticUnderlineInfo  = { undercurl = true, sp = c.secondary },
    DiagnosticUnderlineHint  = { undercurl = true, sp = c.on_surface_variant },

    -- Git (gitsigns)
    GitSignsAdd    = { fg = add_c },
    GitSignsChange = { fg = chg_c },
    GitSignsDelete = { fg = del_c },
    DiffAdd        = { fg = add_c, bg = bg_alt },
    DiffChange     = { fg = chg_c, bg = bg_alt },
    DiffDelete     = { fg = del_c, bg = bg_alt },
    DiffText       = { fg = bg, bg = chg_c },

    -- Telescope
    TelescopeBorder         = { fg = border, bg = bg_dark },
    TelescopeNormal         = { fg = c.on_surface, bg = bg_dark },
    TelescopePromptBorder   = { fg = border, bg = bg_dark },
    TelescopePromptTitle    = { fg = bg, bg = c.primary, bold = true },
    TelescopeResultsTitle   = { fg = bg_dark, bg = bg_dark },
    TelescopePreviewTitle   = { fg = bg, bg = c.tertiary, bold = true },
    TelescopeSelection      = { bg = bg_sel, fg = c.on_surface },
    TelescopeMatching       = { fg = c.primary, bold = true },

    -- which-key
    WhichKey          = { fg = c.primary },
    WhichKeyGroup     = { fg = c.tertiary },
    WhichKeyDesc      = { fg = c.on_surface },
    WhichKeySeparator = { fg = c.outline },
    WhichKeyFloat     = { bg = bg_dark },
  }

  for group, spec in pairs(groups) do
    hl(group, spec)
  end

  -- Link a few extra treesitter groups to keep things consistent.
  local links = {
    ["@number"] = "Number", ["@boolean"] = "Boolean", ["@float"] = "Float",
    ["@string.escape"] = "Special", ["@operator"] = "Operator",
    ["@field"] = "@variable.member", ["@namespace"] = "@type",
    ["@keyword.function"] = "@keyword", ["@keyword.operator"] = "@keyword",
    ["@conditional"] = "Conditional", ["@repeat"] = "Repeat",
  }
  for from, to in pairs(links) do
    vim.api.nvim_set_hl(0, from, { link = to })
  end
end

return M

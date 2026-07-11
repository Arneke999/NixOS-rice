-- Statusline, themed from the matugen palette so it matches the bar and kitty.
return {
  "nvim-lualine/lualine.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    -- Build a lualine theme from the wallpaper palette (pcall for first run).
    local ok, c = pcall(require, "matugen-colors")
    if not ok then
      c = { primary = "#ffb2b9", secondary = "#e5bdbf", tertiary = "#e8c08e",
            on_surface = "#f0dedf", on_surface_variant = "#c8c8ce", outline = "#6e6e76" }
    end
    local bg, bg_alt, black = "#0f0f11", "#1e1e22", "#0b0b0d"

    local mode = { a = { fg = black, bg = c.primary, gui = "bold" },
                   b = { fg = c.on_surface, bg = bg_alt },
                   c = { fg = c.on_surface_variant, bg = bg } }
    local theme = {
      normal   = mode,
      insert   = { a = { fg = black, bg = c.tertiary, gui = "bold" }, b = mode.b, c = mode.c },
      visual   = { a = { fg = black, bg = c.secondary, gui = "bold" }, b = mode.b, c = mode.c },
      replace  = { a = { fg = black, bg = c.tertiary, gui = "bold" }, b = mode.b, c = mode.c },
      command  = { a = { fg = black, bg = c.primary, gui = "bold" }, b = mode.b, c = mode.c },
      inactive = { a = { fg = c.outline, bg = bg }, b = { fg = c.outline, bg = bg }, c = { fg = c.outline, bg = bg } },
    }

    require("lualine").setup({
      options = {
        theme = theme,
        icons_enabled = vim.g.have_nerd_font,
        component_separators = "",
        section_separators = { left = "", right = "" },
        globalstatus = true,
      },
      sections = {
        lualine_a = { "mode" },
        lualine_b = { "branch", "diff", "diagnostics" },
        lualine_c = { { "filename", path = 1 } },
        lualine_x = { "filetype" },
        lualine_y = { "progress" },
        lualine_z = { "location" },
      },
    })
  end,
}

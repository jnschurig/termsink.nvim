local M = {}

---theme settings
local defaults = {
  -- Typographic styles per syntax role. Opt-in only: an empty table means
  -- "no style override" (default appearance). Values are passed through to
  -- nvim_set_hl, so any valid attribute works (italic, bold, underline, ...).
  styles = {
    comments = {},
    strings = {},
    keywords = {},
    functions = {},
    variables = {},
    operators = {},
    types = {},
  },
  disable = {
    background = false,
    eob_lines = true,
  },
  lualine_style = "default",
  -- Lualine theme to apply automatically when termsink loads.
  -- Default "termsink" routes lualine through our contrast-fitted theme.
  -- Set to false (or any other string like "auto") to keep your existing
  -- lualine theme untouched.
  lualine_theme = "termsink",
  plugins = {},
  async_loading = false,
  -- Contrast thresholds for the readability pipeline.
  -- See lua/termsink/colors/contrast.lua for defaults and meaning.
  contrast_thresholds = {},
}

M.settings = defaults

---setup function
---@param user_settings table user defined settings for the theme
M.setup = function(user_settings)
  M.settings = vim.tbl_deep_extend("force", {}, defaults, user_settings or {})
end

return M

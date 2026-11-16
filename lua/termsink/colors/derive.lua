-- Fill in colors the terminal did not report.
-- Some sources return a palette with no (or only some) special colors, and
-- may leave individual palette slots null. Derive sensible values from what
-- is there so the theme stays coherent instead of mixing in unrelated
-- defaults. Results still pass through the contrast pipeline downstream.

local contrast = require("termsink.colors.contrast")
local oklch = require("termsink.colors.oklch")

local M = {}

-- How far (OKLCH L) the derived selection bg sits from the editor bg.
local SELECTION_L_OFFSET = 0.15

---@param colors table theme_info.colors (mutated and returned)
---@param default_palette string[] built-in palette, [1..16] = ANSI 0..15
---@return table colors
function M.derive_missing(colors, default_palette)
  colors.palette = colors.palette or {}
  local palette = colors.palette
  for i = 1, 16 do
    palette[i] = palette[i] or default_palette[i]
  end

  colors.background = colors.background or palette[1]

  if not colors.foreground then
    local white, bright_white = palette[8], palette[16]
    local better = contrast.wcag_ratio(bright_white, colors.background)
      > contrast.wcag_ratio(white, colors.background)
    colors.foreground = better and bright_white or white
  end

  colors.cursor_color = colors.cursor_color or colors.foreground
  colors.cursor_text = colors.cursor_text or colors.background

  if not colors.selection_bg then
    local bg_l = oklch.hex_to_oklch(colors.background).L
    local fg_l = oklch.hex_to_oklch(colors.foreground).L
    local direction = (fg_l >= bg_l) and 1 or -1
    colors.selection_bg = oklch.shift_lightness(colors.background, direction * SELECTION_L_OFFSET)
  end

  -- selection_fg is left nil on purpose: colors/init.lua picks whichever of
  -- bg/fg reads better on the selection bg.
  return colors
end

return M

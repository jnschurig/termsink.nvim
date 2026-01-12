-- local high_visibility = require "termsink.util.config".settings.high_visibility
local term_colors = require("termsink.colors.termcolor")
-- local closest_color_match = require("termsink.functions.functions.closest_color_match")
-- local adjust_color_value = require("termsink.functions.functions.adjust_color_value")
local functions = require("termsink.functions")

local pure_red    = "#ff0000"
local pure_green  = "#00ff00"
local pure_blue   = "#0000ff"
local pure_cyan   = "#40ffff"
local pure_yellow = "#ffff00"
local pure_purple = "#8000ff"
local pure_orange = "#ff8000" -- 255 128 0
-- local pure_pink   = "#ff00ff"
local pure_white  = "#ffffff"
local pure_black  = "#000000"
local pure_gray   = "#808080"

-- local palette_index = 1
-- if vim.g.termsink_style == "secondary" then
-- 	palette_index = 9
-- end

-- TODO: create a function in functions which will take the above as input
-- and return the colors.main colors below

-- local local_use_palette = {}
-- for i = 1, 8 do
-- 	local idx = i + palette_index
-- 	local_use_palette[i] = term_colors.palette[idx]
-- end

print("------ termcolor test ------")
print("term_color type: ", type(term_colors))

for key, value in pairs(term_colors) do
  print("key: " .. key)
  if value then
    if type(value) ~= "table" then
      print("value: " .. value)
    else
      for subkey, subval in ipairs(value) do
        print("  subkey: " .. subkey)
        print("  subval: " .. subval)
      end
    end
  else
    print("value is nil")
  end
end
print("------ termcolor test end ------")

---colors table
local colors = {
	---main colors
	main = {
		red      = functions.closest_color_match(pure_red   , term_colors.palette),
		green    = functions.closest_color_match(pure_green , term_colors.palette),
		yellow   = functions.closest_color_match(pure_yellow, term_colors.palette),
		blue     = functions.closest_color_match(pure_blue  , term_colors.palette),
		purple   = functions.closest_color_match(pure_purple, term_colors.palette),
		cyan     = functions.closest_color_match(pure_cyan  , term_colors.palette),
		orange   = functions.closest_color_match(pure_orange, term_colors.palette),
  },
}

colors.main.darkred     = functions.adjust_color_value(colors.main.red   , 0.75)
colors.main.darkgreen   = functions.adjust_color_value(colors.main.green , 0.75)
colors.main.darkyellow  = functions.adjust_color_value(colors.main.yellow, 0.75)
colors.main.darkblue    = functions.adjust_color_value(colors.main.blue  , 0.75)
colors.main.darkcyan    = functions.adjust_color_value(colors.main.cyan  , 0.75)
colors.main.darkpurple  = functions.adjust_color_value(colors.main.purple, 0.75)
colors.main.darkorange  = functions.adjust_color_value(colors.main.orange, 0.75)
colors.main.paleblue    = functions.adjust_color_value(colors.main.blue  , 1.25)

term_colors.palette[17] = term_colors.ui.foreground
term_colors.palette[18] = term_colors.ui.background
term_colors.palette[19] = term_colors.ui.cursor_color
term_colors.palette[20] = term_colors.ui.cursor_text
term_colors.palette[21] = term_colors.ui.selection_background
term_colors.palette[22] = term_colors.ui.selection_foreground

colors.main.gray     = functions.closest_color_match(pure_gray, term_colors.palette)
colors.main.white    = functions.closest_color_match(pure_white, term_colors.palette)
colors.main.black    = functions.closest_color_match(pure_black, term_colors.palette)

	---colors applied to the editor
colors.editor = {
  link = colors.main.cyan,
  cursor = colors.main.yellow,
  title = term_colors.ui.foreground
}

colors.lsp = {
  error = colors.main.red,
}

colors.syntax = {}
colors.git = {}
colors.backgrounds = {}

-- {
--   ui = {
--     foreground = "#eeeeee",
--     background = "#1c1c1c",
--     cursor_color = "#eeeeee",
--     cursor_text = "#1c1c1c",
--     selection_background = "#444444",
--     selection_foreground = "#ffffff",
--   },
--   palette = {
--     "#000000", "#cd3131", "#0dbc79", "#e5e510",
--     "#2472c8", "#bc3fbc", "#11a8cd", "#e5e5e5",
--     "#666666", "#f14c4c", "#23d18b", "#f5f543",
--     "#3b8eea", "#d670d6", "#29b8db", "#ffffff",
--   }
-- }

---editor colors
colors.editor.bg = term_colors.ui.background
colors.editor.bg_alt = functions.adjust_color_value(colors.editor.bg, 0.75)
colors.editor.fg = term_colors.ui.foreground
colors.editor.fg_dark = functions.adjust_color_value(colors.editor.fg, 0.75)
colors.editor.selection = term_colors.ui.selection_background
colors.editor.contrast = functions.adjust_color_value(colors.editor.selection, 0.75) -- darker than selection
colors.editor.active = colors.editor.selection -- similar to selection
colors.editor.border = colors.editor.selection -- slightly darker than active
colors.editor.line_numbers = colors.editor.border -- about the same as border
colors.editor.highlight = colors.editor.selection
colors.editor.disabled = functions.adjust_color_value(colors.editor.highlight, 1.25) -- lighter than highlight
colors.editor.accent = colors.main.purple
colors.editor.none = "NONE"
colors.syntax.comments = colors.main.gray -- use main.gray

---syntax colors
colors.syntax.variable = colors.editor.fg
colors.syntax.field = colors.editor.fg
colors.syntax.keyword = colors.main.purple
colors.syntax.value = colors.main.orange
colors.syntax.operator = colors.main.cyan
colors.syntax.fn = colors.main.blue
colors.syntax.parameter = colors.main.paleblue
colors.syntax.string = colors.main.green
colors.syntax.type = colors.main.purple

---git colors
colors.git.added = colors.main.green
colors.git.removed = colors.main.red
colors.git.modified = colors.main.blue

---lsp colors
colors.lsp.warning = colors.main.yellow
colors.lsp.info = colors.main.paleblue
colors.lsp.hint = colors.main.purple

---contrasted backgrounds
colors.backgrounds.sidebars = colors.editor.bg
colors.backgrounds.floating_windows = colors.editor.bg
colors.backgrounds.non_current_windows = colors.editor.bg
colors.backgrounds.bg_blend = colors.editor.bg
colors.backgrounds.cursor_line = colors.editor.active

return colors

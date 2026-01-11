-- local high_visibility = require "material.util.config".settings.high_visibility

---colors table
local colors = {
    ---main colors
    main = {
        white      = "#EEFFFF",
        gray       = "#717CB4",
        black      = "#000000",
        red        = "#F07178",
        green      = "#C3E88D",
        yellow     = "#FFCB6B",
        blue       = "#82AAFF",
        paleblue   = "#B0C9FF",
        cyan       = "#89DDFF",
        purple     = "#C792EA",
        orange     = "#F78C6C",
        -- pink       = "#FF9CAC",

        darkred    = "#DC6068",
        darkgreen  = "#ABCF76",
        darkyellow = "#E6B455",
        darkblue   = "#6E98EB",
        darkcyan   = "#71C6E7",
        darkpurple = "#B480D6",
        darkorange = "#E2795B",
    },

    ---colors applied to the editor
    editor = {
        link   = "#80CBC4",
        cursor = "#FFCC00",
        title  = "#EEFFFF",
    },

    lsp = {
        error = "#FF5370",
    },

    syntax = {},
    git = {},
    backgrounds = {},
}

---editor colors
colors.editor.bg           = "#292D3E"
colors.editor.bg_alt       = "#1B1E2B"
colors.editor.fg           = "#A6ACCD"
colors.editor.fg_dark      = "#717CB4"
colors.editor.selection    = "#444267"
colors.editor.contrast     = "#202331"
colors.editor.active       = "#414863"
colors.editor.border       = "#364367"
colors.editor.line_numbers = "#3A3F58"
colors.editor.highlight    = "#444267"
colors.editor.disabled     = "#515772"
colors.editor.accent       = "#AB47BC"
colors.editor.none         = "NONE"
colors.syntax.comments     = "#676E95"

---syntax colors
colors.syntax.variable  = colors.editor.fg
colors.syntax.field     = colors.editor.fg
colors.syntax.keyword   = colors.main.purple
colors.syntax.value     = colors.main.orange
colors.syntax.operator  = colors.main.cyan
colors.syntax.fn        = colors.main.blue
colors.syntax.parameter = colors.main.paleblue
colors.syntax.string    = colors.main.green
colors.syntax.type      = colors.main.purple

---git colors
colors.git.added    = colors.main.green
colors.git.removed  = colors.main.red
colors.git.modified = colors.main.blue

---lsp colors
colors.lsp.warning = colors.main.yellow
colors.lsp.info    = colors.main.paleblue
colors.lsp.hint    = colors.main.purple

---contrasted backgrounds
colors.backgrounds.sidebars            = colors.editor.bg
colors.backgrounds.floating_windows    = colors.editor.bg
colors.backgrounds.non_current_windows = colors.editor.bg
colors.backgrounds.bg_blend            = colors.editor.bg -- backup used for blending backgrounds (issue: #212)
colors.backgrounds.cursor_line         = colors.editor.active

return colors

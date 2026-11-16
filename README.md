# termsink.nvim

A Neovim colorscheme that takes its colors from the terminal you are running in.

termsink reads the active terminal theme through the
[`termcolors`](https://github.com/jnschurig/termcolors) CLI and builds a full
Neovim colorscheme from it, so Neovim always matches your terminal. It works
with any terminal `termcolors` can read (currently Ghostty and Rex), and falls
back to a built-in palette everywhere else.

Adapted from material.nvim by Marko Cerovac, whose work is the foundation of this
plugin.

Design philosophy:

1. If possible, colors should move straight across from the terminal theme.
2. Minimal configuration and customization.
3. If additional colors are needed, they should be adapted from original colors.
4. Highlights are checked for WCAG contrast against their background and adjusted
   along OKLCH lightness when needed — hue is preserved so the theme's character
   stays intact. See `lua/termsink/colors/README.md` for the readability
   pipeline and `:TermsinkAudit` for live inspection.

This is why so much customization has been removed from the source theme, and why there will
be even more options removed in the future.

## Requirements

- Neovim 0.10+
- The `termcolors` CLI on your `PATH`:

  ```sh
  brew install jnschurig/termcolors/termcolors
  ```

`termcolors` is the only external command the plugin runs. Rex support needs a
`termcolors` release that has `--source rex`.

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "jnschurig/termsink.nvim",
  lazy = false,
  priority = 1001,
  config = function()
    require("termsink").setup()
    vim.cmd.colorscheme("termsink")
  end,
}
```

## Configuration

```lua
require("termsink").setup({
  -- source = nil,                 -- which terminal to read; see below
  disable = {
    background = false,  -- set true for a transparent terminal
    eob_lines = true,    -- hide end-of-buffer ~ tildes
  },
  plugins = {
    -- "neo-tree",
  },
  styles = {
    comments = { italic = true },
    functions = { bold = true },
    -- keywords, strings, variables, operators, types, ...
  },
  -- lualine_theme = "termsink",   -- or false to keep your existing theme
  -- lualine_style = "default",    -- or "stealth"
  -- async_loading = false,
  -- contrast_thresholds = {},     -- override readability thresholds
})
vim.cmd.colorscheme("termsink")
```

## Where the colors come from

Colors are read once, when the colorscheme loads. To pick them up again after
changing your terminal theme, run `:colorscheme termsink`.

The source is chosen in this order:

1. The `source` option, passed straight through as `termcolors --source <value>`.
   Use an emulator name (`"rex"`, `"ghostty"`) or an absolute path to an
   emulator binary.
2. `$TERM_PROGRAM`, when it names a terminal `termcolors` knows (`rex`,
   `ghostty`).
3. Only if `$TERM_PROGRAM` is unset or unknown (for example inside tmux): the
   marker variables `GHOSTTY_RESOURCES_DIR` and `REX_SESSION`. If both are
   set, neither is used.
4. Otherwise plain `termcolors`, which honors `$TERMCOLORS_TERMINAL` and
   `~/.config/termcolors/config`.

Colors the terminal does not report are derived from the ones it does: for
example a missing background comes from palette color 0, and a missing
selection color is the background shifted toward the foreground.

### When colors can't be read

- If `termcolors` is missing, times out (1 second), fails, or prints something
  unreadable, termsink loads its built-in palette and shows one warning per
  Neovim session.
- In a terminal `termcolors` has no source for (kitty, WezTerm, ...), the
  built-in palette loads silently. Set `source`, or configure `termcolors`
  itself, to point it at a terminal it can read.

Run `:checkhealth termsink` to see whether `termcolors` was found, which
source was chosen and why, and whether the built-in palette is in use.

Ghostty note: `--source ghostty` needs the `ghostty` binary on `PATH`. On
macOS it usually is only inside a Ghostty window; elsewhere, pass the full
path:

```lua
require("termsink").setup({
  source = "/Applications/Ghostty.app/Contents/MacOS/ghostty",
})
```

## Commands

- `:colorscheme termsink` — load (or reload) the colorscheme.
- `:TermsinkAudit` — contrast audit of the currently loaded palette.
- `:TermsinkColors` — show the colors in use.
- `:checkhealth termsink` — diagnose color reading.

## Migrating from ghosttysync.nvim

termsink.nvim is the successor to ghosttysync.nvim. There are no compatibility
shims; rename these in your config:

| ghosttysync.nvim | termsink.nvim |
|---|---|
| `"jnschurig/ghosttysync.nvim"` | `"jnschurig/termsink.nvim"` |
| `require("ghosttysync")` | `require("termsink")` |
| `:colorscheme ghosttysync` | `:colorscheme termsink` |
| lualine themes `ghosttysync`, `ghosttysync-nvim`, `ghosttysync-stealth` | `termsink`, `termsink-nvim`, `termsink-stealth` |
| `:GhosttysyncAudit`, `:GhosttysyncColors` | `:TermsinkAudit`, `:TermsinkColors` |
| `vim.g.ghosttysync_style` | `vim.g.termsink_style` |

The plugin no longer runs `ghostty +show-config`. Install `termcolors`
instead (see Requirements).

## Plugin Structure

```
lua/termsink/
├── init.lua              # Exposes setup()
├── health.lua            # :checkhealth termsink
├── audit.lua             # :TermsinkAudit live contrast audit
├── audit_classify.lua    # Heuristics for classifying highlight groups
├── colors/
│   ├── reader.lua        # Runs `termcolors` and maps its JSON to the palette
│   ├── derive.lua        # Fills in colors the terminal did not report
│   ├── init.lua          # Builds the main/editor/syntax/backgrounds tables
│   ├── conditionals.lua  # Applies contrast options and binds role colors
│   ├── contrast.lua      # WCAG/OKLCH contrast enforcement
│   └── oklch.lua         # sRGB↔OKLCH conversion (gamut-clamped)
├── highlights/           # nvim_set_hl definitions (core + plugin integrations)
├── functions/            # User commands (incl. :TermsinkAudit)
└── util/                 # config defaults, deep-merge, theme loader
```

The full readability pipeline and audit harness are documented in
`lua/termsink/colors/README.md`. `scripts/audit.lua` runs the audit
against every fixture in `tests/fixtures/palettes/` and exits non-zero on
contrast regressions.

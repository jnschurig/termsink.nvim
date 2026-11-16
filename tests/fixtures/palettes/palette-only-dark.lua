-- A source that reports the 16 ANSI colors but no special colors (and a
-- null theme name). Exercises colors/derive.lua: bg, fg, cursor, and
-- selection are all derived from the palette.
return {
  name = "palette-only-dark",
  colors = {
    palette = {
      "#1d1f21",
      "#cc6666",
      "#b5bd68",
      "#f0c674",
      "#81a2be",
      "#b294bb",
      "#8abeb7",
      "#c5c8c6",
      "#666666",
      "#d54e53",
      "#b9ca4a",
      "#e7c547",
      "#7aa6da",
      "#c397d8",
      "#70c0b1",
      "#eaeaea",
    },
  },
}

-- Light terminal reporting background/foreground but no cursor or selection
-- colors, with two null palette slots. Exercises colors/derive.lua on a
-- light background (selection derived toward a darker foreground).
return {
  name = "palette-only-light",
  colors = {
    palette = {
      [2] = "#c82829",
      [3] = "#718c00",
      [4] = "#eab700",
      [5] = "#4271ae",
      [6] = "#8959a8",
      [7] = "#3e999f",
      [8] = "#d6d6d6",
      [9] = "#8e908c",
      [10] = "#c82829",
      [11] = "#718c00",
      [12] = "#eab700",
      [13] = "#4271ae",
      [14] = "#8959a8",
      [15] = "#3e999f",
    },
    background = "#ffffff",
    foreground = "#4d4d4c",
  },
}

-- Plain test runner. Run via:  nvim --headless -l scripts/test.lua
-- Adds the repo's `lua/` to package.path so requires resolve when run directly.

local script_path = debug.getinfo(1, "S").source:sub(2) -- strip leading "@"
local script_dir = script_path:match("(.*/)") or "./"
local repo_root = script_dir:gsub("scripts/$", "")
if repo_root == "" then
  repo_root = "./"
end
package.path = repo_root .. "lua/?.lua;" .. repo_root .. "lua/?/init.lua;" .. package.path

local failures = 0
local passes = 0

local function check(name, ok, msg)
  if ok then
    passes = passes + 1
    print(string.format("  ok  %s", name))
  else
    failures = failures + 1
    print(string.format("  FAIL %s: %s", name, msg or "(no message)"))
  end
end

local function approx(a, b, tol)
  return math.abs(a - b) <= (tol or 1e-6)
end

local function hex_to_rgb(hex)
  hex = hex:gsub("#", "")
  return tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16)
end

-- ---------- oklch ----------
print("oklch:")
local oklch = require("termsink.colors.oklch")

do
  for _, hex in ipairs({ "#000000", "#ffffff", "#808080" }) do
    local back = oklch.oklch_to_hex(oklch.hex_to_oklch(hex))
    local r1, g1, b1 = hex_to_rgb(hex)
    local r2, g2, b2 = hex_to_rgb(back)
    local close = math.abs(r1 - r2) <= 1 and math.abs(g1 - g2) <= 1 and math.abs(b1 - b2) <= 1
    check("round-trip " .. hex, close, "got " .. back)
  end
end

do
  -- pure red/green/blue should round-trip with hue preserved within 1 degree
  for _, hex in ipairs({ "#ff0000", "#00ff00", "#0000ff" }) do
    local lch1 = oklch.hex_to_oklch(hex)
    local back = oklch.oklch_to_hex(lch1)
    local lch2 = oklch.hex_to_oklch(back)
    local dh = math.abs(lch1.h - lch2.h)
    if dh > 180 then
      dh = 360 - dh
    end
    check("hue preserved " .. hex, dh < 1, "delta_h=" .. dh)
  end
end

do
  -- gamut clamp: an OKLCH with high chroma should still produce a valid 7-char hex
  local out = oklch.oklch_to_hex({ L = 0.7, c = 0.5, h = 30 })
  check(
    "gamut clamp produces valid hex",
    type(out) == "string" and #out == 7 and out:match("^#%x%x%x%x%x%x$") ~= nil,
    "got " .. tostring(out)
  )
end

do
  -- set_lightness preserves hue
  local lch1 = oklch.hex_to_oklch("#ff0000")
  local lighter = oklch.set_lightness("#ff0000", 0.8)
  local lch2 = oklch.hex_to_oklch(lighter)
  local dh = math.abs(lch1.h - lch2.h)
  if dh > 180 then
    dh = 360 - dh
  end
  check("set_lightness preserves hue", dh < 2, "delta_h=" .. dh)
  check("set_lightness changes L", approx(lch2.L, 0.8, 0.05), "got L=" .. lch2.L)
end

-- ---------- contrast ----------
print("\ncontrast:")
local contrast = require("termsink.colors.contrast")

do
  -- known WCAG ratios
  check(
    "wcag white on black ~= 21",
    approx(contrast.wcag_ratio("#ffffff", "#000000"), 21, 0.1),
    "got " .. contrast.wcag_ratio("#ffffff", "#000000")
  )
  check(
    "wcag identical = 1",
    approx(contrast.wcag_ratio("#808080", "#808080"), 1, 1e-9),
    "got " .. contrast.wcag_ratio("#808080", "#808080")
  )
end

do
  -- ensure_contrast lifts a low-contrast fg
  local low_fg = "#444444"
  local bg = "#222222"
  local ratio_before = contrast.wcag_ratio(low_fg, bg)
  local fixed, meets = contrast.ensure_contrast(low_fg, bg, 4.5)
  local ratio_after = contrast.wcag_ratio(fixed, bg)
  check(
    "ensure_contrast meets threshold on dark bg",
    meets,
    string.format("before=%.2f after=%.2f", ratio_before, ratio_after)
  )
  check("ensure_contrast no-op when already met", contrast.ensure_contrast("#ffffff", "#000000", 4.5) == "#ffffff")
end

do
  -- ensure_contrast preserves hue family
  local lch_before = oklch.hex_to_oklch("#aa3333")
  local fixed = contrast.ensure_contrast("#aa3333", "#222222", 7.0)
  local lch_after = oklch.hex_to_oklch(fixed)
  local dh = math.abs(lch_before.h - lch_after.h)
  if dh > 180 then
    dh = 360 - dh
  end
  check("ensure_contrast preserves hue", dh < 5, "delta_h=" .. dh)
end

do
  -- nudge_apart separates near-identical colors
  local a = "#3060a0"
  local b = "#3565a5"
  local dist_before = contrast.oklch_distance(a, b)
  local nudged, meets = contrast.nudge_apart(a, b, "#1a1a1a", 0.10, 3.0)
  local dist_after = contrast.oklch_distance(a, nudged)
  check("nudge_apart increases distance", meets, string.format("before=%.3f after=%.3f", dist_before, dist_after))
end

-- ---------- reader ----------
print("reader:")
local reader = require("termsink.colors.reader")

do
  local function detect(source, env)
    local s, reason = reader.detect_source(source, env)
    return tostring(s) .. " / " .. reason
  end
  local function expect(name, got, want)
    check(name, got == want, string.format("got %q, want %q", got, want))
  end

  expect(
    "detect: option wins over environment",
    detect("ghostty", { TERM_PROGRAM = "rex", REX_SESSION = "s" }),
    "ghostty / option"
  )
  expect(
    "detect: option passes an absolute path through",
    detect("/Applications/Ghostty.app/Contents/MacOS/ghostty", {}),
    "/Applications/Ghostty.app/Contents/MacOS/ghostty / option"
  )
  expect("detect: TERM_PROGRAM=rex", detect(nil, { TERM_PROGRAM = "rex" }), "rex / TERM_PROGRAM")
  expect("detect: TERM_PROGRAM is lowercased", detect(nil, { TERM_PROGRAM = "Ghostty" }), "ghostty / TERM_PROGRAM")
  expect(
    "detect: TERM_PROGRAM beats a stale REX_SESSION",
    detect(nil, { TERM_PROGRAM = "ghostty", REX_SESSION = "stale" }),
    "ghostty / TERM_PROGRAM"
  )
  expect(
    "detect: tmux + single marker uses the marker",
    detect(nil, { TERM_PROGRAM = "tmux", REX_SESSION = "s" }),
    "rex / marker REX_SESSION"
  )
  expect(
    "detect: unset TERM_PROGRAM + ghostty marker",
    detect(nil, { GHOSTTY_RESOURCES_DIR = "/x" }),
    "ghostty / marker GHOSTTY_RESOURCES_DIR"
  )
  expect(
    "detect: both markers are ambiguous",
    detect(nil, { TERM_PROGRAM = "tmux", REX_SESSION = "s", GHOSTTY_RESOURCES_DIR = "/x" }),
    "nil / auto"
  )
  expect("detect: unknown terminal falls to auto", detect(nil, { TERM_PROGRAM = "kitty" }), "nil / auto")
  expect("detect: empty values count as unset", detect("", { TERM_PROGRAM = "", REX_SESSION = "" }), "nil / auto")

  expect(
    "build_cmd: auto has no --source",
    table.concat(reader.build_cmd(nil), " "),
    "termcolors --format=json --color=hex"
  )
  expect(
    "build_cmd: source is one argv element",
    table.concat(reader.build_cmd("/a b/ghostty"), "|"),
    "termcolors|--format=json|--color=hex|--source=/a b/ghostty"
  )
end

do
  -- Build termcolors-shaped JSON. `false` in a slot encodes JSON null.
  local function json(palette, special, meta)
    local function enc(v)
      return v and ('"' .. v .. '"') or "null"
    end
    local slots = {}
    for i = 1, 16 do
      slots[i] = enc(palette[i])
    end
    local sp = {}
    for _, k in ipairs({
      "foreground",
      "background",
      "cursor",
      "cursor_text",
      "selection_background",
      "selection_foreground",
    }) do
      sp[#sp + 1] = string.format('"%s": %s', k, enc(special[k]))
    end
    return string.format(
      '{"palette": [%s], "special": {%s}, "meta": {"schema_version": 1, "source": "x", "theme": %s, "notice": %s}}',
      table.concat(slots, ","),
      table.concat(sp, ","),
      enc(meta and meta.theme),
      enc(meta and meta.notice)
    )
  end

  local full_palette = {}
  for i = 1, 16 do
    full_palette[i] = string.format("#0000%02X", i)
  end
  local full_special = {
    foreground = "#E6EDF3",
    background = "#0d1117",
    cursor = "#2f81f7",
    cursor_text = "#eff8ff",
    selection_background = "#111111",
    selection_foreground = "#222222",
  }

  local info, err, extra = reader.map_output(json(full_palette, full_special, { theme = "Merino Dark" }))
  check("map: full output parses", info ~= nil and err == nil, tostring(err))
  check("map: theme name", info.name == "Merino Dark", tostring(info.name))
  check(
    "map: palette is 1-based, lowercased",
    info.colors.palette[1] == "#000001" and info.colors.palette[16] == "#000010" and info.colors.palette[10] == "#00000a",
    vim.inspect(info.colors.palette)
  )
  check(
    "map: specials renamed",
    info.colors.background == "#0d1117"
      and info.colors.foreground == "#e6edf3"
      and info.colors.cursor_color == "#2f81f7"
      and info.colors.cursor_text == "#eff8ff"
      and info.colors.selection_bg == "#111111"
      and info.colors.selection_fg == "#222222",
    vim.inspect(info.colors)
  )
  check("map: full output is not all_null", extra.all_null == false)

  info, err, extra = reader.map_output(json(full_palette, {}, nil))
  check(
    "map: null specials and null theme are not errors",
    info ~= nil and info.name == nil and info.colors.background == nil and info.colors.selection_fg == nil,
    tostring(err)
  )
  check("map: palette-only is not all_null", extra.all_null == false)

  local holes = vim.deepcopy(full_palette)
  holes[1], holes[4], holes[16] = false, false, false
  info = reader.map_output(json(holes, full_special, nil))
  check(
    "map: null palette slots stay nil without shifting",
    info.colors.palette[1] == nil
      and info.colors.palette[4] == nil
      and info.colors.palette[16] == nil
      and info.colors.palette[2] == "#000002"
      and info.colors.palette[15] == "#00000f",
    vim.inspect(info.colors.palette)
  )

  info, err, extra = reader.map_output(json({}, {}, { notice = "no controlling tty" }))
  check("map: all-null flagged with notice", info ~= nil and extra.all_null and extra.notice == "no controlling tty")

  info, err = reader.map_output("{ not json")
  check("map: malformed JSON returns an error", info == nil and err:match("could not parse") ~= nil, tostring(err))
  info, err = reader.map_output('{"special": {}}')
  check("map: JSON without a palette returns an error", info == nil and err:match("no palette") ~= nil, tostring(err))
  info = reader.map_output(json({ "red", "#12345", "#1234567" }, { background = "rgb(0,0,0)" }, nil))
  check(
    "map: non-hex values are dropped",
    info.colors.palette[1] == nil and info.colors.palette[2] == nil and info.colors.background == nil
  )

  -- get_theme_info with a stubbed runner.
  local function get(env, source, result)
    local seen
    local theme, e = reader.get_theme_info({
      env = env,
      source = source,
      run = function(cmd)
        seen = cmd
        return vim.tbl_extend("keep", result, { stdout = "", stderr = "", timed_out = false, missing = false })
      end,
    })
    return theme, e, seen
  end

  local theme, e, cmd = get({ TERM_PROGRAM = "rex" }, nil, { code = 0, stdout = json(full_palette, full_special, nil) })
  check("get: success returns theme_info", theme ~= nil and e == nil and theme.colors.background == "#0d1117")
  check("get: detected source reaches argv", cmd[4] == "--source=rex", vim.inspect(cmd))
  check(
    "get: status on success",
    reader.status.outcome == "ok"
      and reader.status.source == "rex"
      and reader.status.reason == "TERM_PROGRAM"
      and reader.status.using_defaults == false,
    vim.inspect(reader.status)
  )

  theme, e = get({}, nil, { missing = true })
  check(
    "get: missing binary",
    theme == nil and e:match("not found on PATH") ~= nil and reader.status.binary_found == false,
    tostring(e)
  )

  theme, e = get({ TERM_PROGRAM = "rex" }, nil, { code = 124, timed_out = true })
  check("get: timeout", theme == nil and e:match("timed out after 1000 ms") ~= nil, tostring(e))

  theme, e = get({ TERM_PROGRAM = "ghostty" }, nil, { code = 4, stderr = "termcolors: 'ghostty' binary not found\n" })
  check(
    "get: non-zero exit includes code, stderr, and upgrade hint",
    theme == nil
      and e:match("code 4") ~= nil
      and e:match("'ghostty' binary not found") ~= nil
      and e:match("upgrading termcolors may help") ~= nil,
    tostring(e)
  )

  theme, e = get({}, nil, { code = 2, stderr = "boom" })
  check(
    "get: non-zero exit on auto has no upgrade hint",
    theme == nil and e:match("boom") ~= nil and e:match("upgrading") == nil,
    tostring(e)
  )

  theme, e = get({ TERM_PROGRAM = "rex" }, nil, { code = 0, stdout = "<html>" })
  check("get: unparseable output", theme == nil and e:match("could not parse") ~= nil, tostring(e))

  theme, e, cmd = get({ TERM_PROGRAM = "kitty" }, nil, { code = 0, stdout = json({}, {}, { notice = "no tty" }) })
  check(
    "get: all-null on auto is silent",
    theme == nil and e == nil and #cmd == 3 and reader.status.outcome == "no colors (silent)",
    tostring(e)
  )
  check("get: silent case still reports defaults in use", reader.status.using_defaults == true)

  theme, e = get({}, "rex", { code = 0, stdout = json({}, {}, { notice = "no theme" }) })
  check(
    "get: all-null from a named source is an error",
    theme == nil and e ~= nil and e:match("no colors for source 'rex'") ~= nil and e:match("no theme") ~= nil,
    tostring(e)
  )
end

-- ---------- summary ----------
print(string.format("\n%d passed, %d failed", passes, failures))
if failures > 0 then
  os.exit(1)
end

-- Terminal color reader.
-- Shells out to the `termcolors` CLI (JSON, hex) and maps its output to the
-- theme_info shape the rest of the colorscheme consumes. `termcolors` is the
-- only external command this plugin runs.

local M = {}

local BINARY = "termcolors"
local TIMEOUT_MS = 1000

-- termcolors emulator sources we can pick without being told.
local KNOWN_SOURCES = { rex = true, ghostty = true }

-- Fallback markers, consulted only when $TERM_PROGRAM names no known source
-- (e.g. inside tmux). These are inherited by child processes, so they can be
-- stale; $TERM_PROGRAM always wins over them.
local MARKERS = {
  { var = "GHOSTTY_RESOURCES_DIR", source = "ghostty" },
  { var = "REX_SESSION", source = "rex" },
}

-- JSON `special` key -> theme_info.colors key.
local SPECIALS = {
  background = "background",
  foreground = "foreground",
  cursor = "cursor_color",
  cursor_text = "cursor_text",
  selection_background = "selection_bg",
  selection_foreground = "selection_fg",
}

---Outcome of the most recent get_theme_info() call, for :checkhealth.
M.status = nil

local function env_get(env, name)
  local value = env[name]
  if value == nil or value == "" then
    return nil
  end
  return value
end

local function hex_or_nil(value)
  if type(value) == "string" and value:match("^#%x%x%x%x%x%x$") then
    return value:lower()
  end
  return nil
end

---Choose the termcolors source.
---@param source string|nil the user's `source` option
---@param env table environment lookup (vim.env or a plain table)
---@return string|nil source nil means plain `termcolors` (--source auto)
---@return string reason "option" | "TERM_PROGRAM" | "marker <VAR>" | "auto"
function M.detect_source(source, env)
  if source ~= nil and source ~= "" then
    return source, "option"
  end

  local term_program = env_get(env, "TERM_PROGRAM")
  if term_program and KNOWN_SOURCES[term_program:lower()] then
    return term_program:lower(), "TERM_PROGRAM"
  end

  local found
  for _, marker in ipairs(MARKERS) do
    if env_get(env, marker.var) then
      if found then
        return nil, "auto" -- more than one marker: ambiguous
      end
      found = marker
    end
  end
  if found then
    return found.source, "marker " .. found.var
  end

  return nil, "auto"
end

---@param source string|nil
---@return string[] argv
function M.build_cmd(source)
  local cmd = { BINARY, "--format=json", "--color=hex" }
  if source then
    cmd[#cmd + 1] = "--source=" .. source
  end
  return cmd
end

---Run the command without a shell, bounded by TIMEOUT_MS.
---@param cmd string[]
---@return { code: integer|nil, stdout: string, stderr: string, timed_out: boolean, missing: boolean }
function M.run(cmd)
  if vim.fn.executable(cmd[1]) == 0 then
    return { stdout = "", stderr = "", timed_out = false, missing = true }
  end
  local result = vim.system(cmd, { text = true, timeout = TIMEOUT_MS }):wait()
  return {
    code = result.code,
    stdout = result.stdout or "",
    stderr = result.stderr or "",
    -- vim.system reports a timeout as exit 124 plus the kill signal.
    timed_out = result.code == 124 and result.signal ~= 0,
    missing = false,
  }
end

---Map termcolors JSON (schema v1) to theme_info.
---@param json_text string
---@return table|nil theme_info palette[1..16] = ANSI 0..15; null slots stay nil
---@return string|nil err
---@return table|nil info { all_null: boolean, notice: string|nil }
function M.map_output(json_text)
  local ok, data = pcall(vim.json.decode, json_text, { luanil = { object = true, array = true } })
  if not ok then
    return nil, "could not parse termcolors output: " .. tostring(data)
  end
  if type(data) ~= "table" or type(data.palette) ~= "table" then
    return nil, "could not parse termcolors output: no palette in JSON"
  end

  local special = type(data.special) == "table" and data.special or {}
  local meta = type(data.meta) == "table" and data.meta or {}

  local colors = { palette = {} }
  local all_null = true

  -- Explicit indices: `#` and ipairs are unreliable on arrays with nil holes.
  for i = 1, 16 do
    local hex = hex_or_nil(data.palette[i])
    colors.palette[i] = hex
    all_null = all_null and hex == nil
  end
  for json_key, key in pairs(SPECIALS) do
    local hex = hex_or_nil(special[json_key])
    colors[key] = hex
    all_null = all_null and hex == nil
  end

  local theme_info = {
    name = type(meta.theme) == "string" and meta.theme or nil,
    colors = colors,
  }
  return theme_info, nil, { all_null = all_null, notice = type(meta.notice) == "string" and meta.notice or nil }
end

---Read the terminal's colors.
---@param deps table|nil test seams: { source, env, run }
---@return table|nil theme_info nil means "use the built-in defaults"
---@return string|nil err set for real failures (caller warns); nil with a nil
---  theme_info means there were simply no colors to read (stay silent)
function M.get_theme_info(deps)
  -- With no deps (production) the source option comes from setup().
  deps = deps or { source = require("termsink.util.config").settings.source }
  local env = deps.env or vim.env
  local run = deps.run or M.run
  local option = deps.source

  local source, reason = M.detect_source(option, env)
  local cmd = M.build_cmd(source)
  local status = {
    binary_found = true,
    source = source or "auto",
    reason = reason,
    cmd = cmd,
    outcome = nil,
    stderr = "",
    using_defaults = true,
  }
  M.status = status

  local function fail(outcome, message)
    status.outcome = outcome
    return nil, message
  end

  local result = run(cmd)
  status.stderr = vim.trim(result.stderr or "")
  local stderr_suffix = status.stderr ~= "" and (": " .. status.stderr) or ""

  if result.missing then
    status.binary_found = false
    return fail(
      "termcolors not found",
      "`termcolors` was not found on PATH (install: brew install jnschurig/termcolors/termcolors)"
    )
  end
  if result.timed_out then
    return fail("timed out", string.format("`termcolors` timed out after %d ms%s", TIMEOUT_MS, stderr_suffix))
  end
  if result.code ~= 0 then
    local message = string.format("`termcolors` exited with code %s%s", tostring(result.code), stderr_suffix)
    if source then
      message = message
        .. string.format(" (source '%s' via %s; upgrading termcolors may help)", source, reason)
    end
    return fail("exit code " .. tostring(result.code), message)
  end

  local theme_info, err, info = M.map_output(result.stdout)
  if not theme_info then
    return fail("unparseable output", err)
  end

  if info.all_null then
    if not source then
      status.outcome = "no colors (silent)"
      return nil, nil
    end
    local notice = info.notice and (": " .. info.notice) or stderr_suffix
    return fail(
      "no colors from source",
      string.format("`termcolors` returned no colors for source '%s' (via %s)%s", source, reason, notice)
    )
  end

  status.outcome = "ok"
  status.using_defaults = false
  return theme_info, nil
end

return M

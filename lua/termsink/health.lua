-- :checkhealth termsink

local M = {}

local INSTALL_HINT = "Install it with: brew install jnschurig/termcolors/termcolors"

local REASONS = {
  option = "set by the `source` option",
  TERM_PROGRAM = "detected from $TERM_PROGRAM",
  auto = "no source detected; termcolors decides (--source auto)",
}

local function describe_reason(reason)
  local marker = reason:match("^marker (.+)$")
  if marker then
    return "detected from the $" .. marker .. " marker variable"
  end
  return REASONS[reason] or reason
end

function M.check()
  local health = vim.health
  local reader = require("termsink.colors.reader")

  health.start("termsink: terminal colors")

  local path = vim.fn.exepath("termcolors")
  if path == "" then
    health.error("`termcolors` was not found on PATH", { INSTALL_HINT })
  else
    health.ok("`termcolors` found: " .. path)
  end

  -- Report the read the colorscheme actually did; if it has not been loaded
  -- in this session, do one now.
  local status = reader.status
  if status then
    health.info("Showing the read made when the colorscheme loaded")
  else
    reader.get_theme_info()
    status = reader.status
    health.info("Colorscheme not loaded in this session; ran the reader now")
  end

  health.info(string.format("Source: %s (%s)", status.source, describe_reason(status.reason)))
  health.info("Command: " .. table.concat(status.cmd, " "))

  if status.outcome == "ok" then
    health.ok("Colors read from the terminal")
  elseif status.outcome == "no colors (silent)" then
    health.warn("termcolors reported no colors for this terminal; using the built-in defaults", {
      "Set `source` in setup() to a termcolors source (e.g. 'rex', 'ghostty', or an absolute path)",
      "Or configure termcolors itself: $TERMCOLORS_TERMINAL or ~/.config/termcolors/config",
    })
  else
    local advice = {}
    if status.stderr ~= "" then
      advice[#advice + 1] = "termcolors stderr: " .. status.stderr
    end
    if not status.binary_found then
      advice[#advice + 1] = INSTALL_HINT
    elseif status.source ~= "auto" then
      advice[#advice + 1] = "Upgrading termcolors may help if this source is newer than your install"
    end
    health.error(string.format("Read failed (%s); using the built-in defaults", status.outcome), advice)
  end
end

return M

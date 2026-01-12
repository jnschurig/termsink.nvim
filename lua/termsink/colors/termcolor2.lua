local M = {}

local ESC = "\27"
local BEL = "\7"

-- tmux-safe OSC wrapper
local function osc(seq)
	if vim.env.TMUX then
		return ESC .. "Ptmux;" .. ESC .. seq .. ESC .. "\\"
	else
		return ESC .. seq
	end
end

-- rgb:RRRR/GGGG/BBBB → #RRGGBB
local function rgb16_to_hex(rgb)
	local r, g, b = rgb:match("rgb:([%x]+)/([%x]+)/([%x]+)")
	if not r then
		return nil
	end
	return string.format(
		"#%02x%02x%02x",
		tonumber(r:sub(1, 2), 16),
		tonumber(g:sub(1, 2), 16),
		tonumber(b:sub(1, 2), 16)
	)
end

local UI_OSC = {
	foreground = 10,
	background = 11,
	cursor_color = 12,
	selection_background = 17,
	cursor_text = 18,
	selection_foreground = 19,
}

function M.query_all()
	local result = { ui = {}, palette = {} }

	local pending_ui = vim.tbl_count(UI_OSC)
	local pending_palette = 16
	local buffer = ""
	local done = false

	local function finish()
		if done then
			return
		end
		done = true
		vim.on_key(nil, M)
	end

	vim.on_key(function(key)
		buffer = buffer .. key

		while true do
			local seq, rest = buffer:match("^(.-)\7(.*)")
			if not seq then
				break
			end
			buffer = rest

			-- UI colors
			local ui_code, ui_rgb = seq:match("%](%d+);(rgb:[^%]]+)")
			ui_code = tonumber(ui_code)

			if ui_code and ui_rgb then
				for name, code in pairs(UI_OSC) do
					if ui_code == code then
						result.ui[name] = rgb16_to_hex(ui_rgb)
						pending_ui = pending_ui - 1
						break
					end
				end
			end

			-- Palette
			local idx, pal_rgb = seq:match("%]4;(%d+);(rgb:[^%]]+)")
			idx = tonumber(idx)

			if idx and pal_rgb and idx < 16 and not result.palette[idx + 1] then
				result.palette[idx + 1] = rgb16_to_hex(pal_rgb)
				pending_palette = pending_palette - 1
			end

			if pending_ui <= 0 and pending_palette <= 0 then
				finish()
				return
			end
		end
	end, M)

	-- Emit queries
	for _, code in pairs(UI_OSC) do
		vim.api.nvim_chan_send(vim.v.stderr, osc("]" .. code .. ";?" .. BEL))
	end

	for i = 0, 15 do
		vim.api.nvim_chan_send(vim.v.stderr, osc("]4;" .. i .. ";?" .. BEL))
	end

	-- Wait up to 200ms
	vim.wait(200, function()
		return done
	end, 10)

	finish()
	return result
end

return M

local M = {}

local ESC = "\27"
local BEL = "\7"
local ST = ESC .. "\\"

-- tmux-safe OSC wrapper
local function osc(seq)
	if vim.env.TMUX then
		return ESC .. "Ptmux;" .. ESC .. seq .. ST
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

	local stdin = vim.loop.new_tty(0, true)

	local function finish()
		if done then
			return
		end
		done = true
		stdin:read_stop()
		stdin:close()
	end

	stdin:read_start(function(err, chunk)
		if err or not chunk then
			return
		end
		buffer = buffer .. chunk

		while true do
			local seq, rest = buffer:match("^(.-)\7(.*)") or buffer:match("^(.-)\27\\(.*)")
			if not seq then
				break
			end
			buffer = rest

			-- UI colors
			local code, rgb = seq:match("%](%d+);(rgb:[^%]]+)")
			code = tonumber(code)
			if code and rgb then
				for name, osc_code in pairs(UI_OSC) do
					if code == osc_code then
						result.ui[name] = rgb16_to_hex(rgb)
						pending_ui = pending_ui - 1
					end
				end
			end

			-- Palette
			local idx, pal = seq:match("%]4;(%d+);(rgb:[^%]]+)")
			idx = tonumber(idx)
			if idx and idx < 16 and not result.palette[idx + 1] then
				result.palette[idx + 1] = rgb16_to_hex(pal)
				pending_palette = pending_palette - 1
			end

			if pending_ui <= 0 and pending_palette <= 0 then
				finish()
				return
			end
		end
	end)

	-- Emit queries
	for _, code in pairs(UI_OSC) do
		vim.api.nvim_chan_send(vim.v.stdout, osc("]" .. code .. ";?" .. BEL))
	end

	for i = 0, 15 do
		vim.api.nvim_chan_send(vim.v.stdout, osc("]4;" .. i .. ";?" .. BEL))
	end

	vim.wait(300, function()
		return done
	end, 10)
	finish()

	return result
end

return M

local M = {}

local ESC = "\27"
local BEL = "\7"

local function osc(seq)
	if vim.env.TMUX then
		return ESC .. "Ptmux;" .. ESC .. seq .. ESC .. "\\"
	else
		return ESC .. seq
	end
end

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

--- Query ANSI palette colors
--- @param count number: usually 16 or 256
--- @param callback fun(colors: string[]|nil)
function M.query_palette(count, callback)
	count = count or 16
	local results = {}
	local pending = count
	local buffer = ""

	local done = false
	local function finish()
		if done then
			return
		end
		done = true
		vim.on_key(nil, M)

		if #results == count then
			callback(results)
		else
			callback(nil)
		end
	end

	vim.on_key(function(key)
		buffer = buffer .. key

		while true do
			local osc_reply = buffer:match("%]4;(%d+);(rgb:[^\7]+)\7")
			if not osc_reply then
				break
			end

			local idx, rgb = buffer:match("%]4;(%d+);(rgb:[^\7]+)\7")
			idx = tonumber(idx) + 1 -- Lua arrays are 1-based
			results[idx] = rgb16_to_hex(rgb)

			buffer = buffer:gsub("%]4;%d+;rgb:[^\7]+\7", "", 1)
			pending = pending - 1

			if pending == 0 then
				finish()
				return
			end
		end
	end, M)

	-- Send queries
	for i = 0, count - 1 do
		vim.api.nvim_chan_send(vim.v.stderr, osc("]4;" .. i .. ";?" .. BEL))
	end

	-- Timeout safeguard
	vim.defer_fn(finish, count == 256 and 300 or 100)
end

return M

local M = {}

local function rgb16_to_hex(rgb)
	-- rgb:RRRR/GGGG/BBBB → #RRGGBB
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

local function parse_helper_output(text)
	local result = {
		ui = {},
		palette = {},
	}

	for line in text:gmatch("[^\r\n]+") do
		local key, rgb = line:match("^([^=]+)=(rgb:[%x/]+)$")
		if key and rgb then
			local hex = rgb16_to_hex(rgb)
			if hex then
				local ui_name = key:match("^ui%.(.+)$")
				if ui_name then
					result.ui[ui_name] = hex
				else
					local idx = key:match("^palette%.(%d+)$")
					if idx then
						result.palette[tonumber(idx) + 1] = hex
					end
				end
			end
		end
	end

	return result
end

function M.query_all()
	local output = vim.fn.system("termcolor_helper.sh")

	if vim.v.shell_error ~= 0 or not output or output == "" then
		return { ui = {}, palette = {} }
	end

	return parse_helper_output(output)
end

return M

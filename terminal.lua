digipad.keyb_formspec =
"size[4,1;]"..
"field[0,1;5,1;input;Input;]"

digipad.terminal_formspec =
"size[4,5;]"..
"field[0,5;5,1;input;;]"

help_text = "Commands preceded with a / go to the terminal. All others are sent along the digiline."
digipad.help = function(pos)
	digipad.new_line(pos, "Commands preceded with a / go to the")
	digipad.new_line(pos, "terminal. All others are sent along the digiline.")
	digipad.new_line(pos, "Commands are:   /clear   /help")
end
--~ terminal_cmds = {
--~ 	
--~ }

digipad.parse_cmd = function(pos, cmd)
	local meta = minetest.env:get_meta(pos)
	if cmd == "clear" then
		print("clearing screen")
		meta:set_string("formspec", digipad.terminal_formspec) -- reset to default formspec
		meta:set_int("lines", 0)  -- start at the top of the screen again
	elseif cmd == "help" then
		digipad.help(pos)
	end
	
end

local on_digiline_receive = function (pos, node, channel, msg)
	digipad.new_line(pos, msg)
end

 digipad.new_line = function(pos, text)
	local max_chars = 40
	local meta = minetest.env:get_meta(pos)
	local formspec = meta:get_string("formspec")
	local lines = meta:get_int("lines")
	local offset = lines / 4
	
	line = string.sub(text, 1, max_chars) -- take first chars
	local new_formspec = formspec .. "label[0," .. offset .. ";" .. line .. "]"
	meta:set_string("formspec", new_formspec)
	lines = lines + 1
	meta:set_int("lines", lines)
	meta:set_string("formspec", new_formspec)
	if string.len(text) > max_chars then -- If not all could be printed, recurse
		text = string.sub(text,max_chars)
		digipad.new_line(pos, text)
	end
	
end

minetest.register_node("digipad:keyb", {
	description = "Digiline keyboard",
	walkable = true,
	digiline = 
		{
			receptor={},
			effector={},
		},
		groups = {dig_immediate = 2},
		on_construct = function(pos)
			local meta = minetest.env:get_meta(pos)
			meta:set_string("formspec", digipad.keyb_formspec)
			
		end,
		on_receive_fields = function(pos, formname, fields, sender)
			local channel = "tty1"
			local text = fields.input
			if text ~= nil then
				digiline:receptor_send(pos, digiline.rules.default, channel, text)
			end
		end,
})

minetest.register_node("digipad:terminal", {
	description = "Text entry terminal",
	walkable = true,
	digiline = 
		{
			receptor={},
			effector = {
				action = on_digiline_receive
			},
		},
		groups = {dig_immediate = 2},
		on_construct = function(pos)
			local meta = minetest.env:get_meta(pos)
			meta:set_string("formspec", digipad.terminal_formspec)
			meta:set_int("lines", 0)
			digipad.new_line(pos, "/help for help")
		end,
		on_receive_fields = function(pos, formname, fields, sender)
			local meta = minetest.env:get_meta(pos)
			local text = fields.input
			digipad.new_line(pos, "> " .. text)
			local channel = "tty1"
			if string.sub(text,1,1) == "/" then  -- command is for terminal
				text = string.sub(text, 2) -- cut off first char
				digipad.parse_cmd(pos, text)
			elseif text ~= nil then
				digiline:receptor_send(pos, digiline.rules.default, channel, text)
			end
			local formspec = meta:get_string("formspec")
			minetest.show_formspec("singleplayer", "terminal", formspec)
		end,
})
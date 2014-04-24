-- ================
-- Variable declarations
-- ================

digipad.keyb_form_first = 
"size[4,1;]"..
"field[0,0;2,1;chan;Channel;]"..
"label[0,0;Channel "

digipad.keyb_form_second =
 "]"..
"field[0,1;5,1;input;Input;]"

digipad.keyb_formspec = digipad.keyb_form_first .. "keyb1" .. digipad.keyb_form_second

digipad.terminal_formspec =
"size[4,5;]"..
"field[0,5;5,1;input;;]"

digipad.keyb_base_chan = "keyb"
digipad.keyb_def_chan = 1
digipad.term_base_chan = "tty"
digipad.term_def_chan = "1"

-- ================
-- Function declarations
-- ================
digipad.get_keyb_formspec = function(pos)  -- Construct updated formspec for keyboard
local meta = minetest.env:get_meta(pos)
local current_chan = meta:get_string("chan_num")
new_formspec = "size[4,1;]"..
"field[0,0;2,1;chan;Channel;" .. current_chan .. "]"..
"label[0,0;Channel " ..  digipad.keyb_base_chan .. current_chan .. "]"..
"field[0,1;5,1;input;Input;]"
return new_formspec
end

digipad.set_channel = function(pos, new_channel)
local meta = minetest.env:get_meta(pos)
meta:set_string("channel", new_channel)
end

digipad.help = function(pos)  -- print help text
	digipad.new_line(pos, "Commands preceded with a / go to the")
	digipad.new_line(pos, "terminal. All others are sent along the digiline.")
	digipad.new_line(pos, "Commands are:   /clear  /help  /channel")
end

digipad.parse_cmd = function(pos, cmd)	
	if cmd == "clear" then
		digipad.clear(pos)
	elseif cmd == "help" then
		digipad.help(pos)
	elseif string.sub(cmd, 1, 7) == "channel" then -- If cmd _starts_with_ "channel", since we need an argument too.
		raw_arg = string.sub(cmd, 8) -- Cut "channel" out
		print ("Start " .. "'" .. raw_arg .. "'")
		while string.sub(raw_arg, 1,1) == " " do -- While first character is a space,
			raw_arg = string.sub(raw_arg, 2) -- cut that first char
		end --WORKS
		print ("Mid " .. "'" .. raw_arg .. "'")
		while string.sub(raw_arg, -1,-1) == " " do -- While last character is a space,
			raw_arg = string.sub(raw_arg, 1, -2) -- cut that last char
		end  --DOESN'T WORK
		print ("End " .. "'" .. raw_arg .. "'")
		print(raw_arg)
		if (raw_arg ~= nil) and (raw_arg ~= "") then
			arg = raw_arg -- sanitized output (hopefully)
			digipad.set_channel(pos, digipad.term_base_chan .. arg)
			digipad.new_line(pos, "Channel set to " .. digipad.term_base_chan .. arg)
		else -- no argument
			digipad.new_line(pos, "Example: ''/channel 2'' will change")
			digipad.new_line(pos, "channel to ''tty2'' ")
		end
		
	else
		digipad.new_line(pos, cmd .. ": command not found")
	end
end

digipad.clear = function(pos)
	local meta = minetest.env:get_meta(pos)
	print("clearing screen")
	meta:set_string("formspec", digipad.terminal_formspec) -- reset to default formspec
	meta:set_int("lines", 0)  -- start at the top of the screen again
end

local on_digiline_receive = function (pos, node, channel, msg)
	digipad.new_line(pos, msg)
end

 digipad.new_line = function(pos, text)
	local max_chars = 40
	local max_lines = 10
	local meta = minetest.env:get_meta(pos)
	local formspec = meta:get_string("formspec")
	local lines = meta:get_int("lines")
	local offset = lines / 4
	
	if lines > max_lines then  -- clear screen before printing the line - so it's never blank
		digipad.clear(pos)
	end
	
	line = string.sub(text, 1, max_chars) -- take first chars
	local new_formspec = formspec .. "label[0," .. offset .. ";" .. line .. "]"
	meta:set_string("formspec", new_formspec)
	lines = lines + 1
	meta:set_int("lines", lines)
	meta:set_string("formspec", new_formspec)
	
	if string.len(text) > max_chars then -- If not all could be printed, recurse on the rest of the string
		text = string.sub(text,max_chars)
		digipad.new_line(pos, text)
	end

end

-- ================
-- Node declarations
-- ================
 
minetest.register_node("digipad:keyb", {
	description = "Digiline keyboard",
	paramtype = "light",
	paramtype2 = "facedir",
	sunlight_propagates = true,
	walkable = true,
	digiline = 
		{
			receptor={},
			effector={},
		},
	tiles = {
		"keyb.png",
		"digicode_side.png",
		"digicode_side.png",
		"digicode_side.png",
		"digicode_side.png",
		"digicode_side.png"
	},
	
	drawtype = "nodebox",
	selection_box = {
		type ="fixed",
		fixed = {-0.500000,-0.500000,-0.000000,0.500000,-0.3,0.5}, -- Keyboard
	
	},
	node_box = {
		type ="fixed",
		fixed = {-0.500000,-0.500000,-0.000000,0.500000,-0.3,0.5}, -- Keyboard
	
	},
	groups = {dig_immediate = 2},
	on_construct = function(pos)
		local meta = minetest.env:get_meta(pos)
		meta:set_string("formspec", digipad.keyb_formspec)
		meta:set_string("Infotext", "Keyboard")
		meta:set_int("chan_num", digipad.keyb_def_chan)
		 -- set default channel (base + default extension) :
		meta:set_string("channel", digipad.keyb_base_chan .. digipad.keyb_def_chan)
	end,
	on_receive_fields = function(pos, formname, fields, sender)
		local meta = minetest.env:get_meta(pos)
		local channel = meta:get_string("channel")
		local text = fields.input
		if (fields.chan ~= "") and (fields.chan ~= nil) then 
			local chan_num = fields.chan
			meta:set_string("chan_num", chan_num) -- save user's channel choice
			channel = digipad.keyb_base_chan .. chan_num
			meta:set_string("channel", channel)
		end
		if text ~= nil then
			digiline:receptor_send(pos, digiline.rules.default, channel, text)
		end
		
		meta:set_string("formspec", digipad.get_keyb_formspec(pos))-- generate new formspec
	end,
	
})

minetest.register_node("digipad:terminal", {
	description = "Interactive Terminal",
	paramtype = "light",
	paramtype2 = "facedir",
	sunlight_propagates = true,
	walkable = true,
	drawtype = "nodebox",
	selection_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.5, 0.5, -0.3, 0}, -- Keyboard
			{-0.5, -0.5, 0, 0.5, 0.5, 0.5}, --Screen
		}
	},
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.5, 0.5, -0.3, 0}, -- Keyboard
			{-0.5, -0.5, 0, 0.5, 0.5, 0.5}, --Screen
		}
	},
	tiles = {
		"terminal_top.png",
		"digicode_side.png",
		"digicode_side.png",
		"digicode_side.png",
		"digicode_side.png",
		"terminal_front.png"
	},
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
		meta:set_string("Infotext", "Terminal")
		meta:set_int("lines", 0)
		-- set default channel (base + default extension) :
		meta:set_string("channel", digipad.term_base_chan .. digipad.term_def_chan)
		
		digipad.new_line(pos, "/help for help")  -- print welcome text
	end,
	on_receive_fields = function(pos, formname, fields, sender)
		local meta = minetest.env:get_meta(pos)
		local text = fields.input
		local channel = meta:get_string("channel")
		print(channel)
		if text ~= nil then
			digipad.new_line(pos, "> " .. text)
			
			if string.sub(text,1,1) == "/" then  -- command is for terminal
				text = string.sub(text, 2) -- cut off first char
				digipad.parse_cmd(pos, text)
			else
				digiline:receptor_send(pos, digiline.rules.default, channel, text)
			end
		end
		local formspec = meta:get_string("formspec")
		--minetest.show_formspec("singleplayer", "terminal", formspec)  doesn't allow submit anyway
	end,
})

-- ================
--Crafting recipes
-- ================

minetest.register_craft({
	output = "digipad:keyb",
	recipe = {
		{"mesecons_button:button_off", "mesecons_button:button_off", "mesecons_button:button_off"},
		{"mesecons_button:button_off", "mesecons_button:button_off", "mesecons_button:button_off"},
		{"default:steel_ingot", "digilines:wire_std_00000000", "default:steel_ingot"}
	}
})

minetest.register_craft({
	output = "digipad:terminal",
	recipe = {
		{"", "digilines_lcd:lcd", "default:steel_ingot"},
		{"digipad:keyb", "mesecons_luacontroller:luacontroller0000", "default:steel_ingot"},
		{"default:steel_ingot", "digilines:wire_std_00000000", "default:steel_ingot"}
	}
})
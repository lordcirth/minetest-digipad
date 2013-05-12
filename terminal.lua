digipad.terminal_formspec =
"size[4,1;]"..
"field[0,1;4,1;input;Input;]"

minetest.register_node("digipad:terminal", {
	description = "Text entry terminal",
	walkable = true,
	digiline = 
		{
			receptor={},
			effector={},
		},
		groups = {dig_immediate = 2},
		on_construct = function(pos)
			local meta = minetest.env:get_meta(pos)
			meta:set_string("formspec", digipad.terminal_formspec)
		end,
		on_receive_fields = function(pos, formname, fields, sender)
			local text = fields.input
			local channel = "tty1"
			digiline:receptor_send(pos, digiline.rules.default, channel, text)
		end,
		

})
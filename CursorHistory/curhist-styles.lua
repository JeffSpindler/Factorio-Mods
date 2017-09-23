local default_gui = data.raw["gui-style"].default
default_gui.curhist_sprite_act_style = 
{
	type="button_style",
	parent="button_style",
	top_padding = 0,
	right_padding = 0,
	bottom_padding = 0,
	left_padding = 0,
	height = 32,
	width = 32,
	scalable = false
}


default_gui.curhist_sprite_highlight_style = 
{
	type="button_style",
	parent="button_style",
	top_padding = 0,
	right_padding = 0,
	bottom_padding = 0,
	left_padding = 0,
	height = 48,
	width = 48,
	scalable = false,
	default_background =
	{
	filename = "__CursorHistory__/graphics/highlight",
	width=64,
	height=64
	}
}

default_gui.curhist_sprite_nert_style = 
{
	type="image_style",
	top_padding = 0,
	right_padding = 0,
	bottom_padding = 0,
	left_padding = 0,
	height = 8,
	width = 48,
	scalable = false
}

data:extend(
{
	{
	type = "sprite",
	name = "curhist_toggle_sprite",
	filename = "__CursorHistory__/graphics/scroll.png",
	width = 64,
	height = 64
}
})

data:extend(
{
	{
	type = "sprite",
	name = "curhist_nert_sprite",
	filename = "__CursorHistory__/graphics/highlight.png",
	width = 48,
	height = 8
}
})
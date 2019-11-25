local default_gui = data.raw["gui-style"].default

default_gui.sprite_obj_marc_style = 
{
	type="button_style",
	parent="train_schedule_item_select_button",
	disabled_graphical_set =
	{
		base = {border = 4, position = {2, 738}, size = 76},
		shadow =
		{
			position = {382, 107},
			corner_size = 12,
			top_outer_border_shift = 4,
			bottom_outer_border_shift = -4,
			left_outer_border_shift = 4,
			right_outer_border_shift = -4,
			draw_type = "outer"
		}
	}
}

default_gui.marcalc_button_style = 
{
	type="button_style",
	-- parent="button_style",
	top_padding = 0,
	right_padding = 0,
	bottom_padding = 0,
	left_padding = 0,
	height = 40,
	width = 40,
	scalable = false
}

default_gui.table_marc_style =
{
	type = "table_style",
	horizontal_spacing = 5,
	vertical_spacing = 1,
	resize_row_to_width = false,
	resize_to_row_height = false,
}

default_gui.scroll_pane_marc_style =
{
	type = "scroll_pane_style",
	parent="scroll_pane_light",
	-- flow_style =
	-- {
	-- 	type = "flow_style",
	-- 	parent = "flow_style"
	-- },
	resize_row_to_width = true,
	resize_to_row_height = false,
	minimal_height=128,
	maximal_height=400,
	max_on_row = 1,
	right_margin = 4
}

data:extend(
{
	{
		type = "sprite",
		name = "sprite_marc_calculator",
		filename = "__MaxRateCalculator__/graphics/calculator-x32.png",
		size = 32,
		mipmap_count = 2,
		flags = {"icon"}
	}
})
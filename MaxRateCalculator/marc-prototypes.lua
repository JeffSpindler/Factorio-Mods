-- Max Rate Calculator mod for Factorio
--
-- This mod provides a tool for calculating the throughput rate of machines
--
-- The tool is a selection tool - drag it over some machines and it calculates
-- the maximum rate those macines could consume and produce items, given the
-- modules in the machine, machine rate, beacon effects
--
-- the max-rate-calculator selection tool is automatically created when the user
-- invokes the hot key, and is destroyed when they finish selecting the area to
-- be analyzed.   The tool is not craftable, and requires no research.

data:extend(
{
	{
		type = "selection-tool",
		name = "max-rate-calculator",
		show_in_library = false,
		icon = "__MaxRateCalculator__/graphics/max-rate-calculator32.png",
		flags = { "only-in-cursor"},
		subgroup = "tool",
		order = "c[automated-construction]-b[tree-deconstructor]",
		stack_size = 1,
		icon_size = 32,
		selection_color = { r = 0.6, g = 0.6, b = 0 },
		alt_selection_color = { r = 0, g = 0, b = 1 },
		selection_mode = {"blueprint", "buildable-type"},
		alt_selection_mode = {"blueprint", "buildable-type"},
		selection_cursor_box_type = "entity",
		alt_selection_cursor_box_type = "not-allowed",
	}

	,
	select = {
	      border_color = { r = 1, g = 1 },
	      mode = { "buildable-type", "friend" },
	      cursor_box_type = "entity",
	      entity_type_filters = type_filters,
	    },
	    alt_select = {
	      border_color = { r = 1, g = 0.5 },
	      mode = { "buildable-type", "friend" },
	      cursor_box_type = "entity",
	      entity_type_filters = type_filters,
	    },
	    reverse_select = {
	      border_color = { r = 1 },
	      mode = { "buildable-type", "friend" },
	      cursor_box_type = "not-allowed",
	      entity_type_filters = type_filters,
	    },
	    alt_reverse_select = {
	      border_color = { r = 1 },
	      mode = { "buildable-type", "friend" },
	      cursor_box_type = "not-allowed",
	      entity_type_filters = type_filters,
	    },
	    stack_size = 1,
	    flags = { "only-in-cursor", "not-stackable", "spawnable" },
    hidden = true,
	
	

    }

})


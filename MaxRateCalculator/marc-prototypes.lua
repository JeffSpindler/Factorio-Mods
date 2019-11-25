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

local function shortcut_icon(name, size)
	return {
		filename = "__MaxRateCalculator__/graphics/"..name,
		priority = "extra-high-no-scale",
		size = size,
		scale = 1,
		mipmap_count = 2,
		flags = {"icon"}
	}
end

data:extend(
{
	{
		type = "selection-tool",
		name = "max-rate-calculator",
		show_in_library = false,
		icons =
		{
			{icon='__MaxRateCalculator__/graphics/black.png', icon_size=1, scale=64},
			{icon='__MaxRateCalculator__/graphics/max-rate-calculator-x32-white.png', icon_size=32, mipmap_count=2}
		},
		flags = {"hidden", "only-in-cursor"},
		subgroup = "tool",
		order = "c[automated-construction]-b[tree-deconstructor]",
		stack_size = 1,
		stackable = false,
		icon_size = 32,
		selection_color = { r = 0.6, g = 0.6, b = 0 },
		alt_selection_color = { r = 0, g = 0, b = 1 },
		selection_mode = {"blueprint", "buildable-type"},
		alt_selection_mode = {"blueprint", "buildable-type"},
		selection_cursor_box_type = "entity",
		alt_selection_cursor_box_type = "not-allowed",
	}

	,
	{
		type = "shortcut",
		name = "max-rate-shortcut",
		order = "b[blueprints]-h[max-rate-calc]",
		action = "lua",
		associated_control_input = "marc_hotkey",
		toggleable = false,
		icon = shortcut_icon('max-rate-calculator-x32.png', 32),
		disabled_icon = shortcut_icon('max-rate-calculator-x32-white.png', 32),
		small_icon = shortcut_icon('max-rate-calculator-x24.png', 24),
		disabled_small_icon = shortcut_icon('max-rate-calculator-x24-white.png', 24)
    }
	,
	{
		type = "shortcut",
		name = "marc_calc_4func",
		order = "b[blueprints]-h[max-rate-calc]",
		action = "lua",
		toggleable = true,
		icon = shortcut_icon('calculator-x32.png', 32),
		disabled_icon = shortcut_icon('calculator-x32-white.png', 32),
		small_icon = shortcut_icon('calculator-x24.png', 24),
		disabled_small_icon = shortcut_icon('calculator-x24-white.png', 24)
    }

})

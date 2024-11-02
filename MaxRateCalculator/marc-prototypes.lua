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
    icons = {
      { icon = "__MaxRateCalculator__/graphics/max-rate-calculator32.png", icon_size = 32, mipmap_count = 2 },
    },
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
    },
    
        {
    type = "shortcut",
    name = "max-rate-shortcut",
    order = "d[tools]-r[max-rate-calculator]",
    icon = "__MaxRateCalculator__/graphics/max-rate-calculator32.png",
    small_icon = "__MaxRateCalculator__/graphics/max-rate-calculator24.png",
    icon_size = 32,
    small_icon_size = 24,
    action = "lua",
    associated_control_input = "max-rate-shortcut",
   }
}
)


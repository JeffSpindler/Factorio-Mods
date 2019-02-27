-- Powered Floor mod for Factorio
--
-- This mod adds tiles which provide power to whatever's sitting on top of them.
--
-- There's 3 items which the user gets to play with:
--
--   powered-floor-tile         provides power to objects on top of the tile.  
--                              Also transmits power to adjacent powered-floor-* things 
--                              (via powered-floor-widget, see below).

--   powered-floor-circuit-tile Provides power to objects on top of the tile  
--                              Also transmits power to adjacent powered-floor-* things
--                              and transmits red and green circuit signals to 
--                              adjacent powered-floor-circuit-tiles and powered-floor-taps 
--                              (via powered-floor-circuit-widget, see below)

--   powered-floor-tap          Not a tile, more like a very small electric-pole, 
--                              that also transmits red and green circuit signals to 
--                              adjacent powered-floor-circuit-tiles and powered-floor-taps
--
-- Some hidden entities that are used in this mod.  These are placed when a powered-floor-*tile is built.  
-- They actually have the wiring.
--
--   powered-floor-widget        electric-pole type
--   powered-floor-circuit-widget Same as powered-floor-widget, handled differently in control.lua



--
-- item
-- 


data:extend({

{
    type = "item",
    name = "powered-floor-widget",
    icon = "__PoweredFloor__/graphic/powered-floor-icon.png",
    icon_size = 32,
    flags = {"hidden"},
    subgroup = "energy-pipe-distribution",
    order = "a[energy]-b[medium-electric-pole]",
    place_result = "powered-floor-widget",
    stack_size = 50
},

{
    type = "item",
    name = "powered-floor-circuit-widget",
    icon = "__PoweredFloor__/graphic/powered-floor-icon.png",
    icon_size = 32,
    flags = {"hidden"},
    subgroup = "energy-pipe-distribution",
    order = "a[energy]-b[medium-electric-pole]",
    place_result = "powered-floor-circuit-widget",
    stack_size = 50
},

{
    type = "item",
    name = "powered-floor-tap",
    icon = "__PoweredFloor__/graphic/powered-floor-tap.png",
    icon_size = 32,
    subgroup = "energy-pipe-distribution",
    order = "a[energy]-p2[powered-floor-tap]",
    place_result = "powered-floor-tap",
    stack_size = 50
  },

{
    type = "item",
    name = "powered-floor-tile",
    icon = "__PoweredFloor__/graphic/powered-floor-icon.png",
    icon_size = 32,
    subgroup = "energy-pipe-distribution",
    order = "a[energy]-p1[powered-floor-tile]",
    stack_size = 50,
    place_as_tile =
         {
          result = "powered-floor-tile",
          condition_size = 4,
          condition = { "water-tile" }
         }
},

{
    type = "item",
    name = "powered-floor-circuit-tile",
    icon = "__PoweredFloor__/graphic/powered-floor-circuit-icon.png",
    icon_size = 32,
    subgroup = "energy-pipe-distribution",
    order = "a[energy]-p3[powered-floor-circuit-tile]",
    stack_size = 50,
    place_as_tile =
         {
          result = "powered-floor-circuit-tile",
          condition_size = 4,
          condition = { "water-tile" }
         }
},

--
-- recipe
-- 
{
    type = "recipe",
    name = "powered-floor-tile",
    enabled = "false",
    ingredients =
    {
      {"steel-plate", 1},
      {"plastic-bar", 4},
      {"copper-cable", 2},
      {"electronic-circuit", 2}
    },
    result = "powered-floor-tile"
},

{
    type = "recipe",
    name = "powered-floor-tap",
    enabled = "false",
    ingredients =
    {
      {"steel-plate", 2},
      {"plastic-bar", 4},
      {"copper-cable", 6},
      {"electronic-circuit", 6}
    },
    result = "powered-floor-tap"
},

{
    type = "recipe",
    name = "powered-floor-circuit-tile",
    enabled = "false",
    ingredients =
    {
      {"steel-plate", 1},
      {"plastic-bar", 4},
      {"copper-cable", 2},
      {"red-wire", 2},
      {"green-wire", 2},
      {"advanced-circuit", 2}
    },
    result = "powered-floor-circuit-tile"
},

--
-- entity
-- 

{
    type = "electric-pole",
    name = "powered-floor-widget",
    zorkmid = "goodbye",
    icon = "__PoweredFloor__/graphic/powered-floor-icon.png",
    icon_size = 32,
    flags = {"placeable-neutral", "player-creation"},
    minable = {hardness = 0.2, mining_time = 0.5, result = "powered-floor-widget"},
    max_health = 120,
    corpse = "small-remnants",
    draw_copper_wires = false,
    resistances =
    {
      {
        type = "fire",
        percent = 100
      }
    },
    collision_mask = {"ground-tile"},
    collision_box = {{-0.15, -0.15}, {0.15, 0.15}},  -- collision mask affects effect radius somehow
    walking_speed_modifier = 2.0,
    -- selection_box = {{-0.5, -0.5}, {0.5, 0.5}},   -- selection box makes it a mineable entity rather than mineable tire
    drawing_box = {{0,0}, {0,0}},
    maximum_wire_distance = 1,
    max_circuit_wire_distance = 1,
    supply_area_distance = 0.5,
    vehicle_impact_sound =  { filename = "__base__/sound/car-metal-impact.ogg", volume = 0.65 },
    pictures =
    {
      filename = "__PoweredFloor__/graphic/powered-floor.png",
      priority = "low",
      width = 32,
      height = 32,
      
      axially_symmetrical = true,
      direction_count = 1,
      shift = {0, 0}
    },
    render_layer="floor",
    connection_points =
    {
      {
        shadow =  {  copper = {0, 0}  },
        wire =    {  copper = {0, 0}  }
      }
    },
    radius_visualisation_picture =
    {
      filename = "__base__/graphics/entity/small-electric-pole/electric-pole-radius-visualization.png",
      width = 12,
      height = 12
    }
 },


{
    type = "electric-pole",
    name = "powered-floor-circuit-widget",
    zorkmid = "goodbye",
    icon = "__PoweredFloor__/graphic/powered-floor-icon.png",
    icon_size = 32,
    flags = {"placeable-neutral", "player-creation"},
    minable = {hardness = 0.2, mining_time = 0.5, result = "powered-floor-circuit-widget"},
    max_health = 120,
    corpse = "small-remnants",
    draw_copper_wires = false,
    draw_circuit_wires = false,
    resistances =
    {
      {
        type = "fire",
        percent = 100
      }
    },
    collision_mask = {"ground-tile"},
    collision_box = {{-0.15, -0.15}, {0.15, 0.15}},  -- collision mask affects effect radius somehow
    walking_speed_modifier = 2.0,
    -- selection_box = {{-0.5, -0.5}, {0.5, 0.5}},   -- selection box makes it a mineable entity rather than mineable tire
    drawing_box = {{0,0}, {0,0}},
    maximum_wire_distance = 1,
    max_circuit_wire_distance = 1,
    supply_area_distance = 0.5,
    vehicle_impact_sound =  { filename = "__base__/sound/car-metal-impact.ogg", volume = 0.65 },
    pictures =
    {
      filename = "__PoweredFloor__/graphic/powered-floor.png",
      priority = "low",
      width = 32,
      height = 32,
      
      axially_symmetrical = true,
      direction_count = 1,
      shift = {0, 0}
    },
    render_layer="floor",
    connection_points =
    {
      {
        shadow =  {  copper = {0, 0}  },
        wire =    {  copper = {0, 0}  }
      }
    },
    radius_visualisation_picture =
    {
      filename = "__base__/graphics/entity/small-electric-pole/electric-pole-radius-visualization.png",
      width = 12,
      height = 12
    }
 },


{   
      type = "tile",
      name = "powered-floor-tile",
      needs_correction = false,
      minable = {hardness = 0.2, mining_time = 0.5, result = "powered-floor-tile"},
      mined_sound = { filename = "__base__/sound/deconstruct-bricks.ogg" },
      collision_mask = {"ground-tile"},
      walking_speed_modifier = 1.7,
      layer = 61,
      decorative_removal_probability = 0.9,
      variants =
      {
        main =
        {
          {
             picture = "__PoweredFloor__/graphic/powered-floor-tile1.png",
            count = 16,
            size = 1
          },
          {
            picture = "__PoweredFloor__/graphic/powered-floor-tile2.png",
            count = 4,
            size = 2,
            probability = 0.08,
          },
          {
            picture = "__PoweredFloor__/graphic/powered-floor-tile4.png",
            count = 4,
            size = 4,
            probability = .10,  
          },  
        },
        inner_corner =
        {
          picture = "__PoweredFloor__/graphic/powered-floor-no-edges.png",
          count = 1
        },
        outer_corner =
        {
          picture = "__PoweredFloor__/graphic/powered-floor-no-edges.png",
          count = 1
        },
        side =
        {
          picture = "__PoweredFloor__/graphic/powered-floor-no-edges.png",
          count = 1
        },
        u_transition =
        {
          picture = "__PoweredFloor__/graphic/powered-floor-no-edges.png",
          count = 1
        },
        o_transition =
        {
          picture = "__PoweredFloor__/graphic/powered-floor-no-edges.png",
          count = 1
        }
      },
      walking_sound =
      {
        {
          filename = "__base__/sound/walking/concrete-01.ogg",
          volume = 1.2
        },
        {
          filename = "__base__/sound/walking/concrete-02.ogg",
          volume = 1.2
        },
        {
          filename = "__base__/sound/walking/concrete-03.ogg",
          volume = 1.2
        },
        {
          filename = "__base__/sound/walking/concrete-04.ogg",
          volume = 1.2
        }
      },
      map_color={r=70, g=90, b=85},
      ageing=0,
      vehicle_friction_modifier = concrete_vehicle_speed_modifier
},

{   
      type = "tile",
      name = "powered-floor-circuit-tile",
      needs_correction = false,
      zorkmid = "howdy",
      minable = {hardness = 0.2, mining_time = 0.5, result = "powered-floor-circuit-tile"},
      mined_sound = { filename = "__base__/sound/deconstruct-bricks.ogg" },
      collision_mask = {"ground-tile"},
      walking_speed_modifier = 1.7,
      layer = 61,
      decorative_removal_probability = 0.9,
      variants =
      {
        main =
        {
          {
             picture = "__PoweredFloor__/graphic/powered-floor-circuit-tile1.png",
            count = 16,
            size = 1
          },
          {
            picture = "__PoweredFloor__/graphic/powered-floor-tile2.png",
            count = 4,
            size = 2,
            probability = 0.08,
          },
          {
            picture = "__PoweredFloor__/graphic/powered-floor-tile4.png",
            count = 4,
            size = 4,
            probability = .10,  
          },  
        },
        inner_corner =
        {
          picture = "__PoweredFloor__/graphic/powered-floor-no-edges.png",
          count = 1
        },
        outer_corner =
        {
          picture = "__PoweredFloor__/graphic/powered-floor-no-edges.png",
          count = 1
        },
        side =
        {
          picture = "__PoweredFloor__/graphic/powered-floor-no-edges.png",
          count = 1
        },
        u_transition =
        {
          picture = "__PoweredFloor__/graphic/powered-floor-no-edges.png",
          count = 1
        },
        o_transition =
        {
          picture = "__PoweredFloor__/graphic/powered-floor-no-edges.png",
          count = 1
        }
      },

      walking_sound =
      {
        {
          filename = "__base__/sound/walking/concrete-01.ogg",
          volume = 1.2
        },
        {
          filename = "__base__/sound/walking/concrete-02.ogg",
          volume = 1.2
        },
        {
          filename = "__base__/sound/walking/concrete-03.ogg",
          volume = 1.2
        },
        {
          filename = "__base__/sound/walking/concrete-04.ogg",
          volume = 1.2
        }
      },
      map_color={r=70, g=90, b=85},
      ageing=0,
      vehicle_friction_modifier = concrete_vehicle_speed_modifier
},



{
    type = "electric-pole",
    name = "powered-floor-tap",
    icon = "__PoweredFloor__/graphic/powered-floor-icon.png",
    icon_size = 32,
    flags = {"placeable-neutral", "player-creation"},
    minable = {hardness = 0.2, mining_time = 0.5, result = "powered-floor-tap"},
    max_health = 120,
    corpse = "small-remnants",
    resistances =
    {
      {
        type = "fire",
        percent = 100
      }
    },
    
    collision_box = {{-0.15, -0.15}, {0.15, 0.15}}, 
    walking_speed_modifier = 2.0,
    selection_box = {{-0.5, -0.5}, {0.5, 0.5}},
    drawing_box = {{-0.5, -0.5}, {0.5, 0.5}},
    maximum_wire_distance = 2.5,
    max_circuit_wire_distance = 1000,
    supply_area_distance = 0.5,
    vehicle_impact_sound =  { filename = "__base__/sound/car-metal-impact.ogg", volume = 0.65 },
    pictures =
    {
      filename = "__PoweredFloor__/graphic/powered-floor-tap.png",
      priority = "low",
      width = 32,
      height = 32,
      
      axially_symmetrical = true,
      direction_count = 1,
      shift = {0, 0}
    },
    render_layer="floor",
    connection_points =
    {
      {
        shadow =  {  copper = {0, 0}, green = {0.2,0.0}, red = {0.2,0.0}  },
        wire =    {  copper = {0, 0}, green = {0.1,0.0}, red = {0.0,0.1}  }
      }
    },
    radius_visualisation_picture =
    {
      filename = "__base__/graphics/entity/small-electric-pole/electric-pole-radius-visualization.png",
      width = 12,
      height = 12
    }
 },


--
-- technology
-- 

{
	type = "technology",
	name = "powered-floors",
	icon = "__PoweredFloor__/graphic/powered-floor-technology-icon.png",
	icon_size = 128,
	effects =
	{
		{
			type = "unlock-recipe",
			recipe = "powered-floor-tile"
		},
		{
			type = "unlock-recipe",
			recipe = "powered-floor-tap"
		},
		{
			type = "unlock-recipe",
			recipe = "powered-floor-circuit-tile"
		},
		{
			type = "ghost-time-to-live",
			modifier = 60 * 60 * 6
		}
	},
	prerequisites = {"electric-energy-distribution-1"},
	unit =
		{
			count = 40,
			ingredients =
			{
				{"automation-science-pack", 1},
				{"logistic-science-pack", 1}
			},
			time = 30
		},
	order = "c-k-a",
}     
     

})

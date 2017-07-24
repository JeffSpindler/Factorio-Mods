-- control.lua
-- Max Rate Calculator mod for Factorio
--
-- This calculates max possible rates for a selected set of machines.
-- Does not compute actual running rates - see the Efficen-See mod for that
-- (from which I learned and borrowed)



g_marc_units = {}


g_marc_units[1] = {name="marc-gui-persec", 			localized_name = {"marc-gui-persec"}, 			multiplier = 1, divisor = 1, infotype="time"}
g_marc_units[2] = {name="marc-gui-permin", 			localized_name = {"marc-gui-permin"}, 			multiplier = 60, divisor = 1, infotype="time"}
g_marc_units[3] = {name="marc-transport-belt", 		localized_name = {"marc-transport-belt"}, 		multiplier = 3, divisor = 40, infotype="transport"}
g_marc_units[4] = {name="marc-fast-transport-belt", localized_name = {"marc-fast-transport-belt"}, 	multiplier = 3, divisor = 80, infotype="transport"}
g_marc_units[5] = {name="marc-express-transport-belt", localized_name = {"marc-express-transport-belt"}, multiplier = 1, divisor = 40, infotype="transport"}
g_marc_units[6] = {name="marc-burner-inserter", 	localized_name = {"marc-burner-inserter"}, 		multiplier = 3, divisor = 1.76, infotype="inserter"} -- divisor from https://wiki.factorio.com/Inserters
g_marc_units[7] = {name="marc-basic-inserter", 		localized_name = {"marc-basic-inserter"}, 		multiplier = 3, divisor = 2.50, infotype="inserter"}
g_marc_units[8] = {name="marc-long-inserter", 		localized_name = {"marc-long-inserter"}, 		multiplier = 3, divisor = 3.46, infotype="inserter"}
g_marc_units[9] = {name="marc-fast-inserter", 		localized_name = {"marc-fast-inserter"}, 		multiplier = 1, divisor = 2.31, infotype="inserter"}
g_marc_units[10] = {name="marc-stack-inserter", 	localized_name = {"marc-stack-inserter"}, 		multiplier = 12, divisor = 27.70, infotype="stack-inserter"}
g_marc_units[11] = {name="marc-wagon-permin", 	localized_name = {"marc-wagon-permin"}, 		multiplier = 60, divisor =1 , infotype="wagon"}
g_marc_units[12] = {name="marc-wagon-perhr", 	localized_name = {"marc-wagon-perhr"}, 		multiplier = 3600, divisor =1 , infotype="wagon"}
g_marc_units_count = 12

-- string formats so numbers are displayed in a consistent way
local persec_format = "%16.3f"
local permin_format = "%16.1f"

local function boolstr(bool)
	if bool
	then return "T"
	else return "F"
	end
end

local function compatible_units(item_or_fluid, unit_type)

	if item_or_fluid == "fluid" and
			(unit_type ~= "time") and
			(unit_type ~= "wagon")
	then		
		return false
	else
		return true
	end

end

-- Return a flag indicating if name refers to an item (such as iron-plate) or a fluid
local function get_item_or_fluid(name)
	local proto = game.item_prototypes[name]
	item_or_fluid = "item"
	if proto == nil
	then
		item_or_fluid = "fluid"
	end
	return item_or_fluid
end


-- return the prototype
local function get_proto(name)

	if get_item_or_fluid(name) == "item"
	then
		return game.item_prototypes[name]
	else
		return game.fluid_prototypes[name]
	end

end

-- fill out the first part of a row with the icon and the rate.  Used for both inputs and outputs
local function build_gui_row(guirow, name, count, rownum, machine_count, unit_type)
	if machine_count == nil
	then
		machine_count = 0
	end
	
	local proto = get_proto(name)
	if proto == nil	-- not sure what this is
		then
			return false
	end
	
	local item_or_fluid = get_item_or_fluid(name)
	
	if not compatible_units(item_or_fluid, unit_type)
	then
		-- showing inserter/belt rate for a fluid makes no sense
		return false
	end
	
	localized_name = proto.localised_name
	
	guirow.add({type = "sprite-button", sprite =  item_or_fluid .. "/" .. name, name = "marc_sprite" .. rownum, style = "sprite_obj_marc_style", tooltip = {"marc-gui-tt-item-sprite",localized_name, machine_count}})
	guirow.add({type = "label", name = "marc_per_min" .. rownum, caption = string.format(persec_format, count ), tooltip={"marc-gui-tt-rate"} })

	return true
end

-- create the list of rate units the user can choose from
local function build_units_dropdown_list()

	local item_list = {}

	
	local listix = 1
	for _, marc_unit in ipairs(g_marc_units)
	do
		item_list[listix] = g_marc_units[listix].localized_name
		listix = listix + 1
	end
	
	
	return item_list
end


-- scale the count based on the unit.
-- some rate units require more than just the multiplier/divisor in the g_marc_units table
local function scale_rate(player, name, count)

	local selected = player.gui.left.marc_gui_top.marc_gui_upper.maxrate_units.selected_index
	local unit_entry = g_marc_units[selected]
	local divisor = unit_entry.divisor
	local multiplier = unit_entry.multiplier
	local unit_type = unit_entry.infotype
	
	-- game.print("scale_rate " .. name .. " mult " .. multiplier .. " div " .. divisor .. " count " .. count)


	local proto = get_proto(name)
	if proto == nil	-- not sure what this is
	then
		game.print("neither item nor fluid?")
		return -1
	end
	local item_or_fluid = get_item_or_fluid(name)
	
	if not compatible_units(item_or_fluid, unit_type)
	then
		-- game.print("not compatible:" .. item_or_fluid .. " name " .. name .. " unit_type" .. unit_type)
		-- showing inserter/belt rate for a fluid makes no sense
		return -1
	end


	if unit_type == "inserter"
	then
		local old_div = divisor
		stack_size = player.force.inserter_stack_size_bonus + 1
		divisor = divisor * stack_size 
	elseif unit_type == "stack-inserter"
	then
		stack_size = player.force.stack_inserter_capacity_bonus + 1
		local old_div = divisor
		divisor = divisor * stack_size 
	elseif unit_type == "wagon"
		then
			local total_capacity
	
			if item_or_fluid == "item"
			then
				cargo_wagon_proto = game.entity_prototypes["cargo-wagon"]
				total_capacity = cargo_wagon_proto.get_inventory_size(1) * proto.stack_size
			else
				-- fluid_wagon_proto = game.entity_prototypes["fluid-wagon"]
				-- game.print("fluid wagon holds " .. fluid_wagon_proto.fluid_box.get_capacity(1))  -- .. or some such
				total_capacity = 25000 * 3		-- copied from base/prototypes/entity/entities.lua for name="fluid-wagon"
			end
			divisor = divisor * total_capacity
			-- game.print("divisor " .. divisor .. " total_capacity " .. total_capacity .. " multiplier " .. multiplier )
			debug = true
	end
	-- game.print("scale_rate now " .. name .. " mult " .. multiplier .. " div " .. divisor .. " count " .. count)
	return multiplier*count/divisor
end

-- Puts the calculated info into a frame on the left side of the window
--
local function write_marc_gui(player, inout_data)

	local inputs = inout_data.inputs
	local outputs = inout_data.outputs
	local machines = inout_data.machines
	local machines_fed = inout_data.machines_fed or {}
	
	-- count input, output items and number in common between them
	local input_items = 0
	for input_name, input_count in pairs(inout_data.inputs) 
	do
		input_items = input_items + 1
	end

	local both_input_and_output_items = 0
	local output_items = 0
	for output_name, output_count in pairs(outputs) 
	do
		output_items = output_items + 1
		if inputs[output_name] ~= nil
		then
			both_input_and_output_items = both_input_and_output_items + 1
		end
	end
	
	if input_items == 0 and output_items == 0
	then
		-- nothing to see here, move on
		if player.gui.left.marc_gui_top
		then
			player.gui.left.marc_gui_top.destroy()
		end
		return
	end
	
	
	player.gui.left.add({type = "frame", name = "marc_gui_top", direction = "vertical"})
	
	local marc_gui_top = player.gui.left.marc_gui_top
	local marc_gui_top1 = marc_gui_top.add({type = "flow", name = "marc_gui_top1", direction = "horizontal"})
	marc_gui_top1.add({type = "label", name="marc_top_label", caption={"marc-gui-top-label"}})
	
	-- can't figure out a nicer way to right justify the close button
	if both_input_and_output_items > 0
	then
		marc_gui_top1.add({type = "label", name = "marc_top1_spacer" , caption = "                                                                                                     "})
	else
		marc_gui_top1.add({type = "label", name = "marc_top1_spacer" , caption = "                                                      "})
	end

	marc_gui_top1.add({type = "sprite-button", sprite = "sprite_marc_close", name = "marc_close_button" ,align = "right", style = "sprite_obj_marc_style"})

	
	
	-- upper section has Rate <dropdown> <close button>
	local marc_gui_upper = marc_gui_top.add({type = "flow", name = "marc_gui_upper", direction = "horizontal"})
	marc_gui_upper.add({type = "label", name="marc_upper_rate_label", caption={"marc-gui-rate-colon"}, tooltip={"marc-gui-tt-rate-select"}})
	
	local ix = global.marc_selected_units[player.index]
	marc_gui_upper.add({type="drop-down", name="maxrate_units", items=build_units_dropdown_list(), selected_index=ix, tooltip={"marc-gui-tt-rate-select"}})
	
	
	
	
	-- main marc gui has two frames, one for inputs, one for outputs
	local marc_gui = marc_gui_top.add({type = "flow", name = "marc_gui", direction = "horizontal"})
	
	-- marc_gui contains two frames, one for inputs and one for outputs

	-- what units are we displaying in?
	local selected = player.gui.left.marc_gui_top.marc_gui_upper.maxrate_units.selected_index
	local unit_entry = g_marc_units[selected]
	local divisor = unit_entry.divisor
	local multiplier = unit_entry.multiplier
	local unit_type = unit_entry.infotype

	
	-- Input ingredients
	--
	if input_items > 0
	then
		-- frame to hold the rows of input items
		gui_input_frame = marc_gui.add({type = "frame", name = "marc_inputs", direction = "vertical", caption = {"marc-gui-inputs"}})
		gui_input_scrollpane = gui_input_frame.add({type = "scroll-pane", name = "marc_inputs_pane", vertical_scroll_policy = "auto", style = "scroll_pane_marc_style",  direction = "vertical", caption = {"marc-gui-inputs"}})
		
		-- three columns - item icon, rate per second, rate per minute
		gui_inrows= gui_input_scrollpane.add({type = "table", name = "marc_inrows", style = table_marc_style, colspan = 2 })
		gui_inrows.style.column_alignments[2] = "right"	-- numbers look best right justified
		
		-- column headers
		gui_inrows.add({type = "label", name="marc_placeholder", caption="" })
		gui_inrows.add({type = "label", name = "marc_header_rate", caption = {"marc-gui-rate"}, tooltip={"marc-gui-tt-rate-input"} })
		

		-- add a row for each input item, with sexy icon (sprite button), rate
		
		local rownum = 1
		local name
		local count
		local sorted_names = {}

		for name in pairs(inputs) do table.insert(sorted_names, name) end
		table.sort(sorted_names)
		
		for i, name in ipairs(sorted_names)
		do
			count = inputs[name]
			local scaled_count = scale_rate(player, name, count)
			build_gui_row(gui_inrows, name, scaled_count, rownum, machines_fed[name], unit_type) 
			rownum = rownum+1		
		end
	end
	
	-- Output products
	--
	if output_items > 0
	then
		gui_output_frame = marc_gui.add({type = "frame", name = "marc_outputs", direction = "vertical", caption = {"marc-gui-outputs"}})
		gui_output_scrollpane = gui_output_frame.add({type = "scroll-pane", name = "marc_outputs_pane", vertical_scroll_policy = "auto", style = "scroll_pane_marc_style",  direction = "vertical", caption = {"marc-gui-inputs"}})

		-- if there were items both consumed and produced, we'll have two more columns to show the net result
		if both_input_and_output_items > 0
		then
			cols = 5
		else
			cols = 3
		end
		gui_outrows = gui_output_scrollpane.add({type = "table", name = "marc_outrows", style = table_marc_style, colspan = cols })
		
		-- right justify the numbers
		for i=1,cols
		do
			gui_outrows.style.column_alignments[i] = "right"
		end	
		
		-- column headers
		gui_outrows.add({type = "label", name="marc_header1_placeholder", caption=""}) -- this goes where the widget is in the rows below
		gui_outrows.add({type = "label", name = "marc_header1_rate", caption = "" , tooltip={"marc-gui-tt-rate-output"}})
		gui_outrows.add({type = "label", name = "marc_header1_machine_rate", caption = {"marc-gui-items-per"}, tooltip={"marc-gui-tt-items-per-machine"} })
		if both_input_and_output_items > 0
		then
			gui_outrows.add({type = "label", name = "marc_header1_net_per_sec", caption = {"marc-gui-net"} , tooltip={"marc-gui-tt-net-rate"}})	
			gui_outrows.add({type = "label", name = "marc_header1_net_machine_count", caption = {"marc-gui-net"} , tooltip={"marc-gui-tt-net-machines"}})
		end
		-- second row of column headers
		gui_outrows.add({type = "label", name="marc_placeholder", caption=""}) -- this goes where the widget is in the rows below
		gui_outrows.add({type = "label", name = "marc_header_rate", caption = {"marc-gui-rate"} , tooltip={"marc-gui-tt-rate-output"}})
		gui_outrows.add({type = "label", name = "marc_header_machine_rate", caption = {"marc-gui-machine"} , tooltip={"marc-gui-tt-items-per-machine"}})

		if both_input_and_output_items > 0
		then
			gui_outrows.add({type = "label", name = "marc_header_net_per_sec", caption = {"marc-gui-rate"} , tooltip={"marc-gui-tt-net-rate"}})	
			gui_outrows.add({type = "label", name = "marc_header_net_machine_count", caption = {"marc-gui-machines"} , tooltip={"marc-gui-tt-net-machines"}})
		end

		local rownum = 1
		local sorted_names = {}

		for name in pairs(outputs) do table.insert(sorted_names, name) end
		table.sort(sorted_names)
		
		for i, name in ipairs(sorted_names)
		do
			count = outputs[name]
			local scaled_count = scale_rate(player, name, count)
			local legit = build_gui_row(gui_outrows, name, scaled_count, rownum, machines[name], unit_type)
			if legit	-- only add to row if unit_type is compatible with the item
			then
				local average_per_machine = count/machines[name]
				local scaled_average_per_machine = scale_rate(player, name, average_per_machine) -- multiplier*average_per_machine/divisor
				gui_outrows.add({type = "label", name = "marc_machine_rate" .. rownum, caption = string.format( persec_format,scaled_average_per_machine), tooltip={"marc-gui-tt-items-per-machine"} })			

				-- add extra columns if an item appears in both inputs and outputs

				input_count = inout_data.inputs[name]
				if input_count ~= nil
				then
					local net_difference = (count - input_count)
					local net_count = scale_rate(player, name,net_difference)
					gui_outrows.add({type = "label", name = "marc_net_per_min" .. rownum, caption = string.format( persec_format, net_count ), tooltip={"marc-gui-tt-net-rate"}})

					local net_machines = net_difference/average_per_machine
					gui_outrows.add({type = "label", name = "marc_net_machines" .. rownum, caption = string.format( persec_format, net_machines  ), tooltip={"marc-gui-tt-net-machines"}})
				elseif both_input_and_output_items > 0
				then 
					-- five column display, but this item doesn't have net info
					gui_outrows.add({type = "label", name = "marc_net_per_min" .. rownum, caption = "" })
					gui_outrows.add({type = "label", name = "marc_net_machines" .. rownum, caption = "" })
				end
				rownum = rownum+1
			end
		end
	end

end

-- show the gui with the rate calculations
local function open_gui(event, inout_data)

	local player = game.players[event.player_index]
	if player.gui.left.marc_gui_top
	then
		player.gui.left.marc_gui_top.destroy()
	end
	
	script.on_event(defines.events.on_tick, on_tick)
    
	write_marc_gui(player, inout_data)
end

-- calculate the speed and productivity effects of a single module
local function calc_mod( modname, modeffects, modquant, effectivity )
	protoeffects = game.item_prototypes[modname].module_effects
	-- game.print("mod is " .. modname .. " quantity " .. modquant)
	for effectname,effectvals in pairs(protoeffects)
	do
		-- game.print("...effectname is " .. effectname .. " modquant " .. modquant)
		for _,bonamount in pairs(effectvals) -- first item in pair seems to be always "bonus"
		do
			-- game.print("...effectname,bonix,bon " .. effectname ..  "," .. bonamount)
			if effectname == "speed"
			then
				-- game.print("...adjust speed by " .. ( bonamount * modquant ))
				modeffects.speed = modeffects.speed + ( bonamount * modquant * effectivity)
			elseif effectname == "productivity"
			then
				-- game.print("...adjust productivity by " .. ( bonamount * modquant ))
				modeffects.prod = modeffects.prod + (bonamount * modquant  * effectivity)
			end
		end

	end
end

-- calculate the effects of all the modules in the entity
local function calc_mods(entity, modeffects, effectivity)
	modinv = entity.get_module_inventory()
	modcontents = modinv.get_contents()
	local ix = 1

	for modname,modquant in pairs(modcontents)
	do
		-- game.print("calc_mods proto is " .. game.item_prototypes[modname].name)
		-- game.print("calc_mods modname,modquant " .. modname .. "," .. modquant)
		
		calc_mod(modname, modeffects, modquant, effectivity)
		ix = ix + 1
	end 

	
	return modeffects
end

-- calculate effects of beacons.  For our purposes, only speed effects count
local function check_beacons(surface, entity)
	
	local x = entity.position.x
	local y = entity.position.y
	
	beacon_dist = game.entity_prototypes["beacon"].supply_area_distance
	
	-- game.print("check_beacons searching around " .. x .. "," .. y .. " beacon dist is " .. beacon_dist)
	machine_box = entity.prototype.selection_box
	-- game.print("check_beacons box is " .. machine_box.left_top.x .. "," .. machine_box.left_top.y .. " thru " .. machine_box.right_bottom.x .. "," .. machine_box.right_bottom.y)
	modeffects = { speed = 0, prod = 0 }

	local beacons = 0
	local mods = 0

	-- assumes all beacons have same effect radius
	search_area = { { x + machine_box.left_top.x - beacon_dist, 	y + machine_box.left_top.y - beacon_dist }, 
				    { beacon_dist + x + machine_box.right_bottom.x, beacon_dist + y + machine_box.right_bottom.y }}
	-- game.print(" upper left " .. 	x + machine_box.left_top.x - beacon_dist .. "," .. y + machine_box.left_top.y - beacon_dist)			    

	for _,beacon in pairs(surface.find_entities_filtered{ area=search_area, type="beacon"})
	do	
		-- game.print(" beacon area is " .. beacon.prototype.supply_area_distance .. " at " .. beacon.position.x .. "," .. beacon.position.y)
		beacons = beacons + 1	
		-- local effectivity = beacon.prototype.distribution_effectivity
		local effectivity = 0.5 -- beacon.prototype.distribution_effectivity exists, but isn't readable
		calc_mods( beacon, modeffects, effectivity)
	end
	
	beacon_speed_effect = modeffects.speed 
	-- game.print("beacon_speed_effect " .. beacon_speed_effect .. " beacons " .. beacons .. " mods" .. mods)
	return beacon_speed_effect

end

-- for an individual assembler, calculate the rates all the inputs are used at and the outputs are produced at, per second
local function calc_assembler(entity, inout_data, beacon_speed_effect)

	-- get the machines base crafting speed, in cycles per second
	local crafting_speed = entity.prototype.crafting_speed

	modeffects = { speed = 0, prod = 0 }
	local effectivity = 1
	modeffects = calc_mods(entity, modeffects, effectivity)

	-- adjust crafting speed based on modules and beacons
	-- game.print( "calc_assembler cspeed " .. crafting_speed .. " modspeed " .. modeffects.speed .. " beacon_speed_effect " .. beacon_speed_effect)
	crafting_speed = crafting_speed * ( 1 + modeffects.speed + beacon_speed_effect)
	-- how long does the item take to craft if no modules and crafting speed was 1?  It's in the recipe.energy!
	crafting_time = entity.recipe.energy
	
	-- game.print("crafting time " .. crafting_time .. " modeffects.speed " .. modeffects.speed .. " beacon_speed_effect " .. beacon_speed_effect )
	
	if(crafting_time == 0)
	then
		crafting_time = 1
		game.print("entity.recipe.energy = 0, wtf?")
	end
	

	-- for all the ingredients in the recipe, calculate the rate
	-- they're consumed at.  Add to the inputs table.
	for _, ingred in ipairs(entity.recipe.ingredients)
	do
		local amount = ingred.amount * crafting_speed / crafting_time
		if inout_data.inputs[ingred.name] ~= nil
		then
			inout_data.inputs[ingred.name] = inout_data.inputs[ingred.name] + amount
			inout_data.machines_fed[ingred.name] = inout_data.machines_fed[ingred.name] + 1
		else
			inout_data.inputs[ingred.name] = amount
			inout_data.machines_fed[ingred.name] = 1
		end
	end
	
	--[[ 
	-- initial code to compute fuel consumption by stone & electric furnaces
	-- not sure who cares, not in game's production graph.  would also need to consider burner inserter
	-- Rseding says use burner_prototype info
	fuel_inventory = entity.get_fuel_inventory()
	if fuel_inventory ~= nil
	then
		local fuel_name = fuel_inventory[1].name
		game.print(entity.name  .. " has fuel " .. fuel_name)
		fuel_proto = game.item_prototypes[fuel_name]
		game.print("fuel value " .. fuel_proto.fuel_value)
	end
	]]--
	
	-- for all the products in the recipe (usually just one)
	-- calculate the rate they're produced at and add each product to the outputs
	-- table
	for _, prod in ipairs(entity.recipe.products)
	do
		-- game.print("prod amount, modeffects.prod " .. prod.name .. " " .. prod.amount .. "," .. modeffects.prod )
		local amount
		if prod.amount ~= nil
		then
			amount = prod.amount 
		else
			-- handle if Product has probability not amount, like for centrifuges sometimes
			amount = prod.probability * (prod.amount_min + prod.amount_max) / 2
		end
		-- game.print("calc_assembler " .. prod.name .. " amount " .. amount .. " modeffects " .. ( 1 + modeffects.prod) .. " cspeed " .. crafting_speed .. " crafting_time" .. crafting_time)
		amount = amount * ( 1 + modeffects.prod) *  crafting_speed / crafting_time
		if inout_data.outputs[prod.name] ~= nil
		then
			inout_data.outputs[prod.name] = inout_data.outputs[prod.name] + amount
			inout_data.machines[prod.name] = inout_data.machines[prod.name] + 1
		else
			inout_data.outputs[prod.name] = amount
			inout_data.machines[prod.name] =  1
		end
	end
	
end

-- player has selected some machines with our tool
script.on_event(defines.events.on_player_selected_area,
	function(event)
	
		-- leave if not our tool
		if event.item ~= "max-rate-calculator" 
		then
			return
		end
		global.marc_selected_unit_index = global.marc_selected_unit_index or {}
		local player = game.players[event.player_index]
		local surface = player.surface
		
		local inout_data = { inputs={}, outputs = {}, machines = {}, machines_fed = {} }
		-- for all the machines selected, calculate consumption/production rates.
		-- (note: beacons themselves don't need to be selected, if one is in range
		--  of a selected machine, it will be considered)
		local no_recipe_smelters = 0
		local no_recipe_assemblers = 0
		for _, entity in ipairs(event.entities)
		do
			-- game.print("Found entity " .. entity.name  )
			if entity.energy ~= nil
			then
				-- game.print("Has energy " .. entity.energy )
			else
				-- game.print("No energy")
			end
			
			if entity.type == "assembling-machine" or entity.type == "furnace"
			then		
				if entity.recipe ~= nil
				then
					local beacon_speed_effect = 0
					if entity.prototype.module_inventory_size > 0					
					then
						beacon_speed_effect = check_beacons(surface, entity, beacon_speed_effect)
					end
					calc_assembler(entity, inout_data, beacon_speed_effect)	
				else
					if entity.type == "assembling-machine"
					then
						no_recipe_assemblers = no_recipe_assemblers + 1
					else
						no_recipe_smelters = no_recipe_smelters + 1
					end
				end
			end
		end
		
		if no_recipe_assemblers > 0 or no_recipe_smelters > 0
		then
			
			if no_recipe_assemblers > 0 and no_recipe_smelters > 0
			then
				player.print({"marc-gui-no-recipe-both", no_recipe_assemblers, no_recipe_smelters})
			else
				if no_recipe_assemblers > 0
				then
					player.print({"marc-gui-no-recipe-assemblers", no_recipe_assemblers})				
				else
					player.print({"marc-gui-no-recipe-smelters", no_recipe_smelters})
				end
			end
			
		end
		
		-- save so if user changes units dropdown, we can recalculate the gui
		global.marc_inout_data = inout_data
		
		-- now open and show the gui with the calculations
		open_gui(event, inout_data)
		
		-- throw away the max-rate-calculator item.  User never gets one in their inventory (unless they click hotkey and directly put it in inventory)
		local cursor_stack = player.cursor_stack
		cursor_stack.clear()

	end
)

-- player hit the magic key, create our selection tool and put it in their hand
local function on_hotkey_main(event)

	global.marc_selected_units = global.marc_selected_units or {}
	global.marc_selected_units[event.player_index] = global.marc_selected_units[event.player_index] or 2
	local player = game.players[event.player_index]

	-- once in their life, a message is displayed giving a hint	
	global.marc_hint = global.marc_hint or 0	
	if global.marc_hint == 0
	then
		player.print({"marc-gui-select-hint"})
		global.marc_hint = 1
	end

	-- put whatever is in the player's hand back in their inventory
	-- and put our selection tool in their hand
	player.clean_cursor()
	local cursor_stack = player.cursor_stack
	cursor_stack.clear()
	cursor_stack.set_stack({name="max-rate-calculator", type="selection-tool", count = 1})


end

-- user has clicked somewhere.  If clicked on any gui item name that starts with "marc_..."
-- hide the gui
local function on_gui_click(event)
	local event_name = event.element.name
	-- game.print("event_name " .. event_name)
	local s = string.sub( event_name, 1, 5 )
	local player = game.players[event.player_index]
	
	if s == "marc_"
	then
		if player.gui.left.marc_gui_top then
			player.gui.left.marc_gui_top.destroy()
		end

	end
end

local function on_gui_selection(event)

	local event_name = event.element.name
	local player = game.players[event.player_index]

		
	if event_name == "maxrate_units"
	then
		local selected = player.gui.left.marc_gui_top.marc_gui_upper.maxrate_units.selected_index
		-- game.print("selected is " .. selected)
		global.marc_selected_units[event.player_index] = selected
		-- local selname = player.gui.left.marc_gui_top.maxrate_units.items[selected]
		-- game.print("selname is " .. selname)
		unit_entry = g_marc_units[selected]
		-- game.print("selected " .. unit_entry.name .. " " .. unit_entry.multiplier .. "/" .. unit_entry.divisor)
		player.gui.left.marc_gui_top.destroy()
		open_gui(event, global.marc_inout_data)
	end
end

script.on_event(defines.events.on_gui_selection_state_changed, on_gui_selection)

script.on_event("marc_hotkey", on_hotkey_main)

script.on_event(defines.events.on_gui_click, on_gui_click)
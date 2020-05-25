-- control.lua
-- Max Rate Calculator mod for Factorio
--
-- This calculates max possible rates for a selected set of machines.
-- Does not compute actual running rates - see the Efficen-See mod for that
-- (from which I learned and borrowed)

require("calculator")


g_marc_units = {}


-- .16 values for belts m/d = 3/40, 3/80, 1/40

g_marc_units[1] = {name="marc-gui-persec", 			localized_name = {"marc-gui-persec"}, 			multiplier = 1, divisor = 1, infotype="time"}
g_marc_units[2] = {name="marc-gui-permin", 			localized_name = {"marc-gui-permin"}, 			multiplier = 60, divisor = 1, infotype="time"}
-- g_marc_units[3] = {name="marc-transport-belt", 		localized_name = {"marc-transport-belt"}, 		multiplier = 3, divisor = 45, infotype="transport"}
-- g_marc_units[4] = {name="marc-fast-transport-belt", localized_name = {"marc-fast-transport-belt"}, 	multiplier = 3, divisor = 90, infotype="transport"}
-- g_marc_units[5] = {name="marc-express-transport-belt", localized_name = {"marc-express-transport-belt"}, multiplier = 1, divisor = 45, infotype="transport"}
g_marc_units[3] = {name="marc-burner-inserter", 	localized_name = {"marc-burner-inserter"}, 		multiplier = 3, divisor = 1.76, infotype="inserter"} -- divisor from https://wiki.factorio.com/Inserters
g_marc_units[4] = {name="marc-basic-inserter", 		localized_name = {"marc-basic-inserter"}, 		multiplier = 3, divisor = 2.50, infotype="inserter"}
g_marc_units[5] = {name="marc-long-inserter", 		localized_name = {"marc-long-inserter"}, 		multiplier = 3, divisor = 3.46, infotype="inserter"}
g_marc_units[6] = {name="marc-fast-inserter", 		localized_name = {"marc-fast-inserter"}, 		multiplier = 1, divisor = 2.31, infotype="inserter"}
g_marc_units[7] = {name="marc-stack-inserter", 	localized_name = {"marc-stack-inserter"}, 		multiplier = 12, divisor = 27.70, infotype="stack-inserter"}
g_marc_units[8] = {name="marc-wagon-permin", 	localized_name = {"marc-wagon-permin"}, 		multiplier = 60, divisor =1 , infotype="wagon"}
g_marc_units[9] = {name="marc-wagon-perhr", 	localized_name = {"marc-wagon-perhr"}, 		multiplier = 3600, divisor =1 , infotype="wagon"}

g_marc_units_default = 2 -- per minutes is the default

g_belts_added = false

-- string formats so numbers are displayed in a consistent way
local persec_format = "%16.3f"
local permin_format = "%16.1f"

global.marc_win_loc_x = 0
global.marc_win_loc_y = 176 -- puts us just below rocket stats
-- ----------------------------------------------------------------


function boolstr(bool)
	if bool
	then return "T"
	else return "F"
	end
end

-- ----------------------------------------------------------------

function debug_print(str)
	if global.marc_debug
	then
		game.print(str)
	end
end

function __FUNC__() return debug.getinfo(2, 'n').name end

function debug_log(f, str)
	if global.marc_debug
	then
		game.print(f .. ": " .. str)
	end
end


-- ----------------------------------------------------------------

function printObj(obj) 
 
 for k,v in pairs(obj)
 do
    if(type(v) == "userdata")
    then
       debug_print(k .. " is userdata")
    else
 		debug_print(k .. "=" .. v.name)
 	end
 end

end


-- ----------------------------------------------------------------

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

-- ----------------------------------------------------------------

local function get_entity_recipe(entity)
	if entity.type == "furnace"
	then
		return (entity.get_recipe() or entity.previous_recipe)				
	elseif entity.type == "assembling-machine"				
	then 
		return entity.get_recipe() 
	else
		return nil
	end
end


-- ----------------------------------------------------------------

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

-- ----------------------------------------------------------------

-- return the prototype
local function get_proto(name)
	
	local p
	local itype
	if get_item_or_fluid(name) == "item"
	then
		
		p = game.item_prototypes[name]
		itype = "item"
	else
		itype = "fluid"
		p = game.fluid_prototypes[name]
	end
	if(p == nil)
	then
		debug_print(__FUNC__() .. " could not find proto for " .. itype .. " " .. name)
	end
	return p
end

local function add_value_to_marcalc_clickable_list(inout_data, label_name, count)
	inout_data.clickable_values[label_name] = count
end


-- ----------------------------------------------------------------

local function get_gui_root(player)
	-- return player.gui.left
	return player.gui.screen
end

-- ----------------------------------------------------------------

function destroy_marc_gui(player)
	local root = get_gui_root(player)
	global.marc_win_loc_x = root.marc_gui_top.location.x
	global.marc_win_loc_y = root.marc_gui_top.location.y
	root.marc_gui_top.destroy()
end
-- ----------------------------------------------------------------

-- fill out the first part of a row with the icon and the rate.  Used for both inputs and outputs
local function build_gui_row(guirow, name, count, rownum, machine_count, unit_type, inout_data)
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
	local label_name = "marc_per_min" .. rownum
	guirow.add({type = "label", name = label_name, caption = string.format(persec_format, count ), tooltip={"marc-gui-tt-rate"} })
	add_value_to_marcalc_clickable_list(inout_data, label_name, count)
	return true
end

-- ----------------------------------------------------------------

local function find_belts()


	if g_belts_added
	then
		return
	end
	g_belts_added = true

	local items_per_belt = 8
	
	for _,entity_proto in pairs(game.entity_prototypes)
	do

		if entity_proto.type == "transport-belt"
		then
			local p = entity_proto
			debug_print(__FUNC__().. " found a belt " .. entity_proto.name)

			local maxh = entity_proto.max_health
					local speed = entity_proto.belt_speed
			local denom = items_per_belt * speed * 60
			local sz = #g_marc_units
			debug_print (entity_proto.name .. " has speed " .. speed .. " denom is " .. denom .. " size " .. #g_marc_units)
			
			table.insert(g_marc_units,{name=p.name, 	localized_name = p.localised_name, 		multiplier = 1, divisor =denom , infotype="transport"})
			

		end
	end				
		

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

-- ----------------------------------------------------------------

local function init_selected_units(player_index)

	global.marc_selected_units = global.marc_selected_units or {}
	global.marc_selected_units[player_index] = global.marc_selected_units[player_index] or g_marc_units_default
	if global.marc_selected_units[player_index] == 0 or global.marc_selected_units[player_index] > #g_marc_units
	then
		global.marc_selected_units[player_index] = g_marc_units_default
	end
end



-- ----------------------------------------------------------------

-- scale the count based on the unit.
-- some rate units require more than just the multiplier/divisor in the g_marc_units table
local function scale_rate(player, name, count)
	local root = get_gui_root(player)

	local selected = root.marc_gui_top.marc_gui_upper.maxrate_units.selected_index
	local unit_entry = g_marc_units[selected]
	local divisor = unit_entry.divisor
	local multiplier = unit_entry.multiplier
	local unit_type = unit_entry.infotype
	
	-- debug_print("scale_rate " .. name .. " mult " .. multiplier .. " div " .. divisor .. " count " .. count)


	local proto = get_proto(name)
	if proto == nil	-- not sure what this is
	then
		debug_print("neither item nor fluid?")
		return -1
	end
	local item_or_fluid = get_item_or_fluid(name)
	
	if not compatible_units(item_or_fluid, unit_type)
	then
		debug_print("not compatible:" .. item_or_fluid .. " name " .. name .. " unit_type" .. unit_type)
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
				fluid_wagon_proto = game.entity_prototypes["fluid-wagon"]
				total_capacity = fluid_wagon_proto.fluid_capacity
			end
			divisor = divisor * total_capacity
			debug_print("divisor " .. divisor .. " total_capacity " .. total_capacity .. " multiplier " .. multiplier )
			debug = true
	end
	-- debug_print("scale_rate now " .. name .. " mult " .. multiplier .. " div " .. divisor .. " count " .. count)
	return multiplier*count/divisor
end

-- ----------------------------------------------------------------

-- Puts the calculated info into a frame on the left side of the window
--
local function write_marc_gui(player, inout_data)

	local inputs = inout_data.inputs
	local outputs = inout_data.outputs
	local machines = inout_data.machines
	local machines_fed = inout_data.machines_fed or {}
	inout_data.clickable_values = {}
	local root = get_gui_root(player)
	
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
		if root.marc_gui_top
		then
			destroy_marc_gui(player)
		end
		return
	end
	
	
	root.add({type = "frame", name = "marc_gui_top", direction = "vertical", caption={"marc-gui-top-label"}})
	
	local marc_gui_top = root.marc_gui_top
	debug_print(__FUNC__() .. ": marc location " .. root.marc_gui_top.location.x .. "," .. root.marc_gui_top.location.y)
	debug_log(__FUNC__(), "hello")
	if( global.marc_win_loc_x == nil )
	then
		global.marc_win_loc_x = 0
	end
	if( global.marc_win_loc_y == nil )
	then
		global.marc_win_loc_y = 172
	end
	root.marc_gui_top.location = { global.marc_win_loc_x, global.marc_win_loc_y }
	local marc_gui_top1 = marc_gui_top.add({type = "flow", name = "marc_gui_top1", direction = "horizontal"})
	-- marc_gui_top1.add({type = "label", name="marc_top_label", caption={"marc-gui-top-label"}})
	
	
		-- upper section has Rate <dropdown> <close button>
		local marc_gui_upper = marc_gui_top.add({type = "flow", name = "marc_gui_upper", direction = "horizontal"})

	

	
	
	marc_gui_upper.add({type = "label", name="marc_upper_rate_label", caption={"marc-gui-rate-colon"}, tooltip={"marc-gui-tt-rate-select"}})
	
	debug_print("#g_marc_units " .. #g_marc_units)
	
	init_selected_units(player.index)
	local ix = global.marc_selected_units[player.index]
	debug_print("global.marc_selected_units[" .. player.index .. "] = " .. ix)
	marc_gui_upper.add({type="drop-down", name="maxrate_units", items=build_units_dropdown_list(), selected_index=ix, tooltip={"marc-gui-tt-rate-select"}})
	
		-- can't figure out a nicer way to right justify the close button
		if both_input_and_output_items > 0
		then
			marc_gui_upper.add({type = "label", name = "marc_top1_spacer" , caption = "                                                                                                     "})
		else
			marc_gui_upper.add({type = "label", name = "marc_top1_spacer" , caption = "                                                      "})
		end
	
		marc_gui_upper.add({type = "sprite-button", sprite = "sprite_marc_calculator", name = "marc_calculator_button" ,align = "right", style = "sprite_obj_marc_style"})
	
		marc_gui_upper.add({type = "sprite-button", sprite = "sprite_marc_close", name = "marc_close_button" ,align = "right", style = "sprite_obj_marc_style"})

	
	
	-- main marc gui has two frames, one for inputs, one for outputs
	local marc_gui = marc_gui_top.add({type = "flow", name = "marc_gui", direction = "horizontal"})
	
	-- marc_gui contains two frames, one for inputs and one for outputs

	-- what units are we displaying in?
	local selected = root.marc_gui_top.marc_gui_upper.maxrate_units.selected_index
	local unit_entry = g_marc_units[selected]
	if unit_entry == nil
	then
		game.print("unit_entry was nil.   selected is " .. selected)
		unit_entry = g_marc_units[g_marc_units_default]
		if unit_entry == nil
		then
			game.print("still nil, wtf?")
		end
	end
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
		gui_inrows= gui_input_scrollpane.add({type = "table", name = "marc_inrows", style = table_marc_style, column_count = 2 })
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
			build_gui_row(gui_inrows, name, scaled_count, rownum, machines_fed[name], unit_type, inout_data) 
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
		gui_outrows = gui_output_scrollpane.add({type = "table", name = "marc_outrows", style = table_marc_style, column_count = cols })
		
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
			local legit = build_gui_row(gui_outrows, name, scaled_count, rownum, machines[name], unit_type, inout_data)
			if legit	-- only add to row if unit_type is compatible with the item
			then
				local average_per_machine = count/machines[name]
				local scaled_average_per_machine = scale_rate(player, name, average_per_machine) -- multiplier*average_per_machine/divisor
				local label_name = "marc_machine_rate" .. rownum
				gui_outrows.add({type = "label", name = label_name, caption = string.format( persec_format,scaled_average_per_machine), tooltip={"marc-gui-tt-items-per-machine"} })						
				add_value_to_marcalc_clickable_list(inout_data, label_name, scaled_average_per_machine)

				-- add extra columns if an item appears in both inputs and outputs

				input_count = inout_data.inputs[name]
				if input_count ~= nil
				then
					local net_difference = (count - input_count)
					local net_count = scale_rate(player, name,net_difference)
					label_name = "marc_net_per_min" .. rownum
					gui_outrows.add({type = "label", name = label_name, caption = string.format( persec_format, net_count ), tooltip={"marc-gui-tt-net-rate"}})
					add_value_to_marcalc_clickable_list(inout_data, label_name, net_count)

					local net_machines = net_difference/average_per_machine
					label_name = "marc_net_machines" .. rownum
					gui_outrows.add({type = "label", name = label_name, caption = string.format( persec_format, net_machines  ), tooltip={"marc-gui-tt-net-machines"}})
					add_value_to_marcalc_clickable_list(inout_data, label_name, net_machines)
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

-- ----------------------------------------------------------------

-- show the gui with the rate calculations
local function open_gui(event, inout_data)


	local player = game.players[event.player_index]
	local root = get_gui_root(player)
	if root.marc_gui_top
	then
		root.marc_gui_top.destroy()
	end
	
	-- script.on_event(defines.events.on_tick, on_tick)
    
	write_marc_gui(player, inout_data)
end

-- ----------------------------------------------------------------

-- calculate the speed and productivity effects of a single module
local function calc_mod( modname, modeffects, modquant, effectivity )
	protoeffects = game.item_prototypes[modname].module_effects
	debug_print("mod is " .. modname .. " quantity " .. modquant)
	for effectname,effectvals in pairs(protoeffects)
	do
		-- debug_print("...effectname is " .. effectname .. " modquant " .. modquant)
		for _,bonamount in pairs(effectvals) -- first item in pair seems to be always "bonus"
		do
			-- debug_print("...effectname,bonix,bon " .. effectname ..  "," .. bonamount)
			if effectname == "speed"
			then
				-- debug_print("...adjust speed by " .. ( bonamount * modquant ))
				modeffects.speed = modeffects.speed + ( bonamount * modquant * effectivity)
			elseif effectname == "productivity"
			then
				-- debug_print("...adjust productivity by " .. ( bonamount * modquant ))
				modeffects.prod = modeffects.prod + (bonamount * modquant  * effectivity)
			end
		end

	end
end

-- ----------------------------------------------------------------

-- calculate the effects of all the modules in the entity
local function calc_mods(entity, modeffects, effectivity)
	modinv = entity.get_module_inventory()
	modcontents = modinv.get_contents()
	local ix = 1

	for modname,modquant in pairs(modcontents)
	do
		debug_print("calc_mods proto is " .. game.item_prototypes[modname].name)
		debug_print("calc_mods modname,modquant " .. modname .. "," .. modquant)
		
		calc_mod(modname, modeffects, modquant, effectivity)
		ix = ix + 1
	end 

	
	return modeffects
end


-- ----------------------------------------------------------------

local function print_bounding_box(name, b)
	debug_print(name .. " " .. b.left_top.x .. "," .. b.left_top.y .. " " .. b.right_bottom.x .. "," .. b.right_bottom.y)
end

-- ----------------------------------------------------------------
-- thanks to Psihuis for this one:

local function do_boxes_intersect(a, b)
    local a_left = a.left_top.x
    local a_right = a.right_bottom.x
    local a_top = a.left_top.y
    local a_bottom = a.right_bottom.y
    local b_left = b.left_top.x
    local b_right = b.right_bottom.x
    local b_top = b.left_top.y
    local b_bottom = b.right_bottom.y
    return (a_left < b_right and a_right > b_left) and (a_top < b_bottom and a_bottom > b_top)
end
-- ----------------------------------------------------------------

local function is_machine_in_range_of_beacon(entity, beacon)
	debug_print("is machine in range")
	local machine_selection_box = entity.prototype.selection_box
	local beac_dist = game.entity_prototypes[beacon.name].supply_area_distance
	
	-- debug_print("beac prot selbox" .. beacon.prototype.selection_box.left_top.x .. " - " .. beacon.prototype.selection_box.right_bottom.y )
	local beacsel_left = beacon.prototype.selection_box.left_top.x
	local beacsel_top = beacon.prototype.selection_box.left_top.y
	local beacsel_right = beacon.prototype.selection_box.right_bottom.x
	local beacsel_bottom = beacon.prototype.selection_box.right_bottom.y
	debug_print(beacsel_left .. " " .. beacsel_top .. " X " .. beacsel_right .. " " .. beacsel_bottom)

	debug_print(beacsel_left .. " " .. beacsel_top .. " X " .. beacsel_right .. " " .. beacsel_bottom)
	
	local beacon_left_top = {x = beacsel_left + beacon.position.x - beac_dist,
							y = beacsel_top + beacon.position.y - beac_dist}
							
	local beacon_right_bottom = {x = beacsel_right + beacon.position.x + beac_dist,
							y = beacsel_bottom + beacon.position.y + beac_dist}
	local beacon_box = { left_top = beacon_left_top, right_bottom = beacon_right_bottom }
	
	local machine_left_top = { x = entity.position.x + machine_selection_box.left_top.x,
								y = entity.position.y + machine_selection_box.left_top.y }
	local machine_right_bottom = { x = entity.position.x + machine_selection_box.right_bottom.x,
								y = entity.position.y + machine_selection_box.right_bottom.y }

	local machine_box = { left_top = machine_left_top, right_bottom = machine_right_bottom }
	-- print_bounding_box("             machine_box", machine_box)
	-- debug_print("..........")
	--print_bounding_box("             beacon_box ", beacon_box)
	-- debug_print(",,,,,,,,,,")


	local ans = do_boxes_intersect(beacon_box, machine_box)



	return ans
end


-- ----------------------------------------------------------------

max_beacon_dist = -1

-- calculate effects of beacons.  For our purposes, only speed effects count
local function check_beacons(surface, entity)
	
	local x = entity.position.x
	local y = entity.position.y

	
	if max_beacon_dist == -1
	then
		debug_print("beacon distance was -1 so look")
		for _,entity_proto in pairs(game.entity_prototypes)
		do
			
			if entity_proto.type == "beacon"
			then
				debug_print("found a beacon " .. entity_proto.name)
				local distance = game.entity_prototypes[entity_proto.name].supply_area_distance
				if distance > max_beacon_dist
				then
					max_beacon_dist = distance
				end
			end
		end
		-- max_beacon_dist = game.entity_prototypes["beacon"].supply_area_distance
		debug_print("beacon distance is " .. max_beacon_dist)
	end
	
	debug_print("check_beacons searching around " .. x .. "," .. y .. " beacon dist is " .. max_beacon_dist)
	machine_box = entity.prototype.selection_box
	debug_print("check_beacons box is " .. machine_box.left_top.x .. "," .. machine_box.left_top.y .. " thru " .. machine_box.right_bottom.x .. "," .. machine_box.right_bottom.y)
	modeffects = { speed = 0, prod = 0 }

	local beacons = 0
	local mods = 0

	-- assumes all beacons have same effect radius
	search_area = { { x + machine_box.left_top.x - max_beacon_dist, 	y + machine_box.left_top.y - max_beacon_dist }, 
				    { max_beacon_dist + x + machine_box.right_bottom.x, max_beacon_dist + y + machine_box.right_bottom.y }}
	debug_print(" upper left " .. 	x + machine_box.left_top.x - max_beacon_dist .. "," .. y + machine_box.left_top.y - max_beacon_dist)			    

	for _,beacon in pairs(surface.find_entities_filtered{ area=search_area, type="beacon"})
	do	
		debug_print("test a beacon")
		if is_machine_in_range_of_beacon(entity, beacon)
		then
			debug_print(" beacon area is " .. beacon.prototype.supply_area_distance .. " at " .. beacon.position.x .. "," .. beacon.position.y)
			beacons = beacons + 1	
			local effectivity = beacon.prototype.distribution_effectivity
			debug_print("effectivity is " .. effectivity)
			calc_mods( beacon, modeffects, effectivity)
		end
	end
	
	debug_print("check_beacons - Saw " .. beacons)
	
	return modeffects

end

-- ----------------------------------------------------------------

-- for an individual assembler, calculate the rates all the inputs are used at and the outputs are produced at, per second
local function calc_assembler(entity, inout_data, beacon_modeffects)

		local prodproto = game.entity_prototypes[entity.name]
		
		if false
		then
			if prodproto ~= nil and prodproto.allowed_effects ~= nil
			then
			debug_print(prodproto.name .. " type ".. prodproto.type )
				for thing,effect in pairs(prodproto.allowed_effects)
				do
					debug_print(entity.name .. " allowed_effect " .. prodproto.name .. " for " .. thing .. " is " .. boolstr(effect))
				end
			elseif prodproto ~= nil
			then
				debug_print( prodproto.name  .. " has no allowed_effects")
			else
				debug_print("bad proto")
			end
		end

	-- get the machines base crafting speed, in cycles per second
	local crafting_speed = entity.prototype.crafting_speed

	modeffects = { speed = 0, prod = 0 }
	local effectivity = 1
	modeffects = calc_mods(entity, modeffects, effectivity)

	-- adjust crafting speed based on modules and beacons
	local total_speed_effect = modeffects.speed + beacon_modeffects.speed
	if total_speed_effect < -0.80 -- no worse than 20%
	then
		total_speed_effect = -0.80
	end
	
	-- issue reported for Pyanodon's alien life mod says some machines don't have consumption and pollution
	-- in allowed effects.  I'm not seeing this in the prototype, nor in run-time tests, the fawogae plantations
	-- do have consumption included in allowed_effects, and the plantation's water consumption is affected by
	-- speed modules in beacons or in the plantation itself
	--
	-- consumption applies to energy?  Pyanodon seems to treat it as item inputs
 
	
	debug_print( "calc_assembler cspeed " .. crafting_speed .. " modspeed " .. modeffects.speed .. " beacon_modeffects.speed " .. beacon_modeffects.speed .. " total_speed_effect " .. total_speed_effect)

	crafting_speed = crafting_speed * ( 1 + total_speed_effect)
	-- how long does the item take to craft if no modules and crafting speed was 1?  It's in the recipe.energy!
	local recipe = get_entity_recipe(entity)
	crafting_time = recipe.energy
	
	debug_print("crafting time " .. crafting_time .. " modeffects.speed " .. modeffects.speed .. " beacon_modeffects.speed " .. beacon_modeffects.speed )
	
	if(crafting_time == 0)
	then
		crafting_time = 1
		debug_print("(entity.get_recipe() or entity.previous_recipe) .energy = 0, wtf?")
	end
	


	-- for all the ingredients in the recipe, calculate the rate
	-- they're consumed at.  Add to the inputs table.
	for _, ingred in ipairs(recipe .ingredients)
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
		debug_print(entity.name  .. " has fuel " .. fuel_name)
		fuel_proto = game.item_prototypes[fuel_name]
		debug_print("fuel value " .. fuel_proto.fuel_value)
	end
	]]--
	
	-- for all the products in the recipe (usually just one)
	-- calculate the rate they're produced at and add each product to the outputs
	-- table
	for _, prod in ipairs(get_entity_recipe(entity) .products)
	do
	    local chance
		local amount
		

		
		-- sometime in 0.17 factorio changed uranium recipe to use a probability value  * amount
		-- rather than probability with a range of amount_min and amount_max
		-- but some mods like Bob's Greenhouse still was using a range
	    if prod.probability ~= nil
	    then 
	    	debug_print("probability is " .. prod.probability)
	    	chance = prod.probability
	    	if prod.amount_min ~= nil
	    	then
	    	amount = chance * (prod.amount_min + prod.amount_max) / 2
	    	else
	    	   amount = prod.amount * chance
	    	end
	    else
	    	debug_print("probability is nil")
	    	chance = 1
	    	

			if prod.amount ~= nil
			then
				debug_print("prod amount, modeffects.prod " .. prod.name .. " " .. prod.amount .. "," .. modeffects.prod )
				amount = prod.amount 
			else
				amount =  (prod.amount_min + prod.amount_max) / 2
			end
    	
	    end	   
	

		-- gotta handle super beacons - they can affect prod too
		debug_print("calc_assembler " .. prod.name .. " amount " .. amount .. " modeffects " .. ( 1 + modeffects.prod) .. " cspeed " .. crafting_speed .. " crafting_time" .. crafting_time)
		local catalyst_amount = 0
		if prod.catalyst_amount ~= nil
		then
			catalyst_amount = prod.catalyst_amount
		end
		local productivity = modeffects.prod + beacon_modeffects.prod
		if productivity < 0
		then
			productivity = 0
		end
		amount =  amount + (amount - catalyst_amount) * productivity
		-- amount = amount * ( 1 + modeffects.prod + beacon_modeffects.prod) *  crafting_speed / crafting_time
		-- amount = amount * ( 1 + productivity) *  crafting_speed / crafting_time
		amount = amount * crafting_speed / crafting_time
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

-- ----------------------------------------------------------------

-- for an individual mining- drill, calculate the rates all the inputs are used at and the outputs are produced at, per second
local function calc_mining(entity, inout_data, beacon_modeffects, drilling_bonus)

	local x = entity.position.x
	local y = entity.position.y
	debug_log(__FUNC__(),"Found a drill")
	local prod = entity.mining_target
	if prod == nil
	then
		debug_log(__FUNC__(),"nil mining_target " .. x .. "," .. y)
		return
	end
	
	local prodproto = entity.mining_target.prototype
	local drillproto = entity.prototype
    
    printObj(prod)

    
	debug_log(__FUNC__(),"bse = " .. beacon_modeffects.speed)
	
	debug_log(__FUNC__(),"target is " .. prod.name .. " type " .. prod.type)
	debug_log(__FUNC__(),"target amount " .. prod.amount .. " normal amount " .. prodproto.normal_resource_amount)
	debug_log(__FUNC__(),"progress " .. entity.mining_progress .. " bonus " .. entity.bonus_mining_progress)
	debug_log(__FUNC__(),"speed " .. drillproto.mining_speed )
	-- get the machines base crafting speed, in cycles per second
	local mining_speed = entity.prototype.mining_speed
	local mining_power = 1 -- entity.prototype.mining_power

	
	
	local mining_time = prodproto.mineable_properties.mining_time
	local result_type = get_item_or_fluid(prodproto.name)
	
	debug_log(__FUNC__(),"result type is " .. result_type)
	
	modeffects = { speed = 0, prod = 0 }
	local effectivity = 1
	modeffects = calc_mods(entity, modeffects, effectivity)

	-- adjust crafting speed based on modules and beacons
	local total_speed_effect = modeffects.speed + beacon_modeffects.speed
	if total_speed_effect < -0.80 -- no worse than 20%
	then
		total_speed_effect = -0.80
	end
	debug_log(__FUNC__(), "calc_assembler cspeed " .. mining_speed .. " modspeed " .. modeffects.speed .. " beacon_modeffects.speed " .. beacon_modeffects.speed .. " total_speed_effect " .. total_speed_effect)

	mining_speed = mining_speed * ( 1 + total_speed_effect)

    local amount =  mining_speed / mining_time
    
    
  
    amount = amount* ( 1 + drilling_bonus + modeffects.prod + beacon_modeffects.prod)
    debug_log(__FUNC__(),"amount = amount* ( 1 +  drilling_bonus _modeffects.prod + beacon_modeffects.prod)")
    debug_log(__FUNC__(),amount.." = amount  * ( 1 +" ..drilling_bonus.. "+" ..  modeffects.prod.. " +" ..  beacon_modeffects.prod..")")
	  
    if result_type == "fluid"
    then	
    	local mining_yield = (prod.amount / prodproto.normal_resource_amount ) *100
		debug_log(__FUNC__(),"yield is " .. math.floor(mining_yield))
		mining_yield = math.min(mining_yield, 100)
	
        amount = amount *  mining_yield / 10     
        debug_log(__FUNC__(),amount .." = amount*  "..mining_yield )
 
    end
    
	if inout_data.outputs[prod.name] ~= nil
	then
		debug_log(__FUNC__(),"adding " .. amount .. " into " .. inout_data.outputs[prod.name])
		inout_data.outputs[prod.name] = inout_data.outputs[prod.name] + amount
		inout_data.machines[prod.name] = inout_data.machines[prod.name] + 1
	else
	    debug_log(__FUNC__(),"setting " .. prod.name .. " amount to " ..amount)
		inout_data.outputs[prod.name] = amount
		inout_data.machines[prod.name] =  1
	end

end

-- ----------------------------------------------------------------

-- player has selected some machines with our tool
script.on_event(defines.events.on_player_selected_area,
	function(event)
	
		-- leave if not our tool
		if event.item ~= "max-rate-calculator" 
		then
			return
		end
		
		find_belts()
		
		
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
			debug_print("Found entity " .. entity.name  )
			if entity.energy ~= nil
			then
				debug_print("Has energy " .. entity.energy )
			else
				debug_print("No energy")
			end
			
			if entity.type == "assembling-machine" or entity.type == "furnace"
			then		
				if get_entity_recipe(entity)  ~= nil
				then
					local beacon_modeffects = { speed = 0, prod = 0 }
					if entity.prototype.module_inventory_size > 0					
					then
						beacon_modeffects = check_beacons(surface, entity)
					else
						debug_print(" zero module_inventory_size")
					end
					debug_print("bse = " .. beacon_modeffects.speed)
					calc_assembler(entity, inout_data, beacon_modeffects)	
				else
					if entity.type == "assembling-machine"
					then
						no_recipe_assemblers = no_recipe_assemblers + 1
					else
						no_recipe_smelters = no_recipe_smelters + 1
					end
				end
			end
			
			-- 0.17 gives error "LuaEntityPrototype doesn't contain key mining_power."
			if entity.type == "mining-drill"
			then
				local beacon_modeffects = { speed = 0, prod = 0 }
			 	if entity.prototype.module_inventory_size > 0					
			 	then
			 		beacon_modeffects = check_beacons(surface, entity)
				end
				local drilling_bonus = player.force.mining_drill_productivity_bonus
				debug_print("drilling_bonus " .. drilling_bonus)
				calc_mining(entity, inout_data, beacon_modeffects, drilling_bonus)
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
		global.marc_inout_data_by_player = global.marc_inout_data_by_player or {}
		global.marc_inout_data_by_player[event.player_index] = inout_data
		global.marc_inout_data = inout_data
		
		-- now open and show the gui with the calculations
		open_gui(event, inout_data)
		
		-- throw away the max-rate-calculator item.  User never gets one in their inventory (unless they click hotkey and directly put it in inventory)
		local cursor_stack = player.cursor_stack
		cursor_stack.clear()

	end
)

-- ----------------------------------------------------------------

-- player hit the magic key, create our selection tool and put it in their hand
local function on_hotkey_main(event)

	init_selected_units(event.player_index)
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
	if player.cursor_stack ~= nil -- muppet9010 reported crash accessing nil cursor_stack here when player died
	then
		local cursor_stack = player.cursor_stack
		cursor_stack.clear()
		cursor_stack.set_stack({name="max-rate-calculator", type="selection-tool", count = 1})
	end


end


local function max_rate_shortcut(event)
	debug_print("Max Rate Shortcut")
	if event.prototype_name == "max-rate-shortcut"
	then
		on_hotkey_main(event)
    elseif event.prototype_name == "marc_calc_4func"
    then
    	local player = game.players[event.player_index]
    	toggle_calculator(player)
	end
end


-- ----------------------------------------------------------------

-- user has clicked somewhere.  If clicked on any gui item name that starts with "marc_..."
-- hide the gui
local function on_gui_click(event)
	local event_name = event.element.name
	debug_print("event_name " .. event_name)
	local marc_prefix = "marc_"
	local possible_marc_prefix = string.sub( event_name, 1, string.len(marc_prefix) )
	local player = game.players[event.player_index]
	local root = get_gui_root(player)
	
	local marcalc_prefix = "marcalc_"
	local possible_marcalc_prefix = string.sub( event_name, 1, string.len(marcalc_prefix))
	if possible_marcalc_prefix == marcalc_prefix
	then
		handle_marcalc_click(event_name, player)
		return
	end
	
	if global.marc_inout_data_by_player ~= nil
	then
		local inout_data = global.marc_inout_data_by_player[event.player_index]
		if inout_data ~= nil
		then
			-- debug_print("on_gui_click looking for " .. event_name .. " in clickable values")
			val = inout_data.clickable_values[event_name]
			if val ~= nil
			then
				-- debug_print("on_gui_click found " .. event_name .. " in clickable values. val = " .. val)
				marcalc_clickable_value_clicked(player, val)
				return
			end
		end
	end
	
	
	if possible_marc_prefix == marc_prefix
	then
		if event_name == "marc_calculator_button"
		then
			toggle_calculator(player)
			return
		end
	
		if root.marc_gui_top then
		    if event_name == "marc_close_button"
		    then
				destroy_marc_gui(player)
				hide_calculator(player)
			end
		elseif event_name == "marc_close_button"
		then

			if player.gui.left.marc_gui_top then
				player.gui.left.marc_gui_top.destroy()
				hide_calculator(player)
			end
		end

	end
end

-- ----------------------------------------------------------------

local function on_gui_selection(event)

	local event_name = event.element.name
	local player = game.players[event.player_index]
	local root = get_gui_root(player)
	


		
	if event_name == "maxrate_units"
	then
		local selected = root.marc_gui_top.marc_gui_upper.maxrate_units.selected_index
		global.marc_selected_units[event.player_index] = selected
		unit_entry = g_marc_units[selected]
		debug_print("selected " .. unit_entry.name .. " " .. unit_entry.multiplier .. "/" .. unit_entry.divisor)
		root.marc_gui_top.destroy()
		if global.marc_inout_data_by_player == nil -- by_player is new, may not exist in old save
		then
			open_gui(event, global.marc_inout_data)
		else
			open_gui(event, global.marc_inout_data_by_player[event.player_index])
		end
	end
end


-- ----------------------------------------------------------------

local function on_marc_command(event)

if event.parameter == "debug"
	then
		global.marc_debug = true
		debug_print("marc debugging is on")
	elseif event.parameter == "nodebug"
	then
		debug_print("marc debugging is off")
		global.marc_debug = false
	else
		game.players[event.player_index].print("unknown marc parameter: " .. event.parameter)
	end
end

-- ----------------------------------------------------------------

script.on_event( defines.events.on_gui_selection_state_changed, on_gui_selection )

script.on_event( "marc_hotkey", on_hotkey_main )

script.on_event( defines.events.on_lua_shortcut, max_rate_shortcut )

script.on_event( defines.events.on_gui_click, on_gui_click)

script.on_event( defines.events.on_gui_text_changed, marcalc_on_gui_text_changed )
 
commands.add_command( "marc", "Max Rate Calculator [ debug | nodebug ] ", on_marc_command )


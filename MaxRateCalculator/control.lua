-- control.lua
-- Max Rate Calculator mod for Factorio
--
-- This calculates max possible rates for a selected set of machines.
-- Does not compute actual running rates - see the Efficen-See mod for that
-- (from which I learned and borrowed)

-- string formats so numbers are displayed in a consistent way
local persec_format = "%16.3f"
local permin_format = "%16.1f"

local function build_gui_row(guirow, name, count, rownum)

	proto = game.item_prototypes[name]
	item_or_fluid = "item"
	if proto == nil
	then
		item_or_fluid = "fluid"
		proto = game.fluid_prototypes[name]
	end
	localized_name = proto.localised_name

	guirow.add({type = "sprite-button", sprite =  item_or_fluid .. "/" .. name, name = "marc_sprite" .. rownum, style = "sprite_obj_marc_style", tooltip = localized_name})
	guirow.add({type = "label", name = "marc_per_sec" .. rownum, caption = string.format(persec_format, count) })
	guirow.add({type = "label", name = "marc_per_min" .. rownum, caption = string.format(permin_format, count * 60) })

end


-- Puts the calculated info into a frame on the left side of the window
--
local function write_marc_gui(player, inputs, outputs)

	
	-- count input, output items and number in common between them
	local input_items = 0
	for input_name, input_count in pairs(inputs) 
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
	
	-- top gui is a vertical frame, with a label,and another frame ("marc_gui") underneath 
	player.gui.left.add({type = "frame", name = "marc_gui_top", direction = "vertical"})
	
	local marc_gui_top = player.gui.left.marc_gui_top
	marc_gui_top.add({type = "label", name="marc_top_label", caption={"marc-gui-top-label"}})
	local marc_gui = marc_gui_top.add({type = "frame", name = "marc_gui", direction = "horizontal", label = "Max Rates!!"})
	
	-- marc_gui contains two frames, one for inputs and one for outputs




	-- Input ingredients
	--
	if input_items > 0
	then
		-- frame to hold the rows of input items
		gui_input_frame = marc_gui.add({type = "frame", name = "marc_inputs", direction = "vertical", caption = {"marc-gui-inputs"}})
		
		-- three columns - item icon, rate per second, rate per minute
		gui_inrows= gui_input_frame.add({type = "table", name = "marc_inrows", style = table_marc_style, colspan = 3 })
		gui_inrows.style.column_alignments[2] = "right"	-- numbers look best right justified
		gui_inrows.style.column_alignments[3] = "right"
		
		-- column headers
		gui_inrows.add({type = "label", name="marc_placeholder", caption=""})
		gui_inrows.add({type = "label", name = "marc_header_per_sec", caption = {"marc-gui-persec"} })
		gui_inrows.add({type = "label", name = "marc_header_per_min", caption = {"marc-gui-permin"} })

		-- add a row for each input item, with sexy icon (sprite button), rate used per sec, rate used per minute
		local rownum = 1
		for input_name, input_count in pairs(inputs) 
		do
			build_gui_row(gui_inrows, input_name, input_count, rownum)
			rownum = rownum+1		
		end
	end
	
	-- Output products
	--
	if output_items > 0
	then
		gui_output_frame = marc_gui.add({type = "frame", name = "marc_outputs", direction = "vertical", caption = {"marc-gui-outputs"}})
		
		-- if there were items both consumed and produced, we'll have two more columns to show the net result
		if both_input_and_output_items > 0
		then
			cols = 5
		else
			cols = 3
		end
		gui_outrows = gui_output_frame.add({type = "table", name = "marc_outrows", style = table_marc_style, colspan = cols })
		
		-- right justify the numbers
		for i=1,cols
		do
			gui_outrows.style.column_alignments[i] = "right"
		end	
		
		-- column headers
		gui_outrows.add({type = "label", name="marc_placeholder", caption=""}) -- this goes where the widget is in the rows below
		gui_outrows.add({type = "label", name = "marc_header_per_sec", caption = {"marc-gui-persec"} })
		gui_outrows.add({type = "label", name = "marc_header_per_min", caption = {"marc-gui-permin"} })

		if both_input_and_output_items > 0
		then
			gui_outrows.add({type = "label", name = "marc_header_net_per_sec", caption = {"marc-gui-netsec"} })
			gui_outrows.add({type = "label", name = "marc_header_net_per_min", caption = {"marc-gui-netmin"} })
		end

		local rownum = 1
		for output_name, output_count in pairs(outputs) 
		do
			build_gui_row(gui_outrows, output_name, output_count, rownum)
			

			-- add extra columns if an item appears in both inputs and outputs
			input_count = inputs[output_name]
			if input_count ~= nil
			then
				gui_outrows.add({type = "label", name = "marc_net_per_sec" .. rownum, caption = string.format( persec_format, output_count - input_count) })
				gui_outrows.add({type = "label", name = "marc_net_per_min" .. rownum, caption = string.format( permin_format, (output_count - input_count)*60) })
			elseif both_input_and_output_items > 0
			then -- five column display, but this item doesn't have net info
				gui_outrows.add({type = "label", name = "marc_net_per_sec" .. rownum, caption = "" })
				gui_outrows.add({type = "label", name = "marc_net_per_min" .. rownum, caption = "" })
			end
			rownum = rownum+1
		end
	end

end

-- show the gui with the rate calculations
local function open_gui(event, inputs, outputs)

	local player = game.players[event.player_index]
	if player.gui.left.marc_gui_top
	then
		player.gui.left.marc_gui_top.destroy()
	end
	
	script.on_event(defines.events.on_tick, on_tick)
    
	write_marc_gui(player, inputs, outputs)
end

-- calculate the speed and productivity effects of a single module
local function calc_mod( ent, modeffects, modquant )
	protoeffects = mod.prototype.module_effects
	for effectname,effectvals in pairs(protoeffects)
	do
		-- game.print(" effectname is " .. effectname .. " modquant " .. modquant)
		for _,bonamount in pairs(effectvals) -- first item in pair seems to be always "bonus"
		do
			-- game.print(" effectname,bonix,bon " .. effectname ..  "," .. bonamount)
			if effectname == "speed"
			then
				-- game.print("adjust speed by " .. ( bonamount * modquant ))
				modeffects.speed = modeffects.speed + ( bonamount * modquant )
			elseif effectname == "productivity"
			then
				-- game.print("adjust productivity by " .. ( bonamount * modquant ))
				modeffects.prod = modeffects.prod + (bonamount * modquant )
			end
		end

	end
end

-- calculate the effects of all the modules in the entity
local function calc_mods(entity, modeffects)
	modinv = entity.get_module_inventory()
	modcontents = modinv.get_contents()

	local ix = 1

	for modname,modquant in pairs(modcontents)
	do
		-- game.print("calc_mods modname,modquant " .. modname .. "," .. modquant)
		mod = modinv[ix]
		
		calc_mod(mod, modeffects, modquant)
		ix = ix + 1
	end 
	
	return modeffects
end

-- calculate effects of beacons.  For our purposes, only speed effects count
local function check_beacons(surface, entity)
	
	local x = entity.position.x
	local y = entity.position.y
	
	-- game.print("check_beacons searching around " .. x .. "," .. y)
	modeffects = { speed = 0, prod = 0 }

	local beacons = 0
	local mods = 0
	-- we cheat here because we know the supply area of all beacons is the same.  Edge of assembler must be within 2 squares
	-- and assemblers are 3x3 ( so radius is 1.5 - round up to 2, plus 2 squares to beacon )
	-- this will break with beacon mods, and may need to revisit when we want to calculate smelters, centrifuges, etc.
	for _,beacon in pairs(surface.find_entities_filtered{ area= {{ x - 4, y - 4}, { x + 4, y + 4}}, type="beacon"})
	do	
		beacons = beacons + 1	
		calc_mods( beacon, modeffects, modquant)
	end

	-- another cheat here, beacons affect things by half.  There must be a field in the prototype for beacons for this number
	beacon_speed_effect = modeffects.speed * 0.5
	-- game.print("beacon_speed_effect " .. beacon_speed_effect .. " beacons " .. beacons .. " mods" .. mods)
	return beacon_speed_effect

end

-- for an individual assembler, calculate the rates all the inputs are used at and the outputs are produced at, per second
local function calc_assembler(entity, inputs, outputs, beacon_speed_effect)

	-- get the machines base crafting speed, in cycles per second
	local crafting_speed = entity.prototype.crafting_speed

	modeffects = { speed = 0, prod = 0 }
	modeffects = calc_mods(entity, modeffects)

	-- adjust crafting speed based on modules and beacons
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
		if inputs[ingred.name] ~= nil
		then
			inputs[ingred.name] = inputs[ingred.name] + amount
		else
			inputs[ingred.name] = amount
		end
	end
	
	-- for all the products in the recipe (usually just one)
	-- calculate the rate they're produced at and add each product to the outputs
	-- table
	for _, prod in ipairs(entity.recipe.products)
	do
		-- game.print("prod amount, modeffects.prod " .. prod.amount .. "," .. modeffects.prod )
		local amount
		if prod.amount ~= nil
		then
			amount = prod.amount 
		else
			-- handle if Product has probability not amount, like for centrifuges sometimes
			amount = prod.probability * (prod.amount_min + prod.amount_max) / 2
		end
		
		amount = amount * ( 1 + modeffects.prod) *  crafting_speed / crafting_time
		if outputs[prod.name] ~= nil
		then
			outputs[prod.name] = outputs[prod.name] + amount
		else
			outputs[prod.name] = amount
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
		
		local player = game.players[event.player_index]
		local surface = player.surface
		
		local inputs = {}
		local outputs = {}
		-- for all the machines selected, calculate consumption/production rates.
		-- (note: beacons themselves don't need to be selected, if one is in range
		--  of a selected machine, it will be considered)
		for _, entity in ipairs(event.entities)
		do
			if entity.type == "assembling-machine"
			then
				-- game.print("Found entity " .. entity.name)
				if entity.recipe ~= nil
				then
					local beacon_speed_effect= check_beacons(surface, entity, beacon_speed_effect)
				
					calc_assembler(entity, inputs, outputs, beacon_speed_effect)
				end
			end
		end
		
		-- now open and show the gui with the calculations
		open_gui(event, inputs, outputs)
		
		-- throw away the max-rate-calculator item.  User never gets one in their inventory
		local cursor_stack = player.cursor_stack
		cursor_stack.clear()

	end
)

-- player hit the magic key, create our selection tool and put it in their hand
local function on_hotkey_main(event)
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

	if s == "marc_"
	then
		local player = game.players[event.player_index]
		if player.gui.left.marc_gui_top then
			player.gui.left.marc_gui_top.destroy()
		end

	end
end

script.on_event("marc_hotkey", on_hotkey_main)

script.on_event(defines.events.on_gui_click, on_gui_click)
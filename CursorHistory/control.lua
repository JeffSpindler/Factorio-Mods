-- CursorHistory_X.X.X/control.lua

global.curhist_debug = global.curhist_debug or false


curhist_max_num_in_history_list = 6


ignore_list = ignore_list or { "blueprint", "blueprint-book", "deconstruction-planner", "max-rate-calculator"}
-- ----------------------------------------------------------------

local function boolstr(b)
	if b
	then
		return "TRUE"
	else
		return "FALSE"
	end
end

-- ----------------------------------------------------------------

function debug_print(str)
	if global.curhist_debug
	then
		game.print(str)
	end
end

-- ----------------------------------------------------------------

function sumstr(str)
	local sum = 0
	
	for i = 1, #str
	do		
		sum = sum + string.byte(str, i)
		debug_print(i .. " sum now " .. sum)
	end
	return sum
end


-- ----------------------------------------------------------------


function checksum_blueprint(bp_item)
	if bp_item.is_blueprint_setup()
	then
		local 	checksum = 0
		local bp_entities = bp_item.get_blueprint_entities()
		if bp_item.label
		then
			checksum = sumstr(bp_item.label)
		end
		for _, entity in ipairs(bp_entities)
		do
			local pos = entity.position
			local x = pos.x
			local y = pos.y
			local dir = 0
			if entity.direction ~= nil
			then
				dir = entity.direction
			end
			checksum = checksum + entity.entity_number + dir + x + y + sumstr(entity.name)
			debug_print(entity.entity_number .. " name " .. entity.name .. " position " .. x .. "," .. y .. " dir " .. dir .. " sum " .. checksum)

		end
	end
end

-- ----------------------------------------------------------------

local function player_history(player_index)
	global.curhist_player_history = global.curhist_player_history or {}
	if global.curhist_player_history[player_index] == nil
	then
		global.curhist_player_history[player_index] = { scrolling=false, list={}, position=0 }	
	end
	
	return global.curhist_player_history[player_index]
end

-- ----------------------------------------------------------------

local function update_gui(player)

	if player.gui.top.curhist_main == nil or
		player.gui.top.curhist_main.curhist_top == nil
	then
		return
	end
	
	if player.gui.top.curhist_main.curhist_top.curhist_icon_list ~= nil
	then
		player.gui.top.curhist_main.curhist_top.clear()
	end
	
	local gui1 = player.gui.top.curhist_main.curhist_top.add(
				{
				type = "flow", 
				name = "curhist_icon_list", 
				direction = "vertical"
				})
	local history = player_history(player.index)
	if #history.list > 0
	then	
		if history.position == 0
		then
			gui1.add({type = "sprite", 
					name = "curhist_button_nert", 											
					style = "curhist_sprite_nert_style",
			sprite = "curhist_nert_sprite"})
		end
		for k,v in ipairs(history.list)
		do		
			gui1.add({type = "sprite-button", 
						name = "curhist_button".. k, 											
						style = "curhist_sprite_act_style",
						sprite = "item/" .. v.name})
			if k == history.position
			then
						gui1.add({type = "sprite", 
									name = "curhist_button_nert", 											
									style = "curhist_sprite_nert_style",
						sprite = "curhist_nert_sprite"})
			end
		end
	end
end

-- ----------------------------------------------------------------

local function same_item(fred, ethel)
	if fred.name == ethel.name
	then
		return true
	else
		return false
	end

end

-- ----------------------------------------------------------------

local function add_to_history(player, history,thing)

	
	local previous_thing_name = ""
	local which_to_remove = -1
	
	if #history.list >= curhist_max_num_in_history_list
	then
		which_to_remove = 1
	end
	
	if #history.list > 0
	then		
		for i,entry in ipairs(history.list)
		do
--			if i ~= 1 -- ok to push first thing off list if same
--			then
				previous_thing = history.list[i]
				if previous_thing ~= nil
				then
					if same_item(previous_thing, thing)
					then
						which_to_remove = i
					end
				end
--			end
		end
	end
	

	if which_to_remove > 0
	then
		table.remove(history.list,which_to_remove)
	end
	table.insert(history.list, thing)
	debug_print("add_to_history added " .. thing.name)
	history.position = #history.list
	update_gui(player)
		
end

-- ----------------------------------------------------------------

local function should_ignore_this(name)
	for _,ignore_me in ipairs(ignore_list)
	do
		if ignore_me == name
		then
			return true
		end
	end

	return false
end


-- ----------------------------------------------------------------

local function on_player_cursor_stack_changed(event)

	global.curhist_bp_next_id = global.curhist_bp_next_id or 4000

	local player = game.players[event.player_index]

--[[
	game.print("check the button")
	if player.gui.top.curhist_toggle_button == nil
	then
		game.print("force start")
		init_players()
	end
]]--	
	
	local cursor_stack = player.cursor_stack
	local history = player_history(event.player_index)
	if not cursor_stack.valid or not cursor_stack.valid_for_read -- not valid_for_read occurs when Q clears cursor
	then
		if #history.list > 0
		then
			history.position = #history.list
			update_gui(player)
		else
			history.position = 0
		end
		history.scrolling = false

		debug_print("scrolling now off")
		return
	end

	local name = cursor_stack.name
	debug_print("player cursor stack changed - " .. name)
	
	if should_ignore_this(name)
	then
		return
	end
		
	if not history.scrolling
	then
		local thing = { name=cursor_stack.name }
		global.curhist_source = "(unknown)"
		add_to_history(player, history, thing)
	end
end

-- ----------------------------------------------------------------

local function quantity_in_player_quickbar_inventory(player_index, name)

	local player = game.players[player_index]
	inventory = player.get_inventory(defines.inventory.player_quickbar)
	if inventory == nil	then return 0	end
	count = inventory.get_item_count(name)
	debug_print("quantity_in_player_quickbar_inventory " .. count .. " name " .. name)
	return count
end

-- ----------------------------------------------------------------

local function quantity_in_player_main_inventory(player_index, name)

	local player = game.players[player_index]
	inventory = player.get_inventory(defines.inventory.player_main)
	if inventory == nil	then return 0	end
	count = inventory.get_item_count(name)
	debug_print("quantity_in_player_main_inventory " .. count .. " name " .. name)
	return count
end

-- ----------------------------------------------------------------

local function quantity_in_player_inventory(player_index, name)

	return 
		quantity_in_player_quickbar_inventory(player_index, name) +
		quantity_in_player_main_inventory(player_index, name)
	
end

direction_forwards = 1
direction_backwards = -1


-- ----------------------------------------------------------------

local function select_history_item(player, history, direction)
	
	local pos = history.position
	history.scrolling = true	
	
	debug_print("on_hotkey_main scrolling was " .. boolstr(history.scrolling) .. " pos " .. pos .. " len " .. #history.list .. " dir " .. direction)
	
	if direction == direction_forwards
	then
		if pos == #history.list
		then
			debug_print("on_hotkey_main past the end of the list")
			return	
		end
		history.position = pos + 1
		pos = history.position
	elseif direction == direction_backwards
	then
		debug_print(" compare " .. pos .. " with 1")
		if pos == 0
		then
			debug_print("on_hotkey_main past the beginning of the list")
			return	
		end
		history.position = pos - 1
	end
	
	
	update_gui(player)
	
	debug_print("on_hotkey_main pos is " .. pos)
	local thing = history.list[pos]
	current_name = thing.name

	debug_print("on_hotkey_main at " .. current_name)
	count = quantity_in_player_inventory(player.index, current_name)
	if count > 0
	then
		cursor_stack = player.cursor_stack
		if cursor_stack == nil
		then
			debug_print("cursor stack is nil?")
			return
		end
		local proto = game.item_prototypes[current_name]
		debug_print("on_hotkey_main count " .. count .. " proto size " .. proto.stack_size)
		if count > proto.stack_size
		then
			-- count = count % proto.stack_size
			-- if count == 0 then count = proto.stack_size end
			
			count = proto.stack_size
		end
		debug_print("on_hotkey_main count now " .. count )
		local new_stack = {  name = current_name, count = count  }
		
		
		local old_items
		local old_source = "blurk"
		
		if cursor_stack.valid_for_read
		then
			old_items = { name=cursor_stack.name, count=cursor_stack.count }
			old_source = global.curhist_source
		end
		
		if cursor_stack.can_set_stack(new_stack)
		then
			debug_print("set it")
			cursor_stack.set_stack(new_stack)
			local inventory
			local source
			if quantity_in_player_quickbar_inventory(player.index, current_name) > 0
			then
				inventory = player.get_inventory(defines.inventory.player_quickbar)
				source = "quickbar"
			else	
				inventory = player.get_inventory(defines.inventory.player_main)
				source = "main"
			end
			global.curhist_source = source
			inventory.remove(new_stack)				
		else
			debug_print("can't set stack")
		end
		
		if old_items ~= nil
		then
			debug_print(" put " .. old_items.name .. " " .. old_items.count .. " back" )
			if old_source == nil
			then
				debug_print("old_source is nil, WTF?")
				old_source = "main"
			end
			
			local main_inventory = player.get_inventory(defines.inventory.player_main)
			local quickbar_inventory = player.get_inventory(defines.inventory.player_quickbar)
			if old_source == "main"
			then
				inventory = main_inventory
				debug_print("os main")
			elseif old_source == "quickbar"
			then
				debug_print("os qb")
				inventory = player.get_inventory(defines.inventory.player_quickbar)
			else
				-- unknown   Try to put in quickbar first
				inventory = player.get_inventory(defines.inventory.player_quickbar)
			end
			 -- convert to SimpleItemStack
			if inventory.can_insert(old_items)
			then
				local actually_insertered_count = inventory.insert(old_items)
				debug_print(" actually put " .. actually_insertered_count .. " back to inventory source " .. old_source)
			elseif main_inventory.can_insert(old_items)
			then
				local actually_insertered_count = main_inventory.insert(old_items)
				debug_print(" actually put " .. actually_insertered_count .. " back to main inventory")
			elseif quickbar_inventory.can_insert(old_items)
			then
				local actually_insertered_count = quickbar_inventory.insert(old_items)
				debug_print(" actually put " .. actually_insertered_count .. " back to quickbar inventory")
			else
				game.players[player.index].print("Can't put cursor item back into inventory")
			end
		else
			debug_print("old_items was nil")
		end
	end
end

-- ----------------------------------------------------------------

local function on_hotkey_main(event)
	debug_print("curhist hotkey")
	local player = game.players[event.player_index]
		
	history = player_history(event.player_index)
	if history.list == nil then return end
	if #history.list == 0 then return end
	select_history_item(player, history, direction_backwards)

end

-- ----------------------------------------------------------------

local function print_history_list(player_index)

	local history = player_history(player_index)
	debug_print("Cursor History")
	if history == nil
	then
		debug_print("   nil")
		return
	end

	if history.list == nil
	then
		debug_print("   list nil")
		return
	end

	debug_print("   position " .. history.position)
	
	if #history.list == 0
	then
		debug_print("   list empty")
	end
	
	for i,thing in ipairs(history.list)
	do
		local nert = " "
		if i == history.position then nert = ">" end
		if thing.name == nil
		then
			debug_print("   " .. nert .. i .. ": " .. "nil???")
		else
			debug_print("   " .. nert .. i .. ": " .. thing.name)
		end
	end

end

-- ----------------------------------------------------------------

local function on_hotkey_back(event)

	local player = game.players[event.player_index]

	history = player_history(event.player_index)
	if history.list == nil then return end
	if #history.list == 0 then return end
	select_history_item(player, history, direction_forwards)
end

-- ----------------------------------------------------------------

local function clear(player_index)
	global.curhist_player_history = global.curhist_player_history or {}
	
	global.curhist_player_history[player_index] = { scrolling=false, list={}, position=0 }	
end

-- ----------------------------------------------------------------

local function on_curhist_command(event)

	if event.parameter == "clear"
	then
		clear(event.player_index)
	elseif event.parameter == "list"
	then
		print_history_list(event.player_index)
	elseif event.parameter == "debug"
	then
		global.curhist_debug = true
		debug_print("curhist debugging is on")
	elseif event.parameter == "nodebug"
	then
		debug_print("curhist debugging is off")
		global.curhist_debug = false
	else
		game.players[event.player_index].print("unknown curhist parameter: " .. event.parameter)
	end
end

-- ----------------------------------------------------------------

local function build_gui(player)
	local gui0 = player.gui.top.curhist_main.add({type = "frame", name = "curhist_top", direction = "vertical"})
	local gui1 = gui0.add({type = "flow", name = "curhist_icon_list", direction = "vertical"})
	update_gui(player)
end

-- ----------------------------------------------------------------

local function close_gui(player)
	if player.gui.top.curhist_main.curhist_top then
		player.gui.top.curhist_main.curhist_top.destroy()
	end
end

-- ----------------------------------------------------------------

local function build_bar( player, reset )

	if reset and player.gui.top.curhist_main then 
		player.gui.top.curhist_main.destroy()
	end

	if player.gui.top.curhist_main == nil then
		local curhist_main = player.gui.top.add({type = "flow", name = "curhist_main", direction = "vertical"})
		curhist_main.add(
			{
			type = "sprite-button", 
			name = "curhist_toggle_button", 
			tooltip = "toggle history - localize this", 
			style = "curhist_sprite_act_style",
			sprite = "curhist_toggle_sprite"
			})
		build_gui(player) 	-- start out with history list unfurled
	end
end

-- ----------------------------------------------------------------

local function init_player(player)
	build_bar(player, false)
end

local function init_players()
	for _, player in pairs(game.players) do
		init_player(player)
	end
end


-- ----------------------------------------------------------------

curhist_started = false

local function start()
	if not curhist_started
	then
		init_players()
		curhist_started = true
	end
end

-- ----------------------------------------------------------------

local function on_init()
	start()
end


script.on_init(on_init)

-- ----------------------------------------------------------------

local function on_player_created(event)

	debug_print("Player " .. event.player_index .. " created ")
	local player = game.players[event.player_index]
	if player.gui.top.curhist_main == nil
	then
		game.print("init player")
		init_player(player)
	end
end

-- ----------------------------------------------------------------

local function on_gui_click(event)
	local player = game.players[event.player_index]
	local event_name = event.element.name
	local prefix = string.sub(event_name,1,14)
	local suffix = string.sub(event_name,15) 
	
	
	debug_print( "on_gui_click " ..  player.name ..  " " .. event_name )
	debug_print( "on_gui_click " ..  prefix ..  "/" .. suffix )
	
	if event_name == "curhist_toggle_button" then -- main bar button
		if player.gui.top.curhist_main.curhist_top == nil then
			build_gui(player)
			-- update_gui(player,true,true)
		else
			close_gui(player)
		end
	elseif prefix == "curhist_button"
	then
		local history = player_history(event.player_index)
		history.position = tonumber(suffix)
		select_history_item(player, history,0)
		history.scrolling = false
	end
end

-- ----------------------------------------------------------------

local function on_configuration_changed(event)
	debug_print("on_configuration_changed")
end

-- ----------------------------------------------------------------

local function on_player_mined_item(event)
	debug_print("on_player_mined_item " .. event.item_stack.name)
	local player = game.players[event.player_index]
	local thing = { name=event.item_stack.name }
	local history = player_history(event.player_index)
	add_to_history(player, history, thing)
end

-- ----------------------------------------------------------------
-- ----------------------------------------------------------------

script.on_configuration_changed(on_configuration_changed)

script.on_event(defines.events.on_player_created, on_player_created)


script.on_event(defines.events.on_player_cursor_stack_changed, on_player_cursor_stack_changed)

script.on_event("curhist_hotkey", on_hotkey_main)

script.on_event("curhist_back_hotkey", on_hotkey_back)

script.on_event(defines.events.on_gui_click, on_gui_click)

script.on_event(defines.events.on_player_mined_item, on_player_mined_item)

commands.add_command("curhist", "Cursor History mod special functions - [ list | clear | ", on_curhist_command)



-- script.on_event(defines.events.on_player_main_inventory_changed, on_player_main_inventory_changed)
-- Event Handler for on_built_entity and on_robot_built_entity
--
-- powered-floor-taps are normal entities (like a stubby electric-pole) except
-- they auto connect both control wires to neighboring powered floor taps and widgets
function BuiltEntity(event)
    -- game.print("BuiltEntity " .. event.created_entity.name)

    if event.created_entity.name == "powered-floor-tap"
    then    
        local pf_entity = event.created_entity
        local surface = pf_entity.surface
        IncludeControlWiresToNeighbors( pf_entity, surface )
    end
end


-- Event Handler for on_player_built_tile
--
-- Add the widget
function PlayerBuiltTile(event)
    -- game.print("PlayerBuiltTile")
    local player = game.players[event.player_index]
    if player ~= nil and event.tiles ~= nil and player.surface ~= nil
    then
    	IncludePoweredWidget(event.tiles, player.surface )
    elseif player == nil
    then
    	game.print("PlayerBuiltTile nil player?")
    elseif event.tiles == nil
    then
    	game.print("PlayerBuiltTile nil positions?")
    elseif player.surface == nil
    then
    	game.print("PlayerBuiltTile nil surface?")
    end
    
end

-- Event Handler for on_robot_built_tile
--
-- Add the widget
function RobotBuiltTile(event)
    -- game.print("RobotBuiltTile")
    if(event.robot ~= nil and event.robot.surface ~= nil)
    then 
       IncludePoweredWidget(event.tiles, event.robot.surface)
    end

end

-- returns whether some_entity should be connected with a control wire
function EntityConnectable(some_entity)
	local connectable
	
	-- if we want to connect control wires to everything that takes them:
	--[[connectable = 
	   (some_entity.prototype.max_circuit_wire_distance ~= nil and 
		some_entity.prototype.max_circuit_wire_distance ~= 0) or
	   (some_entity.prototype.max_wire_distance ~= nil and 
	some_entity.prototype.max_wire_distance ~= 0) ]]--
    
   
   return some_entity.name == "powered-floor-tap" or some_entity.name == "powered-floor-circuit-widget"

end


-- connect red and green wires from a powered floor tap or widget to another entity if appropriate
function IncludeControlWires(pf_entity, some_entity)

    -- game.print("IncludeControlWires some_entity.name=" .. some_entity.name)
    
    connectable = EntityConnectable(some_entity)
    if connectable
    then
        -- game.print("IncludeControlWires connecting neighbor with control wires " 
        -- 	.. pf_entity.position.x .. "," .. pf_entity.position.y .. " to "
        -- 	.. some_entity.position.x .. "," .. some_entity.position.y  )
        	
        target = { wire = defines.wire_type.green, target_entity = some_entity }
        pf_entity.connect_neighbour(target)
        
		target = { wire = defines.wire_type.red, target_entity = some_entity }
		pf_entity.connect_neighbour(target)

    else
    	-- game.print("IncludeControlWires not connectable")
    end
end

-- for all neighboring entities, connect control wires (if appropriate)
function IncludeControlWiresToNeighbors(pf_entity, surface)
	local X = pf_entity.position.x 
	local Y = pf_entity.position.y  
	-- game.print("IncludeControlWiresToNeighbors looking around " .. X .. "," .. Y)
	elist = surface.find_entities_filtered{ area={{X-1.0, Y-1.0}, {X+1.0, Y+1.0}} }
	
	for i, other_entity in ipairs(elist)
	do
		-- game.print("IncludeControlWiresToNeighbors found entity " .. other_entity.name .. " type " .. other_entity.type .. " at " .. other_entity.position.x .. "," .. other_entity.position.y)

		if( other_entity.position.x == X and other_entity.position.y == Y  )
		then
			-- game.print("IncludeControlWiresToNeighbors that's me")
		else
			-- game.print("IncludeControlWiresToNeighbors found entity at " .. other_entity.position.x .. "," .. other_entity.position.y)
			IncludeControlWires(pf_entity,other_entity )
		end
	end
end

-- when adding tiles, include a hidden widget which has power wires
-- if it's a circuit tile, add the circuit wires too
function IncludePoweredWidget(tiles, surface)
	-- game.print("IncludePoweredWidget")


	for i, oldtile in ipairs(tiles)
	do
		local position = oldtile.position
		-- game.print("IncludePoweredWidget x " .. position.x .. " y " .. position.y )
		local currentTile = surface.get_tile(position.x,position.y)

		local currentTilename = surface.get_tile(position.x,position.y).name

		local X = position.x
		local Y = position.y

		-- game.print("IncludePowered tilename is " .. currentTilename .. " at " .. X .. "," .. Y)

		if 
		currentTilename == "powered-floor-circuit-tile" or
		currentTilename == "powered-floor-tile"
		then    
			if( currentTilename == "powered-floor-circuit-tile" )
			then
				widget_name = "powered-floor-circuit-widget"
			else
				widget_name = "powered-floor-widget"
			end
			-- game.print("IncludePowered add " .. widget_name)
			pf_entity = surface.create_entity{name = widget_name, position = {X,Y}, force = game.forces.neutral}
			pf_entity.destructible = false

			if currentTilename == "powered-floor-circuit-tile"
			then
				IncludeControlWiresToNeighbors( pf_entity, surface )
			end
		end
	end
end




script.on_event(defines.events.on_player_built_tile,	PlayerBuiltTile)
script.on_event(defines.events.on_robot_built_tile, 	RobotBuiltTile)
script.on_event(defines.events.on_built_entity, 		BuiltEntity)
script.on_event(defines.events.on_robot_built_entity, 	BuiltEntity)

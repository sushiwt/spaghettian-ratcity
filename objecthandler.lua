local objecthandler = {}

-- Object Functions
function objecthandler.createObject(iType, iState, iTexture, ix, iy, iz) 
	return {
		type = iType,
		state = iState,
		texture = iTexture,
		x = ix,
		y = iy,
		z = iz,
		distance = 0
	}
end

function objecthandler.updateObject(objects_table, player_object, render_object)
	-- The render_object parameter is temporary. 
	-- It's used to check if the object is on the center, but I want to find a better
	-- way to aim at enemies
	local ordered_objects = {}

	for index, value in ipairs(objects_table) do

		local object_x = objects_table[index].x - player_object.x
		local object_y = objects_table[index].y - player_object.y
		
		local CS = math.cos(player_object.angle)
		local SS = -math.sin(player_object.angle)
		
		local a = object_y * CS + object_x * SS
		local b = object_x * CS - object_y * SS
		object_y = b
		
		local epsilon = 0.1

		object_x = (a * (render_object.width / 1.4) / (object_y + 1))+(render_object.width/2)

		local bounds = 12

		local object_size = 16 
		local scale = (object_size * render_object.height / (b + epsilon))

		if objects_table[index].type == "pickup" then
			if objects_table[index].state == 1 then
				if player_object.x < objects_table[index].x + bounds and
					player_object.x > objects_table[index].x - bounds and
					player_object.y < objects_table[index].y + bounds and
					player_object.y > objects_table[index].y - bounds then
					objects_table[index].state = 0
				end
			end
		elseif objects_table[index].type == "enemy" then
			if objects_table[index].state == 1 then
				if objects_table[index].x > player_object.x then
					objects_table[index].x = objects_table[index].x - 0.1
				end
				if objects_table[index].x < player_object.x then
					objects_table[index].x = objects_table[index].x + 0.1
				end
				if objects_table[index].y > player_object.y then
					objects_table[index].y = objects_table[index].y - 0.1
				end
				if objects_table[index].y < player_object.y then
					objects_table[index].y = objects_table[index].y + 0.1
				end
			end

			if player_shoot and render_object.center_width > object_x - scale / 2 and render_object.center_width < object_x + scale / 2 and b < render_object.depth[math.floor(#render_object.depth / 2)]then
				objects_table[index].state = 0
			end
			player_shoot = false
		end	
		
		local order_index = 1 --432432423
		
		for i, v in ipairs(ordered_objects) do 
			if v.distance <= b then 
				break
			end 
			order_index = order_index + 1 
		end

		value.distance = b 
		
		table.insert(ordered_objects, order_index, value)
	end

	return ordered_objects
end

return objecthandler
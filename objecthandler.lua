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
	}
end

function objecthandler.updateObject(objects_table, player_object, render_object)
	-- The render_object parameter is temporary. 
	-- It's used to check if the object is on the center, but I want to find a better
	-- way to aim at enemies
	for index, value in ipairs(objects_table) do
		local object_x = objects_table[index].x - player_object.x
		local object_y = objects_table[index].y - player_object.y
		
		local CS = math.cos(player_object.angle)
		local SS = -math.sin(player_object.angle)
		
		local a = object_y * CS + object_x * SS

		object_x = (a * (render_object.width / 1.4) / (object_y + 1))+(render_object.width/2)

		local bounds = 12

		if objects_table[index].type == 1 then
			if objects_table[index].state == 1 then
				if player_object.x < objects_table[index].x + bounds and
					player_object.x > objects_table[index].x - bounds and
					player_object.y < objects_table[index].y + bounds and
					player_object.y > objects_table[index].y - bounds then
					objects_table[index].state = 0
				end
			end
		elseif objects_table[index].type == 2 then
			if objects_table[index].state == 1 then
				if objects_table[index].x > player_object.x then
					objects_table[index].x = objects_table[index].x - 0.01
				end
				if objects_table[index].x < player_object.x then
					objects_table[index].x = objects_table[index].x + 0.01
				end
				if objects_table[index].y > player_object.y then
					objects_table[index].y = objects_table[index].y - 0.01
				end
				if objects_table[index].y < player_object.y then
					objects_table[index].y = objects_table[index].y + 0.01
				end
			end

			if player_shoot and object_x > render_object.center_width - 20 and object_x < render_object.center_width + 20 then
				objects_table[index].state = 0
			end
			player_shoot = false
		end
	end
end

return objecthandler
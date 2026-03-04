local spritehandler = {}

-- Object Functions
function spritehandler.createSprite(iType, iState, iTexture, ix, iy, iz) 
	return {
		type = iType,
		state = iState,
		texture = iTexture,
		x = ix,
		y = iy,
		z = iz,
	}
end

function spritehandler.updateSprite(sprites_table, player_object, render_object)
	-- The render_object parameter is temporary. 
	-- It's used to check if the sprite is on the center, but I want to find a better
	-- way to aim at enemies
	for index, value in ipairs(sprites_table) do
		local sprite_x = sprites_table[index].x - player_object.x
		local sprite_y = sprites_table[index].y - player_object.y
		
		local CS = math.cos(player_object.angle)
		local SS = -math.sin(player_object.angle)
		
		local a = sprite_y * CS + sprite_x * SS

		sprite_x = (a * (render_object.width / 1.4) / (sprite_y + 1))+(render_object.width/2)

		local bounds = 12

		if sprites_table[index].type == 1 then
			if sprites_table[index].state == 1 then
				if player_object.x < sprites_table[index].x + bounds and
					player_object.x > sprites_table[index].x - bounds and
					player_object.y < sprites_table[index].y + bounds and
					player_object.y > sprites_table[index].y - bounds then
					sprites_table[index].state = 0
				end
			end
		elseif sprites_table[index].type == 2 then
			if sprites_table[index].state == 1 then
				if sprites_table[index].x > player_object.x then
					sprites_table[index].x = sprites_table[index].x - 0.01
				end
				if sprites_table[index].x < player_object.x then
					sprites_table[index].x = sprites_table[index].x + 0.01
				end
				if sprites_table[index].y > player_object.y then
					sprites_table[index].y = sprites_table[index].y - 0.01
				end
				if sprites_table[index].y < player_object.y then
					sprites_table[index].y = sprites_table[index].y + 0.01
				end
			end

			if player_shoot and sprite_x > render_object.center_width - 20 and sprite_x < render_object.center_width + 20 then
				sprites_table[index].state = 0
			end
			player_shoot = false
		end
	end
end

return spritehandler
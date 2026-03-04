-- Player File :)

-- Player properties
local player = {}

player.x = 64
player.y = 64
player.delta_x = 0
player.delta_y = 0
player.angle = math.pi / 2
player.speed = 1
player.speed_multiplier = 50

player.max_hp = 100
player.hp = 100

function player:updateControls(dt, level_object) 
	-- Player Movement
	
	-- Keyboard Turn
	if love.keyboard.isDown("left") then
		self.angle = self.angle - 0.05 * (dt * self.speed_multiplier)
		if self.angle < 0 then
			self.angle = self.angle + 2 * pi
		end
		self.delta_x = math.cos(self.angle) * self.speed
		self.delta_y = math.sin(self.angle) * self.speed
	end
	if love.keyboard.isDown("right") then
		self.angle = self.angle + 0.05 * (dt * self.speed_multiplier)
		if self.angle >= 2*pi then
			self.angle = self.angle - 2 * pi
		end
		self.delta_x = math.cos(self.angle) * self.speed
		self.delta_y = math.sin(self.angle) * self.speed
	end
	
	-- Mouse Turn
	
	if mouse_controls == true then
		self.angle = self.angle + ((love.mouse.getX() - 320) * 0.001) * (dt * self.speed_multiplier)
		if self.angle < 0 then
			self.angle = self.angle + 2 * pi
		end
		if self.angle >= 2*pi then
			self.angle = self.angle - 2 * pi
		end
		self.delta_x = math.cos(self.angle) * self.speed
		self.delta_y = math.sin(self.angle) * self.speed
		love.mouse.setPosition(320, 240)
	end
	
	
	-- Player Transform
	local player_boundary = 4
	
	local x_offset = 0
	if self.delta_x < 0 then x_offset = -player_boundary else x_offset = player_boundary end
	
	local y_offset = 0
	if self.delta_y < 0 then y_offset = -player_boundary else y_offset = player_boundary end
	
	local player_gridpos_x = self.x / level_object.cell_size
	local gridpos_add_xoffset = (self.x + x_offset) / level_object.cell_size
	local gridpos_sub_xoffset = (self.x - x_offset) / level_object.cell_size
	
	local player_gridpos_y = self.y / level_object.cell_size
	local gridpos_add_yoffset = (self.y + y_offset) / level_object.cell_size
	local gridpos_sub_yoffset = (self.y - y_offset) / level_object.cell_size
	
	
	if love.keyboard.isDown("up") or love.keyboard.isDown("w") then
		-- Checks if the offsets are within the bounds
		if gridpos_add_xoffset > 0 and gridpos_add_yoffset > 0 and gridpos_add_xoffset < level_object.columns and gridpos_add_yoffset < level_object.rows  then
			if level_object.walls[math.floor(player_gridpos_y) + 1][math.floor(gridpos_add_xoffset + 1)] == nil or level_object.walls[math.floor(player_gridpos_y) + 1][math.floor(gridpos_add_xoffset + 1)] == 0 then
				self.x = self.x + self.delta_x * (dt * self.speed_multiplier)
			end
			
			if level_object.walls[math.floor(gridpos_add_yoffset) + 1][math.floor(player_gridpos_x + 1)] == nil or level_object.walls[math.floor(gridpos_add_yoffset) + 1][math.floor(player_gridpos_x + 1)] == 0 then
				self.y = self.y + self.delta_y * (dt * self.speed_multiplier)
			end
		end
		-- self.x = self.x + self.delta_x * (dt * self.speed_multiplier)
		-- self.y = self.y + self.delta_y * (dt * self.speed_multiplier)
	end
	
	if love.keyboard.isDown("down") or love.keyboard.isDown("s") then
		if gridpos_sub_xoffset < level_object.columns and gridpos_sub_yoffset < level_object.rows and gridpos_sub_xoffset > 0 and gridpos_sub_yoffset > 0 then
			if level_object.walls[math.floor(player_gridpos_y) + 1][math.floor(gridpos_sub_xoffset + 1)] == 0 then
				self.x = self.x - self.delta_x * (dt * self.speed_multiplier)
			end
			if level_object.walls[math.floor(gridpos_sub_yoffset) + 1][math.floor(player_gridpos_x + 1)] == 0 then
				self.y = self.y - self.delta_y * (dt * self.speed_multiplier)
			end
		end
		-- self.x = self.x - self.delta_x * (dt * self.speed_multiplier)
		-- self.y = self.y - self.delta_y * (dt * self.speed_multiplier)
	end
	
	
	if love.keyboard.isDown("e") then
		-- Checks if the offsets are within the bounds
		if gridpos_add_xoffset < level_object.columns and gridpos_add_yoffset < level_object.rows and gridpos_add_xoffset > 0 and gridpos_add_yoffset > 0 then
			if level_object.walls[math.floor(player_gridpos_y) + 1]
			[math.floor(gridpos_add_xoffset + 1)] == 4 then
				level_object.walls[math.floor(player_gridpos_y) + 1]
				[math.floor(gridpos_add_xoffset + 1)] = 0
			end
			
			if level_object.walls[math.floor(gridpos_add_yoffset) + 1]
			[math.floor(player_gridpos_x + 1)] == 4 then
				level_object.walls[math.floor(gridpos_add_yoffset) + 1]
				[math.floor(player_gridpos_x + 1)] = 0
			end
		end
	end
end

return player
-- Spaghettian Ratcity v0.1.5

-- Code written and documented by sushiwt 
-- and based on the Raycaster tutorials by 3DSage :3

-- I say 'based' because even though the algorithms are the same, 
-- the language is completely different and I had to make modifications
-- to deal with how Lua handles code like arrays and math. 

-- made by sushiwt, 15-02-2026

-- meow :3

-- Math Lookups
pi = math.pi

-- Level properties
Level = {
	walls = {},
	floors = {},
	ceilings = {},
	rows = 0,
	columns = 0,
	wall_height = 30,
	cell_size = 32,
}
    
-- Player properties
Player = {
	x = 64,
	y = 64,
	delta_x = 0,
	delta_y = 0,
	angle = pi / 2,
	speed = 1,
	max_hp = 100,
	hp = 100
}

level_toggle = false
mouse_controls = true

-- Gun Settings
player_shoot = false

ui_offset_x = 0
ui_offset_y = 400


-- Map Textures
textures_image = love.image.newImageData("graphics/defaulttexture.png")
sky_image = love.image.newImageData("graphics/defaultsky.png")
sprites_image = love.image.newImageData("graphics/smiley.png")

-- UI Textures
shooter_image = love.graphics.newImage("graphics/lasershooter.png")
healthbar_image = love.graphics.newImage("graphics/uibar.png")
crosshair_image = love.graphics.newImage("graphics/crosshair.png")

-- Misc stuff
debug_number = 0
debug_number2 = 0
fps = 0
delta_time = 0


speed = 50 -- I already have a player speed ill remove this eventually
sprites = {}


-- Level initialization. 
level = "house1"
invalid_level = false

-- Game States
game_state = 1

-- Main Menus
menu_option = 0

-- For drawing the fps graph...
fps_graph = {0,0}
fps_point = 0


-- Render settings
Render = {
	width = 640,
	height = 480,
	center_width = 320,
	center_height = 240,
	dof_value = 16,
	fog = 0,
	quality = 8, -- Calculates how wide each segment of the screen would be for the rays
	field_of_view = 75, -- The amount of area the player can see
	depth = {} -- Contains each rays distance value for sprite occlusion
}

function Render:raycaster(player_object, level_object)
	local point_x, point_y, point_x_offset, point_y_offset, depth_of_field
	local distance = 0
	
	-- Calculates how many rays will be created based on the width of the window
	local ray_count = self.width / self.quality
	local starting_degree_offset = ray_count / 2
	
	-- Uses the player angle with the ray count and field of view
	-- to calculate the direction a single ray points to
	local ray_angle = self.fixRadians(player_object.angle - (((pi / 180) * (self.field_of_view / ray_count)) * starting_degree_offset))
	
	local wall_layer = {}
	local floor_layer = {}
	local ceiling_layer = {}

	-- Ray initialization + 3d Drawing
	for rays = 0, ray_count do 
		-- vertical and horizontal level texture number
		local ver_level_texture = 0
		local hor_level_texture = 0
		
		-- Creates the horizontal ray and its corresponding lines
		local pointed_horizontal_line = 0
		depth_of_field = 0
		
		-- The properties of the horizontal ray
		-- Horizontal point x and y refers to the nearest horizontal wall intersection.
		local horizontal_distance = 65536
		local horizontal_point_x = 0
		local horizontal_point_y = 0
		
		if ray_angle > pi then
			-- Calculates the horizontal line above the player needed to check the intersection
			pointed_horizontal_line = (math.floor(player_object.y / level_object.cell_size) * level_object.cell_size)
			
			-- Finds the point of intersection of the horizontal line and the player ray
			point_y = player_object.y - (player_object.y - pointed_horizontal_line)
			point_x = (player_object.y - pointed_horizontal_line) * math.tan(ray_angle - (pi/2)) + player_object.x
			
			-- Finds the point of intersection of the next horizontal line and the player ray
			point_y_offset = -level_object.cell_size
			point_x_offset = -point_y_offset * math.tan(ray_angle - (pi/2)) 
			
		elseif ray_angle < pi then
			-- Utilizes the horizontal line below the player
			pointed_horizontal_line = (math.floor(player_object.y / level_object.cell_size) * level_object.cell_size) + level_object.cell_size
			
			-- Finds the point of intersection of the horizontal line and the player ray
			point_y = player_object.y - (player_object.y - pointed_horizontal_line)
			point_x = (player_object.y - pointed_horizontal_line) * math.tan(ray_angle - (pi/2)) + player_object.x
			
			-- Finds the point of intersection of the next horizontal line and the player ray
			point_y_offset = level_object.cell_size 
			point_x_offset = -point_y_offset * math.tan(ray_angle - (pi/2)) 
			
		elseif ray_angle == 0 or ray_angle == pi then
			-- The horizontal line and player ray would be parallel, 
			-- so default the point to the player and refuse checking for intersections.
			point_x = player_object.x
			point_y = player_object.y
			depth_of_field = self.dof_value
		end
		
		-- Checks the intersections
		while depth_of_field < self.dof_value do
			-- Correlates the location the ray is currently intersecting with the array size.
			cell_x = math.floor(point_x / level_object.cell_size) 
			cell_y = math.floor(point_y / level_object.cell_size) 
			
			-- Checks if the intersections are within the bounds
			if cell_x < level_object.columns and cell_y < level_object.rows and cell_x > -1 and cell_y > 0 then
				-- Shifts the array to account for the bottom of the grid.
				if ray_angle < pi then
					cell_y = cell_y + 1
				end
				
				hor_level_texture = level_object.walls[cell_y][cell_x + 1] - 1
				
				-- Checks if ray is intersecting wall
				if level_object.walls[cell_y][cell_x + 1] > 0 then
					horizontal_point_x = point_x
					horizontal_point_y = point_y
					horizontal_distance = math.sqrt(math.pow(horizontal_point_y - player_object.y, 2) + math.pow(horizontal_point_x - player_object.x, 2))
					break
				end
				
			end
			
			-- The code normally breaks before these lines of code execute
			-- if there was an intersection within the point.
			-- This checks the next intersection
			point_x = point_x + point_x_offset
			point_y = point_y + point_y_offset
			depth_of_field = depth_of_field + 1
		end
		
		-- Creates the vertical ray and its corresponding lines
		local pointed_vertical_line = 0
		depth_of_field = 0
		
		-- The properties of the vertical ray
		-- Vertical point x and y refers to the nearest vertical wall intersection.
		local vertical_distance = 65536
		local vertical_point_x = 0
		local vertical_point_y = 0
		
		if ray_angle > pi/2 and ray_angle < (3*pi)/2 then
			-- Calculates the vertical line left of the player needed to check the intersection
			pointed_vertical_line = (math.floor(player_object.x / level_object.cell_size) * level_object.cell_size)
			
			-- Finds the point of intersection of the vertical line and the player ray
			point_x = player_object.x - (player_object.x - pointed_vertical_line)
			point_y = (player_object.x - pointed_vertical_line) * math.tan(-ray_angle) + player_object.y
			
			-- Finds the point of intersection of the next line and the player ray
			point_x_offset = -level_object.cell_size 
			point_y_offset = -point_x_offset * math.tan(-ray_angle) 
		elseif ray_angle < pi/2 or ray_angle > (3*pi)/2 then
			-- Calculates the vertical line right of the player needed to check the intersection
			pointed_vertical_line = (math.floor(player_object.x / level_object.cell_size) * level_object.cell_size) + level_object.cell_size
			
			-- Finds the point of intersection of the vertical line and the player ray
			point_x = player_object.x - (player_object.x - pointed_vertical_line)
			point_y = (player_object.x - pointed_vertical_line) * math.tan(-ray_angle) + player_object.y
			
			-- Finds the point of intersection of the next vertical line and the player ray
			point_x_offset = level_object.cell_size 
			point_y_offset = -point_x_offset * math.tan(-ray_angle) 
		elseif ray_angle == pi/2 or ray_angle == (3*pi)/2 then 
			-- The horizontal line and player ray would be parallel, 
			-- so default the point to the player and refuse checking for intersections.
			point_x = player_object.x
			point_y = player_object.y
			depth_of_field = self.dof_value
		end
		
		-- Checks the intersections
		while depth_of_field < self.dof_value do
			-- Correlates the location the ray is currently intersecting with the array size.
			cell_x = math.floor(point_x / level_object.cell_size) 
			cell_y = math.floor(point_y / level_object.cell_size) 
			
			-- Checks if the intersections are within the bounds
			if cell_x < level_object.columns and cell_y < level_object.rows and cell_x > 0 and cell_y > -1 then
				-- Shifts the array to account for the bottom of the grid.
				if ray_angle < pi/2 or ray_angle > (3*pi)/2 then
					cell_x = cell_x + 1
				end
				
				ver_level_texture = level_object.walls[cell_y + 1][cell_x] - 1
				
				-- Checks if ray is intersecting wall
				if level_object.walls[cell_y + 1][cell_x] > 0 then
					vertical_point_x = point_x
					vertical_point_y = point_y
					vertical_distance = math.sqrt(math.pow(vertical_point_y - player_object.y, 2) + math.pow(vertical_point_x - player_object.x, 2))
					break
				end
				
			end
			
			-- The code normally breaks before these lines of code execute
			-- if there was an intersection within the point.
			-- This checks the next intersection
			point_x = point_x + point_x_offset
			point_y = point_y + point_y_offset
			depth_of_field = depth_of_field + 1
		end

		-- Checks if the vertical or horizontal intersections
		-- are shorter. If they are, use that as the point of 
		-- intersection.
		
		-- Shading of the vertical and horizontal walls
		-- Vertical walls are dark
		local shade = 1
		local level_texture = 0;
		
		if vertical_distance < horizontal_distance then
			point_x = vertical_point_x
			point_y = vertical_point_y
			level_texture = ver_level_texture
			distance = vertical_distance
			shade = 0.7
		elseif horizontal_distance < vertical_distance then
			point_x = horizontal_point_x
			point_y = horizontal_point_y
			level_texture = hor_level_texture
			distance = horizontal_distance
		else 
			point_x = player_object.x
			point_y = player_object.y
			level_texture = 0
			distance = horizontal_distance
		end

		-- Fixes fisheye
		local cosine_angle = self.fixRadians(player_object.angle - ray_angle)
		distance = distance * math.cos(cosine_angle)
		
		-- 3D WALL DRAWINGS
		local line_height = (level_object.wall_height * self.height)/distance
		
		-- The numerator takes care of the line segment somethng important
		local texture_y_step = 32 / line_height 
		local texture_y_offset = 0
		
		if line_height > self.height then
			texture_y_offset = (line_height - self.height) / 2.0
			line_height = self.height
		end
		
		local line_offset = (self.center_height)-line_height/2
		
		if line_height > self.height then
			line_height = self.height
		end
		
		love.graphics.setLineWidth(self.quality)
		local starting_segment = rays*self.quality
		
		-- Draws the depth of each ray
		self.depth[rays + 1] = distance
		
		-- DRAW WALLS
		-- Add way to change texture size later. 32x32 is the size of the textures
		local texture_y = texture_y_offset * texture_y_step + (level_texture * 32)
		local texture_x = 0
		
		if shade == 1 then
			texture_x = math.floor(point_x / (level_object.cell_size / 32 )) % 32
			-- Flips the texture at the south
			if ray_angle < pi then texture_x = 31 - texture_x end
		else 
			texture_x = math.floor(point_y / (level_object.cell_size / 32 )) % 32
			-- Flips the texture at the south
			if ray_angle > pi/2 and ray_angle < (3*pi)/2 then texture_x = 31 - texture_x end
		end
		
		-- Resets the color before generating the strips
		love.graphics.setColor(1,1,1,1)
		
		-- A list of points to draw the wall strips.
		local wall_strip = {}

		-- A list of points to draw the floor and ceiling strips
		local floor_strip = {}
		local ceiling_strip = {}
		
		local fog_walls = 0
		if self.fog > 0 then
			fog_walls = math.min(1 - ((distance / 220) - (0.1 * self.fog)), 1)
			if fog_walls < 0 then
				fog_walls = 0
			end
		else 
			fog_walls = 1
		end
		
		-- TODO OPTIMIZE LATER HLY SHIT it sucks
		for line_y = 0, line_height do
			local r, g, b, a = 0,0,0,0

			if self.depth[rays+1] > 0 then
				r, g, b, a = textures_image:getPixel(math.floor(texture_x), math.floor(texture_y))
			end

			wall_strip[line_y + 1] = {starting_segment, line_offset + line_y, (r * fog_walls) * shade , (g * fog_walls) * shade, (b * fog_walls) * shade, a}
			texture_y = texture_y + texture_y_step
		end

		level_object.wall_height = 30 + debug_number2
		
		love.graphics.points(wall_strip)

		-- DRAW FLOORS
		-- Fix ground spacing later... based on the resolution the bigger it is the more it's 
		-- spaced out from the walls.
		local fisheye_floor_fix = math.cos(self.fixRadians(player_object.angle - ray_angle))
		local floor_ceiling_offset = (1.25 + ((0.006)*(self.height) - 1.2))*(level_object.wall_height*2.5) - 1 
		local floor_shade = 0.9
		
		local floor_strip_index = 0
		local ceiling_strip_index = 0
		
		for line_y = line_offset+line_height - 2, self.height do
			local ground_y = line_y - (self.height/2)
			local r, g, b, a = 0, 0, 0, 1
			local ground_texture_x = (player_object.x + math.cos(ray_angle) * (floor_ceiling_offset) * 32 / ground_y / fisheye_floor_fix) 
			local ground_texture_y = (player_object.y + math.sin(ray_angle) * (floor_ceiling_offset) * 32 / ground_y / fisheye_floor_fix) 

			-- Failsafe just in case it goes out of bounds
			if ground_texture_x < 0 then ground_texture_x = ground_texture_x % 32  end
			if ground_texture_y < 0 then ground_texture_y = ground_texture_y % 32 end
			if ground_texture_x / 32 > level_object.columns then ground_texture_x = ground_texture_x % 32 end
			if ground_texture_y / 32 > level_object.rows then ground_texture_y = ground_texture_y % 32 end
			
			local mp = level_object.floors[1 + math.floor(ground_texture_y / 32)][1 + math.floor(ground_texture_x / 32)]*32 -- The multiplier shifts the textures to account for the multiple textures
			if mp ~= nil then r, g, b, a = textures_image:getPixel(math.floor(ground_texture_x % 32), math.floor(ground_texture_y % 32) + mp)end
			
			if self.fog ~= 0 then
				floor_shade = math.min((line_y - self.center_height) * (self.fog * 2) / self.height, 1)
			else
				floor_shade = 0.9
			end
			
			floor_strip[floor_strip_index] = {starting_segment,line_y, r * floor_shade, g * floor_shade, b * floor_shade, a}
			floor_strip_index = floor_strip_index + 1
			
			mp = level_object.ceilings[1 + math.floor(ground_texture_y / 32)][1 + math.floor(ground_texture_x / 32)]*32
			
			if mp ~= nil and mp > 0 then
				r, g, b, a = textures_image:getPixel(math.floor(ground_texture_x % 32), math.floor(ground_texture_y % 32) + mp)
				-- love.graphics.setColor(r * floor_shade,g * floor_shade,b * floor_shade,a)
				-- love.graphics.points(starting_segment,(self.height) - line_y)
				ceiling_strip[ceiling_strip_index] = {starting_segment,(self.height) - line_y, r * floor_shade, g * floor_shade, b * floor_shade, a}
				ceiling_strip_index = ceiling_strip_index + 1
			end
			
		end

		-- Draws the level layer by layer
		love.graphics.points(floor_strip)
		love.graphics.points(ceiling_strip)
		
		-- Recalculates the ray angle for another added ray to span the field of view.
		ray_angle = self.fixRadians(ray_angle + ((pi / 180) * (self.field_of_view / ray_count)))
	end
end

-- Changes the radians to clamp it between 0 and 360 degrees
function Render.fixRadians(ra)
	if ra > 2*pi then
		ra = ra - (2*pi)
	end
	
	if ra < 0 then
		ra = ra + (2*pi)
	end
	
	return ra
end

-- Love2D Functions
function love.load(dt) 
    shooter_image:setFilter("nearest", "nearest")
    healthbar_image:setFilter("nearest", "nearest")
	if game_state == 1 then
		initializeGame()
	end
end

function love.update(dt)
	if game_state == 1 then
		-- Player Movement
		
		-- Keyboard Turn
		if love.keyboard.isDown("left") then
			Player.angle = Player.angle - 0.05 * (dt * speed)
			if Player.angle < 0 then
				Player.angle = Player.angle + 2 * pi
			end
			Player.delta_x = math.cos(Player.angle) * Player.speed
			Player.delta_y = math.sin(Player.angle) * Player.speed
		end
		if love.keyboard.isDown("right") then
			Player.angle = Player.angle + 0.05 * (dt * speed)
			if Player.angle >= 2*pi then
				Player.angle = Player.angle - 2 * pi
			end
			Player.delta_x = math.cos(Player.angle) * Player.speed
			Player.delta_y = math.sin(Player.angle) * Player.speed
		end
		
		-- Mouse Turn
		
		if mouse_controls == true then
			Player.angle = Player.angle + ((love.mouse.getX() - Render.center_width) * 0.001) * (dt * speed)
			if Player.angle < 0 then
				Player.angle = Player.angle + 2 * pi
			end
			if Player.angle >= 2*pi then
				Player.angle = Player.angle - 2 * pi
			end
			Player.delta_x = math.cos(Player.angle) * Player.speed
			Player.delta_y = math.sin(Player.angle) * Player.speed
			love.mouse.setPosition(Render.center_width,Render.center_height)
		end
		
		
		-- Player Transform
		local player_boundary = 4
		
		local x_offset = 0
		if Player.delta_x < 0 then x_offset = -player_boundary else x_offset = player_boundary end
		
		local y_offset = 0
		if Player.delta_y < 0 then y_offset = -player_boundary else y_offset = player_boundary end
		
		local player_gridpos_x = Player.x / Level.cell_size
		local gridpos_add_xoffset = (Player.x + x_offset) / Level.cell_size
		local gridpos_sub_xoffset = (Player.x - x_offset) / Level.cell_size
		
		local player_gridpos_y = Player.y / Level.cell_size
		local gridpos_add_yoffset = (Player.y + y_offset) / Level.cell_size
		local gridpos_sub_yoffset = (Player.y - y_offset) / Level.cell_size
		
		
		if love.keyboard.isDown("up") or love.keyboard.isDown("w") then
			-- Checks if the offsets are within the bounds
			if gridpos_add_xoffset > 0 and gridpos_add_yoffset > 0 and gridpos_add_xoffset < Level.columns and gridpos_add_yoffset < Level.rows  then
				if Level.walls[math.floor(player_gridpos_y) + 1][math.floor(gridpos_add_xoffset + 1)] == nil or Level.walls[math.floor(player_gridpos_y) + 1][math.floor(gridpos_add_xoffset + 1)] == 0 then
					Player.x = Player.x + Player.delta_x * (dt * speed)
				end
				
				if Level.walls[math.floor(gridpos_add_yoffset) + 1][math.floor(player_gridpos_x + 1)] == nil or Level.walls[math.floor(gridpos_add_yoffset) + 1][math.floor(player_gridpos_x + 1)] == 0 then
					Player.y = Player.y + Player.delta_y * (dt * speed)
				end
			end
			-- Player.x = Player.x + Player.delta_x * (dt * speed)
			-- Player.y = Player.y + Player.delta_y * (dt * speed)
		end
		
		if love.keyboard.isDown("down") or love.keyboard.isDown("s") then
			if gridpos_sub_xoffset < Level.columns and gridpos_sub_yoffset < Level.rows and gridpos_sub_xoffset > 0 and gridpos_sub_yoffset > 0 then
				if Level.walls[math.floor(player_gridpos_y) + 1][math.floor(gridpos_sub_xoffset + 1)] == 0 then
					Player.x = Player.x - Player.delta_x * (dt * speed)
				end
				if Level.walls[math.floor(gridpos_sub_yoffset) + 1][math.floor(player_gridpos_x + 1)] == 0 then
					Player.y = Player.y - Player.delta_y * (dt * speed)
				end
			end
			-- Player.x = Player.x - Player.delta_x * (dt * speed)
			-- Player.y = Player.y - Player.delta_y * (dt * speed)
		end
		
		
		if love.keyboard.isDown("e") then
			-- Checks if the offsets are within the bounds
			if gridpos_add_xoffset < Level.columns and gridpos_add_yoffset < Level.rows and gridpos_add_xoffset > 0 and gridpos_add_yoffset > 0 then
				if Level.walls[math.floor(player_gridpos_y) + 1]
				[math.floor(gridpos_add_xoffset + 1)] == 4 then
					Level.walls[math.floor(player_gridpos_y) + 1]
					[math.floor(gridpos_add_xoffset + 1)] = 0
				end
				
				if Level.walls[math.floor(gridpos_add_yoffset) + 1]
				[math.floor(player_gridpos_x + 1)] == 4 then
					Level.walls[math.floor(gridpos_add_yoffset) + 1]
					[math.floor(player_gridpos_x + 1)] = 0
				end
			end
		end
		
		if love.keyboard.isDown("o") then
			debug_number = debug_number - 1
		end
		if love.keyboard.isDown("p") then
			debug_number = debug_number + 1
		end
		
		if love.keyboard.isDown("k") then
			debug_number2 = debug_number2 - 1
		end
		if love.keyboard.isDown("l") then
			debug_number2 = debug_number2 + 1
		end
		

		-- Triggers
		if math.floor(Player.x / Level.cell_size) == 1 and math.floor(Player.y / Level.cell_size) == 5 then
			game_state = 2
		end
		
	end

	fps = 1 / dt
	delta_time = dt

end
function love.draw()
	if game_state == 0 then
		love.graphics.print("Spaghettian Ratcity (Test Menu)", 0, 0)
		love.graphics.print(">", 0, 32 + (menu_option * 16))
		love.graphics.print("    Play" , 0, 32)
		love.graphics.print("    Options" , 0, 48)
		love.graphics.print("    Quit" , 0, 64)
	elseif game_state == 1 then
		love.graphics.setPointSize(Render.quality)

		-- drawSky()
		drawLevel()
		--drawSprite()
		
		love.graphics.draw(shooter_image, Render.width - 180, Render.height - 128,  0, 4)
		love.graphics.draw(healthbar_image, 32, Render.height - 128 , 0, 3)
		love.graphics.draw(crosshair_image, Render.center_width - 15, Render.center_height - 15)

		if level_toggle then
			drawTopDownView()
		end

		
		love.graphics.print(math.floor(Player.x) .. ", " .. math.floor(Player.y), ui_offset_x, ui_offset_y)
		print(debug_number)

		if invalid_level then
			love.graphics.setColor(0,0,0,0.75)
			love.graphics.rectangle("fill", 0, 0, 256, 100)
			love.graphics.setColor(1,1,1)
			love.graphics.print("If you're seeing this, the program tried \nto load a level that doesnt exist, " .. level .. ".srl,\nand it failed. \n\nCheck the levels/ directory.", 0, 0)
		end
	elseif game_state == 2 then
		love.graphics.print("You win! (Win Screen Test)", 0, 0)
	elseif game_state == 3 then
		love.graphics.print("You lose! (Lose Screen Test)", 0, 0)
	end
	
	love.graphics.setLineWidth(1)
	showFpsGraph(16,128,240, 128)
end
function love.keypressed(key, scancode, isrepeat)
   	if key == "escape" then
		love.mouse.setGrabbed(false)
		love.mouse.setVisible(true)
		game_state = 0

  	end

	if game_state == 0 then
		if key == "down" and menu_option < 2 then
			menu_option = menu_option + 1
		elseif key == "up" and menu_option > 0 then
			menu_option = menu_option - 1
		elseif key == "z" then
			if menu_option == 0 then
				game_state = 1
				initializeGame()
			elseif menu_option == 2 then
				love.event.quit()
			end
		end
	elseif game_state == 1 then
		if key == "u" then
				if Render.fog < 10 then
					Render.fog = Render.fog + 1
				else
					Render.fog = 0
				end
		end
		if key == "i" then
				level_toggle = not level_toggle
		end
		if key == "t" then
				initializeGame()
		end
	end
end
function love.mousepressed(x, y, button, istouch)
   if button == 1 then -- Versions prior to 0.10.0 use the MouseConstant 'l'
      player_shoot = true
   end
end


-- "C:\Users\sushi\Documents\Projects\Spaghettian Ratcity\sr-love\love\love.exe" --console "C:\Users\sushi\Documents\Projects\Spaghettian Ratcity\sr-love\spaghettian-ratcity"
-- Debugging purposes :3 the dump function.
-- Source - https://stackoverflow.com/a/27028488
-- Posted by hookenz, modified by community. See post 'Timeline' for change history
-- Retrieved 2026-02-25, License - CC BY-SA 4.0

-- Calculation Functions
function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

-- Object Functions
function createSprite(iType, iState, iTexture, ix, iy, iz) 
	return {
		type = iType,
		state = iState,
		texture = iTexture,
		x = ix,
		y = iy,
		z = iz,
	}
end
function loadLevel(level)
	-- .srl is just a plain text file. Wanted to be unique with my level file types lol
	local level_path = "levels/" .. level .. ".srl"

	Level.walls = {}
	Level.floors = {}
	Level.ceilings = {}

	local file_section = 0
	local level_layer = "none"
	local insert_row = false

	for line in love.filesystem.lines(level_path) do
		local level_info = ""
		local level_row = {}

		for value in line:gmatch("[^,]+") do
			-- File section 0 checks the level information, like the level size and the player position
			-- If it detects the text "changetolevel" as its checking the level information, it changes
			-- to File section 1, the level information checker.
			if file_section == 0 then

				if value == "changetolevel" then
					file_section = 1
				end
				
				if level_info == "" then
					level_info = value
				else 
					if level_info == "lx" then
						Level.columns = tonumber(value)
					elseif level_info == "ly" then
						Level.rows = tonumber(value)
					elseif level_info == "px" then
						Player.x = tonumber(value)
					elseif level_info == "py" then
						Player.y = tonumber(value)
					elseif level_info == "texture" then
						textures_image = love.image.newImageData("graphics/" .. value .. ".png")
					elseif level_info == "sky" then
						sky_image = love.image.newImageData("graphics/" .. value .. ".png")
					elseif level_info == "fog" then
						Render.fog = tonumber(value)
					end
				end

			elseif file_section == 1 then
				-- Checks if the value is a number or an empty space "." 
				-- If both conditions aren't true, it assumes that a new layer 
				-- is being set up. Might change this later. 
				if tonumber(value) then
					table.insert(level_row, tonumber(value) + 1)
				elseif value == "." then
					table.insert(level_row, 0)
				else
					level_layer = value
					insert_row = false
				end
			end
		end

		-- It only adds the walls if its in file section 1, the level information checker.
		-- It adds walls to its designated level layer, but only if its able to with the 
		-- insert row variable.
		if file_section == 1 and insert_row then
			if level_layer == "walls" then
				table.insert(Level.walls, level_row)
			elseif level_layer == "floors" then
				table.insert(Level.floors, level_row)
			elseif level_layer == "ceilings" then
				table.insert(Level.ceilings, level_row)
			end
		end

		-- This is a failsafe to prevent empty rows from being added to 
		-- the level contents. 
		-- If a level layer's value recently changes, the insert_row boolean
		-- changes to false, as the current line doesn't define any row data, so 
		-- the level_row is empty. Because of that, insert_row aims to prevent the 
		-- if statement above this from manipulating the actual level arrays 
		-- before actually checking the next line, which does have the row data. 
		-- I hated explaining this and I am going to fix it later.
		insert_row = true
	end
end

function initializeGame()
	Player.delta_x = math.cos(Player.angle) * Player.speed
	Player.delta_y = math.sin(Player.angle) * Player.speed
	if mouse_controls then
		love.mouse.setGrabbed(true)
		love.mouse.setVisible(false)
	end
	
	sprites[1] = createSprite(2, 1, 0, Level.cell_size * 3.5, Level.cell_size * 2, 8)
	sprites[2] = createSprite(1, 1, 1, Level.cell_size * 4.5, Level.cell_size * 2, 8)
	sprites[3] = createSprite(1, 1, 0, Level.cell_size * 5.5, Level.cell_size * 2, 8)
	
	-- Load level if levels are available
	if love.filesystem.getInfo("levels/" .. level .. ".srl") then
		loadLevel(level)
	else
		loadLevel("default")
		invalid_level = true
	end
end

-- Display Functions
function drawLevel()
	Render:raycaster(Player, Level)
end

function drawSky() 
	-- for y = 0, 119 do
	-- 	local sky_strip = {}
	-- 	for x = 0, 319 do
	-- 		local meow = (-(Player.angle / (2*pi)*4) * 320 - x)
			
	-- 		if meow < 0 then
	-- 			meow = meow + 320
	-- 		end
			
	-- 		meow = meow % 640
			
	-- 		local r, g, b, a = sky_image:getPixel(meow, y)

	-- 		sky_strip[x] = {x,y,r,g,b,a}
	-- 	end

	-- 	love.graphics.points(sky_strip)
	-- end

end

function drawTopDownView() 
	-- Draws the background of the level overlay
	love.graphics.setColor(0,0,0, 0.75)
	love.graphics.rectangle("fill", 0,0,Render.width,Render.height)

	-- Draws the level
	for row, row_value in pairs(Level.walls) do
		for column, column_value in ipairs(row_value) do
			love.graphics.setColor(1,1,1, 0.8)
			
			row_left = row * Level.cell_size - Level.cell_size - Player.y + (Render.height / 2)
			column_top = column * Level.cell_size - Level.cell_size - Player.x + (Render.width / 2)
			row_right = row * Level.cell_size - Player.y + (Render.height / 2)
			column_bottom = column * Level.cell_size - Player.x + (Render.width / 2)
			
			local vertices = {column_top, row_left, column_top, row_right, column_bottom, row_right, column_bottom, row_left}
			
			if column_value > 0 then
				love.graphics.polygon("fill", vertices)
			end
		end
	end
	
	-- Draws the player
	love.graphics.setColor(255, 0, 0)
	love.graphics.circle( "fill", Render.width / 2, Render.height / 2, 3)
	
	love.graphics.line(Render.width / 2, Render.height / 2, Render.width / 2 + Player.delta_x * 10, Render.height / 2 + Player.delta_y * 10)
	
end


function drawSprite() 
	for index, value in ipairs(sprites) do
		local bounds = 12

		local sprite_x = sprites[index].x - Player.x
		local sprite_y = sprites[index].y - Player.y
		local sprite_z = sprites[index].z
		
		local CS = math.cos(Player.angle)
		local SS = -math.sin(Player.angle)
		
		local a = sprite_y * CS + sprite_x * SS
		local b = sprite_x * CS - sprite_y * SS
		sprite_x = a
		sprite_y = b
		
		local epsilon = 0.1
		
		sprite_x = (sprite_x * (Render.width / 1.4) / (sprite_y + epsilon))+(Render.width/2)
		sprite_y = (sprite_z * (Render.width / 1.4) / (sprite_y + epsilon))+(Render.height/2)
		
		local sprite_size = 16 
		local scale = (sprite_size * Render.height / (b + epsilon))
		local sprite_texture_x = 0
		local sprite_texture_y = 16
		
		local sprite_quality = 0
		local sprite_shade = 1
		
		
		if sprites[index].type == 1 then
			if sprites[index].state == 1 then
				if Player.x < sprites[index].x + bounds and
					Player.x > sprites[index].x - bounds and
					Player.y < sprites[index].y + bounds and
					Player.y > sprites[index].y - bounds then
					sprites[index].state = 0
				end
			end
		elseif sprites[index].type == 2 then
			if sprites[index].state == 1 then
				if sprites[index].x > Player.x then
					sprites[index].x = sprites[index].x - 1
				end
				if sprites[index].x < Player.x then
					sprites[index].x = sprites[index].x + 1
				end
				if sprites[index].y > Player.y then
					sprites[index].y = sprites[index].y - 1
				end
				if sprites[index].y < Player.y then
					sprites[index].y = sprites[index].y + 1
				end
			end

			if player_shoot and sprite_x > Render.center_width - 20 and sprite_x < Render.center_width + 20 then
				sprites[index].state = 0
			end
			player_shoot = false
		end

		if b < 25 then
			sprite_quality = (1 / (b + epsilon)) * 25
		end
		
		if Render.fog > 0 then
			sprite_shade = math.min(1 / (b + epsilon) * (Render.fog * 25), 1)
		end
		
		local sprite_strip = {}
		local sprite_strip_index = 0
		
		for x = sprite_x - scale / 2, sprite_x + scale / 2, Render.quality + sprite_quality do
			-- The third condition is a failsafe to not cause an out of bounds error,
			-- but it refuses to draw the rest of the sprite because of it.
			-- Fix it later
			sprite_texture_y = 16
			for y = 0, scale do
				if self.depth[math.floor(x/Render.quality) + 1] ~= nil and 
				b > 10 and b < Render.depth[math.floor(x/Render.quality) + 1] and 
				sprite_y - y < Render.height and
				sprites[index].state == 1
				then
					local r,g,b,a = sprites_image:getPixel(math.floor(sprite_texture_x * (Render.quality + sprite_quality)),math.floor(sprite_texture_y) + (sprites[index].texture * sprite_size))
					
					sprite_strip[sprite_strip_index] = {x - Render.quality / 2, sprite_y - y, r * sprite_shade,g * sprite_shade,b * sprite_shade,a}
					sprite_strip_index = sprite_strip_index + 1
				end	
				sprite_texture_y = sprite_texture_y - (sprite_size / scale)
				
				if sprite_texture_y < 0 then
					sprite_texture_y = 0
				end
			end
			sprite_texture_x = sprite_texture_x + ((sprite_size)/ scale)
		end
		
		love.graphics.points(sprite_strip)
	end
end


function showFpsGraph(x,y, graph_width, graph_height) 
	table.insert(fps_graph, x + fps_point)
	table.insert(fps_graph, y + (graph_height - fps))
	fps_point = fps_point + (delta_time * 100)

	if fps_point > graph_width then
		fps_point = 0
		fps_graph = {0,0,0,0}
	end

	love.graphics.setColor(0,0,0,0.5)
	love.graphics.rectangle("fill", x, y, graph_width, graph_height)
	love.graphics.setColor(1,1,1)
	love.graphics.print(fps, x, y)
	love.graphics.line(fps_graph)
end

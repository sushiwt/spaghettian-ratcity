-- Spaghettian Ratcity v0.1.2

-- Code written and documented by sushiwt 
-- and based on the Raycaster tutorials by 3DSage :3

-- I say 'based' because even though the algorithms are the same, 
-- the language is completely different and I had to make modifications
-- to deal with how Lua handles code like arrays and math. 

-- made by sushiwt, 15-02-2026


-- Level properties
level_walls = {	{1,1,2,2,1,1,1},
				{1,0,0,0,0,0,1},
				{1,0,0,0,1,0,1},
				{1,0,0,0,0,0,1},
				{1,4,1,0,0,0,1},
				{1,0,4,0,0,0,1},
				{1,1,1,1,3,1,1} }
				
level_floors = {{0,0,0,0,0,0,0},
				{0,1,1,1,1,1,0},
				{0,1,1,1,1,1,0},
				{0,1,1,1,1,1,0},
				{0,1,1,1,1,1,0},
				{0,1,1,1,1,1,0},
				{0,0,0,0,0,0,0}}
			
level_ceilings = {{0,0,0,0,0,0,0},
				{0,1,1,1,1,1,0},
				{0,0,0,0,0,0,0},
				{0,0,0,0,0,0,0},
				{0,0,0,0,0,0,0},
				{0,1,1,1,1,1,0},
				{0,0,0,0,0,0,0} }
			

level_x = 7
level_y = 7
wall_height = 30
cell_size = 32

quality = 4 -- Calculates how wide each segment of the screen would be for the rays
field_of_view = 75 -- The amount of area the player can see

pi = math.pi

-- Player properties
player_x = 40
player_y = 40
player_delta_x = 0
player_delta_y = 0
player_angle = 2 * pi
player_speed = 1
map_toggle = false

-- Render settings
render_width = 320
render_height = 200
render_center_width = render_width / 2
render_center_height = render_height / 2

-- Misc stuff
debug_number = 0 
fps = 0

-- Textures
textures_image = love.image.newImageData("graphics/platform.png")
sky_image = love.image.newImageData("graphics/sky.png")
sprites_image = love.image.newImageData("graphics/smiley.png")

speed = 50 -- I already have a player speed ill remove this eventually
sprites = {}

depth = {} -- Contains each rays distance value for sprite occlusion


function love.load(dt) 
	player_delta_x = math.cos(player_angle) * player_speed
	player_delta_y = math.sin(player_angle) * player_speed
	love.mouse.setGrabbed(true)
	love.mouse.setVisible(false)
	
	sprites[1] = createSprite(1, 1, 0, 64, 64, 8)
end


function love.update(dt)
	-- Player Movement
	
	-- Keyboard Turn
	if love.keyboard.isDown("left") then
		player_angle = player_angle - 0.05 * (dt * speed)
		if player_angle < 0 then
			player_angle = player_angle + 2 * pi
		end
		player_delta_x = math.cos(player_angle) * player_speed
		player_delta_y = math.sin(player_angle) * player_speed
	end
	if love.keyboard.isDown("right") then
		player_angle = player_angle + 0.05 * (dt * speed)
		if player_angle >= 2*pi then
			player_angle = player_angle - 2 * pi
		end
		player_delta_x = math.cos(player_angle) * player_speed
		player_delta_y = math.sin(player_angle) * player_speed
	end
	
	-- Mouse Turn
	player_angle = player_angle + ((love.mouse.getX() - render_center_width) * 0.001) * (dt * speed)
	if player_angle < 0 then
		player_angle = player_angle + 2 * pi
	end
	if player_angle >= 2*pi then
		player_angle = player_angle - 2 * pi
	end
	player_delta_x = math.cos(player_angle) * player_speed
	player_delta_y = math.sin(player_angle) * player_speed
	
	love.mouse.setPosition(render_center_width,render_center_height)
	
	-- Player Transform
	local player_boundary = 4
	
	local x_offset = 0
	if player_delta_x < 0 then x_offset = -player_boundary else x_offset = player_boundary end
	
	local y_offset = 0
	if player_delta_y < 0 then y_offset = -player_boundary else y_offset = player_boundary end
	
	local player_gridpos_x = player_x / cell_size
	local gridpos_add_xoffset = (player_x + x_offset) / cell_size
	local gridpos_sub_xoffset = (player_x - x_offset) / cell_size
	
	local player_gridpos_y = player_y / cell_size
	local gridpos_add_yoffset = (player_y + y_offset) / cell_size
	local gridpos_sub_yoffset = (player_y - y_offset) / cell_size
	
	
	if love.keyboard.isDown("up") or love.keyboard.isDown("w") then
		-- Checks if the offsets are within the bounds
		if gridpos_add_xoffset < level_x and gridpos_add_yoffset < level_y and gridpos_add_xoffset > 0 and gridpos_add_yoffset > 0 then
			if level_walls[math.floor(player_gridpos_y) + 1][math.floor(gridpos_add_xoffset + 1)] == 0 then
				player_x = player_x + player_delta_x * (dt * speed)
			end
			if level_walls[math.floor(gridpos_add_yoffset) + 1][math.floor(player_gridpos_x + 1)] == 0 then
				player_y = player_y + player_delta_y * (dt * speed)
			end
		end
	end
	if love.keyboard.isDown("down") or love.keyboard.isDown("s") then
		if gridpos_sub_xoffset < level_x and gridpos_sub_yoffset < level_y and gridpos_sub_xoffset > 0 and gridpos_sub_yoffset > 0 then
			if level_walls[math.floor(player_gridpos_y) + 1][math.floor(gridpos_sub_xoffset + 1)] == 0 then
				player_x = player_x - player_delta_x * (dt * speed)
			end
			if level_walls[math.floor(gridpos_sub_yoffset) + 1][math.floor(player_gridpos_x + 1)] == 0 then
				player_y = player_y - player_delta_y * (dt * speed)
			end
		end
	end
	
	
	if love.keyboard.isDown("e") then
		-- Checks if the offsets are within the bounds
		if gridpos_add_xoffset < level_x and gridpos_add_yoffset < level_y and gridpos_add_xoffset > 0 and gridpos_add_yoffset > 0 then
			if level_walls[math.floor(player_gridpos_y) + 1]
			[math.floor(gridpos_add_xoffset + 1)] == 4 then
				level_walls[math.floor(player_gridpos_y) + 1]
				[math.floor(gridpos_add_xoffset + 1)] = 0
			end
			
			if level_walls[math.floor(gridpos_add_yoffset) + 1]
			[math.floor(player_gridpos_x + 1)] == 4 then
				level_walls[math.floor(gridpos_add_yoffset) + 1]
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
	
	-- Triggers
	if math.floor(player_x / cell_size) == 1 and math.floor(player_y / cell_size) == 5 then
		love.event.quit()
	end
	
	fps = 1 / dt
end

function love.draw()
	love.graphics.setPointSize(quality)

	drawSky()
	drawMap()
	drawSprite()
	
	if map_toggle then
		drawTopDownView()
	end

	love.graphics.print(debug_number, 0, 0)
end

function love.keypressed(key, scancode, isrepeat)
   if key == "escape" then
      love.event.quit()
   end
   if key == "i" then
		map_toggle = not map_toggle
   end
end

-- Calculation Functions
-- Copied from a stack overflow question :3
-- https://stackoverflow.com/questions/32387117/bitwise-and-in-lua
-- Tbh i dont know what this code does but it WORKS so i am not
-- touchibg it...
function bitand(a, b)
    local r, m = 0, 2^31
    repeat
        local sa, sb = a % m, b % m
        if sa >= m/2 and sb >= m/2 then
            r = r + m/2
        end
        a, b = sa, sb
        m = m / 2
    until m < 1
    return r
end

-- Changes the radians to clamp it between 0 and 360 degrees
function fixRadians(ra)
	if ra > 2*pi then
		ra = ra - (2*pi)
	end
	
	if ra < 0 then
		ra = ra + (2*pi)
	end
	
	return ra
end

-- Object Functions
function createSprite(iType, iState, iMap, ix, iy, iz) 
	return {
		type = iType,
		state = iState,
		map = iMap,
		x = ix,
		y = iy,
		z = iz,
	}
end

-- Display Functions
function drawMap()
	local point_x, point_y, point_x_offset, point_y_offset, depth_of_field
	local distance = 0
	
	-- Calculates how many rays will be created based on the width of the window
	local ray_count = render_width / quality
	local starting_degree_offset = ray_count / 2
	
	-- Uses the player angle with the ray count and field of view
	-- to calculate the direction a single ray points to
	local ray_angle = fixRadians(player_angle - (((pi / 180) * (field_of_view / ray_count)) * starting_degree_offset))
	
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
			pointed_horizontal_line = (math.floor(player_y / cell_size) * cell_size)
			
			-- Finds the point of intersection of the horizontal line and the player ray
			point_y = player_y - (player_y - pointed_horizontal_line)
			point_x = (player_y - pointed_horizontal_line) * math.tan(ray_angle - (pi/2)) + player_x
			
			-- Finds the point of intersection of the next horizontal line and the player ray
			point_y_offset = -cell_size
			point_x_offset = -point_y_offset * math.tan(ray_angle - (pi/2)) 
			
		elseif ray_angle < pi then
			-- Utilizes the horizontal line below the player
			pointed_horizontal_line = (math.floor(player_y / cell_size) * cell_size) + cell_size
			
			-- Finds the point of intersection of the horizontal line and the player ray
			point_y = player_y - (player_y - pointed_horizontal_line)
			point_x = (player_y - pointed_horizontal_line) * math.tan(ray_angle - (pi/2)) + player_x
			
			-- Finds the point of intersection of the next horizontal line and the player ray
			point_y_offset = cell_size 
			point_x_offset = -point_y_offset * math.tan(ray_angle - (pi/2)) 
			
		elseif ray_angle == 0 or ray_angle == pi then
			-- The horizontal line and player ray would be parallel, 
			-- so default the point to the player and refuse checking for intersections.
			point_x = player_x
			point_y = player_y
			depth_of_field = 8
		end
		
		-- Checks the intersections
		while depth_of_field < 8 do
			-- Correlates the location the ray is currently intersecting with the array size.
			cell_x = math.floor(point_x / cell_size) 
			cell_y = math.floor(point_y / cell_size) 
			
			-- Checks if the intersections are within the bounds
			if cell_x < level_x and cell_y < level_y and cell_x > -1 and cell_y > 0 then
				-- Shifts the array to account for the bottom of the grid.
				if ray_angle < pi then
					cell_y = cell_y + 1
				end
				
				hor_level_texture = level_walls[cell_y][cell_x + 1] - 1
				
				-- Checks if ray is intersecting wall
				if level_walls[cell_y][cell_x + 1] > 0 then
					horizontal_point_x = point_x
					horizontal_point_y = point_y
					horizontal_distance = math.sqrt(math.pow(horizontal_point_y - player_y, 2) + math.pow(horizontal_point_x - player_x, 2))
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
			pointed_vertical_line = (math.floor(player_x / cell_size) * cell_size)
			
			-- Finds the point of intersection of the vertical line and the player ray
			point_x = player_x - (player_x - pointed_vertical_line)
			point_y = (player_x - pointed_vertical_line) * math.tan(-ray_angle) + player_y
			
			-- Finds the point of intersection of the next line and the player ray
			point_x_offset = -cell_size 
			point_y_offset = -point_x_offset * math.tan(-ray_angle) 
		elseif ray_angle < pi/2 or ray_angle > (3*pi)/2 then
			-- Calculates the vertical line right of the player needed to check the intersection
			pointed_vertical_line = (math.floor(player_x / cell_size) * cell_size) + cell_size
			
			-- Finds the point of intersection of the vertical line and the player ray
			point_x = player_x - (player_x - pointed_vertical_line)
			point_y = (player_x - pointed_vertical_line) * math.tan(-ray_angle) + player_y
			
			-- Finds the point of intersection of the next vertical line and the player ray
			point_x_offset = cell_size 
			point_y_offset = -point_x_offset * math.tan(-ray_angle) 
		elseif ray_angle == pi/2 or ray_angle == (3*pi)/2 then 
			-- The horizontal line and player ray would be parallel, 
			-- so default the point to the player and refuse checking for intersections.
			point_x = player_x
			point_y = player_y
			depth_of_field = 8
		end
		
		-- Checks the intersections
		while depth_of_field < 8 do
			-- Correlates the location the ray is currently intersecting with the array size.
			cell_x = math.floor(point_x / cell_size) 
			cell_y = math.floor(point_y / cell_size) 
			
			-- Checks if the intersections are within the bounds
			if cell_x < level_x and cell_y < level_y and cell_x > 0 and cell_y > -1 then
				-- Shifts the array to account for the bottom of the grid.
				if ray_angle < pi/2 or ray_angle > (3*pi)/2 then
					cell_x = cell_x + 1
				end
				
				ver_level_texture = level_walls[cell_y + 1][cell_x] - 1
				
				-- Checks if ray is intersecting wall
				if level_walls[cell_y + 1][cell_x] > 0 then
					vertical_point_x = point_x
					vertical_point_y = point_y
					vertical_distance = math.sqrt(math.pow(vertical_point_y - player_y, 2) + math.pow(vertical_point_x - player_x, 2))
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
		end
		
		-- Fixes fisheye
		local cosine_angle = fixRadians(player_angle - ray_angle)
		distance = distance * math.cos(cosine_angle)
		
		-- 3D WALL DRAWINGS
		local line_height = (wall_height * render_height)/distance
		
		-- The numerator takes care of the line segment somethng important
		local texture_y_step = 32 / line_height 
		local texture_y_offset = 0
		
		if line_height > render_height then
			texture_y_offset = (line_height - render_height) / 2.0
			line_height = render_height
		end
		
		local line_offset = (render_center_height)-line_height/2
		
		if line_height > render_height then
			line_height = render_height
		end
		
		love.graphics.setLineWidth(quality)
		local starting_segment = rays*quality
		
		-- Draws the depth of each ray
		depth[rays + 1] = distance
		
		-- DRAW WALLS
		-- Add way to change texture size later. 32x32 is the size of the textures
		local texture_y = texture_y_offset * texture_y_step + (level_texture * 32)
		local texture_x = 0
		
		if shade == 1 then
			texture_x = math.floor(point_x / (cell_size / 32 )) % 32
			-- Flips the texture at the south
			if ray_angle < pi then texture_x = 31 - texture_x end
		else 
			texture_x = math.floor(point_y / (cell_size / 32 )) % 32
			-- Flips the texture at the south
			if ray_angle > pi/2 and ray_angle < (3*pi)/2 then texture_x = 31 - texture_x end
		end
		
		-- Resets the color before generating the strip
		love.graphics.setColor(1,1,1,1)
		
		-- A list of points to draw the wall strips.
		local wall_strip = {}
		
		-- TODO OPTIMIZE LATER HLY SHIT it sucks
		for line_y = 0, line_height do
			local r, g, b, a = textures_image:getPixel(math.floor(texture_x), math.floor(texture_y))
			
			wall_strip[line_y] = {starting_segment, line_offset + line_y, r * shade, g * shade, b * shade, a}
			-- love.graphics.setColor(r * shade,g * shade,b * shade,a)
			-- love.graphics.points(starting_segment,line_offset + line_y)
			texture_y = texture_y + texture_y_step
		end
		
		-- A list of points to draw the floor and ceiling strips
		local floor_strip = {}
		local ceiling_strip = {}
		
		-- DRAW FLOORS
		-- Fix ground spacing later... based on the resolution the bigger it is the more it's 
		-- spaced out from the walls.
		local fisheye_floor_fix = math.cos(fixRadians(player_angle - ray_angle))
		local mysterynum = 96 -- There's gotta be a better way to get 224 right..
		local floor_shade = 0.9
		
		local floor_strip_index = 0
		local ceiling_strip_index = 0
		for line_y = line_offset+line_height, render_height do
			local ground_y = line_y - (render_height/2)
			local r, g, b, a = 0, 0, 0, 1
			local ground_texture_x = player_x + math.cos(ray_angle) * mysterynum * 30 / ground_y / fisheye_floor_fix
			local ground_texture_y = player_y + math.sin(ray_angle) * mysterynum * 30 / ground_y / fisheye_floor_fix

			-- Failsafe just in case it goes out of bounds
			if ground_texture_x < 0 then ground_texture_x = 0 end
			if ground_texture_y < 0 then ground_texture_y = 0 end
			if ground_texture_x / 32 > level_x then ground_texture_x = level_x - 1 end
			if ground_texture_y / 32 > level_y then ground_texture_y = level_y - 1 end
			
			local mp = level_floors[1 + math.floor(ground_texture_y / 32)][1 + math.floor(ground_texture_x / 32)]*32
			if mp ~= nil then r, g, b, a = textures_image:getPixel(bitand(math.floor(ground_texture_x), 31), bitand(math.floor(ground_texture_y), 31) + mp)end
			
			-- love.graphics.setColor(r * floor_shade,g * floor_shade,b * floor_shade,a)
			-- love.graphics.points(starting_segment,line_y)
			
			floor_strip[floor_strip_index] = {starting_segment,line_y, r * floor_shade, g * floor_shade, b * floor_shade, a}
			floor_strip_index = floor_strip_index + 1
			
			mp = level_ceilings[1 + math.floor(ground_texture_y / 32)][1 + math.floor(ground_texture_x / 32)]*32
			
			if mp ~= nil and mp > 0 then
				r, g, b, a = textures_image:getPixel(bitand(math.floor(ground_texture_x), 31), bitand(math.floor(ground_texture_y), 31) + mp)
				-- love.graphics.setColor(r * floor_shade,g * floor_shade,b * floor_shade,a)
				-- love.graphics.points(starting_segment,(render_height) - line_y)
				ceiling_strip[ceiling_strip_index] = {starting_segment,(render_height) - line_y, r * floor_shade, g * floor_shade, b * floor_shade, a}
				ceiling_strip_index = ceiling_strip_index + 1
			end
			
		end
		
		-- Draws the map layer by layer
		love.graphics.points(wall_strip)
		love.graphics.points(floor_strip)
		love.graphics.points(ceiling_strip)
		
		-- local player_center_w = render_width / 2
		-- local player_center_h = render_height / 2
		
		-- Draws the rays in the 2D demonstration (weird bug happens when looking
		-- at the left side of the screen.. The rays wont print...
		-- if map_toggle then
			-- love.graphics.setLineWidth(1)
			-- love.graphics.line(player_center_w, player_center_h, point_x - player_x + (player_center_w), point_y - player_y + (player_center_h))
		-- end
		
			-- love.graphics.setLineWidth(1)
		-- Recalculates the ray angle for another added ray to span the field of view.
		ray_angle = fixRadians(ray_angle + ((pi / 180) * (field_of_view / ray_count)))
	end
end

function drawSky() 
	for y = 0, 119 do
		for x = 0, 319 do
			local meow = (-(player_angle / (2*pi)*4) * 320 - x)
			
			if meow < 0 then
				meow = meow + 320
			end
			
			meow = meow % 640
			
			local r, g, b, a = sky_image:getPixel(meow, y)

			love.graphics.setColor(r,g,b,a)
			love.graphics.points(x,y + 1)
		end
	end
end

function drawTopDownView() 
	-- Draws the background of the map overlay
	love.graphics.setColor(0,0,0, 0.75)
	love.graphics.rectangle("fill", 0,0,render_width,render_height)

	-- Draws the level
	for row, row_value in pairs(level_walls) do
		for column, column_value in ipairs(row_value) do
			love.graphics.setColor(1,1,1, 0.8)
			
			row_left = row * cell_size - cell_size - player_y + (render_height / 2)
			column_top = column * cell_size - cell_size - player_x + (render_width / 2)
			row_right = row * cell_size - player_y + (render_height / 2)
			column_bottom = column * cell_size - player_x + (render_width / 2)
			
			local vertices = {column_top, row_left, column_top, row_right, column_bottom, row_right, column_bottom, row_left}
			
			if column_value > 0 then
				love.graphics.polygon("fill", vertices)
			end
		end
	end
	
	-- Draws the player
	love.graphics.setColor(255, 0, 0)
	love.graphics.circle( "fill", render_width / 2, render_height / 2, 3)
	
	love.graphics.line(render_width / 2, render_height / 2, render_width / 2 + player_delta_x * 10, render_height / 2 + player_delta_y * 10)
	
end

function drawSprite() 
	local sprite_x = sprites[1].x - player_x
	local sprite_y = sprites[1].y - player_y
	local sprite_z = sprites[1].z
	
	local CS = math.cos(player_angle)
	local SS = -math.sin(player_angle)
	
	local a = sprite_y * CS + sprite_x * SS
	local b = sprite_x * CS - sprite_y * SS
	sprite_x = a
	sprite_y = b
	
	sprite_x = (sprite_x * 215 / sprite_y)+(render_width/2)
	sprite_y = (sprite_z * 215 / sprite_y)+(render_height/2)
	
	print(sprite_x)
	local sprite_size = 16 
	local scale = (sprite_size * render_height / b)
	local sprite_texture_x = 0
	local sprite_texture_y = 16
	
	local sprite_strip = {}
	local sprite_strip_index = 0
	
	for x = sprite_x - scale / 2, sprite_x + scale / 2, quality do
		-- The third condition is a failsafe to not cause an out of bounds error,
		-- but it refuses to draw the rest of the sprite because of it.
		-- Fix it later
		sprite_texture_y = 16
		for y = 0, scale do
			if sprite_x > 0 and sprite_x < render_width and 
			depth[math.floor(x/quality) + 1] ~= nil and 
			b > 0 and b < depth[math.floor(x/quality) + 1] and 
			sprite_y - y < render_height then
				local r,g,b,a = sprites_image:getPixel(math.floor(sprite_texture_x * quality),math.floor(sprite_texture_y))
				
				-- love.graphics.setColor(r,g,b,a)
				-- love.graphics.points(x, sprite_y - y)
				sprite_strip[sprite_strip_index] = {x, sprite_y - y, r,g,b,a}
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


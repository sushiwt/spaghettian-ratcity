-- Moved the renderer to its own function... fun.!!

-- Render settings
local render = {}

render.width = 640
render.height = 480
render.center_width = 320
render.center_height = 240
render.dof_value = 16
render.fog = 0
render.quality = 8 -- Calculates how wide each segment of the screen would be for the rays
render.field_of_view = 75 -- The amount of area the player can see
render.depth = {} -- Contains each rays distance value for sprite occlusion

function render:raycaster(player_object, level_object)
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
function render.fixRadians(ra)
	if ra > 2*pi then
		ra = ra - (2*pi)
	end
	
	if ra < 0 then
		ra = ra + (2*pi)
	end
	
	return ra
end

return render
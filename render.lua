-- Moved the renderer to its own function... fun.!!

-- Render settings
local render = {}

render.x = 0
render.y = 0

render.width = 640
render.height = 360

render.center_width = render.width / 2
render.center_height = render.height / 2

render.dof_value = 16
render.fog = 0

render.quality = 1 -- Calculates how wide each segment of the screen would be for the rays
render.floor_quality = 4
render.field_of_view = 75 -- The amount of area the player can see
render.depth = {} -- Contains each rays distance value for object occlusion

love.graphics.setScissor(render.x, render.y, render.width, render.height)

-- Light Coordinates (temporary)
render.light_x = 96
render.light_y = 32

-- Light Coordinates 
render.lights = {{32,32},{96,96 + 32}}
render.view_bobbing = 0

function render:drawRaycaster(level_object, player_object)
	-- Calculates how many rays will be created based on the width of the window
	local ray_count = self.width / self.quality

	local starting_degree_offset = ray_count / 2
	-- Uses the player angle with the ray count and field of view
	-- to calculate the direction a single ray points to
	local ray_angle = self.fixRadians(player_object.angle - (((pi / 180) * (self.field_of_view / ray_count)) * starting_degree_offset))

	local ray = self.createRay()

	-- Lighting 
	-- Flashlight Mechanic?
	-- if (math.floor(ray_count / 2) == rays) then
	-- 	self.lights[1][1] = point_x - 16
	-- 	self.lights[1][2]= point_y - 16
	-- end
	
	if love.keyboard.isDown("y") then
		self.lights[1][1] = self.lights[1][1] + 0.001
	end
	if love.keyboard.isDown("h") then
		self.lights[1][1] = self.lights[1][1] - 0.001
	end
	if love.keyboard.isDown("g") then
		self.lights[1][2] = self.lights[1][2] + 0.001
	end
	if love.keyboard.isDown("j") then
		self.lights[1][2] = self.lights[1][2] - 0.001
	end

	-- Ray initialization + 3d Drawing
	for rays = 0, ray_count do 
		local point_x, point_y, depth_of_field
		
		self.findRayIntersections(ray, player_object, level_object, ray_angle, self.dof_value)

		local level_texture = 0
		local distance = 0
		local shade = 0

		point_x = ray.x
		point_y = ray.y
		level_texture = ray.texture
		distance = ray.distance
		shade = ray.shade
		
		self:drawRayWall(ray, player_object, level_object, ray_angle, rays)

		self.findRayIntersections(ray, player_object, level_object, ray_angle, self.dof_value, level_object.ceilings)

		self:drawRayWall(ray, player_object, level_object, ray_angle, rays, 1)

		-- DRAW FLOORS
		-- Fix ground spacing later... based on the resolution the bigger it is the more it's 
		-- spaced out from the walls.
		
		-- A list of points to draw the floor and ceiling strips
		local floor_strip = {}
		local ceiling_strip = {}

		local fisheye_floor_fix = math.cos(self.fixRadians(player_object.angle - ray_angle))
		local floor_ceiling_offset = (1.25 + ((0.006)*(self.height) - 1.2))*(level_object.wall_height*2.5) - 1 
		local floor_shade = 0.9

		local floor_cosine_angle = self.fixRadians(player_object.angle - ray_angle)
		local floor_distance = distance * math.cos(floor_cosine_angle)
		local floor_draw_height = (level_object.wall_height * self.height) / floor_distance
		local floor_draw_offset = (self.center_height) - floor_draw_height / 2
		local floor_starting_segment = rays*self.quality

		local floor_offset = floor_draw_offset + floor_draw_height
		
		local floor_strip_index = 0
		local ceiling_strip_index = 0
		
		if render_floor then
			love.graphics.setPointSize(self.floor_quality)
			if rays % self.floor_quality == 0 then
				for line_y = floor_offset - 2, self.height, self.floor_quality do
					local ground_y = line_y - (self.height/2)
					local r, g, b, a = 0, 0, 0, 1
					local ground_texture_x = (player_object.x + math.cos(ray_angle) * (floor_ceiling_offset) * 32 / ground_y / fisheye_floor_fix) 
					local ground_texture_y = (player_object.y + math.sin(ray_angle) * (floor_ceiling_offset) * 32 / ground_y / fisheye_floor_fix) 
					
					local tile_light = 0

					tile_light = self.calculateLighting(self.lights, ground_texture_x - level_object.cell_size / 2, ground_texture_y - level_object.cell_size / 2, level_object.cell_size, 1, level_object)

					-- Failsafe just in case it goes out of bounds
					if ground_texture_x < 0 then ground_texture_x = ground_texture_x % level_object.cell_size  end
					if ground_texture_y < 0 then ground_texture_y = ground_texture_y % level_object.cell_size end
					if ground_texture_x / level_object.cell_size > level_object.columns then ground_texture_x = ground_texture_x % level_object.cell_size end
					if ground_texture_y / level_object.cell_size > level_object.rows then ground_texture_y = ground_texture_y % level_object.cell_size end
					
					local mp = level_object.floors[1 + math.floor(ground_texture_y / level_object.cell_size)][1 + math.floor(ground_texture_x / level_object.cell_size)]*32 -- The multiplier shifts the textures to account for the multiple textures
					if mp ~= nil then r, g, b, a = textures_image:getPixel(math.floor(ground_texture_x % 32), math.floor(ground_texture_y % 32) + mp)end
					
					-- if (math.floor(ground_texture_x / 32) == 2 and math.floor(ground_texture_y / 32) == 2 ) then
					-- 	tile_light = 0.1
					-- end

					if self.fog ~= 0 then
						floor_shade = math.min((line_y - self.center_height) * (self.fog * 2) / self.height, 1)
					else
						floor_shade = 0.9
					end

					floor_shade = floor_shade * tile_light + 0
					
					floor_strip[floor_strip_index] = {self.x + floor_starting_segment,  self.y + line_y, r * floor_shade, g * floor_shade, b * floor_shade, a}
					floor_strip_index = floor_strip_index + 1
					
					mp = level_object.ceilings[1 + math.floor(ground_texture_y / level_object.cell_size)][1 + math.floor(ground_texture_x / level_object.cell_size)]*32
					
					if mp ~= nil and mp > 0 then
						r, g, b, a = textures_image:getPixel(math.floor(ground_texture_x % 32), math.floor(ground_texture_y % 32) + mp)
						ceiling_strip[ceiling_strip_index] = {self.x + floor_starting_segment, self.y + (self.height) - line_y, r * floor_shade, g * floor_shade, b * floor_shade, a}
						ceiling_strip_index = ceiling_strip_index + 1

						love.graphics.setColor(1,1,1,1)
					end
					
				end
			end

			-- Draws the level layer by layer
			love.graphics.points(floor_strip)
			love.graphics.points(ceiling_strip)
		end
		
		-- Recalculates the ray angle for another added ray to span the field of view.
		ray_angle = self.fixRadians(ray_angle + ((pi / 180) * (self.field_of_view / ray_count)))
	end
end

function render:drawObjects(objects_table, player_object, level_object) 
	for index, value in ipairs(objects_table) do
		local object_x = objects_table[index].x -  player_object.x
		local object_y = objects_table[index].y -  player_object.y
		local object_z = objects_table[index].z
		
		local CS = math.cos(player_object.angle)
		local SS = -math.sin(player_object.angle)
		
		local a = object_y * CS + object_x * SS
		local b = object_x * CS - object_y * SS
		object_x = a
		object_y = b
		
		local epsilon = 0.1
		
		object_x = (object_x * (self.width / 1.4) / (object_y + epsilon))+(self.width/2)
		object_y = (object_z * (self.width / 1.4) / (object_y + epsilon))+(self.height/2)
		
		local object_size = 16 
		local scale = (object_size * self.height / (b + epsilon))
		local object_texture_x = 0
		local object_texture_y = 16
		
		local object_quality = 0
		local object_shade = 1

		if self.fog > 0 then
			object_shade = math.min(1 / (b + epsilon) * (self.fog * 25), 1)
		end
		
		local object_strip = {}
		local object_strip_index = 0

		local visibility_range = 0.75
		
		local sprite_light = 0

		for i, coords in ipairs(self.lights) do
			sprite_light = sprite_light + (visibility_range / ((math.abs((objects_table[index].x) - coords[1]) / level_object.cell_size) + 
											    (math.abs((objects_table[index].y) - coords[2]) / level_object.cell_size) + 1))
		end

		local sprite_fog = sprite_light
		love.graphics.setColor(sprite_fog,sprite_fog,sprite_fog,1)

		for x = object_x - scale / 2, object_x + scale / 2, self.quality + object_quality do
			-- The third condition is a failsafe to not cause an out of bounds error,
			-- but it refuses to draw the rest of the object because of it.
			-- Fix it later
			if self.depth[math.floor(x/self.quality) + 1] ~= nil and 
			b > 10 and b < self.depth[math.floor(x/self.quality) + 1] and 
			objects_table[index].state == 1 then
				local objects_quad = love.graphics.newQuad(object_texture_x - 0.5, 0, 1, 16, objects_table[index].texture)
				love.graphics.draw(objects_table[index].texture, objects_quad, math.floor(self.x + x), math.floor(self.y + object_y) - scale, 0, 1, scale / object_size)
			end	
			object_texture_x = object_texture_x + ((object_size)/ scale)
		end

		

	end

	
	-- HUD Shooter
	if love.keyboard.isDown("w") or love.keyboard.isDown("s") then 
		self.view_bobbing = self.view_bobbing + 0.1
	end

	local shooter_light = self.calculateLighting(self.lights, player_object.x, player_object.y, level_object.cell_size)

	love.graphics.setColor(shooter_light,shooter_light,shooter_light)
	love.graphics.draw(shooter_image, self.width - 180 + (-8 * math.cos(self.view_bobbing)), self.height - 128 + (-8 * math.abs(math.sin(self.view_bobbing))) + 8,  0, 4)

	love.graphics.setColor(1,1,1)
end

function render.calculateLighting(light_coords, subject_x, subject_y, cell_size, light_range, level_object) 
	local light_result = 0
	light_range = light_range or 1
	level_object = level_object or nil

	for i, coords in ipairs(light_coords) do
		local distance = math.pow(((subject_x) - coords[1]) / cell_size,2) + math.pow(((subject_y) - coords[2]) / cell_size,2) 
		local light_level = (light_range / (distance + 1))
		

		light_result = light_result + light_level
	end

	return light_result
end

function render.findRayIntersections(ray, player_object, level_object, ray_angle, dof, wall_layer)
	wall_layer = wall_layer or level_object.walls

	local ray_distance = 0
	
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
	
	local intersect_point_x, intersect_point_y
	local intersect_point_x_offset, intersect_point_y_offset

	if ray_angle > pi then
		-- Calculates the horizontal line above the player needed to check the intersection
		pointed_horizontal_line = (math.floor(player_object.y / level_object.cell_size) * level_object.cell_size)
		
		-- Finds the point of intersection of the horizontal line and the player ray
		intersect_point_y = player_object.y - (player_object.y - pointed_horizontal_line)
		intersect_point_x = (player_object.y - pointed_horizontal_line) * math.tan(ray_angle - (pi/2)) + player_object.x
		
		-- Finds the point of intersection of the next horizontal line and the player ray
		intersect_point_y_offset = -level_object.cell_size
		intersect_point_x_offset = -intersect_point_y_offset * math.tan(ray_angle - (pi/2)) 
		
	elseif ray_angle < pi then
		-- Utilizes the horizontal line below the player
		pointed_horizontal_line = (math.floor(player_object.y / level_object.cell_size) * level_object.cell_size) + level_object.cell_size
		
		-- Finds the point of intersection of the horizontal line and the player ray
		intersect_point_y = player_object.y - (player_object.y - pointed_horizontal_line)
		intersect_point_x = (player_object.y - pointed_horizontal_line) * math.tan(ray_angle - (pi/2)) + player_object.x
		
		-- Finds the point of intersection of the next horizontal line and the player ray
		intersect_point_y_offset = level_object.cell_size 
		intersect_point_x_offset = -intersect_point_y_offset * math.tan(ray_angle - (pi/2)) 
		
	elseif ray_angle == 0 or ray_angle == pi then
		-- The horizontal line and player ray would be parallel, 
		-- so default the point to the player and refuse checking for intersections.
		intersect_point_x = player_object.x
		intersect_point_y = player_object.y
		depth_of_field = dof
	end
	
	-- Checks the intersections
	while depth_of_field < dof do
		-- Correlates the location the ray is currently intersecting with the array size.
		cell_x = math.floor(intersect_point_x / level_object.cell_size) 
		cell_y = math.floor(intersect_point_y / level_object.cell_size) 
		
		-- Checks if the intersections are within the bounds
		if cell_x < level_object.columns and cell_y < level_object.rows and cell_x > -1 and cell_y > 0 then
			-- Shifts the array to account for the bottom of the grid.
			if ray_angle < pi then
				cell_y = cell_y + 1
			end
			
			hor_level_texture = wall_layer[cell_y][cell_x + 1] - 1
			
			-- Checks if ray is intersecting wall
			if wall_layer[cell_y][cell_x + 1] > 0 then
				horizontal_point_x = intersect_point_x
				horizontal_point_y = intersect_point_y
				horizontal_distance = math.sqrt(math.pow(horizontal_point_y - player_object.y, 2) + math.pow(horizontal_point_x - player_object.x, 2))
				break
			end
			
		end
		
		-- The code normally breaks before these lines of code execute
		-- if there was an intersection within the point.
		-- This checks the next intersection
		intersect_point_x = intersect_point_x + intersect_point_x_offset
		intersect_point_y = intersect_point_y + intersect_point_y_offset
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
		intersect_point_x = player_object.x - (player_object.x - pointed_vertical_line)
		intersect_point_y = (player_object.x - pointed_vertical_line) * math.tan(-ray_angle) + player_object.y
		
		-- Finds the point of intersection of the next line and the player ray
		intersect_point_x_offset = -level_object.cell_size 
		intersect_point_y_offset = -intersect_point_x_offset * math.tan(-ray_angle) 
	elseif ray_angle < pi/2 or ray_angle > (3*pi)/2 then
		-- Calculates the vertical line right of the player needed to check the intersection
		pointed_vertical_line = (math.floor(player_object.x / level_object.cell_size) * level_object.cell_size) + level_object.cell_size
		
		-- Finds the point of intersection of the vertical line and the player ray
		intersect_point_x = player_object.x - (player_object.x - pointed_vertical_line)
		intersect_point_y = (player_object.x - pointed_vertical_line) * math.tan(-ray_angle) + player_object.y
		
		-- Finds the point of intersection of the next vertical line and the player ray
		intersect_point_x_offset = level_object.cell_size 
		intersect_point_y_offset = -intersect_point_x_offset * math.tan(-ray_angle) 
	elseif ray_angle == pi/2 or ray_angle == (3*pi)/2 then 
		-- The horizontal line and player ray would be parallel, 
		-- so default the point to the player and refuse checking for intersections.
		intersect_point_x = player_object.x
		intersect_point_y = player_object.y
		depth_of_field = dof
	end
	
	-- Checks the intersections
	while depth_of_field < dof do
		-- Correlates the location the ray is currently intersecting with the array size.
		cell_x = math.floor(intersect_point_x / level_object.cell_size) 
		cell_y = math.floor(intersect_point_y / level_object.cell_size) 
		
		-- Checks if the intersections are within the bounds
		if cell_x < level_object.columns and cell_y < level_object.rows and cell_x > 0 and cell_y > -1 then
			-- Shifts the array to account for the bottom of the grid.
			if ray_angle < pi/2 or ray_angle > (3*pi)/2 then
				cell_x = cell_x + 1
			end
			
			ver_level_texture = wall_layer[cell_y + 1][cell_x] - 1
			
			-- Checks if ray is intersecting wall
			if wall_layer[cell_y + 1][cell_x] > 0 then
				vertical_point_x = intersect_point_x
				vertical_point_y = intersect_point_y
				vertical_distance = math.sqrt(math.pow(vertical_point_y - player_object.y, 2) + math.pow(vertical_point_x - player_object.x, 2))
				break
			end
			
		end
		
		-- The code normally breaks before these lines of code execute
		-- if there was an intersection within the point.
		-- This checks the next intersection
		intersect_point_x = intersect_point_x + intersect_point_x_offset
		intersect_point_y = intersect_point_y + intersect_point_y_offset
		depth_of_field = depth_of_field + 1
	end

	-- Checks if the vertical or horizontal intersections
	-- are shorter. If they are, use that as the point of 
	-- intersection.
	
	-- Shading of the vertical and horizontal walls
	-- Vertical walls are dark
	local ray_shade = 1
	local level_texture_ray = 0;
	
	if vertical_distance < horizontal_distance then
		intersect_point_x = vertical_point_x
		intersect_point_y = vertical_point_y
		level_texture_ray = ver_level_texture
		ray_distance = vertical_distance
		ray_shade = 0.9
	elseif horizontal_distance < vertical_distance then
		intersect_point_x = horizontal_point_x
		intersect_point_y = horizontal_point_y
		level_texture_ray = hor_level_texture
		ray_distance = horizontal_distance
	else 
		intersect_point_x = player_object.x
		intersect_point_y = player_object.y
		level_texture_ray = 0
		ray_distance = horizontal_distance
	end

	ray.x = intersect_point_x
	ray.y = intersect_point_y
	ray.texture = level_texture_ray
	ray.distance = ray_distance
	ray.shade = ray_shade
end

function render:drawRayWall(ray, player_object, level_object, ray_angle, rays, layer)
	layer = layer or 0

	-- Fixes fisheye
	local cosine_angle = self.fixRadians(player_object.angle - ray_angle)
	local wall_distance = ray.distance * math.cos(cosine_angle)
	
	-- DRAW WALLS
	local wall_draw_height = (level_object.wall_height * self.height)/wall_distance
	
	-- The numerator takes care of the line segment somethng important
	local texture_y_step = 32 / wall_draw_height 
	local texture_y_offset = 0

	if wall_draw_height > self.height then
		texture_y_offset = (wall_draw_height - self.height) / 2.0
		wall_draw_height = self.height
	end

	local wall_draw_offset = (self.center_height)-wall_draw_height/2
	
	love.graphics.setLineWidth(self.quality)
	local starting_segment = rays*self.quality
	
	-- Draws the depth of each ray for occlusion

	if layer == 0 then
		self.depth[rays + 1] = wall_distance
	end

	-- DRAW WALLS
	-- Add way to change texture size later. 32x32 is the size of the textures
	local texture_x = 0
	
	if ray.shade == 1 then
		texture_x = math.floor(ray.x / (level_object.cell_size / 32 )) % 32
		-- Flips the texture at the south
		if ray_angle < pi then texture_x = 31 - texture_x end
	else 
		texture_x = math.floor(ray.y / (level_object.cell_size / 32 )) % 32
		-- Flips the texture at the south
		if ray_angle > pi/2 and ray_angle < (3*pi)/2 then texture_x = 31 - texture_x end
	end
	
	-- Resets the color before generating the strips
	love.graphics.setColor(1,1,1,1)
	
	-- A list of points to draw the wall strips.
	local wall_strip = {}
	
	local fog_walls = 0
	if self.fog > 0 then
		fog_walls = math.min(1 - ((wall_distance / 220) - (0.1 * self.fog)), 1)
		if fog_walls < 0 then
			fog_walls = 0
		end
	else 
		fog_walls = 1
	end

	local unfixed_distance = (level_object.wall_height * self.height)/wall_distance

	-- Wall Lighting
	local wall_shade = 0

	wall_shade = self.calculateLighting(self.lights, ray.x - level_object.cell_size / 2, ray.y - level_object.cell_size / 2, level_object.cell_size, 1) - (1 - ray.shade)
	wall_shade = wall_shade * fog_walls

	local wall_quad = love.graphics.newQuad(math.floor(texture_x), ray.texture * 32, 1, 32, textures_image_convert)
	-- Completely different wall rendering engine btw
	love.graphics.setColor(wall_shade, wall_shade, wall_shade,1)
	love.graphics.draw(textures_image_convert, wall_quad, starting_segment, wall_draw_offset - texture_y_offset - (unfixed_distance * layer), 0, 1, unfixed_distance/32)
	love.graphics.setColor(1,1,1,1)
end

function render.createRay()  
	return {
		x = 0,
		y = 0,
		texture = 0,
		distance = 0,
		shade = 0
	}
end

function render:drawSky(player_object) 
	for y = 0, 119 do
		local sky_strip = {}
		for x = 0, 319 do
			local meow = (-(player_object.angle / (2*pi)*4) * 320 - x)
			
			if meow < 0 then
				meow = meow + 320
			end
			
			meow = meow % 640
			
			local r, g, b, a = sky_image:getPixel(meow, y)

			sky_strip[x] = {x,y,r,g,b,a}
		end

		love.graphics.points(sky_strip)
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
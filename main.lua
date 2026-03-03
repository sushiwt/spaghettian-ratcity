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
pi_half = pi / 2

-- File Requirements
local game_renderer = require("render")

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
	angle = pi_half,
	speed = 1,
	max_hp = 100,
	hp = 100
}

function Player:updateControls(dt, level_object) 
	-- Player Movement
	
	-- Keyboard Turn
	if love.keyboard.isDown("left") then
		self.angle = self.angle - 0.05 * (dt * speed)
		if self.angle < 0 then
			self.angle = self.angle + 2 * pi
		end
		self.delta_x = math.cos(self.angle) * self.speed
		self.delta_y = math.sin(self.angle) * self.speed
	end
	if love.keyboard.isDown("right") then
		self.angle = self.angle + 0.05 * (dt * speed)
		if self.angle >= 2*pi then
			self.angle = self.angle - 2 * pi
		end
		self.delta_x = math.cos(self.angle) * self.speed
		self.delta_y = math.sin(self.angle) * self.speed
	end
	
	-- Mouse Turn
	
	if mouse_controls == true then
		self.angle = self.angle + ((love.mouse.getX() - game_renderer.center_width) * 0.001) * (dt * speed)
		if self.angle < 0 then
			self.angle = self.angle + 2 * pi
		end
		if self.angle >= 2*pi then
			self.angle = self.angle - 2 * pi
		end
		self.delta_x = math.cos(self.angle) * self.speed
		self.delta_y = math.sin(self.angle) * self.speed
		love.mouse.setPosition(game_renderer.center_width,game_renderer.center_height)
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
				self.x = self.x + self.delta_x * (dt * speed)
			end
			
			if level_object.walls[math.floor(gridpos_add_yoffset) + 1][math.floor(player_gridpos_x + 1)] == nil or level_object.walls[math.floor(gridpos_add_yoffset) + 1][math.floor(player_gridpos_x + 1)] == 0 then
				self.y = self.y + self.delta_y * (dt * speed)
			end
		end
		-- self.x = self.x + self.delta_x * (dt * speed)
		-- self.y = self.y + self.delta_y * (dt * speed)
	end
	
	if love.keyboard.isDown("down") or love.keyboard.isDown("s") then
		if gridpos_sub_xoffset < level_object.columns and gridpos_sub_yoffset < level_object.rows and gridpos_sub_xoffset > 0 and gridpos_sub_yoffset > 0 then
			if level_object.walls[math.floor(player_gridpos_y) + 1][math.floor(gridpos_sub_xoffset + 1)] == 0 then
				self.x = self.x - self.delta_x * (dt * speed)
			end
			if level_object.walls[math.floor(gridpos_sub_yoffset) + 1][math.floor(player_gridpos_x + 1)] == 0 then
				self.y = self.y - self.delta_y * (dt * speed)
			end
		end
		-- self.x = self.x - self.delta_x * (dt * speed)
		-- self.y = self.y - self.delta_y * (dt * speed)
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
	
	-- Triggers
	if math.floor(self.x / level_object.cell_size) == 1 and math.floor(self.y / level_object.cell_size) == 5 then
		game_state = 2
	end
end

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
		Player:updateControls(dt)

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
		love.graphics.setPointSize(game_renderer.quality)

		-- drawSky()
		drawLevel()
		--drawSprite()
		
		love.graphics.draw(shooter_image, game_renderer.width - 180, game_renderer.height - 128,  0, 4)
		love.graphics.draw(healthbar_image, 32, game_renderer.height - 128 , 0, 3)
		love.graphics.draw(crosshair_image, game_renderer.center_width - 15, game_renderer.center_height - 15)

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
				if game_renderer.fog < 10 then
					game_renderer.fog = game_renderer.fog + 1
				else
					game_renderer.fog = 0
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
						game_renderer.fog = tonumber(value)
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
	game_renderer:raycaster(Player, Level)
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
	love.graphics.rectangle("fill", 0,0,game_renderer.width,game_renderer.height)

	-- Draws the level
	for row, row_value in pairs(Level.walls) do
		for column, column_value in ipairs(row_value) do
			love.graphics.setColor(1,1,1, 0.8)
			
			row_left = row * Level.cell_size - Level.cell_size - Player.y + (game_renderer.height / 2)
			column_top = column * Level.cell_size - Level.cell_size - Player.x + (game_renderer.width / 2)
			row_right = row * Level.cell_size - Player.y + (game_renderer.height / 2)
			column_bottom = column * Level.cell_size - Player.x + (game_renderer.width / 2)
			
			local vertices = {column_top, row_left, column_top, row_right, column_bottom, row_right, column_bottom, row_left}
			
			if column_value > 0 then
				love.graphics.polygon("fill", vertices)
			end
		end
	end
	
	-- Draws the player
	love.graphics.setColor(255, 0, 0)
	love.graphics.circle( "fill", game_renderer.width / 2, game_renderer.height / 2, 3)
	
	love.graphics.line(game_renderer.width / 2, game_renderer.height / 2, game_renderer.width / 2 + Player.delta_x * 10, game_renderer.height / 2 + Player.delta_y * 10)
	
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
		
		sprite_x = (sprite_x * (game_renderer.width / 1.4) / (sprite_y + epsilon))+(game_renderer.width/2)
		sprite_y = (sprite_z * (game_renderer.width / 1.4) / (sprite_y + epsilon))+(game_renderer.height/2)
		
		local sprite_size = 16 
		local scale = (sprite_size * game_renderer.height / (b + epsilon))
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

			if player_shoot and sprite_x > game_renderer.center_width - 20 and sprite_x < game_renderer.center_width + 20 then
				sprites[index].state = 0
			end
			player_shoot = false
		end

		if b < 25 then
			sprite_quality = (1 / (b + epsilon)) * 25
		end
		
		if game_renderer.fog > 0 then
			sprite_shade = math.min(1 / (b + epsilon) * (game_renderer.fog * 25), 1)
		end
		
		local sprite_strip = {}
		local sprite_strip_index = 0
		
		for x = sprite_x - scale / 2, sprite_x + scale / 2, game_renderer.quality + sprite_quality do
			-- The third condition is a failsafe to not cause an out of bounds error,
			-- but it refuses to draw the rest of the sprite because of it.
			-- Fix it later
			sprite_texture_y = 16
			for y = 0, scale do
				if self.depth[math.floor(x/game_renderer.quality) + 1] ~= nil and 
				b > 10 and b < game_renderer.depth[math.floor(x/game_renderer.quality) + 1] and 
				sprite_y - y < game_renderer.height and
				sprites[index].state == 1
				then
					local r,g,b,a = sprites_image:getPixel(math.floor(sprite_texture_x * (game_renderer.quality + sprite_quality)),math.floor(sprite_texture_y) + (sprites[index].texture * sprite_size))
					
					sprite_strip[sprite_strip_index] = {x - game_renderer.quality / 2, sprite_y - y, r * sprite_shade,g * sprite_shade,b * sprite_shade,a}
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

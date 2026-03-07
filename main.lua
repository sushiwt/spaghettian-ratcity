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
local player_meow = require("player")
local level_meow = require("levelhandler")
local sprite_meow = require("spritehandler")

level_topdown_toggle = false
mouse_controls = true

-- Gun Settings
player_shoot = false

ui_offset_x = 0
ui_offset_y = 400

-- Map Textures
textures_image = love.image.newImageData("graphics/defaulttexture.png")
sky_image = love.image.newImageData("graphics/defaultsky.png")
sprites_image = love.image.newImageData("graphics/smiley.png")

textures_image_convert = love.graphics.newImage(textures_image)

-- UI Textures
shooter_image = love.graphics.newImage("graphics/lasershooter.png")
healthbar_image = love.graphics.newImage("graphics/uibar.png")
crosshair_image = love.graphics.newImage("graphics/crosshair.png")

-- Misc stuff
debug_number = 0
debug_number2 = 0
fps = 0
delta_time = 0

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
	textures_image_convert:setFilter("nearest", "nearest")
    shooter_image:setFilter("nearest", "nearest")
    healthbar_image:setFilter("nearest", "nearest")
	if game_state == 1 then
		initializeGame()
	end
end

function love.update(dt)
	if game_state == 1 then
		player_meow:updateControls(dt, level_meow)
		sprite_meow.updateSprite(sprites, player_meow, game_renderer)

		
		-- Triggers
		if math.floor(player_meow.x / level_meow.cell_size) == 1 and math.floor(player_meow.y / level_meow.cell_size) == 5 then
			game_state = 2
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

		-- game_renderer:drawSky(player_meow)
		game_renderer:drawRaycaster(level_meow, player_meow)
		-- game_renderer:drawSprites(sprites, player_meow)
		
		love.graphics.draw(shooter_image, game_renderer.width - 180, game_renderer.height - 128,  0, 4)
		love.graphics.draw(healthbar_image, 32, game_renderer.height - 128 , 0, 3)
		love.graphics.draw(crosshair_image, game_renderer.center_width - 15, game_renderer.center_height - 15)

		if level_topdown_toggle then
			drawTopDownView()
		end

		love.graphics.print(math.floor(player_meow.x) .. ", " .. math.floor(player_meow.y), ui_offset_x, ui_offset_y)
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
	showFpsGraph(16,16,240, 128)
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
				level_topdown_toggle = not level_topdown_toggle
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

function initializeGame()
	player_meow.delta_x = math.cos(player_meow.angle) * player_meow.speed
	player_meow.delta_y = math.sin(player_meow.angle) * player_meow.speed
	if mouse_controls then
		love.mouse.setGrabbed(true)
		love.mouse.setVisible(false)
	end
	
	sprites[1] = sprite_meow.createSprite(2, 1, 0, level_meow.cell_size * 3.5, level_meow.cell_size * 2, 8)
	sprites[2] = sprite_meow.createSprite(1, 1, 1, level_meow.cell_size * 4.5, level_meow.cell_size * 2, 8)
	sprites[3] = sprite_meow.createSprite(1, 1, 0, level_meow.cell_size * 5.5, level_meow.cell_size * 2, 8)
	
	-- Load level if levels are available
	if love.filesystem.getInfo("levels/" .. level .. ".srl") then
		level_meow:loadLevel(level, game_renderer, player_meow)
	else
		level_meow:loadLevel("default", game_renderer, player_meow)
		invalid_level = true
	end
end

-- Display Functions
function drawTopDownView(level_object) 
	-- Draws the background of the level overlay
	love.graphics.setColor(0,0,0, 0.75)
	love.graphics.rectangle("fill", 0,0,game_renderer.width,game_renderer.height)

	-- Draws the level
	for row, row_value in pairs(level_meow.walls) do
		for column, column_value in ipairs(row_value) do
			love.graphics.setColor(1,1,1, 0.8)
			
			row_left = row * level_meow.cell_size - level_meow.cell_size - player_meow.y + (game_renderer.height / 2)
			column_top = column * level_meow.cell_size - level_meow.cell_size - player_meow.x + (game_renderer.width / 2)
			row_right = row * level_meow.cell_size - player_meow.y + (game_renderer.height / 2)
			column_bottom = column * level_meow.cell_size - player_meow.x + (game_renderer.width / 2)
			
			local vertices = {column_top, row_left, column_top, row_right, column_bottom, row_right, column_bottom, row_left}
			
			if column_value > 0 then
				love.graphics.polygon("fill", vertices)
			end
		end
	end
	
	-- Draws the player
	love.graphics.setColor(255, 0, 0)
	love.graphics.circle( "fill", game_renderer.width / 2, game_renderer.height / 2, 3)
	
	love.graphics.line(game_renderer.width / 2, game_renderer.height / 2, game_renderer.width / 2 + player_meow.delta_x * 10, game_renderer.height / 2 + player_meow.delta_y * 10)
	
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

-- Spaghettian Ratcity v0.1.7

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
local object_meow = require("objecthandler")

local level_topdown_toggle = false

local ui_offset_x = 32
local ui_offset_y = 200

local hud_visible = false

-- Map Textures
textures_image = love.image.newImageData("graphics/defaulttexture.png")
sky_image = love.image.newImageData("graphics/defaultsky.png")
textures_image_convert = love.graphics.newImage(textures_image)

-- UI Textures
shooter_image = love.graphics.newImage("graphics/lasershooter.png")
healthbar_image = love.graphics.newImage("graphics/uibar.png")
crosshair_image = love.graphics.newImage("graphics/crosshair.png")
background_image = love.graphics.newImage("graphics/menu_background.png")
pelvis_image = love.graphics.newImage("graphics/pelvis.png")

-- Misc stuff
local fps = 0
local delta_time = 0

local objects = {}

-- Level initialization. 
local level = "house1"
local invalid_level = false

-- Game States
local game_state = "game"

-- Main Menus
local menu_option = 0
local ui_font_size = 32
local ui_line_height = 32

-- For drawing the fps graph...
local fps_graph = {0,0}
local fps_point = 0

-- Love2D Functions
function love.load(dt) 
	textures_image_convert:setFilter("nearest", "nearest")
    shooter_image:setFilter("nearest", "nearest")
    healthbar_image:setFilter("nearest", "nearest")
    background_image:setFilter("nearest", "nearest")

	myFont = love.graphics.newFont("graphics/minitext.ttf", ui_font_size)

	if game_state == "game" then
		initializeGame()
	end
end

function love.update(dt)

	if game_state == "game" then
		player_meow:updateControls(dt, level_meow)
		objects = object_meow.updateObject(objects, player_meow, game_renderer)
		

		-- Triggers
		if math.floor(player_meow.x / level_meow.cell_size) == 1 and math.floor(player_meow.y / level_meow.cell_size) == 5 then
			game_state = "win"
		end
	end

	fps = 1 / dt
	delta_time = dt

end


function love.draw()
	love.graphics.setFont(myFont)
	local menu_margin = 10


	if game_state == "menu" then
		for rows = 0, love.graphics.getWidth() / 128 do 
			for cols = 0, love.graphics.getHeight() / 128 do
				love.graphics.draw(background_image, rows * 128, cols * 128,0,4)
			end
		end

		love.graphics.print("Spaghettian Ratcity (Test Menu)", menu_margin, menu_margin)
		
		love.graphics.setColor(0,0,0,0.5)
		love.graphics.rectangle("fill", menu_margin, (ui_font_size * 2) + (menu_option * (ui_font_size)) + menu_margin, 128, 32)

		love.graphics.setColor(1,1,1)
		love.graphics.print("Play" , 8 + menu_margin, (ui_font_size * 2) + menu_margin)
		love.graphics.print("Options" , 8 + menu_margin, (ui_font_size * 3) + menu_margin)
		love.graphics.print("Quit" , 8 + menu_margin, (ui_font_size * 4) + menu_margin)

	elseif game_state == "game" then
		love.graphics.setPointSize(game_renderer.quality)

		
		-- game_renderer:drawSky(player_meow)
		game_renderer:drawRaycaster(level_meow, player_meow)
		game_renderer:drawObjects(objects, player_meow, level_meow)

		if hud_visible then
			-- love.graphics.draw(shooter_image, game_renderer.width - 180 + (-8 * math.cos(view_bobbing)), game_renderer.height - 128 + (-8 * math.abs(math.sin(view_bobbing))) + 8,  0, 4)
			love.graphics.draw(crosshair_image, game_renderer.center_width - 15, game_renderer.center_height - 15)
			-- love.graphics.draw(healthbar_image, 32, game_renderer.height - 128 , 0, 3)
			
			love.graphics.print("Name: Pelvis", ui_offset_x, ui_offset_y)
			love.graphics.print("HP: " .. player_meow.hp .. "/" .. player_meow.max_hp, ui_offset_x, ui_offset_y + ui_line_height)
			love.graphics.print("Ammo: " .. player_meow.ammo .. "/" .. player_meow.inventory_ammo, ui_offset_x, ui_offset_y + ui_line_height * 2)
			love.graphics.print("Position: " .. math.floor(player_meow.x) .. ", " .. math.floor(player_meow.y), ui_offset_x, ui_offset_y + ui_line_height * 3)
			love.graphics.print("AverageDebug: " .. player_meow.averaged_mouse, ui_offset_x, ui_offset_y + ui_line_height * 4)

			love.graphics.setLineWidth(1)
			showFpsGraph(16,16,240, 128)

			
		end
		
		if invalid_level then
			love.graphics.setColor(0,0,0,0.75)
			love.graphics.rectangle("fill", 0, 0, 256, 100)
			love.graphics.setColor(1,1,1)
			love.graphics.setNewFont(10)
			love.graphics.print("If you're seeing this, the program tried \nto load a level that doesnt exist, " .. level .. ".srl,\nand it failed. \n\nCheck the levels/ directory.", 0, 0)
		end
		
		if level_topdown_toggle then
			drawTopDownView()
		end

	elseif game_state == "options" then 
		love.graphics.print("Options!!!! Change your Settinsg here!!!", menu_margin, menu_margin)
	elseif game_state == "win" then
		love.graphics.print("You win! (Win Screen Test)", menu_margin, menu_margin)
	elseif game_state == "lose" then
		love.graphics.print("You lose! (Lose Screen Test)", menu_margin, menu_margin)
	end
	
end

function love.keypressed(key, scancode, isrepeat)
   	if key == "escape" then
		love.mouse.setGrabbed(false)
		love.mouse.setVisible(true)
		game_state = "menu"

  	end 

	if game_state == "menu" then
		if key == "down" and menu_option < 2 then
			menu_option = menu_option + 1
		elseif key == "up" and menu_option > 0 then
			menu_option = menu_option - 1
		elseif key == "z" or key == "return" then
			if menu_option == 0 then
				game_state = "game"
				initializeGame()
			elseif menu_option == 1 then
				game_state = "options"
			elseif menu_option == 2 then
				love.event.quit()
			end

			menu_option = 0
		end
	elseif game_state == "game" then
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
      player_meow.mouse_shoot = true
   end
end

function initializeGame()
	player_meow.delta_x = math.cos(player_meow.angle) * player_meow.speed
	player_meow.delta_y = math.sin(player_meow.angle) * player_meow.speed
	if player_meow.mouse_controls then
		love.mouse.setGrabbed(true)
		love.mouse.setVisible(false) 
	end
	
	objects[1] = object_meow.createObject("enemy", 1, "smiley_single", level_meow.cell_size * 3.5, level_meow.cell_size * 2, 8)
	objects[2] = object_meow.createObject("pickup", 1, "spaghetti", level_meow.cell_size * 4.5, level_meow.cell_size * 2, 8)
	objects[3] = object_meow.createObject("pickup", 1, "metal_ball", level_meow.cell_size * 5.5, level_meow.cell_size * 2, 10)
	
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
			
			-- if column_value > 0 then
			-- 	love.graphics.polygon("fill", vertices)
			-- end

			if (column_value ~= 0) then

				
				local textureQuad = love.graphics.newQuad(0,level_meow.cell_size * (column_value - 1), level_meow.cell_size, level_meow.cell_size, textures_image_convert)
				love.graphics.draw(textures_image_convert, textureQuad, column_top, row_left)
			end

		end
	end
	
	-- Draws the player
	love.graphics.setColor(255, 0, 0)
	love.graphics.circle( "fill", game_renderer.width / 2, game_renderer.height / 2, 3)
	
	love.graphics.line(game_renderer.width / 2, game_renderer.height / 2, game_renderer.width / 2 + player_meow.delta_x * 10, game_renderer.height / 2 + player_meow.delta_y * 10)
	
	love.graphics.setColor(1,1,1)
	love.graphics.draw(pelvis_image, game_renderer.width / 2, game_renderer.height / 2, player_meow.angle - pi/2, 1, 1, 30, 30)

	love.graphics.setPointSize(8)

	-- Draws the objects
	for index, object in ipairs(objects) do
		if object.state ~= 0 then 
		love.graphics.points(object.x - player_meow.x + (game_renderer.width / 2), object.y - player_meow.y + (game_renderer.height / 2))
		end
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

local fps_timer = 0
local fps_tick = 0
local fps_average = 0
local fps_count = 0

function showFpsGraph(x,y, graph_width, graph_height) 
	table.insert(fps_graph, x + fps_point)
	table.insert(fps_graph, y + (graph_height - fps))
	fps_point = fps_point + (delta_time * 100)
	fps_timer = fps_timer + delta_time

	fps_average = fps_average + fps
	fps_count = fps_count + 1

	if fps_timer > 0.5 then 
		fps_tick = math.floor(fps_average / fps_count)
		fps_timer = 0
		fps_average = 0
		fps_count = 0
	end

	if fps_point > graph_width then
		fps_point = 0
		fps_graph = {0,0,0,0}
	end

	love.graphics.setColor(0,0,0,0.5)
	love.graphics.rectangle("fill", x, y, graph_width, graph_height)
	love.graphics.setColor(1,1,1)
	love.graphics.print(fps_tick, x, y)
	love.graphics.line(fps_graph)
end
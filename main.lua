-- Spaghettian Ratcity v0.1.8

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

-- Variables used everywhere
level = "house1"
invalid_level = false

menu_margin = 10

ui_font_size = 32
ui_line_height = 32

local fps = 0
local delta_time = 0

local myFont = love.graphics.newFont("graphics/minitext.ttf", ui_font_size)

game_handler = require("gamestates.game")
menu_handler = require("gamestates.menu")
options_handler = require("gamestates.options")
win_handler = require("gamestates.win")
lose_handler = require("gamestates.lose")

game_state_updated = game_handler

-- Love2D Functions
function love.load(dt) 
	textures_image_convert:setFilter("nearest", "nearest")
    shooter_image:setFilter("nearest", "nearest")
    healthbar_image:setFilter("nearest", "nearest")
    background_image:setFilter("nearest", "nearest")

	game_handler:initializeGame()
end

function love.update(dt)
	if type(game_state_updated.update) == "function" then
		game_state_updated:update(dt)
	end

	fps = 1 / dt
	delta_time = dt
end

function love.draw()
	love.graphics.setFont(myFont)
	if type(game_state_updated.draw) == "function" then
		game_state_updated:draw()
	end
end

function love.keypressed(key, scancode, isrepeat)
   	if key == "escape" then
		love.mouse.setGrabbed(false)
		love.mouse.setVisible(true)
		game_state_updated = menu_handler
  	end 

	if type(game_state_updated.keypressed) == "function" then
		game_state_updated:keypressed(key, scancode, isrepeat)
	end
end

function love.mousepressed(x, y, button, istouch)
	if type(game_state_updated.mousepressed) == "function" then
		game_state_updated:mousepressed(x, y, button, istouch)
	end
end

-- For drawing the fps graph...
local fps_timer = 0
local fps_tick = 0
local fps_average = 0
local fps_count = 0

local fps_graph = {0,0}
local fps_point = 0

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
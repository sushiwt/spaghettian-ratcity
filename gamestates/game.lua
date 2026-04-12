local game = {}

game.game_renderer = require("handlers.render")
game.player_meow = require("handlers.player")
game.level_meow = require("handlers.levelhandler")
game.object_meow = require("handlers.objecthandler")

game.level_topdown_toggle = false

game.ui_offset_x = 32
game.ui_offset_y = 200

game.hud_visible = false

function game:update(dt)
    self.player_meow:updateControls(dt, self.level_meow)
    self.level_meow.objects = self.object_meow.updateObject(self.level_meow.objects, self.player_meow, self.game_renderer)
    
    -- Triggers
    if math.floor(self.player_meow.x / self.level_meow.cell_size) == 1 and math.floor(self.player_meow.y / self.level_meow.cell_size) == 5 then
        game_state_updated = win_handler
    end
end

function game:draw()
    love.graphics.setPointSize(self.game_renderer.quality)
    
    -- self.game_renderer:drawSky(self.player_meow)
    self.game_renderer:drawRaycaster(self.level_meow, self.player_meow)
    self.game_renderer:drawObjects(self.level_meow.objects, self.player_meow, self.level_meow)

    if self.hud_visible then
        -- love.graphics.draw(shooter_image, self.game_renderer.width - 180 + (-8 * math.cos(view_bobbing)), self.game_renderer.height - 128 + (-8 * math.abs(math.sin(view_bobbing))) + 8,  0, 4)
        love.graphics.draw(crosshair_image, self.game_renderer.center_width - 15, self.game_renderer.center_height - 15)
        -- love.graphics.draw(healthbar_image, 32, self.game_renderer.height - 128 , 0, 3)
        
        love.graphics.print("Name: Pelvis", self.ui_offset_x, self.ui_offset_y)
        love.graphics.print("HP: " .. self.player_meow.hp .. "/" .. self.player_meow.max_hp, self.ui_offset_x, self.ui_offset_y + ui_line_height)
        love.graphics.print("Ammo: " .. self.player_meow.ammo .. "/" .. self.player_meow.inventory_ammo, self.ui_offset_x, self.ui_offset_y + ui_line_height * 2)
        love.graphics.print("Position: " .. math.floor(self.player_meow.x) .. ", " .. math.floor(self.player_meow.y), self.ui_offset_x, self.ui_offset_y + ui_line_height * 3)
        love.graphics.print("AverageDebug: " .. self.player_meow.averaged_mouse, self.ui_offset_x, self.ui_offset_y + ui_line_height * 4)

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
    
    if self.level_topdown_toggle then
        self.game_renderer:drawTopDownView(self.level_meow, self.player_meow)
    end

end

function game:keypressed(key, scancode, isrepeat)
	if key == "u" then
        if self.game_renderer.fog < 10 then
            self.game_renderer.fog = self.game_renderer.fog + 1
        else
            self.game_renderer.fog = 0
        end
    end
    if key == "i" then
            self.level_topdown_toggle = not self.level_topdown_toggle
    end
    if key == "t" then
            initializeGame()
    end
end

function game:mousepressed(x, y, button, istouch)
  if button == 1 then
      self.player_meow.mouse_shoot = true
   end
end

function game:initializeGame()
	self.player_meow.delta_x = math.cos(self.player_meow.angle) * self.player_meow.speed
	self.player_meow.delta_y = math.sin(self.player_meow.angle) * self.player_meow.speed
	if self.player_meow.mouse_controls then
		love.mouse.setGrabbed(true)
		love.mouse.setVisible(false) 
	end
	
	self.level_meow.objects[1] = self.object_meow.createObject("enemy", 1, "smiley_single", self.level_meow.cell_size * 3.5, self.level_meow.cell_size * 2, 8)
	self.level_meow.objects[2] = self.object_meow.createObject("pickup", 1, "spaghetti", self.level_meow.cell_size * 4.5, self.level_meow.cell_size * 2, 8)
	self.level_meow.objects[3] = self.object_meow.createObject("pickup", 1, "metal_ball", self.level_meow.cell_size * 5.5, self.level_meow.cell_size * 2, 10)
	
	-- Load level if levels are available
	if love.filesystem.getInfo("levels/" .. level .. ".srl") then
		self.level_meow:loadLevel(level, self.game_renderer, self.player_meow)
	else
		self.level_meow:loadLevel("default", self.game_renderer, self.player_meow)
		invalid_level = true
	end
end

return game
local menu = {}

menu.menu_option = 0

function menu:draw() 
	for rows = 0, love.graphics.getWidth() / 128 do 
        for cols = 0, love.graphics.getHeight() / 128 do
            love.graphics.draw(background_image, rows * 128, cols * 128,0,4)
        end
    end

    love.graphics.print("Spaghettian Ratcity (Test Menu)", menu_margin, menu_margin)
    
    love.graphics.setColor(0,0,0,0.5)
    love.graphics.rectangle("fill", menu_margin, (ui_font_size * 2) + (self.menu_option * (ui_font_size)) + menu_margin, 128, 32)

    love.graphics.setColor(1,1,1)
    love.graphics.print("Play" , 8 + menu_margin, (ui_font_size * 2) + menu_margin)
    love.graphics.print("Options" , 8 + menu_margin, (ui_font_size * 3) + menu_margin)
    love.graphics.print("Quit" , 8 + menu_margin, (ui_font_size * 4) + menu_margin)
end

function menu:keypressed(key, scancode, isrepeat) 
    if key == "down" and self.menu_option < 2 then
        self.menu_option = self.menu_option + 1
    elseif key == "up" and self.menu_option > 0 then
        self.menu_option = self.menu_option - 1
    elseif key == "z" or key == "return" then
        if self.menu_option == 0 then
            game_state_updated = game_handler
            game_handler:initializeGame()
        elseif self.menu_option == 1 then
            game_state_updated = options_handler
        elseif self.menu_option == 2 then
            love.event.quit()
        end

        self.menu_option = 0
    end
end

return menu
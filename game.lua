local game = {}

game.game_renderer = require("render")
game.player_meow = require("player")
game.level_meow = require("levelhandler")
game.object_meow = require("objecthandler")

game.level_topdown_toggle = false

game.ui_offset_x = 32
game.ui_offset_y = 200

game.hud_visible = false

function game:load()

end

function game:update(dt)

end

function game:draw()

end

function game:keypressed(key, scancode, isrepeat)

end

function game:mousepressed(x, y, button, istouch)

end

function game:initializeGame()

end

return game
-- Spaghettian Ratcity Level Editor v0.1.0

local walls = {}
local floors = {}
local ceilings = {}
local rows = 8
local columns = 8
local wall_height = 30
local cell_size = 32

local chosen_texture = 0

local texture = love.graphics.newImage("graphics/texture.png")

function love.load()
    for row = 0, rows do 
        local row_array = {}

        for col = 0, columns do
            table.insert(row_array, 0)
        end

        table.insert(walls, row_array)
    end
end

function love.update() 
    if love.mouse.isDown(1) and math.floor(love.mouse.getY() / 32) < rows and math.floor(love.mouse.getX() / 32) < columns then
        walls[math.floor(love.mouse.getY() / 32) + 1][math.floor(love.mouse.getX() / 32) + 1] = chosen_texture + 1
    end
    if love.mouse.isDown(2) and math.floor(love.mouse.getY() / 32) < rows and math.floor(love.mouse.getX() / 32) < columns then
        walls[math.floor(love.mouse.getY() / 32) + 1][math.floor(love.mouse.getX() / 32) + 1] = 0
    end
end

function love.draw() 

    
    love.graphics.setColor(1,1,1,0.5)

    love.graphics.line(0, 0, columns * 32, 0)
    for row = 0, rows do 
        love.graphics.line(0, row * 32, columns * 32, row * 32)
    end


    for col = 0, columns do 
        love.graphics.line(col * 32, 0, col * 32, rows * 32)
    end

    love.graphics.rectangle("fill", math.floor(love.mouse.getX() / 32) * 32, math.floor(love.mouse.getY() / 32) * 32, 32, 32)


    love.graphics.setColor(1,1,1,1)
    love.graphics.print(chosen_texture)

    for row, row_value in ipairs(walls) do 
        for column, col_value in ipairs(row_value) do
            if col_value > 0 then
                local texture_quad = love.graphics.newQuad(0, (col_value - 1) * 32, 32, 32, texture)


                love.graphics.rectangle("fill", (column - 1) * 32, (row - 1) * 32, 32, 32)
                love.graphics.draw(texture, texture_quad, (column - 1) * 32, (row - 1) * 32)

            end
        end
    end
end

function love.keypressed(key, scancode, isrepeat)
    if key == "up" then
        chosen_texture = chosen_texture + 1
    end

    if key == "down" then
        chosen_texture = chosen_texture - 1
    end
end
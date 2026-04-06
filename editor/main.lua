-- Spaghettian Ratcity Level Editor v0.1.0

local walls = {}
local floors = {}
local ceilings = {}
local rows = 8
local columns = 8
local wall_height = 30
local cell_size = 32

local editor_cell_size = 32

local editor_offset_x = 32
local editor_offset_y = 32

local grid_position_x = 320
local grid_position_y = 180

local chosen_texture = 0

local texture = love.graphics.newImage("graphics/texture.png")

function love.load()
    editor_offset_x = 320 - (columns * (editor_cell_size / 2))
    editor_offset_y = 180 - (rows * (editor_cell_size / 2))
    setuplevel()
end

function love.update() 
    editor_offset_x = grid_position_x - (columns * (editor_cell_size / 2))
    editor_offset_y = grid_position_y - (rows * (editor_cell_size / 2))

    if love.mouse.isDown(1) and 
        love.mouse.getX() > editor_offset_x and 
        love.mouse.getY() > editor_offset_y and 
        love.mouse.getX() < columns * editor_cell_size + editor_offset_x and 
        love.mouse.getY() < rows * editor_cell_size + editor_offset_y then
        walls[math.floor((love.mouse.getY() - editor_offset_y) / editor_cell_size) + 1][math.floor((love.mouse.getX() - editor_offset_x) / editor_cell_size) + 1] = chosen_texture
    end
    if love.mouse.isDown(2) and math.floor(love.mouse.getY() / editor_cell_size) < rows and math.floor(love.mouse.getX() / editor_cell_size) < columns then
        walls[math.floor((love.mouse.getY() - editor_offset_y) / editor_cell_size) + 1][math.floor((love.mouse.getX() - editor_offset_x) / editor_cell_size) + 1] = 0
    end

    if love.keyboard.isDown("w") then
        grid_position_y = grid_position_y - 2
    end
    if love.keyboard.isDown("s") then
        grid_position_y = grid_position_y + 2
    end
    if love.keyboard.isDown("a") then
        grid_position_x = grid_position_x - 2
    end
    if love.keyboard.isDown("d") then
        grid_position_x = grid_position_x + 2
    end

end

function love.draw() 

    
    love.graphics.setColor(1,1,1,0.5)

    -- Draw Grid
    for row = 0, rows do 
        love.graphics.line(editor_offset_x, row * editor_cell_size + editor_offset_y, columns * editor_cell_size + editor_offset_x, row * editor_cell_size + editor_offset_y)
    end

    for col = 0, columns do 
        love.graphics.line(col * editor_cell_size + editor_offset_x, editor_offset_y, col * editor_cell_size + editor_offset_x, rows * editor_cell_size + editor_offset_y)
    end

    -- Highlight
    -- if love.mouse.getX() > editor_offset_x and 
    -- love.mouse.getY() > editor_offset_y and 
    -- love.mouse.getX() < columns * editor_cell_size + editor_offset_x and 
    -- love.mouse.getY() < rows * editor_cell_size + editor_offset_y then
    --     love.graphics.rectangle("fill", math.floor((love.mouse.getX()) / editor_cell_size) * editor_cell_size, math.floor(love.mouse.getY() / editor_cell_size) * editor_cell_size, editor_cell_size, editor_cell_size)
    -- end

    love.graphics.setColor(1,1,1,1)

    -- Draw Texture Brush

    love.graphics.print("Texture: ")
    love.graphics.print(chosen_texture, 0, 18)
    local chosen_texture_quad = love.graphics.newQuad(0, (chosen_texture - 1) * 32, 32, 32, texture)

    if chosen_texture > 0 then
        love.graphics.draw(texture, chosen_texture_quad, 0, 18)
    end

    -- Draw Walls
    for row, row_value in ipairs(walls) do 
        for column, col_value in ipairs(row_value) do
            if col_value > 0 then
                local texture_quad = love.graphics.newQuad(0, (col_value - 1) * 32, editor_cell_size, editor_cell_size, texture)

                love.graphics.print(col_value,(column - 1) * editor_cell_size + editor_offset_x + 8, (row - 1) * editor_cell_size + editor_offset_y + 8)
                love.graphics.draw(texture, texture_quad, (column - 1) * editor_cell_size + editor_offset_x, (row - 1) * editor_cell_size + editor_offset_y, 0)
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


function love.wheelmoved(x, y)
    editor_cell_size = editor_cell_size + y
end

function setuplevel()
    for row = 0, rows do 
        local row_array = {}

        for col = 0, columns do
            table.insert(row_array, 0)
        end

        table.insert(walls, row_array)
        table.insert(floors, row_array)
        table.insert(ceilings, row_array)
    end
end
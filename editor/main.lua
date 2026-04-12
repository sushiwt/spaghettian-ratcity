-- Spaghettian Ratcity Level Editor v0.1.0

-- Level properties
local walls = {}
local floors = {}
local ceilings = {}
local rows = 20
local columns = 20
local wall_height = 30
local cell_size = 32
local level_fog = 0

local player_x = 64
local player_y = 64

-- Editor properties
local editor_cell_size = 32
local editor_offset_x = 32
local editor_offset_y = 32
local grid_position_x = 320
local grid_position_y = 180

local chosen_texture = 1

local texture = love.graphics.newImage("graphics/texture.png")
local save_file = ""

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
     if love.mouse.isDown(2) and 
        love.mouse.getX() > editor_offset_x and 
        love.mouse.getY() > editor_offset_y and 
        love.mouse.getX() < columns * editor_cell_size + editor_offset_x and 
        love.mouse.getY() < rows * editor_cell_size + editor_offset_y then
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
                local texture_quad = love.graphics.newQuad(0, (col_value - 1) * 32, 32, 32, texture)

                love.graphics.print(col_value,(column - 1) * editor_cell_size + editor_offset_x + 8, (row - 1) * editor_cell_size + editor_offset_y + 8)
                love.graphics.draw(texture, texture_quad, (column - 1) * editor_cell_size + editor_offset_x, (row - 1) * editor_cell_size + editor_offset_y, 0, editor_cell_size / 32)
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
    if key == "p" then
        save_file = 
        "lx," .. rows .. "\n" ..
        "ly," .. columns .. "\n" ..
        "py," .. player_x .. "\n" ..
        "py," .. player_y .. "\n" ..
        "fog," .. 0 .. "\n" ..
        "changetolevel\n"

        save_file = save_file .. levelToString(walls, "walls")
        save_file = save_file .. levelToString(floors, "floors")
        save_file = save_file .. levelToString(ceilings, "ceilings")

        love.filesystem.write("test.srl", save_file)
    end

    if key == "l" then
        loadLevel("house1")
    end
end

function love.wheelmoved(x, y)
    editor_cell_size = editor_cell_size + y
end

function setuplevel()
    walls = createLevelArray(walls) 
    floors = createLevelArray(floors) 
    ceilings = createLevelArray(ceilings) 
end

function loadLevel(level_name)
	-- .srl is just a plain text file. Wanted to be unique with my level file types lol
	local level_path = "levels/" .. level_name .. ".srl"

	walls = {}
	floors = {}
	ceilings = {}

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
						columns = tonumber(value)
					elseif level_info == "ly" then
						rows = tonumber(value)
					elseif level_info == "px" then
						-- player_object.x = tonumber(value)
                        player_x = tonumber(value)
					elseif level_info == "py" then
						-- player_object.y = tonumber(value)
                        player_y = tonumber(value)
					-- elseif level_info == "texture" then
					-- 	textures_image = love.image.newImageData("graphics/" .. value .. ".png")
					-- 	textures_image_convert = love.graphics.newImage(textures_image)
					-- 	textures_image_convert:setFilter("nearest", "nearest")
					-- elseif level_info == "sky" then
					-- 	sky_image = love.image.newImageData("graphics/" .. value .. ".png")
					elseif level_info == "fog" then
						level_fog = tonumber(value)
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
				table.insert(walls, level_row)
			elseif level_layer == "floors" then
				table.insert(floors, level_row)
			elseif level_layer == "ceilings" then
				table.insert(ceilings, level_row)
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

function createLevelArray(wall_array) 
    local array_result = {}

    for row = 1, rows do 
        local row_array = {}

        for col = 1, columns do
            table.insert(row_array, 0)
        end

        table.insert(array_result, row_array)
    end

    return array_result
end

function levelToString(wall_array, wall_name)
    local result = ""

    result = wall_name .. "\n"
    for i, vi in ipairs(wall_array) do
        for j, vj in ipairs(vi) do 
            result = result .. vj

            if j < #vi then
                result = result .. ","
            end
        end
        result = result .. "\n"
    end

    return result
end
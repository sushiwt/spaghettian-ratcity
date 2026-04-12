local levelhandler = {}

-- Level properties
levelhandler.walls = {}
levelhandler.floors = {}
levelhandler.ceilings = {}
levelhandler.rows = 0
levelhandler.columns = 0
levelhandler.wall_height = 30
levelhandler.cell_size = 32

levelhandler.objects = {}

function levelhandler:loadLevel(level_name, render_object, player_object)
	-- .srl is just a plain text file. Wanted to be unique with my level file types lol
	local level_path = "levels/" .. level_name .. ".srl"

	self.walls = {}
	self.floors = {}
	self.ceilings = {}

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
						self.columns = tonumber(value)
					elseif level_info == "ly" then
						self.rows = tonumber(value)
					elseif level_info == "px" then
						player_object.x = tonumber(value)
					elseif level_info == "py" then
						player_object.y = tonumber(value)
					elseif level_info == "texture" then
						textures_image = love.image.newImageData("graphics/" .. value .. ".png")
						textures_image_convert = love.graphics.newImage(textures_image)
						textures_image_convert:setFilter("nearest", "nearest")
					elseif level_info == "sky" then
						sky_image = love.image.newImageData("graphics/" .. value .. ".png")
					elseif level_info == "fog" then
						render_object.fog = tonumber(value)
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
				table.insert(self.walls, level_row)
			elseif level_layer == "floors" then
				table.insert(self.floors, level_row)
			elseif level_layer == "ceilings" then
				table.insert(self.ceilings, level_row)
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

return levelhandler
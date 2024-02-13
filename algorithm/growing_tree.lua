local random = math.random

we_maze.chooser = {}
function we_maze.chooser.random(cells)
	return random(#cells)
end
function we_maze.chooser.newest(cells)
	return #cells
end

function we_maze.algorithm.growing_tree(width, depth, chooser)
	if not chooser then
		return {}
	end
	local schem = {}
	-- schem[min/max][*] and schem[*][min/max] are outer walls
	-- schem[even][even] will all be part of a path
	-- schem[odd][odd] will all be part of a wall
	-- schem[odd][even] and schem[even][odd] may be either a wall or a path
	-- (width=5, depth=3) will look something like
	--[[
	 12345678901
	1###########
	2#   #     #
	3# # # # ###
	4# #   # # #
	5# # ### # #
	6# #   #   #
	7###########
	 12345678901
	]]
	for i = 1, 2 * depth + 1 do
		local row = {}
		for j = 1, 2 * width + 1 do
			row[j] = false
		end
		schem[i] = row
	end

	local function get_unvisited_neighbors(cell)
		local neighbors = {}
		if cell[1] ~= 2 and not schem[cell[1] - 2][cell[2]] then
			neighbors[#neighbors + 1] = { cell[1] - 2, cell[2], cell[1] - 1, cell[2] }
		end
		if cell[1] ~= 2 * depth and not schem[cell[1] + 2][cell[2]] then
			neighbors[#neighbors + 1] = { cell[1] + 2, cell[2], cell[1] + 1, cell[2] }
		end
		if cell[2] ~= 2 and not schem[cell[1]][cell[2] - 2] then
			neighbors[#neighbors + 1] = { cell[1], cell[2] - 2, cell[1], cell[2] - 1 }
		end
		if cell[2] ~= 2 * width and not schem[cell[1]][cell[2] + 2] then
			neighbors[#neighbors + 1] = { cell[1], cell[2] + 2, cell[1], cell[2] + 1 }
		end
		return neighbors
	end

	local cell = { 2 * random(depth), 2 * random(width) }
	schem[cell[1]][cell[2]] = true
	local cells = { cell }

	while #cells > 0 do
		local i = chooser(cells)
		cell = cells[i]
		local neighbors = get_unvisited_neighbors(cell)
		if #neighbors == 0 then
			table.remove(cells, i)
		else
			local neighbor = neighbors[random(#neighbors)]
			schem[neighbor[1]][neighbor[2]] = true
			schem[neighbor[3]][neighbor[4]] = true
			cells[#cells + 1] = { neighbor[1], neighbor[2] }
		end
	end

	return schem
end

function we_maze.algorithm.backtrack(width, depth)
	return we_maze.algorithm.growing_tree(width, depth, we_maze.chooser.newest)
end

function we_maze.algorithm.prims(width, depth)
	return we_maze.algorithm.growing_tree(width, depth, we_maze.chooser.random)
end

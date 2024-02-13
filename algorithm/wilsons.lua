local random = math.random

-- this is used to translate a path index to a schem index
local function d(i)
	return 2 * i
end

local function offset(el, dir)
	if dir == "u" then
		return { el[1] - 1, el[2] }
	elseif dir == "d" then
		return { el[1] + 1, el[2] }
	elseif dir == "l" then
		return { el[1], el[2] - 1 }
	elseif dir == "r" then
		return { el[1], el[2] + 1 }
	end
end

-- used to fill in the walls between main path nodes
local function schem_offset(el, dir)
	if dir == "u" then
		return { d(el[1]) - 2, d(el[2]) - 1 }
	elseif dir == "d" then
		return { d(el[1]), d(el[2]) - 1 }
	elseif dir == "l" then
		return { d(el[1]) - 1, d(el[2]) - 2 }
	elseif dir == "r" then
		return { d(el[1]) - 1, d(el[2]) }
	end
end

-- https://weblog.jamisbuck.org/2011/1/20/maze-generation-wilson-s-algorithm
function we_maze.algorithm.wilsons(width, depth)
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
	for i = 1, d(depth) + 1 do
		local row = {}
		for j = 1, d(width) + 1 do
			row[j] = false
		end
		schem[i] = row
	end
	local remaining = {}
	for i = 1, depth do
		for j = 1, width do
			remaining[#remaining + 1] = { i, j }
		end
	end
	local function remove_random_remaining()
		local i = random(#remaining)
		local el = remaining[i]
		table.remove(remaining, i) -- TODO O(n) but lua makes it hard to be better...
		return el
	end
	local function remove(el) -- TODO O(n) but lua makes it hard to be better...
		for i = 1, #remaining do
			local el2 = remaining[i]
			if el[1] == el2[1] and el[2] == el2[2] then
				table.remove(remaining, i)
				return
			end
		end
	end
	local function get_valid_dirs(el)
		local dirs = {}
		if el[1] ~= 1 then
			dirs[#dirs + 1] = "u"
		end
		if el[1] ~= depth then
			dirs[#dirs + 1] = "d"
		end
		if el[2] ~= 1 then
			dirs[#dirs + 1] = "l"
		end
		if el[2] ~= width then
			dirs[#dirs + 1] = "r"
		end
		return dirs
	end
	local function find_path_to_maze(el)
		local path = {}
		for i = 1, depth do
			path[i] = {}
		end
		while not schem[d(el[1])][d(el[2])] do
			local dirs = get_valid_dirs(el)
			local dir = dirs[random(#dirs)]
			path[el[1]][el[2]] = dir
			el = offset(el, dir)
		end
		return path
	end

	local el = remove_random_remaining()
	schem[d(el[1])][d(el[2])] = true
	while #remaining > 0 do
		el = remove_random_remaining()
		local path = find_path_to_maze(el)
		local dir = path[el[1]][el[2]]
		while dir do
			schem[d(el[1])][d(el[2])] = true
			remove(el)
			local wall_el = schem_offset(el, dir)
			schem[wall_el[1] + 1][wall_el[2] + 1] = true
			el = offset(el, dir)
			dir = path[el[1]][el[2]]
		end
	end
	return schem
end

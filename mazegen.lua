local random = math.random

-- this is used to translate a path index to a schem index
local function d(i)
	return 2 * i - 1
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
		return { d(el[1]) - 1, d(el[2]) }
	elseif dir == "d" then
		return { d(el[1]) + 1, d(el[2]) }
	elseif dir == "l" then
		return { d(el[1]), d(el[2]) - 1 }
	elseif dir == "r" then
		return { d(el[1]), d(el[2]) + 1 }
	end
end

-- https://weblog.jamisbuck.org/2011/1/20/maze-generation-wilson-s-algorithm
local function generate_maze_schem(width, depth)
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
	for i = 1, d(depth + 1) do
		local row = {}
		for j = 1, d(width + 1) do
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
		while not schem[d(el[1]) + 1][d(el[2]) + 1] do
			local dirs = get_valid_dirs(el)
			local dir = dirs[random(#dirs)]
			path[el[1]][el[2]] = dir
			el = offset(el, dir)
		end
		return path
	end

	local el = remove_random_remaining()
	schem[d(el[1]) + 1][d(el[2]) + 1] = true
	while #remaining > 0 do
		el = remove_random_remaining()
		local path = find_path_to_maze(el)
		local dir = path[el[1]][el[2]]
		while dir do
			schem[d(el[1]) + 1][d(el[2]) + 1] = true
			remove(el)
			local wall_el = schem_offset(el, dir)
			schem[wall_el[1] + 1][wall_el[2] + 1] = true
			el = offset(el, dir)
			dir = path[el[1]][el[2]]
		end
	end
	return schem
end

function we_maze.to_string(schem)
	local rows = {}
	for i = 1, #schem do
		local row = {}
		for j = 1, #schem[i] do
			row[j] = schem[i][j] and " " or "X"
		end
		rows[i] = table.concat(row, "")
	end
	return table.concat(rows, "\n")
end

function we_maze.generate(name, wall_nodes, fill_node, path_width, wall_width, seed)
	path_width = path_width or 1
	wall_width = wall_width or 1
	if seed then
		math.randomseed(seed)
	end
	local pos1, pos2 = worldedit.pos1[name]:sort(worldedit.pos2[name])
	local manip, area = worldedit.manip_helpers.init(pos1, pos2)
	local data = manip:get_data()
	local fill_id = minetest.get_content_id(fill_node)
	local node_ids = {}
	for i = 1, #wall_nodes do
		node_ids[i] = minetest.get_content_id(wall_nodes[i])
	end
	local width = math.floor(((pos2.x - pos1.x) + 1 - wall_width) / (path_width + wall_width))
	local depth = math.floor(((pos2.z - pos1.z) + 1 - wall_width) / (path_width + wall_width))
	local schem = generate_maze_schem(width, depth)
	local z0 = pos1.z
	for i, row in ipairs(schem) do
		local z_width
		if i % 2 == 0 then
			z_width = path_width
		else
			z_width = wall_width
		end
		local x0 = pos1.x
		for j, is_path in ipairs(row) do
			local x_width
			if j % 2 == 0 then
				x_width = path_width
			else
				x_width = wall_width
			end
			for dx = 0, x_width - 1 do
				local x = x0 + dx
				for dz = 0, z_width - 1 do
					local z = z0 + dz
					if is_path then
						for y = pos1.y, pos2.y do
							data[area:index(x, y, z)] = fill_id
						end
					else
						for y = pos1.y, pos2.y do
							data[area:index(x, y, z)] = node_ids[math.random(#node_ids)]
						end
					end
				end
			end
			x0 = x0 + x_width
		end
		z0 = z0 + z_width
	end
	worldedit.manip_helpers.finish(manip, data)
end

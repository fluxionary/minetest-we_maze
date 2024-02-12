-- https://weblog.jamisbuck.org/2011/1/20/maze-generation-wilson-s-algorithm
local function generate_maze_schem(width, depth, path_length, path_width, seed)
	if seed then
		math.randomseed(seed)
	end
	local schem = {}
	return schem
end

function we_maze.generate(name, wall_nodes, fill_node, path_length, path_width, seed)
	local pos1, pos2 = worldedit.pos1[name]:sort(worldedit.pos2[name])
	local manip, area = worldedit.manip_helpers.init(pos1, pos2)
	local data = manip:get_data()
	local fill_id = minetest.get_content_id(fill_node)
	local node_ids = {}
	for i = 1, #wall_nodes do
		node_ids[i] = minetest.get_content_id(wall_nodes[i])
	end
	local schem = generate_maze_schem(pos2.x - pos1.x + 1, pos2.z - pos1.z + 1, path_length, path_width, seed)
	for x = pos1.x, pos2.x do
		for z = pos1.z, pos2.z do
			if schem[pos1.x - x + 1][pos1.z - z + 1] then
				for y = pos1.y, pos2.y do
					data[area:index(x, y, z)] = node_ids[math.random(#node_ids)]
				end
			else
				for y = pos1.y, pos2.y do
					data[area:index(x, y, z)] = fill_id
				end
			end
		end
	end
	worldedit.manip_helpers.finish(manip, data)
end

local f = string.format
local S = we_maze.S

worldedit.register_command("maze", {
	description = S("generate a maze"),
	params = S("<wall_node>[,<wall_node,...] [<fill_node=air>, [<path_length=1> [<path_width=1> [<seed>]]]]"),
	privs = { [we_maze.settings.priv] = true },
	require_pos = 2,
	parse = function(param)
		local nodes, rest = unpack(param:split("%s+", false, 1, true))
		if not nodes then
			return false, S("please specify at least one wall node (comma delimited)")
		end
		nodes = nodes:split(",", false)
		if #nodes == 0 then
			return false, S("please specify at least one wall node (comma delimited)")
		end
		local actual_nodes = {}
		for i = 1, #nodes do
			local node = nodes[i]
			local actual_node = worldedit.normalize_nodename(node)
			if not actual_node then
				return false, S("invalid node name: @1", node)
			end
			actual_nodes[i] = actual_node
		end
		rest = rest or ""
		local fill_node, path_length, path_width, seed
		fill_node, rest = unpack(rest:split("%s+", false, 1, true))
		if fill_node then
			local actual_fill_node = worldedit.normalize_nodename(fill_node)
			if not actual_fill_node then
				return false, S("invalid node name: @1", fill_node)
			end
			fill_node = actual_fill_node
		end
		rest = rest or ""
		path_length, rest = unpack(rest:split("%s+", false, 1, true))
		if path_length then
			path_length = tonumber(path_length)
			if not futil.is_positive_integer(path_length) then
				return false, S("path_length must be a positive integer")
			end
		else
			path_length = 1
		end
		rest = rest or ""
		path_width, rest = unpack(rest:split("%s+", false, 1, true))
		if path_width then
			path_width = tonumber(path_width)
			if not futil.is_positive_integer(path_length) then
				return false, S("path_width must be a positive integer")
			end
		else
			path_width = 1
		end
		if rest then
			seed = tonumber(rest)
			if not seed then
				return false, S("seed must be a number")
			end
		end
		return actual_nodes, fill_node, path_length, path_width, seed
	end,
	func = function(name, wall_nodes, fill_node, path_length, path_width, seed)
		local dx = math.abs(worldedit.pos1[name].x - worldedit.pos2[name].x)
		local dz = math.abs(worldedit.pos1[name].z - worldedit.pos2[name].z)
		-- TODO need to check whether we can actually create a maze w/ these params within the region
		if dx < path_length + 1 or dz < path_length + 1 then
			return false, S("maze with given parameters will not fit in the specified volume")
		end
		if dx < path_width + 1 or dz < path_width + 1 then
			return false, S("maze with given parameters will not fit in the specified volume")
		end

		minetest.log("action", f("%s invoked //maze @%s-%s", name, worldedit.pos1[name], worldedit.pos2[name]))
		local start = minetest.get_us_time()
		we_maze.generate(name, wall_nodes, fill_node, path_length, path_width, seed)
		return true, S("maze generated in @1s", f("%.03f", minetest.get_us_time() - start / 1e6))
	end,
})

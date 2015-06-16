-- Parameters

local VERSCA = 30 -- Vertical scale, meters per node
local YWATER = 1

-- Set mapgen parameters

minetest.register_on_mapgen_init(function(mgparams)
	minetest.set_mapgen_params({mgname="singlenode", flags="nolight"})
end)

-- On generated function

minetest.register_on_generated(function(minp, maxp, seed)
	local t0 = os.clock()
	local x1 = maxp.x
	local y1 = maxp.y
	local z1 = maxp.z
	local x0 = minp.x
	local y0 = minp.y
	local z0 = minp.z

	local sidelen = x1 - x0 + 1
	local ystridevm = sidelen + 32

	local cx0 = math.floor((x0 + 32) / 80) -- mapchunk co-ordinates to select
	local cz0 = math.floor((z0 + 32) / 80) -- the flat array of DEM values
	
	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}
	local data = vm:get_data()
	
	local c_grass = minetest.get_content_id("default:dirt_with_grass")
	local c_stone = minetest.get_content_id("default:stone")
	local c_sand  = minetest.get_content_id("default:sand")
	local c_water = minetest.get_content_id("default:water_source")

	local demi = 1 -- index of 80x80 flat array of DEM values

	for z = z0, z1 do
	for x = x0, x1 do
		local elev = (x - 10) * 5 -- elevation in meters from DEM (temporary code)
				-- use demi to get elevation value from flat array
		local node_elev = math.floor(YWATER + elev / VERSCA)
		local vi = area:index(x, y0, z) -- voxelmanip index
		for y = y0, y1 do
			if y < node_elev then
				data[vi] = c_stone
			elseif y == node_elev then
				if y <= YWATER then
					data[vi] = c_sand
				else
					data[vi] = c_grass
				end
			elseif y <= YWATER then
				data[vi] = c_water
			end
			vi = vi + ystridevm
		end
		demi = demi + 1
	end
	end
	
	vm:set_data(data)
	vm:calc_lighting()
	vm:write_to_map(data)
	vm:update_liquids()

	local chugent = math.ceil((os.clock() - t0) * 1000)
	print ("[DEM] "..chugent.." ms  mapchunk ("..cx0..", "..cz0..")")
end)

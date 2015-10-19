local ie = minetest.request_insecure_environment()
ie.require "luarocks.loader"
local imlib2 = ie.require "imlib2"

-- Parameters
local DEM = 'mandelbrot16bit.tif'
local COVER = 'cover.tif'

local VERSCA = 5 -- Vertical scale, meters per node
local YWATER = 1

offset = 0 --will be populated by ImageSize()
--local ImageSize = dofile(minetest.get_modpath("realterrain").."/lua-imagesize-1.2/imagesize.lua")
local demfilename = minetest.get_modpath("realterrain").."/dem/"..DEM
--local width, length, format = ImageSize.imgsize(demfilename)
local dem = imlib2.image.load(demfilename)
local width = dem:get_width()
local length = dem:get_height()
print("width: "..width..", height: "..length)

--open the river tif with no safety checks
covertiff = io.open(minetest.get_modpath("realterrain").."/dem/"..COVER, "rb")

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

	--local blelev = get_pixel(x0, z0)
	--print("block corner elev: "..blelev)
	local sidelen = x1 - x0 + 1
	local ystridevm = sidelen + 32

	local cx0 = math.floor((x0 + 32) / 80) -- mapchunk co-ordinates to select
	local cz0 = math.floor((z0 + 32) / 80) -- the flat array of DEM values
	
	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}
	local data = vm:get_data()
	
	local c_grass  = minetest.get_content_id("default:dirt_with_grass")
	local c_alpine = minetest.get_content_id("default:gravel")
	local c_stone  = minetest.get_content_id("default:stone")
	local c_sand   = minetest.get_content_id("default:sand")
	local c_water  = minetest.get_content_id("default:water_source")

	local demi = 1 -- index of 80x80 flat array of DEM values
	--local blockel = get_pixel(x0, z0)
	for z = z0, z1 do
	for x = x0, x1 do
		local elev, cover = get_pixel(x, z) -- elevation in meters from DEM and water true/false
				-- use demi to get elevation value from flat array

		local node_elev = math.floor(YWATER + elev / VERSCA)
		local vi = area:index(x, y0, z) -- voxelmanip index
		for y = y0, y1 do
			if y < node_elev then
				data[vi] = c_stone
				-- decide on ores, caverns
			elseif y == node_elev then
				--if the river map says this is water then that's all we set
				if cover > 225 then
					data[vi] = c_water
				elseif cover > 128 then 
					data[vi] = c_stone
				else
					if y <= YWATER then
						data[vi] = c_sand
					else
						if y > 100 then 
							data[vi] = c_alpine -- shrubs?
						else
							data[vi] = c_grass -- decide on trees?
						end
					end
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
	--print ("[DEM] "..chugent.." ms  mapchunk ("..cx0..", "..math.floor((y0 + 32) / 80)..", "..cz0..")")
end)

--for now we are going to assume 32 bit signed elevation pixels
--and a header offset of

function get_pixel(x,z)
	if x > math.ceil(width  / 2) or x < - math.floor(width  / 2)
	or z > math.ceil(length / 2) or z < - math.floor(length / 2) then
		--print ("out of range of tiff")
		return -1, 0 --off the TIFF,
	end
	
	local row = math.floor(length / 2) + z
	local col = math.floor(width  / 2) + x
	local pixel = dem:get_pixel(row,col)
    --print(pixel.red)
    --demtiff:seek("set", ( offset + (row * width) + col ))
	covertiff:seek("set", ( offset + (row * width) + col ))
	return pixel.red, 0
end
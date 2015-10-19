local ie = minetest.request_insecure_environment()
local modpath = minetest.get_modpath("realterrain")
function os.capture(cmd, raw)
  local f = assert(io.popen(cmd, 'r'))
  local s = assert(f:read('*a'))
  f:close()
  if raw then return s end
  s = string.gsub(s, '^%s+', '')
  s = string.gsub(s, '%s+$', '')
  s = string.gsub(s, '[\n\r]+', ' ')
  return s
end

-- Parameters
local DEM = 'mandelbrot16bit.tif'
local COVER = 'cover.tif'

local CEILING = 400 --should actually be 65535 for non-contrast-stretched 16 bit DEMs
local VERSCA = 1 -- Vertical scale, meters per node
local YWATER = 1

offset = 0 --will be populated by ImageSize()
local ImageSize = dofile(modpath.."/lua-imagesize-1.2/imagesize.lua")
local demfilename = modpath.."/dem/"..DEM
local width, length, format = ImageSize.imgsize(demfilename)

-- middle of our image
local demtiff --used by get_pixel()
local rivertiff --used by get_river

if width and length then
	demtiff = io.open(minetest.get_modpath("realterrain").."/dem/"..DEM, "rb")
	print("image info: w: "..width.." l: "..length.." format: "..format)
	print("after tiff offset: "..offset)
end
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
	
    local block_elev, cover = get_pixel(x0, z0)
    for z = z0, z1 do    
    for x = x0, x1 do
            
		--local elev, cover = block_elev, 0
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
	demtiff:seek("set", ( offset + (row * width) + col ))
	--covertiff:seek("set", ( offset + (row * width) + col ))
	--return demtiff:read(1):byte() - 32, 0 --covertiff:read(1):byte()
    --local imcommand = 'convert '..demfilename..': -format "%[pixel:s.p{'..x..','..z..'}]" info:'
    --local imcommand = 'convert '..demfilename..':[1x1+'..x..'+'..z..'] txt:-'
    
    --building the imagemagick command, on windows need to use convert.exe
    local imcommand = "convert "..demfilename.." -crop '1x1+"..col.."+"..row.."' -depth 16 -quiet txt:- | tail -n -1"
    --print(imcommand)
    local result = os.capture(imcommand)
    --[[the result will be in the following format:
    0,0: (70.1961%,74.902%,79.6078%)  #B3B3BFBFCBCB  srgb(179,191,203)
    ]]
    --print("raw result: " .. result .. "\n")
    --local i, j = string.find(result, "0,0: (")
    --print("i:" .. i..", j: "..j)
    local k = string.find(result, ",", 8)
    --print("k:" .. k)
    result = string.sub(result, 7, k-2)
    --print("parsed result: " .. result .. "\n")
    result = math.floor(CEILING * tonumber(result) / 100)
    --print(result)
    return result, 0

end
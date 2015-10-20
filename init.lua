local realterrain = {}
local ie = minetest.request_insecure_environment()
ie.require "luarocks.loader"
local imlib2 = ie.require "imlib2"
local magick = ie.require "magick"

-- Parameters
local DEM = 'mandelbrot16bit.tif'
local COVER = 'cover.tif' --cover should only be an 8-bit file of the same dimensions as the DEM

realterrain.settings = {} --form persistence

--defaults
realterrain.settings.bits = 8
realterrain.settings.yscale = 1
realterrain.settings.xscale = 1
realterrain.settings.zscale = 1
realterrain.settings.waterlevel = 1
realterrain.settings.alpinelevel = 200

local demfilename = minetest.get_modpath("realterrain").."/dem/"..DEM
local dem = magick.load_image(demfilename)
local width = dem:get_width()
local length = dem:get_height()
print("width: "..width..", height: "..length)
local coverfilename = minetest.get_modpath("realterrain").."/dem/"..COVER
local cover = imlib2.image.load(coverfilename)

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
	local c_gravel = minetest.get_content_id("default:gravel")
	local c_stone  = minetest.get_content_id("default:stone")
	local c_sand   = minetest.get_content_id("default:sand")
	local c_water  = minetest.get_content_id("default:water_source")
	local c_dirt   = minetest.get_content_id("default:dirt")
	local c_coal   = minetest.get_content_id("default:stone_with_coal")
	local c_cobble = minetest.get_content_id("default:cobble")

	local demi = 1 -- index of 80x80 flat array of DEM values
	--local blockel = get_pixel(x0, z0)
	for z = z0, z1 do
	for x = x0, x1 do
		local elev, cover = realterrain.get_pixel(x, z) -- elevation in meters from DEM and water true/false
				-- use demi to get elevation value from flat array

		local vi = area:index(x, y0, z) -- voxelmanip index
		for y = y0, y1 do
            --underground layers
			if y < elev then 
				--create strata of stone, cobble, gravel, sand, coal, iron ore, etc
				if y < elev - 35 then
					data[vi] = c_sand
				elseif y < elev - 30 then
					data[vi] = c_gravel
				elseif y < elev - 25 then
					data[vi] = c_stone
				elseif y < elev - 20 then
					data[vi] = c_coal
				elseif y < elev - 15 then
					data[vi] = c_stone
				elseif y < elev - 10 then
					data[vi] = c_gravel
				else
					data[vi] = c_dirt
				end
			--the surface layer, determined by "cover"
			elseif y == elev then
				--rivers
				if cover > 225 then
					data[vi] = c_water
				 --roads
				elseif cover > 99 then
					data[vi] = c_cobble
				--biome cover (elev based for now)
				else
					--sand for lake bottoms
					if y < tonumber(realterrain.settings.waterlevel) then
						data[vi] = c_sand
					--alpine level
					elseif y > tonumber(realterrain.settings.alpinelevel) then 
						data[vi] = c_gravel
					--default
					else
						data[vi] = c_grass
					end
				end
			elseif y <= tonumber(realterrain.settings.waterlevel) then
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

function realterrain.get_pixel(x,z)

    local row,col = 0-z, 0+x
	--adjust for scales
    row = math.floor(row / tonumber(realterrain.settings.zscale))
    col = math.floor(col / tonumber(realterrain.settings.xscale))
    
    --off the dem return zero
    if ((col < 0) or (col > width) or (row < 0) or (row > length)) then return 0,0 end
    
    
    local elev = dem:get_pixel(col, row)
    --print(elev)
    local cover = cover:get_pixel(col, row)
	
    --adjust for bit depth and vscale
    elev = math.floor(elev * (2^tonumber(realterrain.settings.bits)))
    elev = math.floor(elev / tonumber(realterrain.settings.yscale))
    --print(elev)
    return elev, cover.red
end

-- the controller for changing map settings
minetest.register_tool("realterrain:remote" , {
	description = "Realterrain Settings",
	inventory_image = "remote.png",
	--left-clicking the tool
	on_use = function (itemstack, user, pointed_thing)
        local pname = user:get_player_name()
		realterrain.show_rc_form(pname)
	end,
})

-- Processing the form from the RC
minetest.register_on_player_receive_fields(function(player, formname, fields)
	if string.sub(formname, 1, 12) == "realterrain:" then
		local wait = os.clock()
		while os.clock() - wait < 0.05 do end --popups don't work without this see issue #30
		print("fields submitted: "..dump(fields))
		local pname = player:get_player_name()
		
		-- always save any form fields
		for k,v in next, fields do
			realterrain.settings[k] = v --we will preserve field entries exactly as entered 
		end
		realterrain.save_settings()
		if formname == "realterrain:popup" then
			if fields.exit == "Back" then
				realterrain.show_rc_form(pname)
				return true
			end
		end
		
		--the main form
		if formname == "realterrain:rc_form" then 
			--actual form submissions
			if fields.exit == "Delete" then
                minetest.chat_send_player(pname, "You changed mapgen settings and are deleting the current map, restart the world!")
                --kick all other players
                
                --delete the map.sqlite file
                
                --kick this player? @todo what if this is a dedicated server?
                
                return true
            elseif fields.exit == "Apply" then
                minetest.chat_send_player(pname, "You changed the mapgen settings!")
                return true
			end
			return true
		end
		return true
	end
end)
--the formspecs and related settings and functions / selected field variables

--called at each form submission
function realterrain.save_settings()
	local file = io.open(minetest.get_worldpath().."/realterrain_settings", "w")
	if file then
		for k,v in next, realterrain.settings do
			local line = {key=k, values=v}
			file:write(minetest.serialize(line).."\n")
		end
		file:close()
	end
end
-- load settings run at EOF at mod start
function realterrain.load_settings()
	local file = io.open(minetest.get_worldpath().."/realterrain_settings", "r")
	if file then
		for line in file:lines() do
			if line ~= "" then
				local tline = minetest.deserialize(line)
				realterrain.settings[tline.key] = tline.values
			end
		end
		file:close()
	end
end
--retrieve individual form field
function realterrain.get_setting(setting)
	if realterrain.settings ~= {} then
		if realterrain.settings[setting] then
			if realterrain.settings[setting] ~= "" then
				return realterrain.settings[setting]
			else
				return false
			end
		else
			return false
		end
	else
		return false
	end
end
-- show the main remote control form
function realterrain.show_rc_form(pname)
	local player = minetest.get_player_by_name(pname)
	local ppos = player:getpos()
	local degree = player:get_look_yaw()*180/math.pi - 90
	if degree < 0 then degree = degree + 360 end
	local dir
	if     degree <= 45 or degree > 315 then dir = "North"
	elseif degree <= 135 then dir = "West"
	elseif degree <= 225 then dir = "South"
	else   dir = "South" end
	
    --form header
	local f_header = 			"size[12,10]" ..
								--"tabheader[0,0;tab;1D, 2D, 3D, Import, Manage;"..tab.."]"..
								"label[0,0;You are at x= "..math.floor(ppos.x)..
								" y= "..math.floor(ppos.y).." z= "..math.floor(ppos.z).." and mostly facing "..dir.."]"
	--Scale settings
	local f_scale_settings =    "field[1,1;4,1;bits;Bit Depth;"..
                                    minetest.formspec_escape(realterrain.get_setting("bits")).."]" ..
                                "field[1,2;4,1;yscale;Vertical meters per voxel;"..
                                    minetest.formspec_escape(realterrain.get_setting("yscale")).."]" ..
                                "field[1,3;4,1;xscale;East-West voxels per pixel;"..
                                    minetest.formspec_escape(realterrain.get_setting("xscale")).."]" ..
								"field[1,4;4,1;zscale;North-South voxels per pixel;"..
                                    minetest.formspec_escape(realterrain.get_setting("zscale")).."]" ..
								"field[1,5;4,1;waterlevel;Water Level;"..
                                    minetest.formspec_escape(realterrain.get_setting("waterlevel")).."]"..
                                "field[1,6;4,1;alpinelevel;Alpine Level;"..
                                    minetest.formspec_escape(realterrain.get_setting("alpinelevel")).."]"
	--Action buttons
	local f_footer = 			"label[3,8.5;Delete the map, reset]"..
								"button_exit[3,9;2,1;exit;Delete]"..
                                "label[7,8.5;Apply changes only]"..
								"button_exit[7,9;2,1;exit;Apply]"
    
    minetest.show_formspec(pname, "realterrain:rc_form", 
                        f_header ..
                        f_scale_settings ..
                        f_footer
    )
    return true
end

-- this is the form-error popup
function realterrain.show_popup(pname, message)
	minetest.chat_send_player(pname, "Form error: ".. message)
	minetest.show_formspec(pname,   "realterrain:popup",
                                    "size[10,8]" ..
                                    "button_exit[1,1;2,1;exit;Back]"..
                                    "label[1,3;"..minetest.formspec_escape(message).."]"
	)
	return true
end

--read from file, various persisted settings
realterrain.load_settings()
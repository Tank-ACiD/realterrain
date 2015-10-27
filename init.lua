MODPATH = minetest.get_modpath("realterrain")
WORLDPATH = minetest.get_worldpath()
RASTERS = MODPATH .. "/rasters/"
local realterrain = {}
realterrain.settings = {}


local ie = minetest.request_insecure_environment()
ie.require "luarocks.loader"
local magick = ie.require "magick"

--defaults
realterrain.settings.bits = 8 --@todo remove this setting when magick autodetects bitdepth
realterrain.settings.yscale = 1
realterrain.settings.xscale = 1
realterrain.settings.zscale = 1
realterrain.settings.yoffset = 0
realterrain.settings.xoffset = 0
realterrain.settings.zoffset = 0
realterrain.settings.waterlevel = 0
realterrain.settings.alpinelevel = 800
realterrain.settings.filedem   = 'dem.tif'
realterrain.settings.filewater = 'water.tif'
realterrain.settings.fileroads = 'roads.tif'
realterrain.settings.filebiome = 'biomes.tif'
realterrain.settings.generate_subsurface = 0
realterrain.settings.default_landcover = "wool:yellow"

realterrain.settings.b01cut = 1
realterrain.settings.b01ground = "default:dirt_with_grass"
realterrain.settings.b01tree = ""
realterrain.settings.b01tprob = 0.3
realterrain.settings.b01shrub = "default:grass_1"
realterrain.settings.b01sprob = 5

realterrain.settings.b02cut = 2
realterrain.settings.b02ground = "default:dirt_with_dry_grass"
realterrain.settings.b02tree = ""
realterrain.settings.b02tprob = 0.3
realterrain.settings.b02shrub = "default:dry_gass_1"
realterrain.settings.b02sprob = 5

realterrain.settings.b03cut = 3
realterrain.settings.b03ground = "default:sand"
realterrain.settings.b03tree = ""
realterrain.settings.b03tprob = 0.3
realterrain.settings.b03shrub = "default:dry_grass_1"
realterrain.settings.b03sprob = 5

realterrain.settings.b04cut = 4
realterrain.settings.b04ground = "default:gravel"
realterrain.settings.b04tree = ""
realterrain.settings.b04tprob = 0.3
realterrain.settings.b04shrub = "default:dry_shrub"
realterrain.settings.b04sprob = 5

realterrain.settings.b05cut = 5
realterrain.settings.b05ground = "default:clay"
realterrain.settings.b05tree = ""
realterrain.settings.b05tprob = 0.3
realterrain.settings.b05shrub = "default:dry_shrub"
realterrain.settings.b05sprob = 5

realterrain.settings.b06cut = 6
realterrain.settings.b06ground = "default:stone"
realterrain.settings.b06tree = ""
realterrain.settings.b06tprob = 0.3
realterrain.settings.b06shrub = "default:junglegrass"
realterrain.settings.b06sprob = 5

realterrain.settings.b07cut = 7
realterrain.settings.b07ground = "default:stone_with_iron"
realterrain.settings.b07tree = ""
realterrain.settings.b07tprob = 0.3
realterrain.settings.b07shrub = "default:junglegrass"
realterrain.settings.b07sprob = 5

realterrain.settings.b08cut = 8
realterrain.settings.b08ground = "default:stone_with_coal"
realterrain.settings.b08tree = ""
realterrain.settings.b08tprob = 0.3
realterrain.settings.b08shrub = "default:junglegrass"
realterrain.settings.b08sprob = 5

realterrain.settings.b09cut = 9
realterrain.settings.b09ground = "default:stone_with_copper"
realterrain.settings.b09tree = ""
realterrain.settings.b09tprob = 0.3
realterrain.settings.b09shrub = "default:junglegrass"
realterrain.settings.b09sprob = 5

realterrain.settings.b10cut = 10
realterrain.settings.b10ground = "default:dirt_with_snow"
realterrain.settings.b10tree = ""
realterrain.settings.b10tprob = 0.3
realterrain.settings.b10shrub = "default:dry_grass_1"
realterrain.settings.b10sprob = 5

--called at each form submission
function realterrain.save_settings()
	local file = io.open(WORLDPATH.."/realterrain_settings", "w")
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
	local file = io.open(WORLDPATH.."/realterrain_settings", "r")
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

--read from file, various persisted settings
realterrain.load_settings()

--need to override the minetest.formspec_escape to return empty string when nil
function realterrain.esc(str)
	if str == "" or not str then return "" else return minetest.formspec_escape(str) end
end

function realterrain.list_images()
	local dir = MODPATH .. "/dem/"
	local rtypes = {".png", ".tif"}
	
	if package.config:sub(1,1) == "/" then
	--Unix
		local list = {}
		--Open directory look for files, save data in p. By giving '-type f' as parameter, it returns all files.
		local p = io.popen('find "'..RASTERS..'" -type f')
		--Loop through all files
		for file in p:lines() do                         
			file = string.sub(file, #RASTERS + 1)
			for j, extension in ipairs(rtypes) do
				if string.find(file, extension, -4) ~= nil then
					table.insert(list, file)
				end
			end
		end
		return list
	else
	--Windows
		local i, list, popen = 0, {}, io.popen 
		--Open directory look for files, loop through all files 
		for filename in popen('dir "'..dir..'" /b'):lines() do
			for j, extension in ipairs(rtypes) do
				if string.find(filename, extension, -4) ~= nil then
					i = i + 1
					list[i] = filename  
				end
			end
		end
		return list
	end
end

--@todo fail if there is no DEM?
local dem = magick.load_image(RASTERS..realterrain.settings.filedem)
local width = dem:get_width()
local length = dem:get_height()
--print("width: "..width..", height: "..length)
local biomeimage, waterimage, roadimage
biomeimage = magick.load_image(RASTERS..realterrain.settings.filebiome)
waterimage = magick.load_image(RASTERS..realterrain.settings.filewater)
roadimage  = magick.load_image(RASTERS..realterrain.settings.fileroads)
--@todo throw warning if image sizes do not match the dem size

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
	local treemap = {}
	
	--content ids
	local c_grass  = minetest.get_content_id("default:dirt_with_grass")
	local c_gravel = minetest.get_content_id("default:gravel")
	local c_stone  = minetest.get_content_id("default:stone")
	local c_sand   = minetest.get_content_id("default:sand")
	local c_water  = minetest.get_content_id("default:water_source")
	local c_dirt   = minetest.get_content_id("default:dirt")
	local c_coal   = minetest.get_content_id("default:stone_with_coal")
	local c_cobble = minetest.get_content_id("default:cobble")
	--biome specific cids
	local cids = {}
	cids[1]  = {ground=minetest.get_content_id(realterrain.settings.b01ground), shrub=minetest.get_content_id(realterrain.settings.b01shrub)}
	cids[2]  = {ground=minetest.get_content_id(realterrain.settings.b02ground), shrub=minetest.get_content_id(realterrain.settings.b02shrub)}
	cids[3]  = {ground=minetest.get_content_id(realterrain.settings.b03ground), shrub=minetest.get_content_id(realterrain.settings.b03shrub)}
	cids[4]  = {ground=minetest.get_content_id(realterrain.settings.b04ground), shrub=minetest.get_content_id(realterrain.settings.b04shrub)}
	cids[5]  = {ground=minetest.get_content_id(realterrain.settings.b05ground), shrub=minetest.get_content_id(realterrain.settings.b05shrub)}
	cids[6]  = {ground=minetest.get_content_id(realterrain.settings.b06ground), shrub=minetest.get_content_id(realterrain.settings.b06shrub)}
	cids[7]  = {ground=minetest.get_content_id(realterrain.settings.b07ground), shrub=minetest.get_content_id(realterrain.settings.b07shrub)}
	cids[8]  = {ground=minetest.get_content_id(realterrain.settings.b08ground), shrub=minetest.get_content_id(realterrain.settings.b08shrub)}
	cids[9]  = {ground=minetest.get_content_id(realterrain.settings.b09ground), shrub=minetest.get_content_id(realterrain.settings.b09shrub)}
	cids[10] = {ground=minetest.get_content_id(realterrain.settings.b10ground), shrub=minetest.get_content_id(realterrain.settings.b10shrub)}
	
	local sidelen = x1 - x0 + 1
	local ystridevm = sidelen + 32

	local cx0 = math.floor((x0 + 32) / 80)
	local cz0 = math.floor((z0 + 32) / 80) 
	
	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}
	local data = vm:get_data()
	local roadcount = {0,0,0,0,0,0,0,0,0,0}
	local watercount = {0,0,0,0,0,0,0,0,0,0}
	local biomecount = {0,0,0,0,0,0,0,0,0,0}
	for z = z0, z1 do
	for x = x0, x1 do
		local elev, biome, water, road = realterrain.get_pixel(x, z) -- elevation in meters from DEM and water true/false

		if biome > 0 and biome < 11 then
			biomecount[biome] = biomecount[biome] + 1
		end
		if water > 0 and water < 11 then
			watercount[water] = watercount[water] + 1
		end
		if road > 0 and road < 11 then
			roadcount[road] = roadcount[road] + 1
		end
		--print("elev: "..elev..", biome: "..biome..", water: "..water..", road: "..road)
		
		local ground, tree, tprob, shrub, sprob
		ground = minetest.get_content_id(realterrain.settings.default_landcover)
		if biome == tonumber(realterrain.get_setting("b01cut")) then
			ground = cids[1].ground
			tree = realterrain.get_setting("b01tree")
			tprob = tonumber(realterrain.get_setting("b01tprob"))
			shrub = cids[1].shrub
			sprob = tonumber(realterrain.get_setting("b01sprob"))
		elseif biome == tonumber(realterrain.get_setting("b02cut")) then
			ground = cids[2].ground
			tree = realterrain.get_setting("b02tree")
			tprob = tonumber(realterrain.get_setting("b02tprob"))
			shrub = cids[2].shrub
			sprob = tonumber(realterrain.get_setting("b02sprob"))
		elseif biome == tonumber(realterrain.get_setting("b03cut")) then
			ground = cids[3].ground
			tree = realterrain.get_setting("b03tree")
			tprob = tonumber(realterrain.get_setting("b03tprob"))
			shrub = cids[3].shrub
			sprob = tonumber(realterrain.get_setting("b03sprob"))
		elseif biome == tonumber(realterrain.get_setting("b04cut")) then
			ground = cids[4].ground
			tree = realterrain.get_setting("b04tree")
			tprob = tonumber(realterrain.get_setting("b04tprob"))
			shrub = cids[4].shrub
			sprob = tonumber(realterrain.get_setting("b04sprob"))
		elseif biome == tonumber(realterrain.get_setting("b05cut")) then
			ground = cids[5].ground
			tree = realterrain.get_setting("b05tree")
			tprob = tonumber(realterrain.get_setting("b05tprob"))
			shrub = cids[5].shrub
			sprob = tonumber(realterrain.get_setting("b05sprob"))
		elseif biome == tonumber(realterrain.get_setting("b06cut")) then
			ground = cids[6].ground
			tree = realterrain.get_setting("b06tree")
			tprob = tonumber(realterrain.get_setting("b06tprob"))
			shrub = cids[6].shrub
			sprob = tonumber(realterrain.get_setting("b06sprob"))
		elseif biome == tonumber(realterrain.get_setting("b07cut")) then
			ground = cids[7].ground
			tree = realterrain.get_setting("b07tree")
			tprob = tonumber(realterrain.get_setting("b07tprob"))
			shrub = cids[7].shrub
			sprob = tonumber(realterrain.get_setting("b07sprob"))
		elseif biome == tonumber(realterrain.get_setting("b08cut")) then
			ground = cids[8].ground
			tree = realterrain.get_setting("b08tree")
			tprob = tonumber(realterrain.get_setting("b08tprob"))
			shrub = cids[8].shrub
			sprob = tonumber(realterrain.get_setting("b08sprob"))
		elseif biome == tonumber(realterrain.get_setting("b09cut")) then
			ground = cids[9].ground
			tree = realterrain.get_setting("b09tree")
			tprob = tonumber(realterrain.get_setting("b09tprob"))
			shrub = cids[9].shrub
			sprob = tonumber(realterrain.get_setting("b09sprob"))
		elseif biome == tonumber(realterrain.get_setting("b10cut")) then
			ground = cids[10].ground
			tree = realterrain.get_setting("b10tree")
			tprob = tonumber(realterrain.get_setting("b10tprob"))
			shrub = cids[10].shrub
			sprob = tonumber(realterrain.get_setting("b10sprob"))
		end
		
		local vi = area:index(x, y0, z) -- voxelmanip index
		for y = y0, y1 do
            --underground layers
			if y < elev and realterrain.settings.generate_subsurface == 1 then 
				--create strata of stone, cobble, gravel, sand, coal, iron ore, etc
				if y < elev - (30 + math.random(1,5)) then
					data[vi] = c_stone
				elseif y < elev - (25 + math.random(1,5)) then
					data[vi] = c_gravel
				elseif y < elev - (20 + math.random(1,5)) then
					data[vi] = c_sand
				elseif y < elev - (15 + math.random(1,5)) then
					data[vi] = c_coal
				elseif y < elev - (10 + math.random(1,5)) then
					data[vi] = c_stone
				elseif y < elev - (5 + math.random(1,5)) then
					data[vi] = c_sand
				else
					data[vi] = ground
				end
			--the surface layer, determined by the different cover files
			elseif y == elev then
				--roads
				if road > 0 then
					data[vi] = c_cobble
				 --rivers and lakes
				elseif water > 0 then
					data[vi] = c_water
				--biome cover
				else
					--sand for lake bottoms
					if y < tonumber(realterrain.settings.waterlevel) then
						data[vi] = c_sand
					--alpine level
					elseif y > tonumber(realterrain.settings.alpinelevel) + math.random(1,5) then 
						data[vi] = c_gravel
					--default
					else
						data[vi] = ground
					end
				end
			--shrubs and trees one block above the ground
			elseif y == elev + 1 and water == 0 and road == 0 then
				if shrub and math.random(0,100) <= sprob then
					data[vi] = shrub
				end
				if tree and y < tonumber(realterrain.settings.alpinelevel) + math.random(1,5) and math.random(0,100) <= tprob then
					table.insert(treemap, {pos={x=x,y=y,z=z}, type=tree})
				end
			elseif y <= tonumber(realterrain.settings.waterlevel) then
				data[vi] = c_water
			end
			vi = vi + ystridevm
		end
	end
	end
	
	vm:set_data(data)
	vm:calc_lighting()
	vm:write_to_map(data)
	vm:update_liquids()
	
	--place all the trees
	for k,v in next, treemap do
		minetest.place_schematic({x=v.pos.x-3,y=v.pos.y,z=v.pos.z-3}, MODPATH.."/schems/"..v.type..".mts", (math.floor(math.random(0,3)) * 90), nil, false)
	end
	
	local chugent = math.ceil((os.clock() - t0) * 1000)
	--print ("[DEM] "..chugent.." ms  mapchunk ("..cx0..", "..math.floor((y0 + 32) / 80)..", "..cz0..")")

--[[ report/output for map gen values
	for a,b in pairs(biomecount) do
		if b > 0 then
			print ("Biome "..a.." Count: "..b)
		end
	end
	for a,b in pairs(roadcount) do
		if b > 0 then
			print ("Road "..a.." Count: "..b)
		end
	end
	for a,b in pairs(watercount) do
		if b > 0 then
			print ("Water "..a.." Count: "..b)
		end
	end
	]]--
end)

--for now we are going to assume 32 bit signed elevation pixels
--and a header offset of

function realterrain.get_pixel(x,z)
	local e, b, w, r = 0,0,0,0
    local row,col = 0 - z + tonumber(realterrain.settings.zoffset), 0 + x - tonumber(realterrain.settings.xoffset)
	--adjust for x and z scales
    row = math.floor(row / tonumber(realterrain.settings.zscale))
    col = math.floor(col / tonumber(realterrain.settings.xscale))
    
    --off the dem return zero for all values
    if ((col < 0) or (col > width) or (row < 0) or (row > length)) then return 0,0,0,0 end
    
    e = dem:get_pixel(col, row)
    --adjust for bit depth and vscale
    e = math.floor(e * (2^tonumber(realterrain.settings.bits))) --@todo change when magick autodetects bit depth
    e = math.floor((e / tonumber(realterrain.settings.yscale)) + tonumber(realterrain.settings.yoffset))
    --print("raw e: "..e)

	if biomeimage then 
		b = biomeimage:get_pixel(col, row) 
		b = math.floor(b * (2^tonumber(realterrain.settings.bits))) --@todo change when magick autodetects bit depth
	end
	if waterimage then 
		w = waterimage:get_pixel(col, row)
		w = math.floor(w * (2^tonumber(realterrain.settings.bits))) --@todo change when magick autodetects bit depth
	end
	if roadimage then 
		r = roadimage:get_pixel(col, row)
	    r = math.floor(r * (2^tonumber(realterrain.settings.bits))) --@todo change when magick autodetects bit depth
	end
	    
	--print("elev: "..e..", biome: "..b..", water: "..w..", road: "..r)
    return e, b, w, r
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
		while os.clock() - wait < 0.05 do end --popups don't work without this
		--print("fields submitted: "..dump(fields))
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
			if fields.exit == "Delete" then --@todo use the popup form do display a confirmation dialog box
                --kick all players and delete the map file
                local players = minetest.get_connected_players()
				for k, player in next, players do
					minetest.kick_player(player:get_player_name(), "map.sqlite deleted by admin, reload level")	
				end
				os.remove(WORLDPATH.."/map.sqlite")
                return true
            elseif fields.exit == "Apply" then
                minetest.chat_send_player(pname, "You changed the mapgen settings!")
                return true
			elseif fields.exit == "Biomes" then
				realterrain.show_biome_form(pname)
				return true
			end
			return true
		end
		
		--biome config form
		if formname == "realterrain:biome_config" then
			if fields.exit == "Apply" then
				realterrain.show_rc_form(pname)
				return true
			end
		end
		return true
	end
end)

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
	
	--[[local images = realterrain.list_images()
	local f_images = ""
	for k,v in next, images do
		f_images = f_images .. v .. ","
	end
	--print("IMAGES in DEM folder: "..f_images)--]]
    --form header
	local f_header = 			"size[14,10]" ..
								--"tabheader[0,0;tab;1D, 2D, 3D, Import, Manage;"..tab.."]"..
								"label[0,0;You are at x= "..math.floor(ppos.x)..
								" y= "..math.floor(ppos.y).." z= "..math.floor(ppos.z).." and mostly facing "..dir.."]"
	--Scale settings
	local f_scale_settings =    "field[1,1;4,1;bits;Bit Depth;"..
                                    realterrain.esc(realterrain.get_setting("bits")).."]" ..
                                "field[1,2;4,1;yscale;Vertical meters per voxel;"..
                                    realterrain.esc(realterrain.get_setting("yscale")).."]" ..
                                "field[1,3;4,1;xscale;East-West voxels per pixel;"..
                                    realterrain.esc(realterrain.get_setting("xscale")).."]" ..
								"field[1,4;4,1;zscale;North-South voxels per pixel;"..
                                    realterrain.esc(realterrain.get_setting("zscale")).."]" ..
								"field[1,5;4,1;waterlevel;Water Level;"..
                                    realterrain.esc(realterrain.get_setting("waterlevel")).."]"..
                                "field[1,6;4,1;alpinelevel;Alpine Level;"..
                                    realterrain.esc(realterrain.get_setting("alpinelevel")).."]"..
								"field[1,7;4,1;yoffset;Vertical Offset;"..
                                    realterrain.esc(realterrain.get_setting("yoffset")).."]" ..
                                "field[1,8;4,1;xoffset;East Offset;"..
                                    realterrain.esc(realterrain.get_setting("xoffset")).."]" ..
								"field[1,9;4,1;zoffset;North Offset;"..
                                    realterrain.esc(realterrain.get_setting("zoffset")).."]" ..
								--[["label[6,1;Elevation File]"..
								"dropdown[6,1.5;4,1;filedem;"..f_images..";"..
                                    realterrain.get_image_id(images, realterrain.get_setting("filedem")) .."]" ..
								"label[6,2.5;Biome File]"..
								"dropdown[6,3;4,1;filebiome;"..f_images..";"..
                                    realterrain.get_image_id(images, realterrain.get_setting("filebiome")) .."]" ..
								"label[6,4;Water File]"..
								"dropdown[6,4.5;4,1;filewater;"..f_images..";"..
                                    realterrain.get_image_id(images, realterrain.get_setting("filewater")) .."]"..
                                "label[6,5.5;Road File]"..
								"dropdown[6,6;4,1;fileroads;"..f_images..";"..
									realterrain.get_image_id(images, realterrain.get_setting("fileroads")) .."]"..--]]
								"field[6,2;4,1;filedem;Elevation File;" ..
                                    realterrain.get_setting("filedem") .."]" ..
								"field[6,3;4,1;filebiome;Biome File;" ..
                                    realterrain.get_setting("filebiome") .."]" ..
								"field[6,4;4,1;filewater;Water File;" ..
                                    realterrain.get_setting("filewater") .."]"..
								"field[6,5;4,1;fileroads;Roads File;" ..
									realterrain.get_setting("fileroads") .."]"..
								"button_exit[10,3;2,1;exit;Biomes]"
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

function realterrain.show_biome_form(pname)
	local col= {0.01,0.7,1.7,4.7,7.5,8.6,11.4,13}
	local row = {0.7,1.7,2.7,3.7,4.7,5.7,6.7,7.7,8.7,9.7}
	local f_header = 	"size[14,10]" ..
						"button_exit["..col[8]..",0.01;1,1;exit;Apply]"..
						"label["..col[1]..",0.01;B]".."label["..col[2]..",0.01;Cutoff]".."label["..col[3]..",0.01;Ground Node]"..
						"label["..col[4]..",0.01;Tree MTS]".."label["..col[5]..",0.01;Prob]".."label["..col[6]..",0.01;Shrub Node]"..
						"label["..col[7]..",0.01;Prob]"
	local f_body = ""
	for i=1,10,1 do
		local r = i
		if r < 10 then r = 0 .. r end
		local h = i * 0.7
		f_body = f_body ..
			"label["..col[1]..","..h ..";"..r.."]"..
			"field["..col[2]..","..h ..";1,1;b"..r.."cut;;"..
				realterrain.esc(realterrain.get_setting("b"..r.."cut")).."]" ..
			"field["..col[3]..","..h ..";3,1;b"..r.."ground;;"..
				realterrain.esc(realterrain.get_setting("b"..r.."ground")).."]" ..
			"field["..col[4]..","..h ..";3,1;b"..r.."tree;;"..
				realterrain.esc(realterrain.get_setting("b"..r.."tree")).."]" ..
			"field["..col[5]..","..h ..";1,1;b"..r.."tprob;;"..
				realterrain.esc(realterrain.get_setting("b"..r.."tprob")).."]" ..
			"field["..col[6]..","..h ..";3,1;b"..r.."shrub;;"..
				realterrain.esc(realterrain.get_setting("b"..r.."shrub")).."]"..
			"field["..col[7]..","..h ..";1,1;b"..r.."sprob;;"..
				realterrain.esc(realterrain.get_setting("b"..r.."sprob")).."]"
	end
					
	minetest.show_formspec(pname,   "realterrain:biome_config",
                                    f_header .. f_body
	)
	return true
end

-- this is the form-error popup
function realterrain.show_popup(pname, message)
	minetest.chat_send_player(pname, "Form error: ".. message)
	minetest.show_formspec(pname,   "realterrain:popup",
                                    "size[10,8]" ..
                                    "button_exit[1,1;2,1;exit;Back]"..
                                    "label[1,3;"..realterrain.esc(message).."]"
	)
	return true
end

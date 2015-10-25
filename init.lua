MODPATH = minetest.get_modpath("realterrain")
WORLDPATH = minetest.get_worldpath() 
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
realterrain.settings.alpinelevel = 200
realterrain.settings.filedem   = 'dem.tif'
realterrain.settings.filewater = 'water.tif'
realterrain.settings.fileroads = 'roads.tif'
realterrain.settings.filebiome = 'biomes.tif'
realterrain.settings.b01cut = 10
realterrain.settings.b01grass = "default:dirt_with_grass"
realterrain.settings.b01tree = "tree"
realterrain.settings.b01shrub = "default:grass_1"
realterrain.settings.b02cut = 20
realterrain.settings.b02grass = "default:dirt_with_dry_grass"
realterrain.settings.b02tree = "tree"
realterrain.settings.b02shrub = "default:dry_grass_1"
realterrain.settings.b03cut = 30
realterrain.settings.b03grass = "default:sand"
realterrain.settings.b03tree = "cactus"
realterrain.settings.b03shrub = "default:dry_grass_1"
realterrain.settings.b04cut = 40
realterrain.settings.b04grass = "default:gravel"
realterrain.settings.b04tree = "cactus"
realterrain.settings.b04shrub = "default:dry_shrub"
realterrain.settings.b05cut = 50
realterrain.settings.b05grass = "default:clay"
realterrain.settings.b05tree = "tree"
realterrain.settings.b05shrub = "default:dry_shrub"
realterrain.settings.b06cut = 60
realterrain.settings.b06grass = "default:stone"
realterrain.settings.b06tree = "tree"
realterrain.settings.b06shrub = "default:junglegrass"
realterrain.settings.b07cut = 70
realterrain.settings.b07grass = "default:stone_with_iron"
realterrain.settings.b07tree = "tree"
realterrain.settings.b07shrub = "default:junglegrass"
realterrain.settings.b08cut = 80
realterrain.settings.b08grass = "default:stone_with_coal"
realterrain.settings.b08tree = "tree"
realterrain.settings.b08shrub = "default:junglegrass"
realterrain.settings.b09cut = 90
realterrain.settings.b09grass = "default:stone_with_copper"
realterrain.settings.b09tree = "tree"
realterrain.settings.b09shrub = "default:junglegrass"
realterrain.settings.b10cut = 100
realterrain.settings.b10grass = "default:dirt_with_snow"
realterrain.settings.b10tree = "tree"
realterrain.settings.b10shrub = "default:dry_grass_1"

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

function realterrain.list_images()
	local dir = MODPATH .. "/dem/"
	local list = {}
	local p = io.popen('find "'..dir..'" -type f')  --Open directory look for files, save data in p. By giving '-type f' as parameter, it returns all files.     
    for file in p:lines() do                         --Loop through all files
        file = string.sub(file, #dir + 1)
		table.insert(list, file)    
	end
	return list
end

function realterrain.get_image_id(images_table, filename)
	--returns the image id or if the image is not found it returns zero
	for k,v in next, images_table do
		if v == filename then
			return k
		end		
	end
	return 0
end

--@todo fail if there is no DEM?
local dem = magick.load_image(MODPATH.."/dem/"..realterrain.settings.filedem)
local width = dem:get_width()
local length = dem:get_height()
--print("width: "..width..", height: "..length)
local biomeimage, waterimage, roadimage
biomeimage = magick.load_image(MODPATH.."/dem/"..realterrain.settings.filebiome)
waterimage = magick.load_image(MODPATH.."/dem/"..realterrain.settings.filewater)
roadimage  = magick.load_image(MODPATH.."/dem/"..realterrain.settings.fileroads)
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
	cids[1]  = {grass=minetest.get_content_id(realterrain.settings.b01grass)}
	cids[2]  = {grass=minetest.get_content_id(realterrain.settings.b02grass)}
	cids[3]  = {grass=minetest.get_content_id(realterrain.settings.b03grass)}
	cids[4]  = {grass=minetest.get_content_id(realterrain.settings.b04grass)}
	cids[5]  = {grass=minetest.get_content_id(realterrain.settings.b05grass)}
	cids[6]  = {grass=minetest.get_content_id(realterrain.settings.b06grass)}
	cids[7]  = {grass=minetest.get_content_id(realterrain.settings.b07grass)}
	cids[8]  = {grass=minetest.get_content_id(realterrain.settings.b08grass)}
	cids[9]  = {grass=minetest.get_content_id(realterrain.settings.b09grass)}
	cids[10] = {grass=minetest.get_content_id(realterrain.settings.b10grass)}
	
	local sidelen = x1 - x0 + 1
	local ystridevm = sidelen + 32

	local cx0 = math.floor((x0 + 32) / 80)
	local cz0 = math.floor((z0 + 32) / 80) 
	
	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}
	local data = vm:get_data()
	for z = z0, z1 do
	for x = x0, x1 do
		local elev, biome, water, road = realterrain.get_pixel(x, z) -- elevation in meters from DEM and water true/false
		--print("elev: "..elev..", biome: "..biome..", water: "..water..", road: "..road)
		
		local vi = area:index(x, y0, z) -- voxelmanip index
		for y = y0, y1 do
            --underground layers
			if y < elev then 
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
					data[vi] = c_dirt
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
						if biome < 10  then data[vi] = cids[1].grass
						elseif biome < 20  then data[vi] = cids[2].grass 
						elseif biome < 30  then data[vi] = cids[3].grass
						elseif biome < 40  then data[vi] = cids[4].grass
						elseif biome < 50  then data[vi] = cids[5].grass
						elseif biome < 60  then data[vi] = cids[6].grass
						elseif biome < 70  then data[vi] = cids[7].grass
						elseif biome < 80  then data[vi] = cids[8].grass
						elseif biome < 90  then data[vi] = cids[9].grass
						else   data[vi] = cids[10].grass
						end
					end
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

	local chugent = math.ceil((os.clock() - t0) * 1000)
	--print ("[DEM] "..chugent.." ms  mapchunk ("..cx0..", "..math.floor((y0 + 32) / 80)..", "..cz0..")")
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
    --print("raw e: "..e)
	if biomeimage then b = 100 * biomeimage:get_pixel(col, row) end--use breakpoints for different biomes
	if waterimage then w = math.ceil(waterimage:get_pixel(col, row)) end --@todo use float for water depth?
	if roadimage  then r = math.ceil(roadimage:get_pixel(col, row)) end --@todo use breakpoints for building height?
	
    --adjust for bit depth and vscale
    e = math.floor(e * (2^tonumber(realterrain.settings.bits))) --@todo change when magick autodetects bit depth
    e = math.floor((e / tonumber(realterrain.settings.yscale)) + tonumber(realterrain.settings.yoffset))
    
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
			if fields.exit == "Delete" then --@todo use the popup form do display a confirmation dialog box
                --kick all players and delete the map file
                local players = minetest.get_connected_players()
				for k, player in next, players do
					minetest.kick_player(player:get_player_name(), "map.sqlite deleted by admin, reload level")	
				end
				local wait = os.clock()
				while os.clock() - wait < 0.1 do end -- map delete sometimes happens before kick
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
			if fields.exit == "Back" then
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
	
	local images = realterrain.list_images()
	local f_images = ""
	for k,v in next, images do
		f_images = f_images .. v .. ","
	end
	--print("IMAGES in DEM folder: "..f_images)
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
                                    minetest.formspec_escape(realterrain.get_setting("alpinelevel")).."]"..
								"field[1,7;4,1;yoffset;Vertical Offset;"..
                                    minetest.formspec_escape(realterrain.get_setting("yoffset")).."]" ..
                                "field[1,8;4,1;xoffset;East Offset;"..
                                    minetest.formspec_escape(realterrain.get_setting("xoffset")).."]" ..
								"field[1,9;4,1;zoffset;North Offset;"..
                                    minetest.formspec_escape(realterrain.get_setting("zoffset")).."]" ..
								"label[6,1;Elevation File]"..
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
									realterrain.get_image_id(images, realterrain.get_setting("fileroads")) .."]"..
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
	minetest.show_formspec(pname,   "realterrain:biome_config",
                                    "size[12,10]" ..
                                    "button_exit[11,9;2,1;exit;Back]"..
                                    "label[0.5,0.3;Biome]".."label[1.7,0.3;Cutoff]".."label[3,0.3;Grass Node]"..
									"label[6,0.3;Tree MTS]".."label[9,0.3;Shrub Node]"..
									
									"label[0.5,0.9;01]"..
									"field[2,1;1,1;b01cut;;"..
										minetest.formspec_escape(realterrain.get_setting("b01cut")).."]" ..
									"field[3,1;3,1;b01grass;;"..
										minetest.formspec_escape(realterrain.get_setting("b01grass")).."]" ..
									"field[6,1;3,1;b01tree;;"..
										minetest.formspec_escape(realterrain.get_setting("b01tree")).."]" ..
									"field[9,1;3,1;b01shrub;;"..
										minetest.formspec_escape(realterrain.get_setting("b01shrub")).."]" ..
										
									"label[0.5,1.9;02]"..
									"field[2,2;1,1;b02cut;;"..
										minetest.formspec_escape(realterrain.get_setting("b02cut")).."]" ..
									"field[3,2;3,1;b02grass;;"..
										minetest.formspec_escape(realterrain.get_setting("b02grass")).."]" ..
									"field[6,2;3,1;b02tree;;"..
										minetest.formspec_escape(realterrain.get_setting("b02tree")).."]" ..
									"field[9,2;3,1;b02shrub;;"..
										minetest.formspec_escape(realterrain.get_setting("b02shrub")).."]" ..
										
									"label[0.5,2.9;03]"..
									"field[2,3;1,1;b03cut;;"..
										minetest.formspec_escape(realterrain.get_setting("b03cut")).."]" ..
									"field[3,3;3,1;b03grass;;"..
										minetest.formspec_escape(realterrain.get_setting("b03grass")).."]" ..
									"field[6,3;3,1;b03tree;;"..
										minetest.formspec_escape(realterrain.get_setting("b03tree")).."]" ..
									"field[9,3;3,1;b03shrub;;"..
										minetest.formspec_escape(realterrain.get_setting("b03shrub")).."]" ..
										
									"label[0.5,3.9;04]"..
									"field[2,4;1,1;b04cut;;"..
										minetest.formspec_escape(realterrain.get_setting("b04cut")).."]" ..
									"field[3,4;3,1;b04grass;;"..
										minetest.formspec_escape(realterrain.get_setting("b04grass")).."]" ..
									"field[6,4;3,1;b04tree;;"..
										minetest.formspec_escape(realterrain.get_setting("b04tree")).."]" ..
									"field[9,4;3,1;b04shrub;;"..
										minetest.formspec_escape(realterrain.get_setting("b04shrub")).."]" ..
										
									"label[0.5,4.9;05]"..
									"field[2,5;1,1;b05cut;;"..
										minetest.formspec_escape(realterrain.get_setting("b05cut")).."]" ..
									"field[3,5;3,1;b05grass;;"..
										minetest.formspec_escape(realterrain.get_setting("b05grass")).."]" ..
									"field[6,5;3,1;b05tree;;"..
										minetest.formspec_escape(realterrain.get_setting("b05tree")).."]" ..
									"field[9,5;3,1;b05shrub;;"..
										minetest.formspec_escape(realterrain.get_setting("b05shrub")).."]" ..
										
									"label[0.5,5.9;06]"..
									"field[2,6;1,1;b06cut;;"..
										minetest.formspec_escape(realterrain.get_setting("b06cut")).."]" ..
									"field[3,6;3,1;b06grass;;"..
										minetest.formspec_escape(realterrain.get_setting("b06grass")).."]" ..
									"field[6,6;3,1;b06tree;;"..
										minetest.formspec_escape(realterrain.get_setting("b06tree")).."]" ..
									"field[9,6;3,1;b06shrub;;"..
										minetest.formspec_escape(realterrain.get_setting("b06shrub")).."]" ..
										
									"label[0.5,6.9;07]"..
									"field[2,7;1,1;b07cut;;"..
										minetest.formspec_escape(realterrain.get_setting("b07cut")).."]" ..
									"field[3,7;3,1;b07grass;;"..
										minetest.formspec_escape(realterrain.get_setting("b07grass")).."]" ..
									"field[6,7;3,1;b07tree;;"..
										minetest.formspec_escape(realterrain.get_setting("b07tree")).."]" ..
									"field[9,7;3,1;b07shrub;;"..
										minetest.formspec_escape(realterrain.get_setting("b07shrub")).."]" ..
										
									"label[0.5,7.9;08]"..
									"field[2,8;1,1;b08cut;;"..
										minetest.formspec_escape(realterrain.get_setting("b08cut")).."]" ..
									"field[3,8;3,1;b08grass;;"..
										minetest.formspec_escape(realterrain.get_setting("b08grass")).."]" ..
									"field[6,8;3,1;b08tree;;"..
										minetest.formspec_escape(realterrain.get_setting("b08tree")).."]" ..
									"field[9,8;3,1;b08shrub;;"..
										minetest.formspec_escape(realterrain.get_setting("b08shrub")).."]" ..
										
									"label[0.5,8.9;09]"..
									"field[2,9;1,1;b09cut;;"..
										minetest.formspec_escape(realterrain.get_setting("b09cut")).."]" ..
									"field[3,9;3,1;b09grass;;"..
										minetest.formspec_escape(realterrain.get_setting("b09grass")).."]" ..
									"field[6,9;3,1;b09tree;;"..
										minetest.formspec_escape(realterrain.get_setting("b09tree")).."]" ..
									"field[9,9;3,1;b09shrub;;"..
										minetest.formspec_escape(realterrain.get_setting("b09shrub")).."]" ..
										
									"label[0.5,9.9;10]"..
									"field[2,10;1,1;b10cut;;"..
										minetest.formspec_escape(realterrain.get_setting("b10cut")).."]" ..
									"field[3,10;3,1;b10grass;;"..
										minetest.formspec_escape(realterrain.get_setting("b10grass")).."]" ..
									"field[6,10;3,1;b10tree;;"..
										minetest.formspec_escape(realterrain.get_setting("b10tree")).."]" ..
									"field[9,10;3,1;b10shrub;;"..
										minetest.formspec_escape(realterrain.get_setting("b10shrub")).."]"
									
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
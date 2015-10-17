local process_frompanel = nil
local http          = nil
local ltn12         = nil
local sync_timeout  = nil
local server_id     = nil
local auth_key      = nil
local webpanel_host = nil
local sync_interval = nil
local function init(iprocess_frompanel, data)
	process_frompanel = iprocess_frompanel
	sync_timeout  = data.sync_timeout
	server_id     = data.server_id
	auth_key      = data.auth_key
	webpanel_host = data.webpanel_host
	sync_interval = data.sync_interval

	-- Include modules
	local ie = _G
	if minetest.request_insecure_environment then
		ie = minetest.request_insecure_environment()
		if not ie then
			error("Insecure environment required!")
		end
	end
	http  = ie.require("socket.http")
	ltn12 = ie.require("ltn12")
	http.TIMEOUT = sync_timeout
end

local function sync()
	local host   = webpanel_host .. "/"
	local method = "get"
	local path   = "api/" .. auth_key .. "/" .. server_id .. "/server_update/"
	local params = ""
	local resp   = {}

	-- Compose URL
	local url = ""
	if params:trim() ~= "" then
		url = host .. path .. "?" .. params
	else
		url = host .. path
	end

	-- Make Request
	local client, code, headers, status = http.request({url=url, sink=ltn12.sink.table(resp),
			method=method })
	-- Not used:
	-- headers=args.headers, source=args.source,
	-- step=args.step, proxy=args.proxy, redirect=args.redirect, create=args.create

	if code ~= 200 then
		if code == 404 then
			minetest.log("warning", "The webpanel reports that this server does not exist!")
		else
			minetest.log("warning", "The webpanel gave an unknown HTTP response code!")
		end
		return
	end

	if resp and resp[1] then
		resp = resp[1]:trim()
	else
		resp = nil
	end

	if resp == "auth" then
		minetest.log("warning", "Authentication error when requesting commands from webpanel")
		return
	end

	if resp == "offline" then
		minetest.log("warning", "The webpanel reports that this server should be offline!")
		return
	end

	if string.find(resp, "return", 1) == nil then
		minetest.log("warning", "The webpanel gave an invalid response!")
		print(dump(resp))
		return
	end

	process_frompanel(minetest.deserialize(resp))
end

return {
	init = init,
	sync = sync
}
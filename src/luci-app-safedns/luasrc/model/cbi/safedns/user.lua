require "luci.model.uci"

MY_CONFIG_FILENAME = "safedns"
MY_CONFIG_SECTION_MAIN = "safedns"


function print_dbg(str)
	dbg = io.open("/tmp/luci.debug", "a")
	dbg:write(string.format("%s\n",str))
	dbg:close()
end

local m = Map(MY_CONFIG_FILENAME, translate("SafeDNS"))

local    login_saved = uci.get(MY_CONFIG_FILENAME, MY_CONFIG_SECTION_MAIN,    "login")
local password_saved = uci.get(MY_CONFIG_FILENAME, MY_CONFIG_SECTION_MAIN, "password")

m.on_before_commit = function(self)
	print_dbg("--- on_before_commit ---")
	print_dbg("login_saved = [%s], password_saved = [%s]"
	          % {tostring(login_saved), tostring(password_saved)})

	local    login = m.uci:get(MY_CONFIG_FILENAME, MY_CONFIG_SECTION_MAIN,    "login")
	local password = m.uci:get(MY_CONFIG_FILENAME, MY_CONFIG_SECTION_MAIN, "password")
	print_dbg("login = [%s], password = [%s]"
	          % {tostring(login), tostring(password)})

	if login_saved ~= login or password_saved ~= password then
		local default_token = fill_profiles(login, password)
		if default_token then
			m.uci:set(MY_CONFIG_FILENAME, MY_CONFIG_SECTION_MAIN, "default_token", default_token)
		else
			m.uci:delete(MY_CONFIG_FILENAME, MY_CONFIG_SECTION_MAIN, "default_token")
		end
		--m.uci:commit(MY_CONFIG_FILENAME)
	end

	print_dbg("^^^ on_before_commit ^^^")
end


-- first need to close <a> from cbi map template our <a> closed by template
m.title = [[</a><a href="]] .. luci.dispatcher.build_url("admin", "services", "safedns") .. [[">]] ..
		translate("SafeDNS")

--m.description = translate("SafeDNS user profile allows user to access DNS filtering features")
m.description = translate("Enter SafeDNS username and password or register a new account at <a href=https://www.safedns.com>https://www.safedns.com</a>")

--m.redirect = luci.dispatcher.build_url("admin", "services", "safedns")



s = m:section(NamedSection, MY_CONFIG_SECTION_MAIN, "user")

enabled = s:option(Flag, "enabled",
                   translate("Enabled"),
                   translate("DNS filtering enabled"))
enabled.rmempty = false

login = s:option(Value, "login",
                 translate("Login"),
                 translate("SafeDNS login (user name or email)"))

password = s:option(Value, "password",
                    translate("Password"),
                    translate("SafeDNS password"))
password.password = true

default_profile = s:option(ListValue, "default_token", "Default profile")
default_profile.validate = function(self, value)
	return value
end


device2profile = m:section(TypedSection, "mac2token", "PC to profile")
--[[
device2profile.filter = function(self, section)
	if m.uci:get(MY_CONFIG_FILENAME, MY_CONFIG_SECTION_MAIN, "enabled") == "1" then
		return section
	end
end
--]]
device2profile.addremove = true
device2profile.anonymous = true
device2profile.template = "cbi/tblsection"
device2profile.sortable = true


device = device2profile:option(Value, "mac", "Device (choose name or insert mac)")
device.datatype = "macaddr"

profile = device2profile:option(ListValue, "token", "Profile")


function fill_profiles(login, password)
	require "luci/model/cbi/safedns/json_utils"

	local api_url = uci.get(MY_CONFIG_FILENAME, MY_CONFIG_SECTION_MAIN, "api_url") or "n/a"
	login    = login    or "n/a"
	password = password or "n/a"

	print_dbg("get_profiles: %s, %s, %s" % {api_url, login, password})
	local profiles = get_profiles(api_url, login, password) or {}

	local default_profile_token
	profile.keylist = {}
	profile.vallist = {}
	default_profile.keylist = {}
	default_profile.vallist = {}

	for _, pr in pairs(profiles) do
		profile:value(pr.token, pr.name)
		default_profile:value(pr.token, pr.name)

		if pr.default then
			profile.default = pr.name
			default_profile.default = pr.name
			default_profile_token = pr.token
		end
	end

	return default_profile_token
end

fill_profiles(login_saved, password_saved)


--[[
function is_mac_in_table(mac)
	local answer = false

	local cursor = uci.cursor()
	cursor:foreach(MY_CONFIG_FILENAME, "mac2token",
		function(sect)
			if tostring(sect["mac"]):lower() == tostring(mac):lower() then
				answer = true
				return false
			end
		end
	)

	return answer
end
--]]


-- "name [mac]"
function parse_device_name_mac(filename)
	for line in io.lines(filename)
	do
		local mac, name = string.match(line, "%S*%s*(%S*)%s*%S*%s*(%S*)")
		if mac and name then
			device:value(mac, "%s [%s]" % {name, mac})
		end
	end
end

parse_device_name_mac("/tmp/dhcp.leases")

--[[
-- "ip [mac]" or "name [mac]"
for k, v in pairs(luci.sys.net.mac_hints()) do
	mac, name = v[1], v[2]
	device:value(mac, "%s [%s]" % {name, mac})
end
--]]

--[[
-- "ip [mac]"
luci.ip.neighbors({ }, function(n)
	if n.mac and n.dest and not n.dest:is6linklocal() then
		device:value(n.mac, "%s [%s]" % {n.dest:string(), n.mac})
	end
end)
--]]

return m

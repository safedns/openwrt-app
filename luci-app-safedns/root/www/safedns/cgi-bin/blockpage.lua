#!/usr/bin/lua

local sys = require "luci.sys"
require "uci"

MY_CONFIG_FILENAME = "safedns"
MY_CONFIG_SECTION_MAIN = "safedns"
DEFAULT_BLOCKPAGE_IP_MAIN = "195.46.39.2"


function print_dbg(str)
	dbg = io.open("/tmp/luci.debug", "a")
	dbg:write(string.format("%s\n",str))
	dbg:close()
end

print_dbg("blockpage")

print ("Content-type: Text/html\n")

local query_string = os.getenv("QUERY_STRING")
local params = {}
local echo = {}

if query_string then
	print_dbg('query_string: "'..query_string..'"')
		
	for name, value in string.gmatch(query_string .. '&', '(.-)%=(.-)%&') do
		value = string.gsub(value , '%+', ' ')
		value = string.gsub(value , '%%(%x%x)',
			function(dpc)
				return string.char(tonumber(dpc, 16))
			end
		)
		params[name] = value

		value = string.gsub(value, "%&", "&amp;")
		value = string.gsub(value, "%<", "&lt;")
		value = string.gsub(value, '%"', "&quot;")
		echo[name] = value
		print_dbg("param["..name.."]="..value)
	end
end 

local url  = params["url"]  or ""
local host = params["host"] or ""


local cursor = uci.cursor()

function ip2mac(ip)
	--  { "IP address", "HW address", "HW type", "Flags", "Mask", "Device" }
	local arp = sys.net.arptable()
	for _, arp_entry in pairs(arp) do
		if arp_entry["IP address"] == ip then
			return arp_entry["HW address"]
		end
	end
end

function mac2token(mac)
	local token
	cursor:foreach(MY_CONFIG_FILENAME, "mac2token",
		function(sect)
			if tostring(sect["mac"]):lower() == tostring(mac):lower() then
				token = sect["token"]
				return false
			end
		end
	)
	return token
end

local blockpage_ip_main = cursor:get(MY_CONFIG_FILENAME, MY_CONFIG_SECTION_MAIN, "blockpage_ip_main") or DEFAULT_BLOCKPAGE_IP_MAIN
local default_token     = cursor:get(MY_CONFIG_FILENAME, MY_CONFIG_SECTION_MAIN, "default_token")

local ip    = os.getenv("REMOTE_ADDR") or "undefined"
local mac   = ip2mac(ip)               or "undefined"
local token = mac2token(mac) or default_token or "0"

print_dbg("ip: %s, mac: %s, token: %s" % {ip, mac, token})

local page = [[
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Cache-Control" content="no-cache" />
<script>
function fake_url() {
	window.history.pushState('blocked', 'Blocked page', ']]..url..[[');
    var height = document.documentElement.clientHeight;
    document.getElementById('body').style.height = height + 'px';
}     
</script>
</head>
<body onload="fake_url()" id="body" >
<iframe width="100%" height="100%" frameborder="0" src="http://]]..blockpage_ip_main..[[/blocked?hostname=]]..host..[[&token=]]..token..[[&url=]]..url..[["></iframe>
</body>
</html>
]]

print (page)

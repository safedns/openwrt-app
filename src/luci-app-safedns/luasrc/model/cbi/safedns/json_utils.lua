require "luci.json"
require "luci.httpclient"

--[[
function print_dbg(str)
	dbg = io.open("/tmp/luci.debug", "a")
	dbg:write(string.format("%s\n",str))
	dbg:close()
end
--]]
--[[ rPrint(struct, [limit], [indent])   Recursively print arbitrary data.
	Set limit (default 100) to stanch infinite loops.
	Indents tables as [KEY] VALUE, nested tables as [KEY] [KEY]...[KEY] VALUE
	Set indent ("") to prefix each line:    Mytable [KEY] [KEY]...[KEY] VALUE
--]]
--[[
function rPrint(s, l, i) -- recursive Print (structure, limit, indent)
	l = (l) or 100; i = i or "";	-- default item limit, indent string
	if (l<1) then print_dbg "ERROR: Item limit reached."; return l-1 end;
	local ts = type(s);
	if (ts ~= "table") then print_dbg (i.." - "..ts.." - "..tostring(s)); return l-1 end
	print_dbg (i.." - "..ts);           -- print "table"
	for k,v in pairs(s) do  -- print "[KEY] VALUE"
		l = rPrint(v, l, i.."\t["..tostring(k).."]");
		if (l < 0) then break end
	end
	return l
end	
--]]

local https = require "ssl.https"
local request = {id = "1", method = "profiles", jsonrpc = "2.0"}
-- todo: should id change during work ???

function get_profiles(api_url, login, password)
	local decoder = luci.json.Decoder()

	local payload = luci.json.encode(request)--:gsub(":",": ")
	--print_dbg("Request: " .. payload)

	if https then
		https.request{
			url = "https://" .. api_url,
			method = "POST",
			headers = {
				[  "user-agent"  ] = "SafeDNS OpenWRT 0.1",
				["Authorization" ] = "Basic " .. (mime.b64(login..":"..password)),
				["Content-Type"  ] = "application/json",
				["Content-Length"] = payload:len()
			},
			source = ltn12.source.string(payload),
			sink = decoder:sink(),
			protocol = "tlsv1_2"
		}
		--print_dbg("Request done")

		local json = decoder:get()
		--rPrint(json)

		return json and json.result
	end
end

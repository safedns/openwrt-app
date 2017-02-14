module("luci.controller.safedns", package.seeall)

function index()
	local nxfs	= require "nixio.fs"

	if not nxfs.access("/etc/config/safedns") then
		nxfs.writefile("/etc/config/safedns", "")
	end

	entry({"admin", "services", "safedns"}, cbi("safedns/user"), "SafeDNS", 10)
end

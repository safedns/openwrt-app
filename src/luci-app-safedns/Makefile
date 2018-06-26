include $(TOPDIR)/rules.mk

PKG_VERSION:=1
PKG_RELEASE:=1

PKG_LICENSE:=GPL-2.0 GPL-3.0
PKG_MAINTAINER:=Dmitry Zubarev <zubarev@safedns.com>

LUCI_TITLE:=SafeDNS Cloud Content Filter
LUCI_DESCRIPTION:=Free for personal use Cloud Content Filter module allows you to filter unwanted websites and protect your network and individual devices from Internet threats like malware, botnets, phishing and so on. In commercial version additional features are available, like scheduler, different filtering policies for individual devices, ads blocking, block page customization, and many more. Visit www.safedns.com to see full list of SafeDNS features.
LUCI_DEPENDS:=+libuci +luci-lib-httpclient +luci-lib-json +luasec +safedns

MY_CONFIG_FILENAME:=safedns
MY_CONFIG_SECTION_MAIN:=safedns
MY_CONFIG_SECTION_SAVE:=saved_options
DNSPROXY_NAME:=safedns


PKG_NAME:=$(notdir ${CURDIR})

define Package/$(PKG_NAME)/postinst
#!/bin/sh
	cur_ip=`uci -q get network.lan.ipaddr`

	touch /etc/config/$(MY_CONFIG_FILENAME)
	if [ -z `uci -q get $(MY_CONFIG_FILENAME).@$(MY_CONFIG_SECTION_SAVE)[0]` ]
	then
		uci -q add $(MY_CONFIG_FILENAME) $(MY_CONFIG_SECTION_SAVE) > /dev/null
		echo --- section \"$(MY_CONFIG_SECTION_SAVE)\" added to \"$(MY_CONFIG_FILENAME)\" config ---
	else
		echo --- section \"$(MY_CONFIG_SECTION_SAVE)\" already exists in \"$(MY_CONFIG_FILENAME)\" config ---
	fi

	##### for unknown dns-server #####
	#prog=`netstat -planW | grep -m 1 ":53" | grep -o "\w*$$"`
	#prog=`netstat -planW | grep      ":53" | grep -o "\w*$$"`
	#kill `pidof $$prog`
	#echo --- $$prog killed (port 53) ---
	##################################

	##### for dnsmasq #####
	if [ -f /etc/rc.d/S??dnsmasq ]
	then
		echo --- dnsmasq found in /etc/rc.d ---

		uci -q set $(MY_CONFIG_FILENAME).@$(MY_CONFIG_SECTION_SAVE)[0].dnsmasq_port="`uci -q get dhcp.@dnsmasq[0].port`"
		uci -q set dhcp.@dnsmasq[0].port=0
		uci -q add_list dhcp.lan.dhcp_option="6,$$cur_ip"
		uci -q commit
		/etc/init.d/dnsmasq reload
		echo --- dnsmasq DNS disabled ---
	fi
	#######################

	if [ -z `uci -q get ucitrack.@$(MY_CONFIG_FILENAME)[0]` ]
	then
		uci -q add ucitrack  $(MY_CONFIG_FILENAME) > /dev/null
		uci -q set ucitrack.@$(MY_CONFIG_FILENAME)[0].init=$(DNSPROXY_NAME)
		uci -q commit
		echo --- ucitrack section \"$(MY_CONFIG_FILENAME)\" added ---
	else
		echo --- ucitrack section \"$(MY_CONFIG_FILENAME)\" already exists ---
	fi

	if [ -z "`uci -q get ucitrack.@network[0].affects | grep $(MY_CONFIG_FILENAME)`" ]
	then
		uci -q add_list ucitrack.@network[0].affects=$(MY_CONFIG_FILENAME)
		uci -q commit
		echo --- ucitrack: \"network\"   now   affects \"$(MY_CONFIG_FILENAME)\" config ---
	else
		echo --- ucitrack: \"network\" already affects \"$(MY_CONFIG_FILENAME)\" config ---
	fi


	uci -q set $(MY_CONFIG_FILENAME).$(MY_CONFIG_SECTION_MAIN).blockpage_local_ip="$$cur_ip"   # useless option
	uci commit
	echo --- blockpage local ip = lan ip ---

	blockpage_ip_token=`uci -q get $(MY_CONFIG_FILENAME).$(MY_CONFIG_SECTION_MAIN).blockpage_ip_token`
	blockpage_port=`uci -q get $(MY_CONFIG_FILENAME).$(MY_CONFIG_SECTION_MAIN).blockpage_port`
	blockpage_local_port=`uci -q get $(MY_CONFIG_FILENAME).$(MY_CONFIG_SECTION_MAIN).blockpage_local_port`

	#uci -q get firewall.$(MY_CONFIG_FILENAME) > /dev/null || {
		uci set firewall.$(MY_CONFIG_FILENAME)=redirect
		uci set firewall.$(MY_CONFIG_FILENAME).name=SafeDNS_blockpage_redirect_for_br_lan
		uci set firewall.$(MY_CONFIG_FILENAME).src=lan
		uci set firewall.$(MY_CONFIG_FILENAME).src_dip="$$blockpage_ip_token"
		uci set firewall.$(MY_CONFIG_FILENAME).src_dport="$$blockpage_port"
		uci set firewall.$(MY_CONFIG_FILENAME).dest_ip="$$cur_ip"
		uci set firewall.$(MY_CONFIG_FILENAME).dest_port="$$blockpage_local_port"
		uci set firewall.$(MY_CONFIG_FILENAME).proto=tcp
	#}

	#uci -q get uhttpd.$(MY_CONFIG_FILENAME) > /dev/null || {
		uci set uhttpd.$(MY_CONFIG_FILENAME)=uhttpd
		uci set uhttpd.$(MY_CONFIG_FILENAME).listen_http="$$cur_ip:$$blockpage_local_port"
		uci set uhttpd.$(MY_CONFIG_FILENAME).redirect_https=0
		uci set uhttpd.$(MY_CONFIG_FILENAME).home=/www/safedns
		uci set uhttpd.$(MY_CONFIG_FILENAME).max_requests=3
		uci set uhttpd.$(MY_CONFIG_FILENAME).max_connections=100
		uci set uhttpd.$(MY_CONFIG_FILENAME).cgi_prefix=/cgi-bin
		uci set uhttpd.$(MY_CONFIG_FILENAME).script_timeout=60
		uci set uhttpd.$(MY_CONFIG_FILENAME).network_timeout=30
		uci set uhttpd.$(MY_CONFIG_FILENAME).http_keepalive=20
		uci set uhttpd.$(MY_CONFIG_FILENAME).tcp_keepalive=1
		uci set uhttpd.$(MY_CONFIG_FILENAME).ubus_prefix=/ubus
		uci set uhttpd.$(MY_CONFIG_FILENAME).index_page=index.html
		uci set uhttpd.$(MY_CONFIG_FILENAME).error_page=/index.html
	#}

	uci commit

	/etc/init.d/firewall reload 2> /dev/null
	echo --- blockpage redirection enabled ---

	/etc/init.d/uhttpd reload
	echo --- blockpage server enabled ---
endef

define Package/$(PKG_NAME)/postrm
#!/bin/sh
	uci -q delete firewall.$(MY_CONFIG_FILENAME)
	uci -q delete firewall.$(MY_CONFIG_FILENAME)_dns_redirect
	uci -q delete uhttpd.$(MY_CONFIG_FILENAME)
	uci commit

	/etc/init.d/firewall reload 2> /dev/null
	echo --- blockpage redirection disabled ---

	/etc/init.d/uhttpd reload
	echo --- blockpage server disabled ---


	uci -q delete ucitrack.@$(MY_CONFIG_FILENAME)[0]
	uci -q del_list ucitrack.@network[0].affects=$(MY_CONFIG_FILENAME)
	uci -q commit
	echo --- ucitrack section \"$(MY_CONFIG_FILENAME)\" deleted ---
	echo --- ucitrack: \"network\" now don\'t affects \"$(MY_CONFIG_FILENAME)\" config ---

	##### for dnsmasq #####
	if [ -f /etc/rc.d/S??dnsmasq ]
	then
		echo --- dnsmasq found in /etc/rc.d ---

		uci -q set dhcp.@dnsmasq[0].port="`uci -q get $(MY_CONFIG_FILENAME).@$(MY_CONFIG_SECTION_SAVE)[0].dnsmasq_port`"
		uci -q del_list dhcp.lan.dhcp_option="6,`uci -q get network.lan.ipaddr`"
		uci -q commit
		/etc/init.d/dnsmasq reload
		echo --- dnsmasq DNS restored to saved state ---
	fi
	#######################


	rm -f    /etc/config/$(MY_CONFIG_FILENAME)
	echo --- /etc/config/$(MY_CONFIG_FILENAME) removed ---

	echo --- $(PKG_NAME) removed ---
endef


include luci.mk

# call BuildPackage - OpenWrt buildroot signature

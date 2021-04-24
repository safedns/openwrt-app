#
# Copyright (C) 2006-2016 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=dnsmasq
PKG_VERSION:=2.77
PKG_RELEASE:=0

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.xz
PKG_SOURCE_URL:=http://thekelleys.org.uk/dnsmasq/
PKG_HASH:=6eac3b1c50ae25170e3ff8c96ddb55236cf45007633fdb8a35b1f3e02f5f8b8a
PKG_LICENSE:=GPL-2.0
PKG_LICENSE_FILES:=COPYING
PKG_CPE_ID:=cpe:/a:thekelleys:dnsmasq

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)

PKG_INSTALL:=1
PKG_BUILD_PARALLEL:=1
PKG_CONFIG_DEPENDS:=

include $(INCLUDE_DIR)/package.mk

define Package/safedns
  SECTION:=net
  CATEGORY:=Network
  TITLE:=SafeDNS Cloud Content Filter
  URL:=http://safedns.com
  DEPENDS:=+libubus +libuci
  USERID:=dnsmasq=453:dnsmasq=453
endef

define Package/safedns/description
Free for personal use Cloud Content Filter module allows you to filter unwanted websites and protect your network and individual devices from Internet threats like malware, botnets, phishing and so on. In commercial version additional features are available, like scheduler, different filtering policies for individual devices, ads blocking, block page customization, and many more. Visit www.safedns.com to see full list of SafeDNS features.
endef

TARGET_CFLAGS += -ffunction-sections -fdata-sections
TARGET_LDFLAGS += -Wl,--gc-sections

COPTS += -DNO_AUTH -DNO_IPSET -DNO_ID -DNO_DHCP -DNO_TFTP -DNO_SCRIPT -DNO_INOTIFY

MAKE_FLAGS := \
	$(TARGET_CONFIGURE_OPTS) \
	CFLAGS="$(TARGET_CFLAGS) $(TARGET_CPPFLAGS)" \
	LDFLAGS="$(TARGET_LDFLAGS)" \
	COPTS="$(COPTS)" \
	PREFIX="/usr"

define Package/safedns/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(CP) $(PKG_INSTALL_DIR)/usr/sbin/safedns $(1)/usr/sbin/
endef

$(eval $(call BuildPackage,safedns))

######################################################
# Project: Somfy Awning Controller Homebridge Wrapper
#
# Type: OpenWRT Makefile
# Author: Zbynek Kocur (zokl@atlas.cz)
#
# Copyright (C) 2020 zokl@2020
# License: MIT
######################################################

include $(TOPDIR)/rules.mk

PKG_NAME:=sac
PKG_VERSION:=2020082501
PKG_RELEASE:=2020090301

PKG_MAINTAINER:=Zbynek Kocur <zokl@atlas.cz>

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SECTION:=Extra packages
  CATEGORY:=Extra packages
  TITLE:=Somfy Awning Controller
  URL:=https://github.com/zokl/openwrt-homebridge-sac
  DEPENDS:=+lua +libubus +libubus-lua +libubox +libubox-lua +libuci-lua
endef

define Package/$(PKG_NAME)/description
Somfy Awning Controller System Ubus Daemon.
endef

define Build/Prepare
	$(call Build/Prepare/Default)
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/sac
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/sac.init $(1)/etc/init.d/sac

	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/sac.conf $(1)/etc/config/sac

	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) ./src/sac-ubus.lua $(1)/usr/sbin/sac

	$(INSTALL_DIR) $(1)/usr/share/sac
	$(INSTALL_BIN) ./src/sac-homebridge-wrapper.sh $(1)/usr/share/sac/
	$(CP) ./files/homebridge-config.json.template $(1)/usr/share/sac/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))

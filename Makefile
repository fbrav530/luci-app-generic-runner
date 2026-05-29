include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-generic-runner
PKG_VERSION:=1.0
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-generic-runner
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=3. Applications
  TITLE:=LuCI support for Generic Runner
  DEPENDS:=+luci-base
  PKGARCH:=all
endef

define Build/Compile
endef

define Package/luci-app-generic-runner/install
	# 创建目标目录
	$(INSTALL_DIR) $(1)/etc/init.d
	
	# 使用 INSTALL_BIN 安装启动脚本（会自动加上执行权限）
	$(INSTALL_BIN) ./root/etc/init.d/generic_runner $(1)/etc/init.d/generic_runner

	# 顺便提一下：普通的配置文件用 INSTALL_DATA，它会保持 644 权限（不可执行）
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DATA) ./root/etc/config/generic_runner $(1)/etc/config/generic_runner

	$(INSTALL_DIR) $(1)/usr/lib/lua/luci
	$(CP) ./root/usr/lib/lua/luci/* $(1)/usr/lib/lua/luci/
endef

$(module luci-app-generic-runner)
$(eval $(call BuildPackage,luci-app-generic-runner))

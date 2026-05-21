#!/bin/bash
set -e

# Default LAN IP. This matches your current router address.
sed -i 's/192.168.1.1/192.168.100.1/g' package/base-files/files/bin/config_generate

# Friendly hostname shown in LuCI.
sed -i 's/OpenWrt/QWRT-N100/g' package/base-files/files/bin/config_generate

# Q-WRT 21.02 is older than the package list we need, so add missing package
# definitions at build time.
if ! grep -q 'nf_add,NF_TPROXY' include/netfilter.mk; then
  awk '
    {
      print
      if ($0 == "# tproxy") {
        print "$(eval $(call nf_add,NF_TPROXY,CONFIG_NF_TPROXY_IPV4, $(P_V4)nf_tproxy_ipv4))"
        print "$(eval $(call nf_add,NF_TPROXY,CONFIG_NF_TPROXY_IPV6, $(P_V6)nf_tproxy_ipv6))"
        print "$(eval $(if $(NF_KMOD),$(call nf_add,NFT_TPROXY,CONFIG_NFT_TPROXY, $(P_XT)nft_tproxy),))"
      }
    }
  ' include/netfilter.mk > include/netfilter.mk.tmp
  mv include/netfilter.mk.tmp include/netfilter.mk
fi

if ! grep -q 'define KernelPackage/nf-tproxy' package/kernel/linux/modules/netfilter.mk; then
  awk '
    {
      print
      if ($0 == "$(eval $(call KernelPackage,nf-flow))") {
        print ""
        print "define KernelPackage/nf-tproxy"
        print "  SUBMENU:=$(NF_MENU)"
        print "  TITLE:=Netfilter tproxy support"
        print "  KCONFIG:=$(KCONFIG_NF_TPROXY)"
        print "  FILES:=$(foreach mod,$(NF_TPROXY-m),$(LINUX_DIR)/net/$(mod).ko)"
        print "  AUTOLOAD:=$(call AutoProbe,$(notdir $(NF_TPROXY-m)))"
        print "endef"
        print ""
        print "$(eval $(call KernelPackage,nf-tproxy))"
      }
    }
  ' package/kernel/linux/modules/netfilter.mk > package/kernel/linux/modules/netfilter.mk.tmp
  mv package/kernel/linux/modules/netfilter.mk.tmp package/kernel/linux/modules/netfilter.mk
fi

if ! grep -q 'define KernelPackage/nft-tproxy' package/kernel/linux/modules/netfilter.mk; then
  awk '
    {
      print
      if ($0 == "$(eval $(call KernelPackage,nft-queue))") {
        print ""
        print "define KernelPackage/nft-tproxy"
        print "  SUBMENU:=$(NF_MENU)"
        print "  TITLE:=Netfilter nf_tables tproxy support"
        print "  DEPENDS:=+kmod-nft-core +kmod-nf-tproxy +kmod-nf-conntrack"
        print "  FILES:=$(foreach mod,$(NFT_TPROXY-m),$(LINUX_DIR)/net/$(mod).ko)"
        print "  AUTOLOAD:=$(call AutoProbe,$(notdir $(NFT_TPROXY-m)))"
        print "  KCONFIG:=$(KCONFIG_NFT_TPROXY)"
        print "endef"
        print ""
        print "$(eval $(call KernelPackage,nft-tproxy))"
      }
    }
  ' package/kernel/linux/modules/netfilter.mk > package/kernel/linux/modules/netfilter.mk.tmp
  mv package/kernel/linux/modules/netfilter.mk.tmp package/kernel/linux/modules/netfilter.mk
fi

if ! grep -q 'define KernelPackage/mt7922-firmware' package/kernel/mt76/Makefile; then
  mkdir -p package/kernel/mt76/files
  curl -fL --retry 3 \
    -o package/kernel/mt76/files/WIFI_MT7922_patch_mcu_1_1_hdr.bin \
    https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/plain/mediatek/WIFI_MT7922_patch_mcu_1_1_hdr.bin
  curl -fL --retry 3 \
    -o package/kernel/mt76/files/WIFI_RAM_CODE_MT7922_1.bin \
    https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/plain/mediatek/WIFI_RAM_CODE_MT7922_1.bin

  awk '
    {
      if ($0 == "define KernelPackage/mt7921-common") {
        print "define KernelPackage/mt7922-firmware"
        print "  $(KernelPackage/mt76-default)"
        print "  TITLE:=MediaTek MT7922 firmware"
        print "endef"
        print ""
      }
      if ($0 == "define KernelPackage/mt7921e/install") {
        print "define KernelPackage/mt7922-firmware/install"
        print "\t$(INSTALL_DIR) $(1)/lib/firmware/mediatek"
        print "\t$(INSTALL_DATA) \\"
        print "\t\t./files/WIFI_MT7922_patch_mcu_1_1_hdr.bin \\"
        print "\t\t./files/WIFI_RAM_CODE_MT7922_1.bin \\"
        print "\t\t$(1)/lib/firmware/mediatek"
        print "endef"
        print ""
      }
      if ($0 == "$(eval $(call KernelPackage,mt7921-common))") {
        print "$(eval $(call KernelPackage,mt7922-firmware))"
      }
      print
    }
  ' package/kernel/mt76/Makefile > package/kernel/mt76/Makefile.tmp
  mv package/kernel/mt76/Makefile.tmp package/kernel/mt76/Makefile
fi

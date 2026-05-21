#!/bin/bash
set -e

# Default LAN IP. This matches your current router address.
sed -i 's/192.168.1.1/192.168.100.1/g' package/base-files/files/bin/config_generate

# Friendly hostname shown in LuCI.
sed -i 's/OpenWrt/QWRT-N100/g' package/base-files/files/bin/config_generate

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

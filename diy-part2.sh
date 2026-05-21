#!/bin/bash
set -e

# Default LAN IP. This matches your current router address.
sed -i 's/192.168.1.1/192.168.100.1/g' package/base-files/files/bin/config_generate

# Friendly hostname shown in LuCI.
sed -i 's/OpenWrt/QWRT-N100/g' package/base-files/files/bin/config_generate


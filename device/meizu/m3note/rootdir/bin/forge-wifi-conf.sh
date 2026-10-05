#!/system/bin/sh
F=/data/misc/wifi/wpa_supplicant.conf
[ -e "$F" ] && exit 0
cp /system/etc/wifi/wpa_supplicant.conf "$F" || exit 1
chown wifi:wifi "$F"
chmod 0660 "$F"
restorecon "$F"

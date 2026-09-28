#!/sbin/sh

PATH=/sbin:/system/bin:/system/xbin

read_file() {
    [ -r "$1" ] && tr '\000' ' ' < "$1" 2>/dev/null
}

cmdline="$(read_file /proc/cmdline)"
compatible="$(read_file /proc/device-tree/compatible) $(read_file /sys/firmware/devicetree/base/compatible)"
model="$(read_file /proc/device-tree/model) $(read_file /sys/firmware/devicetree/base/model)"
product="$(getprop ro.product.device 2>/dev/null) $(getprop ro.build.product 2>/dev/null) $(getprop ro.product.name 2>/dev/null)"
hw="$(getprop ro.boot.hardware 2>/dev/null) $(getprop ro.hardware 2>/dev/null)"
all="$cmdline $compatible $model $product $hw"

codename=unknown
evidence=none

case "$all" in
    *meizu_m6*|*meizu-m6*|*ili9881p_hd_dsi_txd*)
        codename=meizu_m6
        evidence=panel_ili9881p
        ;;
    *l681h*|*l681*)
        codename=l681
        evidence=product_l681
        ;;
    *m681*|*m3note*|*ili9885_fhd_dsi_vdo_txd1*)
        codename=m681
        evidence=panel_ili9885_txd1
        ;;
esac

setprop sys.forge.meizu.codename "$codename"
setprop persist.forge.meizu.codename "$codename"
setprop sys.forge.meizu.detect "$evidence"

case "$codename" in
    meizu_m6)
        setprop sys.forge.meizu.panel ili9881p_hd_dsi_txd
        setprop sys.forge.meizu.touch ft5x0x
        setprop sys.forge.meizu.charger bq24157
        ;;
    m681)
        setprop sys.forge.meizu.panel ili9885_fhd_dsi_vdo_txd1
        setprop sys.forge.meizu.touch gt9xx
        setprop sys.forge.meizu.charger stocktruth
        ;;
    l681)
        setprop sys.forge.meizu.panel l681-stocktruth
        setprop sys.forge.meizu.touch l681-stocktruth
        setprop sys.forge.meizu.charger stocktruth
        ;;
    *)
        setprop sys.forge.meizu.panel unknown
        setprop sys.forge.meizu.touch unknown
        setprop sys.forge.meizu.charger unknown
        ;;
esac

log -t meizu_mt675x_detect "codename=$codename evidence=$evidence" 2>/dev/null
exit 0

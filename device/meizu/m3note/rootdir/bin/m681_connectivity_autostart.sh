#!/system/bin/sh

TAG=m681_conn_autostart
WPA_SOCKET=/data/misc/wifi/sockets/wlan0

log -t "$TAG" "begin"

STAGE=/sys/module/mtk_wcn_consys_hw/parameters/forge_conn_pwron_stage
EMI=/sys/module/mtk_wcn_consys_hw/parameters/forge_conn_emi
AUTO=/sys/module/wmt_dev/parameters/forge_conn_autopwr

# Idempotent: only kick the loader if the nodes are not already there. A second
# DO_MODULE_INIT pass re-enters MODULE_CLEANUP/sdio_detect_exit and re-runs
# BT_init, whose register_chrdev_region(major 192) then fails.
if [ ! -c /dev/wmtWifi ]; then
    setprop debug.m681.wmt.start 1
    n=0
    while [ ! -c /dev/wmtWifi ] && [ "$n" -lt 10 ]; do
        n=$((n + 1)); sleep 1
    done
    if [ ! -c /dev/wmtWifi ]; then
        /vendor/bin/wmt_loader &
        sleep 3
    fi
fi

# Suppress m681_wifi_kick.sh's start_wmt() (it re-triggers debug.m681.wmt.start
# and would cause exactly the duplicate pass described above).
[ -c /dev/wmtWifi ] && setprop debug.m681.wmt.ready 1

# The EMI knob only accepts writes once hw_init has run, i.e. after the loader.
n=0
while [ "$n" -lt 15 ]; do
    echo 7 > "$EMI" 2>/dev/null
    [ "`cat $EMI 2>/dev/null`" = "7" ] && break
    n=$((n + 1)); sleep 2
done
echo 4 > "$STAGE" 2>/dev/null

PSM=/sys/module/wmt_exp/parameters/forge_conn_psm
[ -w "$PSM" ] && echo 0 > "$PSM"

# Belt: wmt_dbg opcode 0x0 with par2=0 calls wmt_lib_ps_ctrl(0) DIRECTLY,
# bypassing the gate above, so it disables a PSM that is already running --
# the exact state the earlier runtime test hit. Covers the residual race where
# the framework auto-enables BT from persisted bluetooth_on at the same moment
# this script runs.
echo "0 0" > /proc/driver/wmt_dbg 2>/dev/null

log -t "$TAG" "psm: gate=$(cat $PSM 2>/dev/null) (0 = suppressed); wmt_dbg disable issued"
# --- end PSM off ------------------------------------------------------------

# forge_conn_autopwr deliberately left at 0. Its only effect is to let the
# fb-notifier work item WMT_init installs power consys spontaneously on screen
# blank/unblank (wmt_dev.c:264-269) -- the documented boot-reset-loop path. The
# BT HAL does not need it: opening /dev/stpbt drives mtk_wcn_wmt_func_on()
# directly. Flip to 1 here once consys power-on is proven green on 16.0.
log -t "$TAG" "knobs: stage=`cat $STAGE 2>/dev/null` emi=`cat $EMI 2>/dev/null` auto=`cat $AUTO 2>/dev/null`"

if [ -c /dev/stpbt ]; then
    chown bluetooth:bluetooth /dev/stpbt 2>/dev/null || chown bluetooth.bluetooth /dev/stpbt 2>/dev/null
    chmod 0660 /dev/stpbt 2>/dev/null
fi
# --- end consys arm --------------------------------------------------------

wifi_status()
{
    /system/bin/wpa_cli -p/data/misc/wifi/sockets -iwlan0 status 2>/dev/null
}

wifi_has_ip()
{
    /system/bin/ip addr show wlan0 2>/dev/null | /system/bin/grep -q " inet "
}

wifi_connected()
{
    if [ ! -S "$WPA_SOCKET" ]; then
        return 1
    fi

    case "`wifi_status`" in
        *"wpa_state=COMPLETED"*)
            if wifi_has_ip; then
                return 0
            fi
            ;;
    esac

    return 1
}

wifi_reconnect()
{
    if [ -S "$WPA_SOCKET" ]; then
        if wifi_connected; then
            log -t "$TAG" "wifi already connected with ip; skip reconnect"
            return 0
        fi
        /system/bin/wpa_cli -p/data/misc/wifi/sockets -iwlan0 enable_network all >/dev/null 2>&1
        /system/bin/wpa_cli -p/data/misc/wifi/sockets -iwlan0 scan >/dev/null 2>&1
        sleep 4
        if wifi_connected; then
            /system/bin/wpa_cli -p/data/misc/wifi/sockets -iwlan0 save_config >/dev/null 2>&1
            log -t "$TAG" "wifi connected after scan; skip reconnect"
            return 0
        fi
        /system/bin/wpa_cli -p/data/misc/wifi/sockets -iwlan0 reconnect >/dev/null 2>&1
        /system/bin/wpa_cli -p/data/misc/wifi/sockets -iwlan0 save_config >/dev/null 2>&1
        log -t "$TAG" "requested wifi reconnect"
        return 0
    fi
    return 1
}

bluetooth_ready()
{
    case "`/system/bin/getprop service.wcn.driver.ready`:`/system/bin/getprop debug.m681.wmt.ready`" in
        yes:*|*:1)
            ;;
        *)
            return 1
            ;;
    esac

    [ -c /dev/stpbt ] || return 1
    return 0
}

wifi_reenable_once()
{
    if [ -n "`getprop debug.m681.wifi.reenable`" ]; then
        return 0
    fi
    setprop debug.m681.wifi.reenable running

    # GATE 1 -- the interface must exist. Without it STA start fails in ~1 s.
    g1=absent
    n=0
    while [ "$n" -lt 60 ]; do
        if [ -d /sys/class/net/wlan0 ]; then g1=present; break; fi
        n=$((n + 1)); sleep 2
    done

    # GATE 2 -- WifiController must have STARTED. A StateMachine accumulates
    # records only inside SmHandler.handleMessage, which cannot run before
    # start(). On a half-started system_server this reads 0 and we refuse to
    # fire. FALSIFIER: if any boot ever logs
    #   FATAL EXCEPTION IN SYSTEM PROCESS: WifiService ... what=155656
    # AFTER this function's "FIRING" line, then records>0 did not imply start()
    # and this gate is invalid. An empty/failed dumpsys reads 0 and blocks,
    # which is the fail-safe direction.
    g2=0
    n=0
    while [ "$n" -lt 30 ]; do
        g2=`dumpsys wifi 2>/dev/null | grep -A1 "WifiController:" \
            | sed -n 's/.*total records=\([0-9][0-9]*\).*/\1/p'`
        [ -z "$g2" ] && g2=0
        if [ "$g2" -gt 0 ]; then break; fi
        n=$((n + 1)); sleep 2
    done

    if [ "$g1" = present ] && [ "$g2" -gt 0 ]; then
        setprop debug.m681.wifi.reenable done
        log -t "$TAG" "wifi re-enable FIRING: gate1 wlan0=$g1 gate2 WifiController_records=$g2"
        /system/bin/svc wifi enable
    else
        setprop debug.m681.wifi.reenable "blocked_g1_${g1}_g2_${g2}"
        log -t "$TAG" "wifi re-enable BLOCKED: gate1 wlan0=$g1 gate2 WifiController_records=$g2"
    fi
}
# --- end single gated Wi-Fi re-enable ---------------------------------------

# Let system_server, SettingsProvider and the MTK connectivity services settle.
sleep 12

/system/bin/settings put global wifi_on 1
/system/bin/settings put global wifi_saved_state 1 2>/dev/null
/system/bin/setprop debug.m681.wifi.power 1
log -t "$TAG" "wifi_on persisted; framework enables Wi-Fi at boot phase 500"

wait_count=0
while [ "$wait_count" -lt 30 ]; do
    if wifi_reconnect; then
        break
    fi
    wait_count=$((wait_count + 1))
    sleep 2
done

if bluetooth_ready; then
    /system/bin/settings put global bluetooth_on 1
    # svc, not `service call bluetooth_manager 6`: that transaction number is
    # Oreo-era and unverified on Pie. svc bluetooth exists in this tree
    # (frameworks/base/cmds/svc/.../BluetoothCommand.java).
    /system/bin/svc bluetooth enable >/dev/null 2>&1
    log -t "$TAG" "requested bluetooth enable"
else
    /system/bin/settings put global bluetooth_on 0 2>/dev/null
    log -t "$TAG" "skip bluetooth enable: wmt/stpbt not ready"
fi

wifi_reenable_once

sleep 8
wifi_reconnect

for delay in 10 20 35; do
    sleep "$delay"
    if wifi_connected; then
        log -t "$TAG" "wifi stable; stop retry loop"
        break
    fi
    wifi_reconnect
done

log -t "$TAG" "end"

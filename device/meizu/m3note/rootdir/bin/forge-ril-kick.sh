#!/system/bin/sh

LOG=/data/local/tmp/forge-ril-kick.log
exec >>"$LOG" 2>&1
echo "=== $(date) forge-ril-kick start (v2)"


wait_for() {                 # wait_for <label> <max-polls> <interval> <test-cmd...>
    label=$1; max=$2; iv=$3; shift 3
    i=0
    while [ $i -lt "$max" ]; do
        if "$@" >/dev/null 2>&1; then echo "$label: ready after ${i} polls"; return 0; fi
        sleep "$iv"; i=$((i+1))
    done
    echo "$label: TIMED OUT after ${i} polls"; return 1
}

prop_is() { [ "$(getprop "$1")" = "$2" ]; }

wait_for boot_completed 120 5 prop_is sys.boot_completed 1

# defect 1: the AT channels must exist before rild is restarted, otherwise the
# restart reproduces the very race it is meant to clear.
wait_for at_channels 60 5 test -e /dev/radio/pttycmd1
sleep 20
# defect 3 stopgap: let the radio group create /dev/socket/rild-mal.
# rild is already uid 1001 by the time any of its libraries load - measured,
# "MAL-EARLY: constructor running as uid=1001" - so libril cannot bind in a
# root-only directory, and init does not create this service's socket even
# though the line is byte-clean in /vendor/etc/init/rild.rc and init makes
# mal-mfi for mal-daemon from the same directory. Why init skips it is NOT
# established; this widens one tmpfs directory by one group instead of
# guessing. Remove it the moment the init side is understood.
chown root:radio /dev/socket 2>/dev/null
chmod 0775 /dev/socket 2>/dev/null
echo "dev/socket now: $(ls -ld /dev/socket)"

echo "restarting ril-daemon-mtk (defect 1); muxd=$(getprop init.svc.gsm0710muxd)"
setprop ctl.restart ril-daemon-mtk

# gsm.sim.state is per slot, comma-separated (FACT l681: ",LOADED" with the
# SIM in slot 2): any slot LOADED is enough.  The old exact match "LOADED"
# never matched on dual-SIM and burned the full 5 min of polls every boot
# (forge-ril-kick.log, 2026-10-01 and 2026-10-05).
sim_any_loaded() { case ",$(getprop gsm.sim.state)," in *,LOADED,*) return 0 ;; esac; return 1; }
wait_for sim_loaded 60 5 sim_any_loaded
echo "sim.state=$(getprop gsm.sim.state) radio=$(getprop init.svc.ril-daemon-mtk)"

APN=$(getprop persist.m681.ril.attach_apn)
[ -z "$APN" ] && APN=internet.mts.ru
if [ -e /dev/radio/atci1 ]; then
    echo "writing attach apn '$APN' to the modem (defect 2)"
    printf 'AT+ES3G=1,7\r'                   > /dev/radio/atci1
    sleep 3
    printf 'AT+CGDCONT=0,"IP","%s"\r' "$APN" > /dev/radio/atci1
    sleep 3
    printf 'AT+COPS=0\r'                     > /dev/radio/atci1
else
    echo "no /dev/radio/atci1 - skipped"
fi

wait_for registered 40 5 sh -c '[ -n "$(getprop gsm.operator.numeric)" ] && [ "$(getprop gsm.operator.numeric)" != "000000" ]'
echo "result: op=$(getprop gsm.operator.alpha) num=$(getprop gsm.operator.numeric) net=$(getprop gsm.network.type)"
echo "=== done"

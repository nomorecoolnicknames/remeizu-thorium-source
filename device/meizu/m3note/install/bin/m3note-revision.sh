#!/sbin/sh
# m3note-revision.sh -- run by the OTA (releasetools.py) in OrangeFox/TWRP
# BEFORE anything is written.  Exit 0 = /tmp/m3note-revision holds m681|l681.
#   $1 -- panel list (install/m3note-panels.tsv, the same list libinit reads)
# Exit codes (the reason also goes to /tmp/recovery.log via stderr):
#   3 not booted as recovery (no bootmode.recovery=true on the cmdline).  FACT
#     (m681, memory no-hands-test-images): a TWRP started from p22 by a normal
#     boot leaves boot write-protected by LK, dd hangs with CMD<29> -110.
#   4 the cmdline names panels of both boards
#   5 no known panel in lcm= -- no default revision, by design
#   6 by-name/boot is not mmcblk0p22 (the boot of both revisions by GPT)
#   7 no panel list
L=$1
BYNAME=/dev/block/platform/mtk-msdc.0/11230000.msdc0/by-name
CL=$(cat /proc/cmdline)
say() { echo "m3note-revision: $*" >&2; }

case " $CL " in
    *" bootmode.recovery=true "*) ;;
    *) say "not booted as recovery; reboot with 'reboot recovery' and install again"; exit 3 ;;
esac
[ -f "$L" ] || { say "no panel list $L"; exit 7; }

board=
for tok in $CL; do
    case "$tok" in lcm=*) ;; *) continue ;; esac
    while IFS='	' read -r sub rev; do
        case "$sub" in ''|'#'*) continue ;; esac
        case "$rev" in m681|l681) ;; *) continue ;; esac
        case "$tok" in
            *"$sub"*)
                if [ -n "$board" ] && [ "$board" != "$rev" ]; then
                    say "cmdline names both $board and $rev panels: $tok"; exit 4
                fi
                board=$rev ;;
        esac
    done < "$L"
done
[ -n "$board" ] || { say "no known panel in lcm= of: $CL"; exit 5; }

boot=$(readlink -f "$BYNAME/boot")
[ "$boot" = /dev/block/mmcblk0p22 ] || { say "by-name/boot -> '$boot', expected /dev/block/mmcblk0p22"; exit 6; }

echo "$board" > /tmp/m3note-revision
say "revision $board, boot $boot"
exit 0

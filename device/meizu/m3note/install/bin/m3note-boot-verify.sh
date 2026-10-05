#!/sbin/sh
# m3note-boot-verify.sh <size-sha256 file> -- read back the first <size> bytes
# of by-name/boot and compare with the sha256 the build recorded for
# boot-l681.img (build/tasks/m3note-boot-l681.mk).  Exit 0 = match.
read -r size want < "$1" || exit 2
have=$(dd if=/dev/block/platform/mtk-msdc.0/11230000.msdc0/by-name/boot bs=4096 count=$(( (size + 4095) / 4096 )) 2>/dev/null | head -c "$size" | sha256sum | cut -d' ' -f1)
[ "$have" = "$want" ] && { echo "m3note-boot-verify: boot-l681 readback ok" >&2; exit 0; }
echo "m3note-boot-verify: readback $have, expected $want" >&2
exit 1

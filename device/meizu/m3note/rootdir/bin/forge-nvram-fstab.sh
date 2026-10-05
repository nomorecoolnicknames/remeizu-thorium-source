#!/system/bin/sh
for d in /nvdata /data/nvram; do
    [ -d "$d" ] || continue
    cp /fstab.mt6755 "$d/.fstab.mt6755.tmp" && chmod 0644 "$d/.fstab.mt6755.tmp" &&
        mv -f "$d/.fstab.mt6755.tmp" "$d/fstab.mt6755"
done

#!/system/bin/sh
# Arms the 4.4 mt_cpufreq driver unless opted out (rootdir/m3note-cpufreq.rc).
[ "$(getprop persist.vendor.m3note.cpufreq_arm)" = 0 ] && exit 0
echo 1 > /sys/module/mt_cpufreq/parameters/forge_mt_cpufreq

#!/bin/bash
set -u
OUT=$1; MODE=$2; mkdir -p "$OUT"
ADB=${ADB:-adb}
sh_() { $ADB shell "$@"; }
ts=$(date -u +%H%M%S)
case "$MODE" in
idle|incall)
    sh_ 'cat /proc/uptime; getprop ro.vendor.meizu.profile; getprop af.modem_1.status; getprop af.ril.speech.codec.info' > "$OUT/$MODE-$ts-props.txt" 2>&1
    sh_ 'dumpsys media.audio_flinger' > "$OUT/$MODE-$ts-audioflinger.txt" 2>&1
    sh_ 'dumpsys audio' > "$OUT/$MODE-$ts-audio.txt" 2>&1
    sh_ 'tinymix 2>/dev/null || echo "no tinymix (user build?)"' > "$OUT/$MODE-$ts-tinymix.txt" 2>&1
    sh_ 'logcat -b all -d -v UTC' | grep -a -iE "speech|SPH|ccci_aud|AudioALSA|SpeechDriver|SpeechMessenger|EFUN|ESPEECH|setMode|MODE_IN_CALL" > "$OUT/$MODE-$ts-logcat.txt"
    echo "saved $OUT/$MODE-$ts-*" ;;
micmode)
    n=$3
    if [ "$n" = reset ]; then sh_ 'setprop persist.rm.debug.phonemic ""'; else sh_ "setprop persist.rm.debug.phonemic $n"; fi
    sh_ 'stop audioserver; start audioserver; sleep 3'
    sh_ 'tinycap /data/local/tmp/m3note-mic.wav -D 0 -d 0 -c 1 -r 48000 -b 16 -T 5 >/dev/null 2>&1; ls -l /data/local/tmp/m3note-mic.wav'
    $ADB pull /data/local/tmp/m3note-mic.wav "$OUT/mic-mode-$n-$ts.wav" >/dev/null
    python3 - "$OUT/mic-mode-$n-$ts.wav" <<'PY'
import sys, wave, struct, math
w = wave.open(sys.argv[1]); d = w.readframes(w.getnframes())
s = struct.unpack('<%dh' % (len(d) // 2), d)
print('samples', len(s), 'rms', round(math.sqrt(sum(x*x for x in s) / max(1, len(s))), 2), 'max', max(map(abs, s)) if s else 0)
PY
    ;;
*) echo "usage: $0 <outdir> idle|incall|micmode <n|reset>" >&2; exit 2 ;;
esac

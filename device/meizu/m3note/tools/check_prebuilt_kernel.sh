#!/bin/sh
set -u
IMG=$1
EXP=$2

# Подробности — в stderr (видны в логе сборки как есть), в stdout — короткий
# маркер, по которому BoardConfig валит сборку через $(error).
[ -f "$IMG" ] || { echo "ЯДРО НЕ НАЙДЕНО: $IMG" >&2; echo "prebuilt-kernel: ЯДРА НЕТ, см. подробности выше"; exit 0; }
[ -f "$EXP" ] || { echo "НЕТ ФАЙЛА ОЖИДАНИЙ: $EXP" >&2; echo "prebuilt-kernel: НЕТ ФАЙЛА ОЖИДАНИЙ, см. подробности выше"; exit 0; }

want_md5=$(awk '$1=="MD5"{print $2}' "$EXP")
have_md5=$(md5sum "$IMG" | cut -d' ' -f1)
[ "$want_md5" = "$have_md5" ] && exit 0

want_ver=$(sed -n 's/^VERSION //p' "$EXP")
have_ver=$(python3 - "$IMG" <<'PY' 2>/dev/null
import sys, zlib, re
d = open(sys.argv[1], 'rb').read()
i = d.find(b'\x1f\x8b\x08')
raw = b''
if i >= 0:
    try:
        raw = zlib.decompressobj(16 + zlib.MAX_WBITS).decompress(d[i:])
    except Exception:
        pass
m = re.search(rb'Linux version [0-9][^\x00]{0,140}', raw)
print(m.group(0).decode('utf-8', 'replace').strip() if m else 'версию извлечь не удалось')
PY
)

cat >&2 <<MSG
ЯДРО В prebuilt-kernel/ НЕ ТО, ЧТО ЗАПИСАНО В EXPECTED.txt.
  файл:    $IMG
  ожидаем: $want_md5
           $want_ver
  найдено: $have_md5
           $have_ver
Что делать:
  * если ядро подменили случайно — вернуть его из git (git checkout -- prebuilt-kernel/);
  * если меняете ядро сознательно — это новое ядро для l681, а у l681 загружались
    только 3.10.72+ #56 (ридбек p22 sha256 65cd6433…, restore-boot65cd-20260606T165057Z)
    Новое ядро вырезается из загрузившегося boot.img страницами
    [page, page+kernel_size) (заголовок ANDROID!, page 2048), кладётся сюда,
    и EXPECTED.txt обновляется ТЕМ ЖЕ коммитом, с записью в README.md
    (откуда образ, какой ридбек подтвердил загрузку).
  * ядро линии m681 (4.4.15 / 4.9) на l681 НЕ ставить вслепую: драйверов панелей
    l681 (hx8399/ili9885/nt35596 *_al1518) в 4.4 m681 нет, плата другая
    (Huaqin hq6755_66_b1a_l против Wingtech wt6755_66_sz_l).

ГРАНИЦА ЭТОГО ГЕЙТА: совпадение md5 означает лишь «файл соответствует дереву»,
а не «ядро годится для Android 9».
MSG
echo "prebuilt-kernel: ядро не совпадает с ожидаемым ($have_md5 вместо $want_md5), см. подробности выше"

# Сессия 2026-09-04: расширение unified-дерева на весь флот

Контекст: устройства офлайн; задача от владельца — собрать унифицированное
дерево так, чтобы LOS 16.0 мог собираться из него для всех устройств, плюс
thin device-три для никогда не подключавшихся U10/U20/M3s/M5 Note/M1 Note.

## Сделано (commit fbc3d68)

1. **Touch-фикс m681/l681 defconfig**: GT9XX on / FT5X* off (GT915L
   подтверждён на 4.4-daily; l681-boot-proven конфиг использует
   `CONFIG_TOUCHSCREEN_MTK_GT9XX_HOTKNOT=y`). u20_resynced из m681.
2. **4 новых thin dir**: u10, m3s (клоны meizu_m6), u20 (клон m681) + per-device
   vendorsetup.sh во ВСЕХ 9 (конвенция P-эры: lunch-комбины читаются из
   device/<oem>/<dev>/vendorsetup.sh, НЕ из центра).
   m1note — README-only stub: MT6752 = отдельная платформа.
3. **devices.json**: все 10 устройств; стейты m681/l681/meizu_m6 обновлены
   с устаревших (май-июнь) на факты 2026-09.
4. **docs/UNVERIFIED_DEVICES_FACTS_20260904.md** — веб-ресёрч 5 устройств.

## Реальные kernel-гейты (вечер 2026-09-04): 6/6 Image.gz-dtb OK

Gate v1 (grep-сид `.config`) был невалиден сам по себе: `grep -v '^#'` выбрасывает
строки `# CONFIG_X is not set`, и опции с `default y` (USB_MTK_HDRC) включались
обратно → mu3d+usb20 multiple-definition. Урок: сидить `.config` только полным
`cp defconfig`.

После честного сида:
- **meizu_m6, u10, m3s** — IMAGE OK в M6-дереве (sha: fc419602 / 545b5f3a / 3d9de8a9;
  System.map meizu_m6 == m3s — детерминизм подтверждён).
- **m681, u20** — сначала FAIL: GT9XX_hotknot-драйвер в graft-дереве ОБРЕЗАН
  (нет goodix_tool.c; M6-база никогда его не собирала) + wrong-symbol. Решение:
  **`CONFIG_TOUCHSCREEN_MTK_GT9XX_MZ=y`** — устройство-верифицированный порт
  стокового Goodix-драйвера v257 (коммиты 4f064166/4a930366 «DEVICE-VERIFIED
  touch works GT915L»), а GT9XX_FIRMWARE/CONFIG = "firmware_default"/
  "config_default" (нативные значения graft-дерева). IMAGE OK: 5371fc43 / 4b294d89.
- **l681** — thorium-клон m681 дрейфанул (чужой аудио-блок → AudDrv_GPIO_EXTAMP_Select
  too-few-args в 99degree). Решение: тело = нативный `l681_318_defconfig`
  (boot-proven, его build-home — 99degree-дерево) + thorium-шапка. IMAGE OK: f9980db4.

Артефакты: `out-gates/<dev>/{Image.gz-dtb,System.map,.config,defconfig.used,build.log,SHA256SUMS}`.

Следствия для дерева: (1) символ тача per-TREE (graft→GT9XX_MZ, 99degree→HOTKNOT);
(2) l681 пока собирается только в 99degree-дереве (в graft нет wt6755_66_n
проекта и l681_318.dts) — вопрос «перенести l681 DTS в graft» открыт;
(3) m681-семья в graft теперь собирается с ПРАВИЛЬНЫМ тачем — это основа
для будущих bacon-сборок m681/u20.
- **West breakfast-гейт**: lineage_{m5,m5note,u10,u20,m3s}-userdebug — все OK
  на боевом LOS16-дереве /home/gun/m6rom16/rom (контроль meizu_m6 OK).
  ВАЖНО: гейт работает только под sudo — out/ принадлежит root (контейнерные
  сборки), под gun envsetup-очистка валится и вешает ALL breakfast'ов,
  включая боевые (ловушка зафиксирована).
- **West mka nothing (граф), ФИНАЛ**: прогон с ALLOW_MISSING_DEPENDENCIES=true
  (только на время гейта, НЕ в дереве): **5/5 OK** (m5, m5note, u10, u20, m3s —
  полный ckati-граф собран, out/build-lineage_<dev>.ninja созданы). Единственный
  реально отложенный dep — 32-бит `libbluetooth_jni` (android-arm): у боевых
  продуктов он приходит из vendor/meizu/* блобов; при первом онбординге каждого
  устройства закроется extraction'ом. Других зависимостных гэпов граф не показал.

## Открытые пункты после этой сессии

- B1 per-device PMIC select (MT6351 vs MT6353) — НЕ тронут сознательно
  (behavior-neutral для бутящихся конфигов).
- B3 промоция shim-каскада в common — не сделана (нужен target-files diff
  гейт, отдельная сессия).
- kernel/meizu/mt6755 source placement на build-хосте (симлинк на M6 или
  graft дерево) — нужен выбор перед первой реальной сборкой bacon.
- Arch-политика per-device (M6_PURE_ARM64 vs 32+64) — решается при первом
  vendor-extract, не раньше (для неподключённых устройств неизвестно).
- m5note: возможен сток-codename m1621 — проверить на первом дампе;
  свериться с bju2000/android_device_meizu_m5note при онбординге.
- m3s: свериться с ElXreno/twrp_device_meizu_m3s + washinston деревьями.
- dump_meizu_M5Note (momo54181) — кандидат на офлайн-разбор стока ДО
  подключения железа.

## Правила для следующих сессий

- НИЧЕГО не пушить поверх боевых device/meizu/{meizu_m6,m681,M6T,m5c,m95} и
  mt6755-common/m3_meizu_m6-common/meizu_mt675x-common на west — только
  additive новые каталоги.
- West-гейты только через sudo (см. ловушка out/ выше).
- Thin dirs до первого онбординга НЕ должны получать выдуманных partition
  sizes/panel/touch — только UNVERIFIED-маркеры.

## Сток-прошивки u10/u20/m3s: загрузка + RE (вечер 2026-09-04)

Загружены с официального CDN dl-res.flymeos.com (Flyme 6.3.0.0G intl, 2018-04-12),
md5 сверены с CDN Content-Md5 — все три MATCH:
- flyme_fw/u10/flyme-6.3.0.0G-intl-u10.zip (1090653789 B, 6ba5a541…)
- flyme_fw/u20/flyme-6.3.0.0G-intl-u20.zip (965001971 B, c4f42863…)
- flyme_fw/m3s/flyme-6.3.0.0G-intl-m3s.zip (1052488861 B, 3a2135c4…)

Unpack-пайплайн (flyme_fw/unpack_stock2.sh): firmware-образы → sdat2img →
debugfs rdump → kernel zlib-распаковка (gzip+appended-DTB; ИЗВЛЕЧЕНИЕ DTB из
хвоста compressed-буфера валидно) → vendor-blobs инвентарь. Итог в
flyme_fw/<dev>/unpacked/ (boot/lk/preloader/recovery/md*/tz + build.prop +
system-files.txt + vendor-blobs/ 34-35M + stock-0.dtb/dts).

RE (субагенты ×3) → STOCK_TRUTH.md на устройство. Главные факты:
- m3s: проект **Y15**, сток-ядро 3.10.72+ Android 5.1; панели hd720 пул
  (hx8392b/hx8394f/ili9881c/otm1285a); камеры main **IMX258**+EEPROM / sub
  **OV5675** (web-гипотезы S5K3L8/S5K5E8 REJECTED); тач FocalTech fts@0x5D
  (+gt9xx backup); PMIC **MT6353**, charger fan5405, ext_buck mt6311;
  ALS/PS STK3x1x; HAL-суффикс mt6750.
- u10: проект **U10** (ODM Wind Z170), сток-ядро 3.18.22+ Android 6.0 —
  эра нашего 3.18-дерева; 5×hd720 панелей (ili9881p REJECTED); камера-пул из
  5 сенсоров (imx258/s5k5e8yx/s5k3l8/ov13853/hi553); тач DUAL FT5X26@0x38 +
  GT9xx@0x5d; PMIC MT6351(DTS)/MT6353(driver) — MT6350 REJECTED; charger
  switching@0x6b+fan5405@0x6a; сенсоры N2DM/qmcX983/mpu6515g/bmp280 +
  stk3x1x/epl259x/pa22x; LM3644 flash; NFC MT6605; PA aw8736.
- u20: проект **hq6755_66_1ma_m** (Huaqin 1MA), сток-ядро 3.18.22+; 13/11
  FHD-панелей (ili9885a/b, hx8399, nt35596, nt35532_boe_al1519); тач
  GT9xx@0x5D 1080×1920×5; PMIC **MT6351 CONFIRMED**; charger **BQ24196**;
  main **OV13853** + front **Hi-553** (web CONFIRMED); HAL-суффикс mt6755.

Внесено в дерево: OTA-assert «m3s M3s»/«u10 U10»/«u20 U20» (сток — заглавные);
defconfig-шапки несут полный STOCK TRUTH + явные placeholder-признания
(сборка на meizu_m6/wt6755_66_sz_l проектах до порта Y15/U10/1ma);
devices.json обновлён сток-фактами (panel/touch/camera/power/sensors/
board_project/hal_suffix).

Открыто: порты борд-проектов Y15 (с 3.10-стока), U10/Z170, hq6755_66_1ma_m
(dws+dts в 3.18-дерево) — класс работы как у m681 wt6755_66_sz_l; привязка
main/sub камер u10 (kdSensorList RE); дефолтная панель u20 из 11 (нужно
живое устройство или LK-objdump).

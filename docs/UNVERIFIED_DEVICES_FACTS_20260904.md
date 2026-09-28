# Неподключённые устройства — веб-ресёрч 2026-09-04 (FACT-база для thin dirs)

Субагент-ресёрч (web, 2026-09-04). Всё ниже — ПУБЛИЧНЫЕ источники; локальных
дампов нет ни по одному устройству (никогда не подключались к стенду).
Метки: CONFIRMED (источник) / LIKELY / UNKNOWN / CONFLICT.

## Сводка

| Устройство | SoC | Экран | Main cam | Front cam | Codename | Публичные деревья |
|---|---|---|---|---|---|---|
| U10 (U680H) | MT6750 CONFIRMED | 5.0" 720x1280 | IMX258 CONFIRMED | S5K5E8 CONFIRMED | u10 LIKELY (alias U680H; ro.product.device UNKNOWN) | **нет вообще** |
| U20 (U685H) | MT6755 Helio P10 CONFIRMED | 5.5" 1080x1920 | OV13853 CONFIRMED | Hi-553 CONFIRMED (≠ M5 Note!) | u20 LIKELY (alias U685H) | **нет вообще** |
| M3s (M612) | MT6750 CONFIRMED | 5.0" 720x1280 | S5K3L8 CONFIRMED | S5K5E8 CONFIRMED | **m3s CONFIRMED** | ElXreno TWRP; washinston cm_m3s + vendor + m3_m3s-common; meizucustoms |
| M5 Note (M621C/H) | MT6755 CONFIRMED | 5.5" 1080x1920 | OV13853 **или** S5K3L8 (два поставщика) | OV5675 **или** S5K5E8 | **m5note CONFIRMED** (возможен m1621 — проверить на первом дампе) | bju2000 lineage_m5note + vendor; momo54181 TWRP + dump-репо; Liuguanyi-fang |
| M1 Note (M463C/U) | **MT6752 CONFIRMED** | 5.5" 1080x1920 Sharp IGZO/AUO | Samsung 13Мп (модель не названа) | OV5670 CONFIRMED | **m1note CONFIRMED** (платформа mt6752) | iicc1 cm12.1; meizuosc/m463 (офиц. ядро); dellwin7ttl kernel; hakutakus/resparkstar TWRP |

## Ключевые URL

- M3s TWRP: github.com/ElXreno/twrp_device_meizu_m3s; CM: github.com/washinston/android_device_meizu_m3s (+vendor, m3_m3s-common)
- M5 Note: github.com/bju2000/android_device_meizu_m5note (+vendor); github.com/momo54181/dump_meizu_M5Note (сток-дамп — кандидат на разбор preloader/scatter!)
- M1 Note: github.com/meizuosc/m463 (официальный дроп ядра M463 = M1 Note/M1); github.com/dellwin7ttl/MT6752_m1note_kernel_source; github.com/hankching/mt6752-meiz-m463
- Спеки: gsmarena.com (8441/8440/8148/8450/6890), devicespecifications.com, meizu.com product spec pages

## Что НЕИЗВЕСТНО без дампа (не гадать)

- Панельные модули и тач-контроллеры — все UNKNOWN.
- PMIC: U10/M3s LIKELY MT6350, U20/M5Note LIKELY MT6351, M1Note LIKELY MT6325 — подтвердить чтением preloader/сток-vmlinux.
- ro.product.device у U10/U20 (алиасы U680H/U685H).
- Preloader-имена (board-проекты MTK) — нигде публично; первый источник — дамп.
- CONFLICT'ы: SD-слот U10; кластеры P10 (1.8 vs 2.0 ГГц); зарядка M5 Note (18 vs 24 Вт); Hall у U10.

## Решения по деревьям (2026-09-04)

- u10/m3s — клоны meizu_m6_defconfig (MT6750-семья); u20 — клон m681_defconfig (MT6755-семья).
- m1note — ЗАВЕДОМО отдельная платформа (MT6752, Mali-T760): в mt675x-дереве только README-стаб
  без makefiles и defconfig. Его путь — своё ядро (meizuosc/m463 / dellwin7ttl), потом отдельный thin dir.
- M3s/M5 Note имеют публичные device-деревья — при первом онбординге СВЕРИТЬСЯ с ними
  (partition sizes, panel modules, sensor списки), а не писать с нуля.
- dump_meizu_M5Note (momo54181) — первый кандидат на разбор стока M5 Note до подключения железа.

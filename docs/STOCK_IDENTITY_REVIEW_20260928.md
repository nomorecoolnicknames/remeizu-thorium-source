# ReMeizu: review старого family layer и stock identity

Дата проверки: 2026-09-28. Исходный thorium HEAD:
`4c5fc3e79d8a6d787efc0d30be3e18c997c40d08`.
Прочитаны применимые `/home/n8n/AGENTS.md`, Build Station AGENTS/CLAUDE и
`/srv/forge/android/AGENTS.md`. Изменяется только этот новый отчёт; stock artifacts,
старые документы, сайт, detector, device/kernel trees не менялись. Сборки,
прошивки, ADB и обращения к аппаратам не выполнялись. Серийные номера не записаны.

## 1. Объединение уже было: продолжать существующую работу

**FACT:** история thorium содержит:

| Commit | Сохранённый результат |
|---|---|
| `fbc3d68beb84564bcbb3cd5eaa9d69e550935554` | Расширение family layer и thin devices |
| `0dd30c80108fbf7e37096acf6cc36925f3b58e0f` | Документирование breakfast/make graph gates |
| `fca2ac17aaaa2797f1e77ac938304693fe71f2eb` | Сохранены шесть Image.gz-dtb build gates, исправления GT9XX/l681 |
| `4c5fc3e79d8a6d787efc0d30be3e18c997c40d08` | Результаты stock RE M3s/U10/U20, source placeholders отмечены явно |

**FACT:** [`SESSION_20260904_UNIFIED_FLEET.md`](SESSION_20260904_UNIFIED_FLEET.md:20)
содержит исторические kernel gates и отдельный graph gate с
`ALLOW_MISSING_DEPENDENCIES=true`. Они полезны как packaging/source evidence;
не обозначают stock-board port или готовую ROM. Не нужно заново создавать эти
пять products и повторять breakfast как будто это новая поддержка.

**FACT:** текущие thorium `device/meizu/{m3s,u10,u20,m5,m5note}` включают
`mt6755-common/BoardConfigCommon.mk` и `device-common.mk`. Common product
подключает `configs/$(TARGET_MEIZU_MT675X_DEVICE).mk` (device-common.mk:10).
Common BoardConfig уже обозначает platform/partition sizes per-device (:19, :61).
Это полезное основание; старые M6-biased panel/PMIC/boot defaults проверяются
по каждой плате, а не превращаются в hardware truth.

## 2. Что реально находится на west и в локальной A9 копии

**FACT, read-only SSH:** `/home/gun/m6rom16/rom/device/meizu/` существует на
`gunwest`, а не на текущем сервере. Локальная копия:
`/srv/forge/android/los16-ct07/device/meizu/`. На обоих хостах common repos:

| Каталог | Проверенный HEAD |
|---|---|
| `mt6755-common` | `b94e0862b18b04f829784226fa187d2f38d2debd` |
| `meizu_mt675x-common` | `c4e09d20fe64a42b0c4760d0e39bf7f6f0f685ab` |
| `m3_meizu_m6-common` | `fe0347645132fd21dfc6c0dbd6010fb8e2dd2a8d` |

**FACT:** A9 `mt6755-common/BoardConfigCommon.mk:1` включает
`meizu_mt675x-common/BoardConfigCommon.mk`; `m3_meizu_m6-common` также включает
этот старый общий слой. Product include `meizu_mt675x-common/device-common.mk`
в A9 optional, самого файла нет. Старый JSON перечисляет только M6/m681/l681.
Эта deployed A9 структура отличается от более позднего thorium common, поэтому
не следует считать два пути взаимозаменяемыми по одному basename.

**FACT:** пять новых A9 device dirs содержат ровно пять make/shell stub-файлов,
не имеют собственного Git HEAD. На west у всех пяти отсутствует
`vendor/meizu/<device>`, а общий `kernel/meizu/mt6755` отсутствует целиком.
`out/target/product/{m3s,m5,m5note,u10,u20}` содержит только fingerprint,
thumbprint, clean_steps, previous_build_config и product_copy_files_ignored;
boot/system/ROM zip в этих каталогах нет. Поэтому строка FLEET_MATRIX:386 про
существующие output dirs не должна отображаться как «ROM собрана».

**FACT:** `BoardConfig.mk` локальных A9 копий побайтно совпадает с west:

| Device | SHA256 BoardConfig.mk |
|---|---|
| m3s | `1b9b7d743301f6e53bfda1904750b104ed90b8bc333b701b1405eb2bec031727` |
| u10 | `32fbc0c4d396ef7356ff876889b65f7074ecf88ba8ea56442727bd09fe889b6c` |
| u20 | `8311638b38476b7183a42080b9b9b092273def18fda874d32bac70004c592b9c` |
| m5 | `b6b18333ccd97e1caac102883ce5edc03e7e424fcebec5e05b2d7481d8972280` |
| m5note | `2b6f74c16ba26d67177c172a7922534c708d4b50a0a68cbee53e6646ff3f9d46` |

**FACT:** для этих пяти имён нет отдельного product в проверенных
`meizu-fleet/a11-trees`, `meizu-fleet/targets/android` и
`/srv/forge/android/los20/device/meizu`. Это ограниченный инвентаризационный
результат, а не утверждение об отсутствии любых сторонних A11/A13 работ.

## 3. Stock binaries: повторная проверка вместо доверия заметкам

Общий префикс ниже: `/srv/forge/android/flyme_fw/<device>/unpacked/`.
**FACT:** для каждого boot.img заново разобран заголовок, gzip kernel
распакован в памяти. Его bytes совпали с `kernel.decompressed`, остаток gzip
побайтно совпал с `stock-0.dtb`. В этих payload ровно один такой appended DTB;
ошибочное описание панели в chosen не доказывает наличия второго DTB.

| Device | boot.img SHA256 | kernel.decompressed SHA256 | stock-0.dtb SHA256 |
|---|---|---|---|
| M3s | `f0b4f31d205a2ce052bb8f0118ee89e5bca322fce5bcf2f638f04e4936205e9a` | `4a64a32b8a30f55107af4ca3d43c6d4e3d23bf11b850adefdd982e49417b8dba` | `a392820fc6516b4b59ac502ef46756bdb5e1ad64fc78f425a11b927c49d9b815` |
| U10 | `03bde51ce54248ac380d47adf8f37bc8a3de374b480a5bc9ef2d536682538188` | `adb5309dade5477ae11aeae58436ff234cdb88be590685af8d06d14c9ea51748` | `07e70460413b8be2bad6a0d0c3acb81017d7c2550cea9fed397cccd50df1d00f` |
| U20 | `411e2b06494dc2e623f3ddd72bf1cee10c28521666e2ea26e3763e47ecf08997` | `8fc5c4103856a81c33352b57b1e18e845c781d68193f464ef80f52c1d12db96f` | `e3a213fba771d9d69488680cc6a47d80668c1c18c3b9c9ccf2237951cd69b4ab` |

**FACT:** все три boot header задают page=2048, kernel_addr=`0x40080000`,
ramdisk_addr=`0x45000000`, tags_addr=`0x44000000`, second_size=0, dt_size=0.
Это совместимая геометрия Android boot header, не равенство DTB, GPIO, carve-outs,
eMMC partition sizes или hardware. Не копировать partition limits из M6 common.

| Device | Подтверждённая software/SoC identity | Kernel banner и board project |
|---|---|---|
| M3s | build.prop:34 `ro.board.platform=mt6750`, :191 MT6755 BSP | 3.10.72+, `device/ginreen/Y15` (:319); Android 5.1 stock |
| U10 | build.prop:34 `ro.board.platform=mt6750`, :158 MT6755 BSP | 3.18.22+, `device/ginreen/U10` (:300); Android 6.0 stock |
| U20 | build.prop:32 `ro.board.platform=mt6755`, :155 MT6755 BSP | 3.18.22+, `device/huaqin/hq6755_66_1ma_m` (:283) |

**FACT, manufacturer specs:** [M3s](https://www.meizu.com/in/products/m3s/spec.html),
[U10](https://www.meizu.com/en/products/u10/spec.html) и
[M5](https://m.meizu.com/en/products/m5/spec.html) используют MT6750;
[U20](https://www.meizu.com/en/products/u20/spec.html) и
[M5 Note](https://www.meizu.com/in/products/m5note/spec.html) — Helio P10.
MT6755 family для M5 Note отражена в existing source plans; точный silicon
segment/eFuse конкретного будущего экземпляра не измерен. M5/M5 Note stock
artifacts в проверенном `flyme_fw` не найдены: это следующие input gates.

## 4. PMIC: исправить вывод, не угадывать замену

**FACT:** stock DTS всех трёх имеют одинаковую строку совместимости с MT6351
и MT6353: M3s `stock-0.dts:578`, U10 :1651, U20 :1654. Порядок совместимостей
не измеряет распаянный PMIC и не доказывает его HWCID.

**FACT:** в распакованном ядре, доказанно принадлежащем указанному boot.img:

| Device | Точный binary anchor / byte offset | Чего нет |
|---|---|---|
| M3s | `6353 PMIC Chip` @`0xd4b991`; `mediatek,mt6353-pmic` @`0xd43d38`; 8 paths `/pmic/mt6353/` | `6351 PMIC Chip`, `mediatek,mt6351-pmic`, `/pmic/mt6351/` |
| U10 | `6353 PMIC Chip` @`0xd85a59`; `mediatek,mt6353-pmic` @`0xd7eb68`; 5 paths `/pmic/mt6353/` | Те же MT6351 anchors |
| U20 | `6351 PMIC Chip` @`0xd65b69`; `mediatek,mt6351-pmic` @`0xd64ef8` | Соответствующие MT6353 anchors |

**INFERENCE:** stock kernel выбирает MT6353 code для M3s/U10 и MT6351 для U20.
Это существенно сильнее первого DTS compatible, но ещё не сегодняшнее чтение
HWCID на физической плате. IKCONFIG markers не найдены, `kernel.config` пусты.
Правильные registry поля: `pmic_driver_evidence=mt6353/mt6351`,
`pmic_live_chip_id=unknown`, а не «PMIC окончательно измерен».

**REJECTED:** U10 `STOCK_TRUTH.md:121` объявляет MT6351, хотя :174–176 сам
приводит MT6353 code; вывод противоречит первичным bytes. U20 документ :§2.3
также не должен обосновывать PMIC только первым compatible: для него теперь есть
независимый binary anchor. Старые документы не переписаны этим review.
M3s также нельзя переопределять на MT6351 по старому knowledge index.

**PLAN:** разносить PMIC subsystem profiles независимо от SoC family. M3s/U10
могут переиспользовать MT6353 driver work от M6, но voltage masks, IRQ/pins,
external buck, charger, battery limits и power sequencing остаются board gates.
U20 сначала сопоставлять с MT6351 m681/l681, а не оставлять MT6353 M6-graft.

## 5. Панели и placeholders: build-success не означает board-port

**FACT:** stock kernel M3s содержит HD720 HX8392/HX8394/ILI9881_CA family;
U10 — HX8392/HX8394/OTM1285A/OTM1287A; U20 — 13 FHD ILI9885/ILI9885A/B,
HX8399, NT35596, NT35532 variants. Это скомпилированный пул, не установленная
панель. `ili9881p_hd_dsi_txd` отсутствует во всех трёх stock kernels.

**FACT:** текущий scaffold всё ещё использует:

| Файл в `kernel/meizu/mt6755/arch/arm64/configs/` | Source anchors |
|---|---|
| `m3s_defconfig` | :192 project `meizu_m6`; :198 MT6353; :215 ILI9881P |
| `u10_defconfig` | :193 project `meizu_m6`; :199 MT6353; :216 ILI9881P |
| `u20_defconfig` | :193 project `wt6755_66_sz_l`; :199 MT6353; :216 ILI9885 TXD1 |
| `m5_defconfig` | :185 project `m5`; :191 MT6353; :208 ILI9881P — placeholder |
| `m5note_defconfig` | :185 project `m5note`; :191 MT6353; :208 HD ILI9881P — placeholder даже для FHD-модели |

**FACT:** сохранённые `out-gates/{meizu_m6,m3s,u10}/.config` имеют один SHA256:
`f93cc55343724f5918df710f87a1cb9dd917c2f4097e5e66b9fde934bbab3057`.
`System.map` M6/M3s также совпал:
`100c8c7b815443b34c149fc6b246a2e81c8f610c51ee35851a769b1dc131311c`.
M681/U20 `.config` совпал:
`cddea5fa5a0809ae07f387910534b2a0b9018b6aacecb140c0c85e0270bed417`.

**FACT:** сами Image.gz-dtb имеют разные hashes; не писать, что образы
побайтно одинаковы. Сохранённые SHA256:
M6 `fc41960249daaa3498aa854f42fc7d003eeabe1ad9c0e462a523986206ed71f3`,
M3s `3d9de8a981422c5d63e02c20413b8f600ad65231878faa76ddf84ed375d71137`,
U10 `545b5f3a6b8a35cbe72c2f56d4fa05c1fe40ec548641d95a3aae3a6119e9bc2f`,
U20 `4b294d89e0b11fe38420bac83a249385e42508d320b2b6926e6c7c4aa2a60e6d`.
**INFERENCE:** gates подтвердили компиляцию donor configurations; Y15/U10/1MA
board mapping и runtime остаются отдельной работой.

**REJECTED, site claim:** `/home/n8n/remeizu/site/ReMeizu.dc.html:926` говорит,
что U10 имеет идентичную M6 плату; :927 обещает простой перенос по layout.
Проверенный SHA256 страницы `2679ce6cd306f659f536b1821b2840c8214fd026db14f848a34f5090018016bf`.
Уже различные stock project и panel pool не позволяют использовать это
утверждение как основание порта. Правильный смысл: общая MT6750 платформа,
отдельный board port и пока неизвестная стоимость. Сайт этим review не менялся.

## 6. Слои ReMeizu и следующие gates

**PLAN:** сохранить ReMeizu umbrella и существующее chip-family объединение;
добавлять новые устройства как board profiles, не новые независимые форки всего:

1. Общие build recipes, provenance, source/DT extraction, ABI checks и лаборатория.
2. SoC/IP family `mt6735/6737`, `mt6753`, `mt6750/6755`, отдельно `mt6797`,
   `mt6752`, Qualcomm. Общий каталог не объявляет все SKU электрически одинаковыми.
3. Независимый PMIC profile, выбранный доказательствами: MT6353 vs MT6351.
4. Board layer: panel/touch/DCT/pins/rails/charger/cameras/firmware/GPT/bootloader.
5. OS layer: A9/A11/A13 ABI/package changes отдельно от hardware; mainline/Nura
   отдельно от legacy Android HAL, с общими hardware facts и evidence gates.

**PLAN / M3s:** Y15 3.10 → 3.18 board-data translation, panel/touch identity,
стоковые PMIC/charger mapping и точный vendor ABI; не переиспользовать M6 DTS.
**PLAN / U10:** U10/Z170 DT/DCT и собственный panel/touch/charger набор; выбранный
stock MT6353 driver допускает общую реализацию, но не общий pin/rail layout.
**PLAN / U20:** hq6755_66_1ma_m, MT6351 code, FHD panel variants и собственный
charger; снять MT6353 graft только после проверки PMIC mapping.
**PLAN / M5/M5 Note:** сначала stock boot/LK/DTB/scatter/blobs и model aliases;
их config stubs не задают аппаратную истину. `m1note` остаётся отдельной MT6752
платформой, M6 Note — Qualcomm, оба не включать в MT6750 driver compatibility.

**PLAN / Android:** после board identity — vendor extraction и полный graph
без `ALLOW_MISSING_DEPENDENCIES`, component ABI checks, image packaging, затем
readback/runtime. A11/A13 нельзя повышать до ready на основании A9 breakfast.
**PLAN / mainline:** брать подтверждённый m681 source baseline и MT6353 работу
M6, но отдельно описывать PMIC и каждую плату; старые proprietary HAL потребуют
собственного Android userspace пути. Kernel version alone не закрывает телефон.

**FACT / remaining uncertainty:** активные panel/PMIC HWCID/charger SKU,
bootloader-patched FDT, runtime power/suspend и периферия новых телефонов сегодня
не измерялись. Следующий наблюдаемый результат — per-board input manifest с
совпадением stock boot → kernel → DTB, затем source-built candidate и readback.

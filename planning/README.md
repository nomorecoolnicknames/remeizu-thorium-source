# ReMeizu: общий план платформ и плат — 2026-09-28

ReMeizu — весь проект: сайт, опубликованные и private исходники, будущие модели,
рабочие Android-ветки и Nura/postmarketOS. Восемь устройств оперативного fleet —
только текущий стенд, а не полный предел проекта. Этот план продолжает
[UNIFIED_TREE_PLAN](../UNIFIED_TREE_PLAN.md) и
[выполненную работу сентября](../docs/SESSION_20260904_UNIFIED_FLEET.md).

## Что уже объединено

**FACT:** Thorium HEAD до этой сессии `4c5fc3e79d8a6d787efc0d30be3e18c997c40d08`:
один `device/meizu/mt6755-common`, девять отдельных device-каталогов, десять записей
в существующем `configs/meizu_mt675x_devices.json` (M1 Note там справочно).
M3s/U10/U20 уже имеют thin device trees, defconfig заготовки, официальные stock
images и их разбор. Исторические kernel images и SHA256SUMS сохранились.

**FACT:** это ещё не завершённые новые board ports. В сохранённых `.config`
M3s/U10 выбирают проект `meizu_m6`, U20 — `wt6755_66_sz_l`. Сборочные результаты
показывают работоспособность донорского кода. Они не подтверждают загрузку Y15,
U10/Z170 или Huaqin 1MA. `ALLOW_MISSING_DEPENDENCIES=true` в старом ROM graph gate
также не является успешной полноценной сборкой Android.

Отдельный `/home/n8n/remeizu/m1882_unlock` сохраняется как исследование загрузчика
Meizu 16th, вне этой 17-модельной firmware-матрицы. Его старые заметки о моделях,
версиях и методах требуют проверки; они не импортируются как аппаратные факты.
Следующие ещё не названные модели добавляются после определения платы/SoC и
владельца трека, с собственным stock evidence и явным scope, без потери этого
исследования и без автоматического обещания готовой ROM.

**FACT:** существующие private GitHub common repos подтверждены авторизованным
`gh repo list`: `android_device_meizu_mt6755-common`,
`android_device_meizu_mt675x-common`, `android_device_meizu_m3_meizu_m6-common`,
`android_device_meizu_mt6753-common`. Unauthenticated 404 не означает, что их нет.
Новый competing common не создаётся; переносы должны использовать эти истории.

**FACT:** публичный [сайт](https://github.com/nomorecoolnicknames/remeizu) на
`0df4e26e870d99736683b341358ffa30314f4957` имеет 15 карточек; `ReMeizu.dc.html`
побайтно совпал с локальным файлом. Но карточки содержат исторические статусы:
M3s/U10/U20, M6T/M5s ещё «не в планах», а сведения о m681 относятся к старому ядру.
Это рассинхронизация содержания, не основание уменьшать текущий scope.

## Один индекс планов, существующие владельцы фактов

[`fleet.json`](fleet.json) связывает **17 моделей и шесть семейств** с существующими
источниками. Это индекс scope/aliases/планов: он не копирует panel/PMIC/serial,
не заменяет аппаратный inventory и не используется для определения живой платы.

| Данные | Где остаётся исходная информация |
|---|---|
| MT675x board research | `device/meizu/mt6755-common/configs/meizu_mt675x_devices.json` и реальные stock dumps; противоречия разбираются по первичным байтам |
| Stock M3s/U10/U20 | `/srv/forge/android/flyme_fw/<device>/unpacked/`; новый [review](../docs/STOCK_IDENTITY_REVIEW_20260928.md) уточняет PMIC/board claims |
| Строгие аппаратные facts Build Station | `/home/n8n/build-station/packages/shared-schemas/device_facts/`; planning не становится inheritance engine |
| Реальные входы сборок | `/srv/forge/android/meizu-fleet/targets/android/`: прежние 21 manifest, без переименования и без новых фиктивных targets |
| Runtime | `/srv/forge/android/meizu-fleet/FLEET_MATRIX.md` и точные captures; статусы проверяются для конкретной платы и образа |
| Публичные загрузки | `remeizu-releases`; наличие плана не создаёт релиз или download link |
| Покрытие всего проекта | `planning/fleet.json`, проверяемое против перечисленных источников и сайта |

Имя для связи каталогов не равно разрешённому OTA assert или `ro.product.device`.
Например, `m6t` сайта и `M6T-a11.json` относятся к `meizu_m6t`, но literal lunch,
asserts и runtime identity остаются прежними. `m95` относится к MX6,
`m2`/`meilan2` — к M2 Mini. **l681 — M3 Note Global, не M3s.** Возможный alias
M5 Note `m1621` пока не участвует в автоматическом разрешении.

## Семейная архитектура

| Трек | Модели в scope | Что объединять | Что проверять отдельно |
|---|---|---|---|
| MT6750/MT6755 | M6, M6T, M5, M3s, U10, M3; m681, l681, M5 Note, U20 | Существующий `mt6755-common`, ABI modules по поколению Android, проверенные SoC drivers и инструменты | PMIC/rails/OPP, ODM project, boot/partitions, panel/touch, camera/audio/modem blobs |
| MT6735/MT6737(M) | M2 Mini, M5c | Проверенные семейные IP-драйверы; current M5c Android и MT6735M mainline опоры | M/M-less pinctrl/PWRAP, CPU firmware, память, vendor ABI конкретной платы |
| MT6753 | M2 Note, M5s | Существующий private common, общие Android исправления, часть MT6735 IP | Два CPU cluster, SMP/SPM, PMIC/boot и board peripherals; отдельный SoC трек |
| MT6752 | M1 Note | Собственный kernel/device baseline | Отдельная платформа/Mali-T760; не создавать MT6755-клон |
| MT6797 | MX6 | Существующий MX6-трек и его владелец | Собственные PM/CPU/CCCI; Gemini mainline — donor, не runtime Meizu |
| MSM8953 | M6 Note/m1721 | Действующие Qualcomm Android/Nura source repositories | Не смешивать с MT6750 M6; собственные boot/firmware/camera пути |

**PLAN:** структура разделяется на `platform common → SoC/PMIC variant → board →
Android release packaging`. Один общий код не означает единый взаимозаменяемый
boot.img, одинаковые `.config` или одну смесь Android 9/11/13 Makefiles. Общие
fixes переносятся между закреплёнными release branches с проверкой ABI и build
inputs. Vendor blobs и калибровки остаются per-board/firmware; один только chip
name не разрешает переиспользование camera, IMS или питания.

Thorium пока не заменил все рабочие build homes: старые LOS16 пути ещё подключают
`m3_meizu_m6-common`, `mt6755-common`, `meizu_mt675x-common`. Закрывать это нужно
через сравнение конкретных продуктов, сохраняя их независимые Git истории и WIP.
Не перемещать все kernel trees под один каталог ради внешнего сходства.

## Ближайшие новые платы: Android и Linux

Все следующие строки — **PLAN**, а не обещание готовой прошивки.

| Плата | Уже есть | Android 9 → 11 → 13 | Современный Linux |
|---|---|---|---|
| **U20 / MT6755** | Stock 3.18.22+, Huaqin `hq6755_66_1ma_m`, thin tree и donor build | Закрыть 1MA DTS/DCT/boot/PMIC, затем A9 на своём vendor. После baseline подключать A11/A13 к проверенным MT6755 common modules | От m681 r95 переносить точную 1MA плату; PMIC MT6351, charger/panel/память сверять отдельно |
| **U10 / MT6750** | Stock 3.18.22+, U10/Z170, thin tree, donor build | Сначала реальный U10 project и vendor ABI; затем тот же порядок A9/A11/A13. Панель и touch не копировать с M6 | Общий MT6750 слой после PMIC support; собственные reset/rails/USB/display. Стоковый список NFC не доказывает распаянный чип |
| **M3s / MT6750** | Stock 3.10.72+, Y15, thin tree, donor build | Board/DCT перенос из более старого BSP, точные HAL/shims и recovery. A11/A13 только после своего загрузившегося baseline | Семейные SoC drivers применимы как основа; Y15 память/PSCI/питание/панель требуют отдельной адаптации |
| **M5 / M5 Note** | Existing thin trees, разная MT6750/MT6755 ветка | Сначала stock identity и vendor extraction, затем добавление реального target на каждую версию | M5 следует MT6750, M5 Note — MT6755; выбранная PMIC/board revision определяется данными |
| **M2 Mini** | Сторонние device/kernel/vendor и Treble ссылки в существующей карточке | Закрепить сохранившиеся источники и stock geometry; стороннее описание GSI не равно нашему A9/A11/A13 PASS | MT6735 ветка, без M5c M-варианта по умолчанию |
| **M3** | Карточка сайта, общий marketing SoC | Candidate до stock/board inventory; не делать copy-paste M3s ROM | Отдельная board запись после проверки firmware/hardware |

**INFERENCE / порядок с минимальной повторной работой:** по MT6755 сначала m681
baseline, затем l681 и U20; по MT6750 сначала M6, затем U10, M3s, M6T/M5 с учётом
доступности аппаратов. Наличие стоковой 3.18-базы у U10 уменьшает разрыв API по
сравнению с Y15/3.10, но не доказывает более быстрый runtime port. Одновременно
могут идти независимые kernel/ROM/stock-research очереди; каждый аппарат получает
одного владельца и одну очередь прошивок.

### M1 Note и Qualcomm

**PLAN / MT6752:** сохранить текущий README-only статус, закрепить отдельный
stock kernel/boot firmware и оценить timer/GIC/UART/USB/SMP до выбора современного
ядра. Android 9/11/13 — цели исследования, не готовые executable profiles.
Для mainline сначала найти и проверить MT6752-specific clock/pinctrl/PMIC support;
MT6735/6755 драйверы не подключаются простой сменой compatible.

**FACT / MSM8953:** уже существует
[meizu-m1721-pmaports](https://github.com/nomorecoolnicknames/meizu-m1721-pmaports)
и настоящая [kernel branch](https://github.com/nomorecoolnicknames/linux/tree/meizu-m1721)
`b465c66c549c018b6a7fac22f88b33a84286afcf` с Makefile 7.1.3. Пустой отдельный
`linux-meizu-m1721-mainline` не выбирать вместо неё. README-утверждения о звонках
и камерах здесь не перепроверялись на железе. Android 9/11/13 планируется своим
Qualcomm-треком; его существующее состояние сначала переносится в общую матрицу
как evidence, а не заменяется MTK boilerplate.

## Переход от существующих common к общей сборке

1. **PLAN:** закрепить SHA каждого текущего common/device/vendor и Android
   platform. Частные remote остаются private; публичный exporter их не раскрывает.
2. **PLAN:** вывести из common M6-specific partition geometry, hwrotation, audio
   suffix, panel/PMIC defaults и blob paths. Сначала сравнить generated config и
   target-files неизменного M6, затем m681. При изменении результата выяснить причину.
3. **PLAN:** подключить одну текущую A9 плату к Thorium через отдельный worktree/
   manifest, не переключая боевые checkout. Только после config/image/runtime
   parity повторить для остальных, затем A11/A13 release branches.
4. **PLAN:** future target появляется в `targets/android` лишь с собственными
   source pins, kernel hash, boot layout и vendor paths. В индексе планов пустой
   `android_targets` не означает поддержку отсутствует; он означает нет такого
   зарегистрированного входа сборки.
5. **PLAN:** CI выбирает затронутые семейства и контрольные платы по индексу.
   Общие module/kernel проверки переиспользуются; полный release acceptance всё
   равно проходит на каждой плате. Mainline и Android имеют разные критерии.

## Проверка покрытия и проекция для сайта

```sh
cd /home/n8n/remeizu-thorium
PYTHONDONTWRITEBYTECODE=1 python3 tools/remeizu_scope.py
PYTHONDONTWRITEBYTECODE=1 python3 tools/remeizu_scope.py --public
TMPDIR=/mnt/ramdisk PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tests -p 'test_remeizu_scope.py' -v
```

Checker читает existing 10-record Thorium inventory, 15-card website, 8 runtime
profiles и 21 Android manifest; обнаруживает пропуски/неоднозначные aliases и
чужие targets. Отдельный snapshot требует сохранения двух внешних треков,
MX6 и M6 Note, даже если модели нет в прочих каталогах.
Он не запускает shell из Make/HTML, сборку или ADB. Public JSON
содержит разрешённые planning fields без локальных путей, serials, firmware
facts и private remote references. Это подготовленный вход для синхронизации
сайта; production и GitHub Pages этой сессией не обновляются.

После подключения сайта к этой проекции карточки M3s/U10/U20 должны показывать
«в плане: stock изучен, board port не завершён», а версии Android — как цели,
пока нет отдельных build/runtime evidence. Старые релизы остаются отдельными
записями. Для отсутствующей физической платы нельзя автоматически поставить
«работает» из результата соседнего телефона.

## Checkpoint

**Категория:** DIAGNOSTIC, planning/source coverage; kernel/device behavior не меняется.
**Hypothesis:** scope lost between the website, Thorium and the eight-device
bench can be restored by one planning index referencing the existing sources.
**Evidence:** matching remote/local website, Thorium history/thin trees, stock
files, 21 existing target manifests and 8 runtime profile keys; exact inputs are
recorded in [sources.json](sources.json) and the stock identity review.
**Files / why:** planning index joins aliases and plan references; checker prevents
silent omissions and keeps public output narrow; current-plan notices point old
documents at this update. Historical inventories and worktrees are preserved.
**Expected next evidence:** complete coverage check, then a real board port for
the selected new device and an unchanged-baseline common migration comparison.
**Rollback condition:** alias collision, omitted model/target, implicit PMIC/
board inheritance or invented runtime readiness blocks use of the projection.
**Verification (2026-09-28):** 13/13 regression tests PASS; real registry PASS:
17 boards, 6 families, Thorium 10/10, site 15/15, runtime profiles 8/8,
Android targets 21/21, required external tracks 2/2. Public projection PASS:
17 boards with only allowlisted fields. Removal of M6 Note and insertion of
local filesystem paths into public prose both block output. Source coverage is
separate from compilation, readback and runtime. No kernel build, flash, public
push or deployment in this step.

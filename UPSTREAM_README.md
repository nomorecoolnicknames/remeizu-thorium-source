# ReMeizu — unified MediaTek device trees (Thorium-style)

> **Current scope / 2026-09-28:** continue the existing common and device trees
> using [the project-wide plan](planning/README.md) and
> [the planning index](planning/fleet.json): 17 models across 6 chipset tracks,
> including M3s/U10/U20, Android 9/11/13 and Nura/mainline. Historical tables below
> describe earlier work; a donor build is not a completed board port.
> `python3 tools/remeizu_scope.py` checks coverage against the existing inventories.
> No new common tree replaces this repository.

One common tree per **platform**, thin per-device trees, device variants selected at
`lunch`. Modeled on the Mi-Thorium MSM8937 unified tree, adapted for MediaTek.

This skeleton is the de-duplicated replacement for the old split common trees.
New work goes here; nothing carries a per-model name anymore — the common tree
is named only by its SoC platform.

## Platform groups (by SoC — confirmed)

| Group (kernel platform) | Common tree | Devices |
|---|---|---|
| **mt6755** (Helio P10/P15; MT6750 = lower bin) | `device/meizu/mt6755-common` | M6, M6T, M5 (MT6750) · M3 Note M681/L681, M5 Note (MT6755) |
| **mt6735** (MT6753 / MT6737) | `device/meizu/mt6735-common` *(future)* | M2 Note, M5s (MT6753), M5c (MT6737m) |
| **mt6752** | standalone | M1 Note — different platform & GPU (Mali-T760), **not** an mt6735 port |

This skeleton scaffolds the **mt6755** group first (the largest: 6 devices).

## Variant matrix (mt6755-common)

| codename | model | SoC | kernel cfg (Phase 1 = 3.18.140) | panel / notes | status |
|---|---|---|---|---|---|
| `meizu_m6` | Meizu M6 | MT6750 | `meizu_m6_defconfig` | HW 180° OVL rotation | ✅ boots (LOS 15.1) |
| `m6t` | Meizu M6T | MT6750 | TODO (clone meizu_m6) | — | ⏳ planned |
| `m5` | Meizu M5 | MT6750 | TODO (clone meizu_m6) | — | ⏳ planned |
| `m681` | M3 Note (China, M91) | MT6755 | `m681_defconfig` (3.18 m6-graft) | ili9885 TXD1 | 🔧 WIP graft |
| `l681` | M3 Note (Global, L91) | MT6755 | `l681_defconfig` (single-dtb) | same panel | 🔧 WIP |
| `m5note` | Meizu M5 Note | MT6755 | TODO (clone m681) | — | ⏳ planned |

## Kernel roadmap

- **Phase 1 — converge on 3.18.140.** Single kernel base for the whole group
  (the working M6 `kernel-3.18.140` tree). Each device = its own `*_defconfig`
  + DTB + in-kernel panel (`CONFIG_CUSTOM_KERNEL_LCM`). This is the precondition
  for real unification: today M6 is on 3.18/LOS15.1 while M681 is still on the
  3.10 stocktruth base — the **m681 "3.18 m6-graft" experiment is exactly this
  convergence step**. Until M681 boots on 3.18, its unification is half-done.
- **Phase 2 — backport to 4.4 from mt6757 (Helio P20).** Plausible: mt6757 is the
  4.4 sibling of mt6755 (same `drivers/misc/mediatek` layout, same ARM64 A53,
  same DDP/MTKCAM lineage). Strategy: take an mt6757 4.4 BSP as the base, graft
  the mt6755 platform dir + our panel/charger/sensor/fp deltas onto it. Risk:
  MTKCAM/ISP ABI and DTB bindings shift between 3.18 and 4.4 — expect real work
  on camera + display. Backport once, benefits the whole group.

## Layout

```
device/meizu/
  mt6755-common/            # the unified common tree (this skeleton)
    BoardConfigCommon.mk     # platform/arch/wifi/kernel-base/sepolicy — SHARED
    device-common.mk         # shared PRODUCT_* / HALs / overlays / rootdir
    vendorsetup.sh           # all lunch combos
    sepolicy/ overlay/ rootdir/ configs/
  <codename>/               # thin per-device (BoardConfig + 3 makefiles)
    BoardConfig.mk           # includes common, sets kernel/DTB/panel/partitions
    device.mk                # inherits device-common, sets variant + vendor
    lineage_<codename>.mk    # PRODUCT_* + lineage common
    AndroidProducts.mk
```

Vendor blobs stay per-device (`vendor/meizu/<codename>`, TheMuppets-style).

## Status

`mt6755-common` is now a REAL consolidated tree (~250 files): merged from the two
old common trees, de-duplicated, **no per-model naming**. Self-references fixed,
per-device SELinux + variant dispatch restored, runtime-detect kept, real shared
payload present (include headers, libbt-vendor-mtk, libxlog, cmhw, flyme, recovery,
wpa_supplicant, configs, rootdir, sepolicy, overlay). The `meizu_m6` variant is
build-complete (the working device); `m681`/`l681` carry the 3.18-graft deltas;
`m6t`/`m5`/`m5note` are thin stubs.

### Known follow-ups (incremental, non-blocking)
- The common still carries some **M6-biased defaults** (mt6750 platform,
  partition sizes, board id, `ro.sf.hwrotation=180`, `ro.hardware.audio.primary=mt6750`)
  inherited from the old tree. `meizu_m6` uses them as-is; `m681`/`l681` override
  the platform to mt6755 — their board id / partitions / 3.18 defconfig are still
  `TODO`. Long-term: push the M6-isms down into `configs/meizu_m6.mk`.
- **`ro.forge.*` / `sys.forge.*` props + init.rc forge markers** are the functional
  runtime-detect + bring-up instrumentation (the m681 decode scripts read these),
  so they are kept. Rename `forge`→`remeizu` as a separate behaviour-preserving
  pass when ready — it is not a blind sed (detect.sh + json + configs + init must
  move together).

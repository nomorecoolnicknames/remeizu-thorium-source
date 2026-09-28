# ReMeizu unified MT6755-family device tree — strategic plan

> **Continuation / 2026-09-28:** [current family and board roadmap](planning/README.md)
> retains this plan and the September implementation, includes M3s/U10/U20 and
> the wider ReMeizu catalog, and adds separate Android 9/11/13 and mainline gates.
> [Stock identity review](docs/STOCK_IDENTITY_REVIEW_20260928.md) qualifies PMIC,
> copied board defaults and old build-success claims. Historical observations
> below keep their original date; they are not a current support matrix.

Date: 2026-07-12. Author: unified-tree-plan lane (Claude), read-only research pass.
Evidence base: `/srv/forge/android/meizu_m6/rom-lineage-15.1-meizu_m6-experimental`
(ROM tree, git head `5c5b66d`), `/home/n8n/remeizu-thorium` (this skeleton),
`/home/n8n/remeizu/site/ReMeizu.dc.html` (site), device/meizu/m681/
`DISPLAY_SHIM_CASCADE.md` + `RUNTIME_BLOCKERS_AUDIT.md` (m681 live-proven fix set),
web (GSMArena/PhoneDB/meizuosc).

Goal: one `mt6755-common` for the whole Meizu Helio-P10 family, thin per-device
overlays, the hard-won m681 bring-up promoted from device-private fixes into
shared defaults — so each next device starts where m681 finished, not where it
started.

---

## 1. Device matrix

| Device | codename | model | SoC | evidence | group | today |
|---|---|---|---|---|---|---|
| Meizu M6 | `meizu_m6` | M711 | MT6750 | FACT: working LOS 15.1 tree, boots | mt6755-family | ROM tree, boots (site: `alpha`) |
| Meizu M3 Note (CN) | `m681` | M681H/Q/C | MT6755 | FACT: meizuosc/m681 + live device | mt6755-family | **the base**: bootanimation visible, system_server up (site: `alpha`) |
| Meizu M3 Note (Global) | `l681` | L681H | MT6755 | FACT: firmwarefile/GSMArena L681H = M3 Note intl | mt6755-family | thorium stub; 3.10 comparator baseline in mt675x README |
| Meizu M5 Note | `m1621` (thorium stub says `m5note`) | M621H/M1621 | **MT6755 Helio P10 — CONFIRMED** | FACT (web): GSMArena/devicespecifications — Helio P10 MT6755, 8×A53, Mali-T860MP2, 5.5" 1080p | mt6755-family | **untouched** (no dir in ROM tree; thorium stub only; site: `planned`) |
| Meizu M6T | `m6t` | M811 | MT6750 | INFERENCE (spec sites; confirm from stock dump before bring-up) | mt6755-family | thorium stub (site: `not_planned`) |
| Meizu M5 | `m5` | M611 | MT6750 | FACT (web): community TWRP "Meizu M5 TWRP Port MT6750" | mt6755-family | thorium stub (site: `not_planned`) |
| Meizu M3s | `m3s` | Y685 | MT6750 | FACT (web): GSMArena M3s = MT6750, 5.0" | mt6755-family (late wave) | none (site: `not_planned`) |
| Meizu M2 Note | `m2note` | M571 | MT6753 | FACT: ROM tree BoardConfig `TARGET_BOARD_PLATFORM := mt6753` | **mt6753 lane — separate** | rich 14.1-era tree in ROM |
| Meizu M5s | `m5s` | M612 | MT6753 | INFERENCE (spec sites) | mt6753 lane | none (site: `not_planned`) |
| Meizu M5c | `m5c` | M710 | MT6737M | INFERENCE (spec sites + community twrp_meizu_m5c) | mt6737/mt6735 lane | site: `bringup` (outside this plan) |
| Meizu M1 Note | `m1note` | M463 | MT6752 | FACT (thorium README) | standalone, out of scope | none |
| Meizu M6 Note | `m1721` | M721H | **Snapdragon 625 MSM8953** | FACT (m1721 SFOS/pmOS projects) | **Qualcomm lane — NOT MT6755** | separate plans (SFOS hybris-18.1) |

Naming corrections this matrix locks in:

- **`l681` = M3 Note Global (L681H), NOT "M3s".** Older working notes called the
  l681 unit "M3s"; the real M3s is Y685 (MT6750, 5.0", different board). FACT via
  GSMArena/firmwarefile. Downstream docs should say "M3 Note Global".
- **M6 Note is not in this family at all** (Qualcomm). The ReMeizu site keeps it,
  but it is fed by the msm8953 lane, never by mt6755-common.
- **Recommend renaming the thorium `m5note` stub → `m1621`** before any content
  lands: Meizu's own device string for M5 Note is m1621 (INFERENCE from Flyme-era
  naming + community TWRP usage; verify `ro.product.device` from the stock dump).
  m681/l681 already match stock naming; consistency matters for OTA asserts and
  runtime detect.

The unified tree targets the **mt6755-family rows (7 devices)**: meizu_m6, m681,
l681, m1621, m6t, m5, m3s. MT6750 is the same kernel platform (lower-binned
Helio P10) — one common tree, per-device platform overrides, exactly as thorium's
README already models.

## 2. What m681 gave us — the shared-base inventory

All FACT, live-proven on device 91HEBNL163XD (3.18 v259 kernel + LOS 15.1),
documented in `DISPLAY_SHIM_CASCADE.md` / `RUNTIME_BLOCKERS_AUDIT.md`, committed
through ROM `5c5b66d` + vendor/mediatek `59332b5`/`4daae01`.

Classification: **[C] = belongs in mt6755-common (or shared vendor/mediatek), [D] = stays per-device.**

1. **[C] MTK vendor-ABI shim cascade** — `libmtkshim_ui` + `libmtkshim_gui`
   packaging, full `android_atomic_*` family in libcutils, `__xlog_buf_printf`,
   `IDumpTunnel::asInterface` stub, `TARGET_LD_SHIM_LIBS` map
   (libgui/libui/libgui_ext/libui_ext → shims). This fixes the *blob-vintage vs
   LOS 15.1* ABI gap, a property of every Flyme-era MTK Nougat blob set, not of
   m681's panel. Today it sits in `device/meizu/m681/BoardConfig.mk:14` —
   the cascade doc itself says "Better: promote the map into mt6755-common".
2. **[C] Sensors HIDL 32/64 rule** — service and impl must be 64-bit when the
   `sensors.mt6755.so` blob is 64-bit-only; per-device override modules in shared
   dirs must never `stem:`-collide onto shared install paths (the m2note module
   broke m681 — see §5 policy).
3. **[C] HAL wiring set** — audio service moved to `Android.bp` (mk-shadowed-by-bp
   rule), `camera.provider@2.4-impl` in PRODUCT_PACKAGES, vibrator service +
   manifest entry, N-era dep blobs pattern (`libkeymaster1.so`), `/vendor/manifest.xml`
   slot. All are family-generic MTK-8.1 packaging facts.
4. **[C] Prop-loading discipline** — on non-SAR 8.1, `/system/etc/prop.default`
   is never loaded; `ro.` props are first-wins from the **ramdisk `default.prop`**.
   Any early-read prop (gl_preload, pm.dexopt, hwrotation) must be duplicated
   into a loaded file. This is a packaging law for the whole family.
5. **[C] Kernel platform work (3.18 m6-graft lane)** — MT6755 pwrap + **MT6351
   PMIC** map (every public tree wrongly ships MT6353 — m681 proved MT6351 from
   stock preloader/LK/kernel), clkbuf/DEW remap, SMP via BROM boot-addr + MTCMOS
   (no PSCI), GICv2 handling, SPM_SW_RSV breadcrumb + 36-marker debug methodology,
   ram_console/pstore capture discipline. One kernel tree, per-device defconfig +
   DTB + LCM (thorium `kernel/meizu/mt6755` scaffold).
6. **[C] Diagnosis tooling** — forge-bootdiag, runtime-detect
   (`sys.forge.meizu.*`), flash-capture-clean recipes, marker decoders,
   machine-readable `meizu_mt675x_devices.json`.
7. **[D] stays per-device** — LCM/panel driver + DTS/DTB, touch, fingerprint blob
   set, camera sensor drivers + camera blobs, NVRAM/modem/regional, partition
   sizes/scatter, keylayouts, overlays (density/dimens), leaf init rc + sepolicy,
   `vendor/meizu/<codename>` blob trees (TheMuppets-style), battery/charger IC
   specifics.

## 3. M5 Note (m1621) ease assessment — "how easy is easy"

**SoC confirmed: MT6755 Helio P10, same silicon as m681 (FACT, web).** The user's
"completely untouched" is also FACT — no m1621/m5note content exists anywhere in
the ROM tree, and thorium has only a 15-line stub BoardConfig.

What m1621 inherits **for free** once §2's [C] items are promoted:

- The kernel: the *same* `kernel/meizu/mt6755` tree that already boots m681 to
  userspace — pwrap/MT6351 (INFERENCE: MT6755 pairs with MT6351; verify from the
  m1621 stock preloader exactly as done for m681), SMP, GIC, SPM markers, all
  debug infra. New work = `m1621_defconfig` + DTB + LCM + touch entries only.
- The entire display shim cascade (5 sub-walls that took the longest on m681) —
  m1621's Flyme blobs are the same Nougat MTK vintage, so `hwcomposer.mt6755.so`
  will hit the identical `libmtkshim_ui`/`android_atomic_*`/`IDumpTunnel` gaps,
  which will already be solved in common. (INFERENCE, high confidence; falsify
  with `nm -D` on the m1621 hwcomposer blob at dump time.)
- Sensors/audio/camera/vibrator/fingerprint HAL wiring patterns and the 32/64 rule.
- Prop discipline, rotation methodology (check `ro.sf.hwrotation` against glass
  once bootanim renders — 5-minute check now, not a multi-session wall).
- Build-station recipes, capture/marker tooling, mtkclient unlock flow (site
  guide already covers MT6755 devices).

What is **genuinely new** for m1621:

1. **Stock Flyme dump** → `vendor/meizu/m1621` blobs, DTB, scatter/partition
   sizes, LK. Public Flyme firmware exists; mechanical work (~1–2 days).
2. **LCM/panel driver — the one real risk.** FACT: meizuosc published `m681` but
   **no m1621 kernel source** (not in the meizuosc repo list). The panel init
   sequence must come from: (a) MTK LCM catalog match (many Meizu FHD panels are
   catalog parts — ili9885 on m681, ili9881p on M6), (b) extraction from the
   stock kernel binary/LK (m681-precedent method), or (c) the vetted public
   MT6755 trees' LCM pools (Vgdn1942 etc.). HYPOTHESIS: catalog or Vgdn pool hit
   → days; binary extraction → up to 1–2 weeks.
3. Touch (likely FT/GT catalog part — HYPOTHESIS until dump), camera sensor
   kernel drivers (13 MP module TBD), fingerprint blobs (front mTouch, likely the
   same goodix family as m681 — INFERENCE).
4. DTS, keylayout, overlays, charger profile (4000 mAh; IC from dump).

**Verdict: "very easy" is conditionally TRUE.** Of the nine walls m681 burned
weeks on (kernel boot, PMIC/pwrap, SMP, 5× shim cascade, sensors HIDL, audio
build, camera impl, prop loading, rotation), *all* transfer via common. The
m1621-specific surface is blobs + LCM + touch + DTS. Estimate: **1–2 weeks to
adb + visible bootanimation** if the LCM resolves from a catalog/pool, plus the
usual runtime-blocker tail; add ~1 week if panel init needs binary extraction.
Prerequisites to confirm before scheduling: (a) an M5 Note in hand, (b) physical
host access for flashing (this VM has no USB), (c) stock Flyme image downloaded.
Staging lives under `/home/n8n` (not /srv/forge — full).

## 4. Unified structure — target layout and disposition of the four commons

Current state (FACT): two parallel worlds.

- ROM tree include chains **diverge**: `m681 → mt6755-common → meizu_mt675x-common`
  but `meizu_m6 → m3_meizu_m6-common → meizu_mt675x-common`. The two boots-capable
  devices share only the bottom layer; the m681 fix set is device-private.
- thorium `mt6755-common` (~250 files) already merged + de-m3-named the old
  commons, with thin stubs for all seven devices and a kernel scaffold — but it
  is a **skeleton outside the building tree** (and until today not even a git repo).
- `mt6753-common` exists in the ROM tree but `m2note/BoardConfig.mk` does not
  include it (INFERENCE from grep — verify before touching that lane).

Target layout (thorium's shape, living in the ROM tree):

```
device/meizu/
  mt6755-common/           # THE common: BoardConfigCommon (arch, platform,
                           #   TARGET_LD_SHIM_LIBS map, sepolicy, kernel-source
                           #   pointer), device-common.mk (shim + HAL
                           #   PRODUCT_PACKAGES, prop discipline, rootdir,
                           #   runtime detect, overlays), configs/devices.json
  m681/  l681/  m1621/  meizu_m6/  m6t/  m5/  m3s/    # thin: BoardConfig
                           #   (partitions, defconfig, OTA assert), device.mk
                           #   (vendor inherit, leaf rc, overlays), sepolicy leaf,
                           #   keylayout, per-device docs
kernel/meizu/mt6755/       # one 3.18 family kernel (m6-graft lane, boots m681);
                           #   per-device defconfig+DTS; 4.4/4.9 as branches
vendor/meizu/<codename>/   # per-device blobs
vendor/mediatek/           # shared shim/symbols/hidl layer (already exists)
```

Disposition of the four commons:

| tree | verdict | when |
|---|---|---|
| ROM `mt6755-common` | **KEEP — canonical.** Grows by promotion (Phase 1) and absorption (Phase 2). | now |
| ROM `m3_meizu_m6-common` | **RETIRE** (m3-named, only meizu_m6 uses it): fold content into mt6755-common, leave a tombstone README. Per the no-premature-deletion rule the dir is not deleted until explicit approval. | Phase 2 |
| ROM `meizu_mt675x-common` | **KEEP short-term** (runtime detect + devices.json live here and work). **MERGE into mt6755-common** once meizu_m6 is on the unified chain — final state is a single common layer. | Phase 3 |
| ROM `mt6753-common` | **OUT OF SCOPE** — it is the m2note/M5s lane's future common. Untouched by this plan. | — |
| thorium `mt6755-common` | **Reference shape + publishing mirror.** Frozen for development until Phase 7 sync; the ROM tree is ground truth. Prevents the #1 structural risk: dual-home drift. | Phase 7 |

Module-collision policy (law, learned the hard way — the m2note 32-bit sensors
module with `stem:` + inverted `ifneq` guard silently broke m681 boot, FACT
`3450cc0`/`db14b8b`): in shared dirs (`vendor/mediatek`, commons), per-device
override modules MUST carry codename-suffixed module names, positive
`ifeq ($(TARGET_DEVICE),X)` guards only, and never install over a shared path.
Device selection happens in the thin `device.mk` via PRODUCT_PACKAGES —
last-writer-wins install races are forbidden.

## 5. Migration path — no m681 regression

Each phase has a **gate**; the next phase does not start until the gate passes.
m681 currently reaches visible bootanimation + running system_server (sensors
fix built, awaiting flash) — that state is the regression baseline.

- **Phase 0 — snapshot (done).** ROM tree committed through `5c5b66d`; this plan
  committed; record md5 of the last-good m681 boot.img/system.img next to the
  build job (build-station hash policy).
- **Phase 1 — promote m681's [C] set into ROM `mt6755-common`.**
  Move `TARGET_LD_SHIM_LIBS` + shim/HAL PRODUCT_PACKAGES + prop-discipline
  templates from `m681/` into the common; m681 keeps only overrides. Behavior-
  neutral by construction. **Gate:** rebuild `lineage_m681`, diff target-files
  vs the pre-promotion build — expected delta: none (or provenance-only);
  on-device smoke (when a flash is next approved anyway): bootanim visible,
  system_server up, `init.svc.sensors-hal-1-0=running`.
  Verify commands: the §10 block of `RUNTIME_BLOCKERS_AUDIT.md` unchanged.
- **Phase 2 — de-m3-naming.** Fold `m3_meizu_m6-common` into `mt6755-common`
  (thorium already dedup'd this merge once — reuse its file dispositions);
  `meizu_m6/BoardConfig.mk` switches its include to mt6755-common; push M6-isms
  (mt6750 platform default, partition sizes, `ro.hardware.audio.primary`) down
  into `configs/meizu_m6.mk` per thorium's known-follow-ups list. **Gate:**
  meizu_m6 build parity (image diff modulo timestamps) — it is the second
  proven-boots device and must not move.
- **Phase 3 — kernel + bottom-layer unification.** `TARGET_KERNEL_SOURCE :=
  kernel/meizu/mt6755` for all devices: the 3.18 m6-graft tree (v259, boots
  m681) with `meizu_m6_defconfig` ported back onto it (a homecoming — the graft
  came *from* the M6 3.18.140 tree). Merge `meizu_mt675x-common` (detect +
  devices.json) into mt6755-common. 4.4/4.9 lanes continue as branches of the
  same tree; nothing in the common may force premature 4.4 adoption. **Gate:**
  both kernels build; m681 image is v259-equivalent.
- **Phase 4 — l681 (first replication, near-zero HW risk).** Thin dir cloned
  from m681: same panel (ili9885 FHD — thorium kernel README), deltas are OTA
  assert, modem/NVRAM regional bits, single-dtb note. **Gate:** build completes;
  flash only with per-build user approval (standing rule). This validates that
  the common really carries a second device.
- **Phase 5 — M5 Note `m1621` (first genuinely new device).** Per §3: dump →
  blobs/DTB/scatter → LCM/touch → thin dir. **Gates in order:** kernel boots to
  markers/adb → shim-cascade-for-free confirmed (`nm -D` on its blobs, SF up) →
  panel lights. Site status `planned → bringup` at dir-landing, `→ alpha` at
  visible bootanim.
- **Phase 6 — MT6750 wave (m6t, m5, m3s).** Clones off the meizu_m6 variant
  defaults, as hardware/interest materializes. Lowest priority.
- **Phase 7 — publish.** Sync consolidated commons + thin devices into thorium;
  push as `android_device_meizu_mt6755-common`, `android_kernel_meizu_mt6755`,
  per-device repos (SSH via ssh.github.com:443). Thorium becomes the public
  face; ROM tree remains the build home.

## 6. ReMeizu site alignment

FACT: the site (`ReMeizu.dc.html`) carries a hand-maintained inline JS device
array (`codename`, `s:` status ∈ {alpha, bringup, planned, not_planned}, soc,
per-device notes in EN/RU) plus mtkclient unlock guides.

Plan — the tree feeds the site, not vice versa:

1. **Single source of truth = `mt6755-common/configs/meizu_mt675x_devices.json`**
   (already machine-readable with panel/touch/sensors/camera/charger per device).
   Extend the schema: `status` (site enum), `model`, `soc`, `artifacts[]`
   ({type: los-zip|recovery|boot, url, sha256, date, build_job}), `notes_en/ru`.
2. **Generator step**: a small script renders the site's JS device array from the
   json (site repo consumes the tree file at build/publish time). Hand-editing
   the html array stops.
3. **Status transitions are defined by tree events** (no aspirational statuses):
   device dir lands = `bringup`; adb + visible bootanim = `alpha`;
   boot_completed + daily basics = `beta`; published artifacts = release.
   Today that yields: meizu_m6 `alpha`, m681 `alpha`, everything else in the
   family `planned`/`not_planned`; m1621 flips to `bringup` when Phase 5 starts.
4. **Artifacts + hashes** come from build-station jobs (hash-persistence policy
   in CLAUDE.md §4), so every download link on the site is traceable to a build
   job + git SHA.
5. Non-family devices stay honest on the site: M2 Note/M5s badge "mt6753 lane",
   M5c "mt6737 lane", M6 Note "Qualcomm lane" — fed by their own stories, never
   by mt6755-common.

## 7. Risks / open questions

1. **Dual-home drift** (ROM commons vs thorium) — mitigated by declaring ROM
   tree ground truth and freezing thorium until Phase 7.
2. **m681 regression during promotion** — mitigated by target-files parity
   gates; flashes remain per-build user-approved.
3. **m1621 LCM unknown** (no meizuosc source) — the single biggest unknown in
   the "easy win" story; three fallback paths listed in §3.
4. **M5 Note hardware availability** — unconfirmed; ask before scheduling
   Phase 5.
5. **MT6750 devices' PMIC** may differ from MT6351 (M6's json lists mt6311
   add-on) — verify per-device at bring-up, m681-preloader-method.
6. **sepolicy**: family common stays permissive-first; the enforcing gate
   (unlabeled /system, audit §8) is a separate cross-device wave.
7. **m6t SoC** taken from spec sites only — confirm from a stock dump before its
   thin dir is created.

---

*Plan is read-only research output; no build/device action was taken. The first
implementing steps are Phase 1 (promotion) and the Phase 0 hash record.*

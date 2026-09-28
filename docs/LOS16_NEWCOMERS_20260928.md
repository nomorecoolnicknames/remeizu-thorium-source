# LOS16 newcomers: source checkpoint, 2026-09-28

## PROPER-FIX: M3s full OTA erase prefix

**Hypothesis:** the extractor incorrectly rejects an initial partition-wide
erase followed by disjoint new extents. **FACT:** the pinned M3s archive
`flyme-6.3.0.0G-intl-m3s.zip` contains transfer version 2, then
`erase 2,0,655360`, then 36 `new` extents; the stock boot pin is
`f0b4f31d205a2ce052bb8f0118ee89e5bca322fce5bcf2f638f04e4936205e9a`.
The previous first fatal was `ValueError: overlapping transfer ranges` before
creating output. **Files / why:** `tools/los16_extract_stock.py` now accepts
erase before later writes because a fresh zeroed image implements that erase;
tests still reject overlapping writes and any erase over previously written
data. **Expected next marker:** complete M3s extraction equals the independent
stock file listing. **Rollback:** a data overwrite is silently ignored or the
complete-list/boot identity check disagrees. **Verification:**
`TMPDIR=/dev/shm PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tests -p test_los16_stock_inputs.py -v`.

## Current readiness

**FACT:** base Thorium commit is `84418dc3067694149cfeb35ab0d387aa9ba7b75a`.
This isolated branch changes M3s/U10/U20/M5/M5 Note product input wiring. It does
not change any active buildhome, kernel or stock extract. M3 still has no device
tree and remains a stock-identity prerequisite. No newcomer is declared build-
or runtime-ready by this checkpoint.

**FACT:** the old LOS16 buildhome `/srv/forge/android/los16-ct07` has these common
pins: `mt6755-common b94e0862b18b04f829784226fa187d2f38d2debd`,
`meizu_mt675x-common c4e09d20fe64a42b0c4760d0e39bf7f6f0f685ab`,
`m3_meizu_m6-common fe0347645132fd21dfc6c0dbd6010fb8e2dd2a8d`.
Its five newcomer directories are unversioned copies, their vendor directories
are absent, and `kernel/meizu/mt6755` is absent. These old commons are not
interchangeable with this unified Thorium checkout.

## PROPER-FIX: required per-board vendor and stock image bounds

**Hypothesis:** optional vendor inheritance previously allowed a newcomer graph
to omit its entire vendor. The generic board layer also cannot own per-board
partition sizes. A cloud graph must fail at the missing board input instead of
being accepted using `ALLOW_MISSING_DEPENDENCIES=true` or an M6 vendor fallback.

**Evidence:** the five `device.mk` files used `inherit-product-if-exists` and all
five BoardConfig files used `-include` before common. Actual Flyme ZIP contents
contain `scatter.txt` and `boot.img`; the latter is byte-compared to the existing
unpacked boot before deriving geometry. Full hashes and individual curated blob
hashes are in `planning/los16-stock/{m3s,u10,u20}.json`.

| Board | Boot | Recovery | System | Cache |
|---|---:|---:|---:|---:|
| M3s/Y15 | 16 MiB | 21 MiB | 2560 MiB | 432 MiB |
| U10/Z170 | 16 MiB | 30 MiB | 2560 MiB | 432 MiB |
| U20/Huaqin 1MA | 16 MiB | 16 MiB | 2560 MiB | 432 MiB |

**FACT:** these are bounds inferred from adjacent named stock scatter starts,
not a live GPT measurement. The end of userdata is not in this format:
`flashinfo`/`sgpt` values are sentinels, never userdata sizes. Boot header physical
addresses are recorded exactly with base zero and explicit offsets; actual
LOS16 `system/core/mkbootimg/mkbootimg` computes each address as base + offset.
The stock boot command line is retained as metadata; the common Android command
line and release binder policy remain unchanged.

**Files / why:** five BoardConfig/device pairs now require their own vendor and
apply BoardConfigVendor after common. Three new BoardConfigStock files provide
only observed address/image bounds. `tools/los16_stock_inputs.py` reproduces
pins/bounds and inventories curated ELF NEEDED names. `tools/los16_extract_stock.py`
reconstructs an existing full OTA into a new private output without reusing stale
files; rejects incremental, overlapping and truncated data. Tests cover input
rejection, exact geometry, and vendor ownership. No stock bytes are added to git.

**Expected next marker:** a strict cloud lunch/graph either reports the exact
missing per-board vendor input or advances after that input is supplied. An
eventual target-files archive must retain these per-board image bounds.
**Rollback condition:** archive/stock identity mismatch, unexpected boot address
change, wrong adjacent partition pair, or a product resolving another board's
vendor. Runtime GPT disagreement requires reviewing the matching stock variant.

## Remaining concrete source blockers

**FACT:** curated extracts have M3s 152 files / 54 ELF; U10 171 files / 56 ELF +
4 HAL symlinks; U20 157 files / 56 ELF + 4 symlinks. Respectively 173/171/173
architecture-specific dependency names are absent from those extracts; all are
present in the historical full-system listing. Many names are AOSP libraries:
this count is not a prescription to ship all of them as proprietary prebuilts.

**FACT:** the existing M3s/U10 defconfigs still select the M6 project, and U20
selects m681's `wt6755_66_sz_l`. These donor kernel compile results remain
separate from Y15/U10/1MA board port completion. Common init currently contains
M6/m681/l681 runtime dispatch only; own-board fstab/init/HAL mapping is also
required. M5/M5 Note have neither pinned stock geometry nor vendor here.

**PLAN:** U20 and U10 are the next source candidates because they have stock
3.18 baselines and complete official OTA archives. First audit full stock native
dependencies against actual LOS16 providers, then produce board-specific vendor
modules/configuration and finish kernel projects. M3s adds the 3.10-to-3.18 gap.
Never copy M6 blobs or use missing-dependency suppression to turn these into a
successful build status.

## Verification

```sh
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tests -p test_los16_stock_inputs.py -v
PYTHONDONTWRITEBYTECODE=1 python3 tools/los16_stock_inputs.py u20 \
  --stock-root /srv/forge/android/flyme_fw
PYTHONDONTWRITEBYTECODE=1 python3 tools/los16_extract_stock.py \
  --archive /srv/forge/android/flyme_fw/u20/flyme-6.3.0.0G-intl-u20.zip \
  --output /dev/shm/remeizu-los16-stock-20260928/u20 \
  --stock-report planning/los16-stock/u20.json \
  --expected-files /srv/forge/android/flyme_fw/u20/unpacked/system-files.txt
```

The extraction command refuses an existing output; use its existing inventory
for repeated analysis. **FACT:** 12 regression tests passed; real stock metadata
audits passed for all three boards. Compilation and device execution have not
been performed by this source track.

## DIAGNOSTIC: complete stock extraction and LOS16 native provider map

**FACT:** both complete `/system` roots have now been recovered into private tmpfs,
outside git: `/dev/shm/remeizu-los16-stock-20260928/{u10,u20}/system`. Images, extraction
logs and hashed inventories remain beside them. U20 contains 2342 regular files
plus 160 symlinks; U10 contains 2678 regular files plus 167 symlinks. Each set of
regular paths exactly matches the independently preserved `system-files.txt`
(zero missing / zero extra). The extractor now requires that complete-list check.
Boot payload hashes are tied to the existing pinned official OTA before extraction.

**FACT:** `tools/los16_vendor_map.py` starts with the native curated HAL files,
hash-checks every expanded own-stock ELF and recursively resolves its NEEDED
names. It searches actual Android.mk/Android.bp declarations in the local LOS16
platform roots and pins every matching definition file by SHA256. It does not
include another phone's vendor or copy stock libc/framework libraries over AOSP.

| Board | Own-stock ELF nodes in audit | Source candidates, architecture-qualified names | Own-stock candidates, architecture-qualified names | Unresolved names |
|---|---:|---:|---:|---:|
| U20 | 252 | 91 | 198 | 0 |
| U10 | 240 | 91 | 186 | 0 |

The candidate graphs are `planning/los16-stock/{u10,u20}-vendor-map.json`.
**INFERENCE:** these are useful input sets for a reviewed vendor extraction, not
a complete Android HAL package. A literal module name does not prove its enabled
architecture or ABI; absence of a literal declaration does not prove proprietary
ownership (generated Make module names need separate review). Dynamic dlopen,
service/init configuration, symbol compatibility and SELinux remain separate gates.

**REJECTED:** the September note that a missing 32-bit `libbluetooth_jni` should
arrive from vendor is not accepted as an implementation recipe. In the current
LOS16 source, `packages/apps/Bluetooth/jni/Android.bp` defines this library with
`compile_multilib: "first"`, and Bluetooth/Android.mk requests it as JNI. A fresh
strict graph failure would require tracing that product's app/native arch choice,
not copying the Android 6 JNI library into Android 9.

**Patch summary:** the second checkpoint adds the full-stock provider mapper and
identity/mutation/unresolved-dependency tests, strengthens complete extraction
verification, and records actual maps. Expected next evidence is reviewed
per-architecture vendor modules and a strict cloud product graph. Roll back a
candidate selection if a generated source provider or incompatible ABI disproves
it; no runtime success is asserted. **Verification:** 16 targeted tests pass;
all 492 mapped stock ELF hashes match private full extracts.

```sh
TMPDIR=/dev/shm PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tests -p 'test_los16_*.py' -v
PYTHONDONTWRITEBYTECODE=1 python3 tools/los16_vendor_map.py \
  --stock-report planning/los16-stock/u20.json \
  --private-extract /dev/shm/remeizu-los16-stock-20260928/u20 \
  --platform /srv/forge/android/los16-ct07 \
  --output planning/los16-stock/u20-vendor-map.json
```


## DIAGNOSTIC: M3s own-stock graph and corrected three-board provider selection

**FACT:** M3s now has a separate `lineage_m3s_stockgraph-userdebug` diagnostic
product using its own Linux 3.10.72+ kernel, SDK22 source properties, default
lights HAL and `mtk-msdc.0/by-name` mount paths. Its old ARM64 header is validated
with an exact M3s-only header pin after the complete boot hash check; no modern
U10/U20 kernel header check is weakened. The stock generic ueventd rule is
recorded separately; no U10 `/dev/ion` rule is invented.

**FACT:** full M3s stock extraction equals 2555 independently listed regular
files, plus 94 symlinks. All 1405 native files were rehashed and inventoried:
766 ELF32/EM_ARM and 639 ELF64/EM_AARCH64. The native inventory stays private;
its SHA256 is pinned by `planning/los16-stock/m3s-system-summary.json`.

**PROVIDER CORRECTION:** `libnativehelper/Android.bp:35` is a real LOS16 source
module but its top-level root was absent from the scanner. Current scanning
includes that root. Both preparation and private preflight explicitly prohibit
stock libnativehelper. Corrected graph selections use the source module and
remove its otherwise unneeded libaed/libmrdump closure, for six removed stock
files per board. Earlier 49-file U10/U20 archives and the 53-file M3s draft are
superseded and remain preserved. Historical preflight only verified bytes and
Python execution, not Android compilation, graph completeness or ABI.

| Board | Mapped native nodes | Source candidates | Own-stock candidates | Selected ELF32 / ELF64 | Private revision |
|---|---:|---:|---:|---:|---|
| M3s | 250 | 86 | 198 | 26 / 21 | m3s-vendor-stockgraph-r2 |
| U10 | 238 | 93 | 184 | 24 / 19 | u10-vendor-stockgraph-r2 |
| U20 | 250 | 93 | 196 | 24 / 19 | u20-vendor-stockgraph-r3 |

All three maps have zero unresolved NEEDED names; source ABI and dynamic loading
remain separate gates. Own kernel pins are unchanged. The private preparation
entrypoint is shared: `tools/u20_stockgraph.py --device BOARD`; the cloud runner
is `tools/run_BOARD_stockgraph.sh ANDROID_TOP THORIUM_ROOT userdebug`.

**Files / why:** M3s product/rootdir/BoardConfig adds only its own diagnostic
inputs; common module discovery includes that explicit product; shared helper
handles its exact legacy header, default lights and generic stock ueventd;
provider maps correct the source-root omission; evidence/tests reject wrong
architecture/board, stock JNI replacement and premature success publication.
**Hypothesis:** these checked inputs expose the first real LOS16 graph failure
without donor substitution or hidden missing-dependency suppression.
**Expected next marker:** normal strict `m -j2 nothing` with SDK28/userdebug,
then success-only artifacts in `/workspace/out`. **Rollback:** wrong identity,
ignored input overwrite, platform replacement, incompatible geometry/ABI or
success evidence after a failed graph. No local ROM/kernel compilation or
runtime success is claimed. Detailed M3s commands and evidence are in
`device/meizu/m3s/stockgraph/README.md`.

**Local validation:** 48/48 unit tests pass in tmpfs, including initial-erase
semantics, wrong-board/ELF/header rejection, source JNI-helper classification,
forbidden pinned stock helper and success-only runner artifacts. All three
current private preflights pass; shell syntax and Python 3.8 grammar pass.
Actual Focal/cloud graph execution remains for the owning Forge run.

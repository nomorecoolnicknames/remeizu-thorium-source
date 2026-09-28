# M3s own-stock LOS16 graph input, 2026-09-28

**DIAGNOSTIC:** `lineage_m3s_stockgraph-userdebug` provides the exact M3s/Y15
stock kernel, core mounts and reviewed native inputs for a strict LOS16 cloud
graph. `eng` is also explicit. This is not a completed ROM or a verified boot.
The ordinary `lineage_m3s` still needs its own board kernel/vendor port.

## Own stock identity and architecture

**FACT:** the official `flyme-6.3.0.0G-intl-m3s.zip` boot SHA256 is
`f0b4f31d205a2ce052bb8f0118ee89e5bca322fce5bcf2f638f04e4936205e9a`.
The exact gzip kernel with appended DTB has SHA256
`0cb9f694e7cece64cdca5d429c8205a78e2aa0bc78f95d8a675763254e9efdf6`.
Its Linux banner is **3.10.72+**, built 2018-04-12, with Y15 source paths.
The diagnostic BoardConfig clears donor source/config and chooses this prebuilt.
No kernel is compiled, and no generated `.config` or System.map is claimed.
The source defconfig remains a donor for the ordinary product.

**FACT:** stock build.prop reports SDK **22**, `arm64-v8a,armeabi-v7a,armeabi`,
`ro.board.platform=mt6750`, and density **320**. The legacy kernel begins with
AArch64 branch `0x14000008` (target offset 0x20) and text offset 0x80000;
it lacks the later ARM64 header magic. Preparation accepts its exact pinned
32-byte legacy header only for M3s and keeps modern U10/U20 checks strict.
All boot/ramdisk/kernel hashes are checked before creating a private vendor.

**FACT:** full extraction verified **2555/2555 regular files** against the
independent preserved system listing, plus **94 symlinks**. A complete native
audit rehashed **1405 ELF files**: **766 ELF32/EM_ARM**, **639 ELF64/EM_AARCH64**.
The private inventory also records each NEEDED list. Hashes and counts are in
`planning/los16-stock/m3s-system-summary.json`; the full inventory is private at
`/dev/shm/remeizu-los16-stock-20260928/m3s/native-inventory.json`.

## Core ramdisk and native selection

**FACT:** M3s stock fstab/init use mt6755 filenames but block paths are
`/dev/block/platform/mtk-msdc.0/by-name`, without U10's `/11230000.msdc0`.
The graph retains its exact system/data/cache entries and metadata encryption.
Recovery adds own named boot/recovery entries and omits runtime resize.
Stock geometry remains boot **16 MiB**, recovery **21 MiB**, system **2560 MiB**,
cache **432 MiB**; no live GPT readback or userdata capacity is invented.

The minimal mount action comes from own `init.mt6755.rc:110-113`. Stock has only
`ueventd.rc`, not `ueventd.mt6755.rc`; its `/dev/mali` rule at line 209 is placed
in a board fragment without replacing Android's generic ueventd rules. Stock
has no `/dev/ion` permission entry, so the U10 rule is not copied. Actual Android
9 init/hardware-name selection, permissions and service behavior remain untested.
Other stock actions and services are outside this diagnostic core graph.

**FACT:** the reviewed subset is **47 own-stock ELF files**, **26 ELF32** and
**21 ELF64**. Seeds are both architectures of gralloc.mt6750, hwcomposer.mt6750,
**lights.default** and Mali EGL. The complete curated dependency audit has
250 ELF nodes, 86 architecture-qualified source candidates, 198 own-stock
candidates and zero unresolved NEEDED names. This is a static provider audit,
not proof of binary compatibility or complete HAL integration.

The mapper includes LOS16's top-level `libnativehelper/Android.bp:35`; the
stock JNI helper is prohibited together with other core platform replacements.
Its private-only libaed/libmrdump dependency closure is no longer selected.
Only platform source dependencies reference `libnativehelper`. Old M3s draft
53-file and U10/U20 49-file private inputs are superseded, preserved for history,
and rejected by current evidence/preflight. Source providers still require
symbol/structure ABI review, particularly Android 5.1 graphics and C++ ABI.

**FACT:** kernel strings include binder_ioctl and binder_transaction, but no
IKCONFIG, hwbinder, vndbinder or binder.devices. **OPEN:** Android 9 binder
protocol/transactions/devices, HWC1 adaptation, dynamic loading, SELinux,
audio/camera/radio and runtime. The evidence deliberately records
`stock_binder_abi_verified=false`, `runtime_verified=false`.

## Reproducible preparation and cloud gate

Use absent private output directories; preserved official inputs stay read-only:

```sh
python3 tools/los16_extract_stock.py \
  --archive /srv/forge/android/flyme_fw/m3s/flyme-6.3.0.0G-intl-m3s.zip \
  --output /dev/shm/remeizu-los16-stock-20260928/m3s \
  --stock-report planning/los16-stock/m3s.json \
  --expected-files /srv/forge/android/flyme_fw/m3s/unpacked/system-files.txt
python3 tools/los16_vendor_map.py \
  --stock-report planning/los16-stock/m3s.json \
  --private-extract /dev/shm/remeizu-los16-stock-20260928/m3s \
  --platform /srv/forge/android/los16-ct07 \
  --output planning/los16-stock/m3s-vendor-map.json
python3 tools/u20_stockgraph.py --device m3s \
  --private-stock /dev/shm/remeizu-los16-stock-20260928/m3s \
  --boot /srv/forge/android/flyme_fw/m3s/unpacked/boot.img \
  --output /dev/shm/remeizu-los16-stock-20260928/m3s-vendor-stockgraph-r2
```

Transfer private payload only to an isolated Forge source view:
`device/meizu/m3s`, `device/meizu/mt6755-common`, `vendor/meizu/m3s`; helper tools
and pinned planning evidence only belong under `.remeizu/m3s-tools`.
There must be no Android.mk/Android.bp copy under that helper directory.
Through the Android 9/JDK 8 Forge image, with Python 3.8 and
`OUT_DIR=/workspace/scratch/out`:

```sh
bash /workspace/src/.remeizu/m3s-tools/tools/run_m3s_stockgraph.sh \
  /workspace/src /workspace/src/.remeizu/m3s-tools userdebug
```

The runner exports `FORGE_OFFLINE_SOURCE_SNAPSHOT=1`, verifies the exact private
inputs, checks actual product/variant/SDK 28 and runs **`m -j2 nothing`** with
missing-dependency suppression unset. Only successful graph execution publishes
`/workspace/out/m3s-stockgraph-evidence.json` and `product-config.txt`.
The cloud graph, actual Focal execution and device runtime are pending gates.

## Patch rationale and validation

**Hypothesis:** exact M3s inputs reveal the next real LOS16 graph failure without
substituting U10/M6 kernels, HALs or mount paths. **Evidence:** own official boot,
complete private system/native inventories and board-specific ramdisk hashes.
**Files / why:** board product/config/rootdir hold own inputs; shared preparation
handles its pinned old kernel and default lights; mapper fixes a proven missing
source root; evidence/tests retain identity and failure boundaries.
**Expected next marker:** verified input identity then a strict Forge graph log.
**Rollback:** wrong-board input, platform-library replacement, geometry mismatch,
ignored extraction overwrite, ABI contradiction or success publication on failure.
**Verification:** RAM-based unit tests, real three-board private preflight,
shell syntax, Python 3.8 grammar and archive hashes. No local ROM/kernel build
or runtime success is asserted.

**Local validation:** 48/48 unit tests pass in tmpfs, including initial-erase
semantics, wrong-board/ELF/header rejection, source JNI-helper classification,
forbidden pinned stock helper and success-only runner artifacts. All three
current private preflights pass; shell syntax and Python 3.8 grammar pass.
Actual Focal/cloud graph execution remains for the owning Forge run.

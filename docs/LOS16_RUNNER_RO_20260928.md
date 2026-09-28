# LOS16 runner read-only shell checks, 2026-09-28

**FACT:** M3s/U10/U20 runners were checked inside an isolated bwrap mount/network
namespace. `/workspace/src` was read-only, `OUT_DIR=/workspace/scratch/out`,
and published artifacts used `/workspace/out`. Real LOS16 envsetup,
Lineage envsetup, vendorsetup and patched roomservice ran normally; only the
Soong executable was replaced by a controlled variable/exit fixture. **This is
shell/identity validation, not an Android graph, ROM build or runtime test.**

The four shell/Python inputs match the exact locked platform source bytes from
build/make `1bfc37a3258f1129411e934abc341de9a60e7aaf` and vendor/lineage
`18cce8519e161dea7e3246b7843f295a77c00bcf`. Full hashes and results are in
`planning/los16-stock/runner-ro-harness-report.json` in the isolated source
checkout, mirrored to fleet `cloud-los16/device-work/runner-ro-harness-report.json`.

| Case | Exit | Synthetic backend reached | Published identity artifacts |
|---|---:|---|---:|
| M3s userdebug, SDK28 | 0 | yes | 2 |
| U10 userdebug, SDK28 | 0 | yes | 2 |
| U20 userdebug, SDK28 | 0 | yes | 2 |
| M3s backend exit47 | 47 | yes | 0 |
| M3s SDK27 | 1 | no | 0 |
| M3s unknown product | 42 | no | 0 |

Each successful backend entry checks actual exported product/userdebug variables,
exact scratch OUT_DIR, unset missing-dependency suppression and the offline flag.
Attempting to write `/workspace/src/forbidden-write` returned EROFS. All six cases
made zero curl calls. Original shell control flow, including common output setup
and real `m` wrapping, executed. No runner code change was needed.

## PROPER-FIX: explicit offline vendorsetup

**Hypothesis / FACT:** roomservice's offline guard alone was insufficient:
`build/envsetup.sh` sources `vendor/lineage/vendorsetup.sh` first, and the latter
unconditionally used curl to fetch the remote interactive lunch menu. That is an
unbounded network operation in an explicitly offline source snapshot.

The only changed target file is `vendor/lineage/vendorsetup.sh`, delivered as
`cloud-los16/patches/0003-vendorsetup-offline-snapshot.patch`. It guards only that
remote menu loop when `FORGE_OFFLINE_SOURCE_SNAPSHOT=1`; the four local generic
combos remain. Unset, empty, 0 and true values preserve original behavior.
No platform checkout, cloud view or root index was changed by this source track.

Patch SHA256: `b0a8d16e10ef2221f3f175a782341237a03ee1feee33fe7e958b89226f884362`.
Before: `91e7ac5ff22267b43156a7a988f455a74a7cbd29313a0c2a501c33c03bfe3993`.
After: `326af9e01f62ebd20d30256bb89fb34e49ff47e434b346916239460c6b8498a5`.
The patch's descriptive Base references local HEAD 8c3b4f98; the guarded file
is byte-identical at the locked 18cce851 revision, independently verified.

**Files / why:** the targeted patch stops only offline menu fetching; a pinned
small fixture validates exact before/after bytes and branch behavior; the RO
harness records real shell flow and failure publication boundaries. Blob payloads
and their source checkpoint `e3303bf` do not change; no blob archive re-export is
needed. Root platform-patch provenance records the additional patch separately.
**Expected next marker:** patched source shell performs no menu network request,
then the strict cloud graph reports a real first fatal or succeeds.
**Rollback:** normal mode changes, local combos disappear, or explicit offline
mode still executes curl. Tests must never contact the network.

## Verification

```sh
TMPDIR=/dev/shm PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tests -p test_offline_vendorsetup.py -v
PYTHONDONTWRITEBYTECODE=1 python3 tests/run_stockgraph_ro_harness.py \
  --platform /srv/forge/android/los16-ct07 \
  --private-root /dev/shm/remeizu-los16-stock-20260928 \
  --patch-root /srv/forge/android/meizu-fleet/cloud-los16/patches \
  --output /dev/shm/remeizu-runner-ro-harness-new
```

Use an absent output directory. The harness requires existing bwrap and the
preserved M3s-r2/U10-r2/U20-r3 private inputs; it builds no Android code.
Two offline fixture tests PASS, including exact patch application/shell syntax,
and all six read-only shell cases PASS. The fleet-local small-fixture equivalent
is `cloud-los16/tests/test_vendorsetup_offline.py` and has no large-source-tree
dependency. New cloud first-fatal evidence remains the next implementation gate.

**Checkpoint validation:** all 50 isolated source tests PASS; the standalone
fleet fixture tests also PASS. Current blob archives and runner bytes are
unchanged.

# U20 LOS16 dependency graph

This product validates stock-backed Android 9 dependencies with `m nothing`.
It requires the device/common trees, matching stock extraction, boot image and
pinned inputs in `planning/los16-stock/`; it does not build a custom-kernel ROM.

Prepare a new vendor output with explicit inputs:

```sh
python3 tools/u20_stockgraph.py --device u20 \
  --private-stock "$STOCK_EXTRACT" --boot "$STOCK_BOOT" --output "$VENDOR_OUTPUT"
```

An existing output can be checked with `--output "$VENDOR_OUTPUT" --verify-existing`.
Place the verified output at `vendor/meizu/u20` in the Android source tree.
Use the Android 9 / JDK 8 build container with writable `OUT_DIR` and the offline
roomservice platform patch, then run:

```sh
bash tools/run_u20_stockgraph.sh "$ANDROID_TOP" "$THORIUM_ROOT" userdebug
```

The runner verifies product, variant and SDK 28, rejects missing dependencies,
and exports graph results under `/workspace/out` only after `m nothing` succeeds.

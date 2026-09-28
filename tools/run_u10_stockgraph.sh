#!/usr/bin/env bash
# Run as the command inside an AndroidForge LOS16 ephemeral build container.
set -eo pipefail
if [ "$#" -ne 3 ]; then
    echo "usage: run_u10_stockgraph.sh ANDROID_TOP THORIUM_ROOT userdebug|eng" >&2
    exit 2
fi
u10_android_top=$1
u10_thorium_root=$2
u10_variant=$3
case "$u10_variant" in userdebug|eng) ;; *) echo "variant must be userdebug or eng" >&2; exit 2 ;; esac
: "${OUT_DIR:?Forge must supply a writable output directory}"
test -f "$u10_android_top/build/envsetup.sh"
test -f "$u10_android_top/device/meizu/u10/lineage_u10_stockgraph.mk"
unset ALLOW_MISSING_DEPENDENCIES
export PYTHONDONTWRITEBYTECODE=1
export FORGE_OFFLINE_SOURCE_SNAPSHOT=1
python3 "$u10_thorium_root/tools/u20_stockgraph.py" \
    --device u10 --output "$u10_android_top/vendor/meizu/u10" --verify-existing
cd "$u10_android_top"
source build/envsetup.sh
lunch "lineage_u10_stockgraph-$u10_variant"
u10_actual_product=$(get_build_var TARGET_PRODUCT)
u10_actual_variant=$(get_build_var TARGET_BUILD_VARIANT)
u10_actual_sdk=$(get_build_var PLATFORM_SDK_VERSION)
test "$u10_actual_product" = lineage_u10_stockgraph
test "$u10_actual_variant" = "$u10_variant"
test "$u10_actual_sdk" = 28
# A normal graph gate; do not replace missing modules with stubs or stock AOSP libs.
m -j2 nothing
# Forge publishes /workspace/out, whereas OUT_DIR can point at scratch output.
# These success artifacts are written only after the strict graph exits zero.
mkdir -p /workspace/out
cp "$u10_thorium_root/planning/los16-stock/u10-stockgraph-evidence.json" \
    /workspace/out/u10-stockgraph-evidence.json
printf 'product=%s\nvariant=%s\nsdk=%s\ndiagnostic_only=true\nruntime_verified=false\ngraph_target=nothing\ngraph_exit_code=0\n' \
    "$u10_actual_product" "$u10_actual_variant" "$u10_actual_sdk" \
    > /workspace/out/product-config.txt

#!/usr/bin/env bash
# Run as the command inside an AndroidForge LOS16 ephemeral build container.
set -eo pipefail
if [ "$#" -ne 3 ]; then
    echo "usage: run_u20_stockgraph.sh ANDROID_TOP THORIUM_ROOT userdebug|eng" >&2
    exit 2
fi
u20_android_top=$1
u20_thorium_root=$2
u20_variant=$3
case "$u20_variant" in userdebug|eng) ;; *) echo "variant must be userdebug or eng" >&2; exit 2 ;; esac
: "${OUT_DIR:?Forge must supply a writable output directory}"
test -f "$u20_android_top/build/envsetup.sh"
test -f "$u20_android_top/device/meizu/u20/lineage_u20_stockgraph.mk"
unset ALLOW_MISSING_DEPENDENCIES
export PYTHONDONTWRITEBYTECODE=1
export FORGE_OFFLINE_SOURCE_SNAPSHOT=1
python3 "$u20_thorium_root/tools/u20_stockgraph.py" \
    --output "$u20_android_top/vendor/meizu/u20" --verify-existing
cd "$u20_android_top"
source build/envsetup.sh
lunch "lineage_u20_stockgraph-$u20_variant"
u20_actual_product=$(get_build_var TARGET_PRODUCT)
u20_actual_variant=$(get_build_var TARGET_BUILD_VARIANT)
u20_actual_sdk=$(get_build_var PLATFORM_SDK_VERSION)
test "$u20_actual_product" = lineage_u20_stockgraph
test "$u20_actual_variant" = "$u20_variant"
test "$u20_actual_sdk" = 28
# A normal graph gate; do not replace missing modules with stubs or stock AOSP libs.
m -j2 nothing
# Forge publishes /workspace/out, whereas OUT_DIR can point at scratch output.
# These success artifacts are written only after the strict graph exits zero.
mkdir -p /workspace/out
cp "$u20_thorium_root/planning/los16-stock/u20-stockgraph-evidence.json" \
    /workspace/out/u20-stockgraph-evidence.json
printf 'product=%s\nvariant=%s\nsdk=%s\ndiagnostic_only=true\nruntime_verified=false\ngraph_target=nothing\ngraph_exit_code=0\n' \
    "$u20_actual_product" "$u20_actual_variant" "$u20_actual_sdk" \
    > /workspace/out/product-config.txt

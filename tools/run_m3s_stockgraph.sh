#!/usr/bin/env bash
# Run as the command inside an AndroidForge LOS16 ephemeral build container.
set -eo pipefail
if [ "$#" -ne 3 ]; then
    echo "usage: run_m3s_stockgraph.sh ANDROID_TOP THORIUM_ROOT userdebug|eng" >&2
    exit 2
fi
m3s_android_top=$1
m3s_thorium_root=$2
m3s_variant=$3
case "$m3s_variant" in userdebug|eng) ;; *) echo "variant must be userdebug or eng" >&2; exit 2 ;; esac
: "${OUT_DIR:?Forge must supply a writable output directory}"
test -f "$m3s_android_top/build/envsetup.sh"
test -f "$m3s_android_top/device/meizu/m3s/lineage_m3s_stockgraph.mk"
unset ALLOW_MISSING_DEPENDENCIES
export PYTHONDONTWRITEBYTECODE=1
export FORGE_OFFLINE_SOURCE_SNAPSHOT=1
python3 "$m3s_thorium_root/tools/u20_stockgraph.py" \
    --device m3s --output "$m3s_android_top/vendor/meizu/m3s" --verify-existing
cd "$m3s_android_top"
source build/envsetup.sh
lunch "lineage_m3s_stockgraph-$m3s_variant"
m3s_actual_product=$(get_build_var TARGET_PRODUCT)
m3s_actual_variant=$(get_build_var TARGET_BUILD_VARIANT)
m3s_actual_sdk=$(get_build_var PLATFORM_SDK_VERSION)
test "$m3s_actual_product" = lineage_m3s_stockgraph
test "$m3s_actual_variant" = "$m3s_variant"
test "$m3s_actual_sdk" = 28
# A normal graph gate; do not replace missing modules with stubs or stock AOSP libs.
m -j2 nothing
# Forge publishes /workspace/out, whereas OUT_DIR can point at scratch output.
# These success artifacts are written only after the strict graph exits zero.
mkdir -p /workspace/out
cp "$m3s_thorium_root/planning/los16-stock/m3s-stockgraph-evidence.json" \
    /workspace/out/m3s-stockgraph-evidence.json
printf 'product=%s\nvariant=%s\nsdk=%s\ndiagnostic_only=true\nruntime_verified=false\ngraph_target=nothing\ngraph_exit_code=0\n' \
    "$m3s_actual_product" "$m3s_actual_variant" "$m3s_actual_sdk" \
    > /workspace/out/product-config.txt

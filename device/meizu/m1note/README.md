# Meizu M1 Note (m1note) — NOT part of the mt675x unified tree.
#
# SoC reality: the M1 Note is MT6752 (32-bit, Mali-T760 MP2),
# a STANDALONE platform — it is NOT mt6750/mt6755/mt675x and
# shares neither the clock/power (MTCMOS/CCF/SPM) layout nor
# the 64-bit kernel base of device/meizu/mt6755-common.
# The mt6755-common kernel (3.18, arm64) is UNSUITABLE for it.
#
# That is why there is deliberately NO thin device dir here
# (no BoardConfig.mk / device.mk / lineage_*.mk) and NO defconfig:
# a thin dir would wrongly pull in mt6755-common and pretend
# the device can build on this kernel. It cannot.
#
# A real bring-up needs its OWN kernel first (3.10 stock
# dump or an MT6752 BSP tree), and only then a thin dir plus
# a defconfig cloned from that base — not from this tree.
#
# Status: a unit exists with the owner but was NEVER connected,
# so there is no stock firmware dump, no partition table probe,
# and no panel/touch/sensor IDs yet. Nothing to verify against.
# This README is a placeholder until that kernel appears.

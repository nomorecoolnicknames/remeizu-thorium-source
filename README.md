# ReMeizu MediaTek common device trees

Android 9 common configuration and thin device trees for Meizu MT6750/MT6755 boards,
including M6, M6T, M5, M3 Note M681/L681, M5 Note, M3s, U10 and U20.

`device/meizu/mt6755-common` contains shared build, init, policy and compatibility
code. Each device directory supplies its own board geometry, product and kernel
configuration. Shared SoC code does not make board firmware interchangeable.

Use with the matching LineageOS 16.0 platform, kernel trees and per-device vendor
inputs. M3s/U10/U20 stockgraph products validate dependency graphs only; they do
not produce a certified custom-kernel device port. `tools/` contains stock-input
validation and graph helpers; supply their explicit paths and retain checksum checks.

Kernel prebuilts, proprietary firmware and ROM downloads are supplied separately.
The common tree still requires per-board integration and hardware testing.
Individual files retain their existing copyright and license notices.

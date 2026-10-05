/*
 * libinit_m3note -- revision profile of the common M3 Note Android 9 ROM.
 *
 * One system/vendor image runs on two boards: m681 (Wingtech wt6755_66_sz_l)
 * and l681 (Huaqin hq6755_66_b1a_l).  The kernel tells them apart by the board
 * DTB it boots with; its root "compatible" carries "meizu,m681" or
 * "meizu,l681" (FACT: arch/arm64/boot/dts/mediatek/{wt6755_66_sz_l,
 * hq6755_66_b1a_l}.dts of the 4.4 line).  vendor_load_properties() runs from
 * load_system_props ("on post-fs", after mount_all, before any class starts)
 * and publishes:
 *
 *   ro.vendor.meizu.profile  m681 | l681 | unknown
 *       m3note-profile.rc (vendor/meizu/m3note) bind-mounts the L681H modem,
 *       WMT patches and msensord over the m681 files on l681;
 *       m3note-sensors.rc starts msensord on l681.
 *   ro.hardware.sensors      l681 on l681 -> sensors.l681.so (L681H hwmsen HAL)
 *   ro.hardware.keystore     m681tee on m681 -> keystore.m681tee.so (Trustonic)
 *   ro.sf.hwrotation         m681 0, l681 180 (the values each revision was
 *                            verified with on Android 9)
 *
 * Second, independent source: the panel name LK writes into the kernel
 * command line (lcm=), mapped to a board by /vendor/etc/m3note-panels.tsv --
 * the same list the OTA installer reads (install/m3note-panels.tsv in this
 * tree has the FACT sources).  LK reads the panel itself, so this holds
 * whatever DTB was flashed.  Optional third: androidboot.meizu.board=
 * (ro.boot.meizu.board).  Every source that answers must agree; one answer
 * is enough.  No answer or a disagreement gives "unknown": no l681 file is
 * mounted, no TEE keystore is selected, sensors stay on the default HAL.
 * The reason is logged to the kernel log ("m3note-profile:").
 */

#include <string>
#include <utility>
#include <vector>

#include <android-base/file.h>
#include <android-base/logging.h>
#include <android-base/properties.h>

#include "property_service.h"
#include "vendor_init.h"

using android::base::GetProperty;
using android::base::ReadFileToString;
using android::init::property_set;

namespace {

// Board from the root "compatible" list (NUL-separated strings).  Both
// tokens present, or neither, gives "".
std::string BoardFromCompatible(const std::string& compatible) {
    std::string board;
    size_t start = 0;
    while (start < compatible.size()) {
        size_t end = compatible.find('\0', start);
        if (end == std::string::npos) end = compatible.size();
        const std::string token = compatible.substr(start, end - start);
        std::string candidate;
        if (token == "meizu,m681") candidate = "m681";
        if (token == "meizu,l681") candidate = "l681";
        if (!candidate.empty()) {
            if (!board.empty() && board != candidate) return "";
            board = candidate;
        }
        start = end + 1;
    }
    return board;
}

using PanelList = std::vector<std::pair<std::string, std::string>>;

// "<substring>\t<board>" lines; '#' comments and blank lines skipped.
PanelList ReadPanels(const std::string& path) {
    PanelList panels;
    std::string text;
    if (!ReadFileToString(path, &text)) return panels;
    size_t start = 0;
    while (start < text.size()) {
        size_t end = text.find('\n', start);
        if (end == std::string::npos) end = text.size();
        const std::string line = text.substr(start, end - start);
        start = end + 1;
        if (line.empty() || line[0] == '#') continue;
        const size_t tab = line.find('\t');
        if (tab == std::string::npos || tab == 0 || tab + 1 >= line.size()) continue;
        const std::string board = line.substr(tab + 1);
        if (board != "m681" && board != "l681") continue;
        panels.emplace_back(line.substr(0, tab), board);
    }
    return panels;
}

// Board from the lcm= tokens of the kernel command line.  On l681 the
// header's own lcm= may be cut at 99 bytes and LK appends a full one, so every
// lcm= token is looked at; tokens naming panels of both boards give "".
std::string BoardFromCmdline(const std::string& cmdline, const PanelList& panels) {
    std::string board;
    size_t pos = 0;
    while ((pos = cmdline.find("lcm=", pos)) != std::string::npos) {
        if (pos > 0 && cmdline[pos - 1] != ' ') { pos += 4; continue; }
        const size_t end = cmdline.find_first_of(" \n", pos);
        const std::string token = cmdline.substr(pos, end == std::string::npos ? std::string::npos : end - pos);
        for (const auto& [panel, candidate] : panels) {
            if (token.find(panel) == std::string::npos) continue;
            if (!board.empty() && board != candidate) return "";
            board = candidate;
        }
        pos += 4;
    }
    return board;
}

// Merges one more answer into *board; false on disagreement.
bool Agree(std::string* board, const std::string& answer, const char* source) {
    if (answer.empty()) return true;
    if (!board->empty() && *board != answer) {
        LOG(ERROR) << "m3note-profile: " << source << " says " << answer << ", earlier source said " << *board;
        return false;
    }
    *board = answer;
    return true;
}

std::string DetectBoard() {
    std::string board, compatible, cmdline;
    if (ReadFileToString("/proc/device-tree/compatible", &compatible) ||
        ReadFileToString("/sys/firmware/devicetree/base/compatible", &compatible)) {
        if (!Agree(&board, BoardFromCompatible(compatible), "device tree")) return "";
    }
    const PanelList panels = ReadPanels("/vendor/etc/m3note-panels.tsv");
    if (panels.empty()) LOG(ERROR) << "m3note-profile: no panel list /vendor/etc/m3note-panels.tsv";
    if (ReadFileToString("/proc/cmdline", &cmdline)) {
        if (!Agree(&board, BoardFromCmdline(cmdline, panels), "lcm= on the command line")) return "";
    }
    if (!Agree(&board, GetProperty("ro.boot.meizu.board", ""), "androidboot.meizu.board")) return "";
    if (board.empty()) LOG(ERROR) << "m3note-profile: neither device tree nor lcm= names m681 or l681";
    return board;
}

}  // namespace

void vendor_load_properties() {
    const std::string board = DetectBoard();
    if (board.empty()) {
        property_set("ro.vendor.meizu.profile", "unknown");
        return;
    }
    property_set("ro.vendor.meizu.profile", board);
    if (board == "l681") {
        property_set("ro.hardware.sensors", "l681");
        property_set("ro.sf.hwrotation", "180");
    } else {
        property_set("ro.hardware.keystore", "m681tee");
        property_set("ro.sf.hwrotation", "0");
    }
    LOG(INFO) << "m3note-profile: " << board;
}

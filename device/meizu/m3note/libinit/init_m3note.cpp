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
        for (const auto& entry : panels) {  // C++14: no structured bindings (-Wc++17-extensions is -Werror here)
            const std::string& panel = entry.first;
            const std::string& candidate = entry.second;
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

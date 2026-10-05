#include <cutils/properties.h>
#include <sys/stat.h>
#include <unistd.h>
#include <limits.h>

#include <fstream>
#include <sstream>
#include <string>

namespace {
constexpr const char* kPrefix = "/dev/block/platform/mtk-msdc.0/11230000.msdc0/by-name/";

bool sameBlockDevice(const std::string& left, const std::string& right) {
    struct stat leftStat {}, rightStat {};
    return stat(left.c_str(), &leftStat) == 0 && stat(right.c_str(), &rightStat) == 0 &&
           S_ISBLK(leftStat.st_mode) && S_ISBLK(rightStat.st_mode) &&
           leftStat.st_rdev == rightStat.st_rdev;
}

bool mountedCalibration(const char* partition, const char* mountpoint) {
    std::ifstream mounts("/proc/mounts");
    std::string line;
    while (std::getline(mounts, line)) {
        std::istringstream fields(line);
        std::string source, target, filesystem, flags;
        if (!(fields >> source >> target >> filesystem >> flags)) continue;
        if (target == mountpoint && filesystem == "ext4" &&
            ("," + flags + ",").find(",rw,") != std::string::npos &&
            sameBlockDevice(source, std::string(kPrefix) + partition)) return true;
    }
    return false;
}
}

int main() {
    if (!mountedCalibration("nvdata", "/nvdata") ||
        !mountedCalibration("protect1", "/protect_f") ||
        !mountedCalibration("protect2", "/protect_s")) return 1;
    for (const char* partition : {"nvram", "md1img", "md1dsp"}) {
        struct stat info {};
        const std::string path = std::string(kPrefix) + partition;
        if (stat(path.c_str(), &info) != 0 || !S_ISBLK(info.st_mode)) return 1;
    }
    char target[PATH_MAX];
    const auto length = readlink("/data/nvram", target, sizeof(target));
    if (length < 0 || std::string(target, static_cast<size_t>(length)) != "/nvdata") return 1;
    return property_set("sys.meizu.calibration.mounted", "1") == 0 ? 0 : 1;
}

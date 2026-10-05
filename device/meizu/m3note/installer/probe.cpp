// SPDX-License-Identifier: Apache-2.0
#include <linux/m3note_factory.h>
#include <linux/fs.h>
#include <openssl/evp.h>
#include <zlib.h>
#include <sys/ioctl.h>
#include <sys/stat.h>
#include <sys/sysmacros.h>
#include <fcntl.h>
#include <unistd.h>
#include <cerrno>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <limits>
#include <stdexcept>
#include <string>
#include <vector>

namespace {
const m3note_factory_pair pairs[] = {
#include "factory_pairs.inc"
    {nullptr, nullptr, nullptr, M3NOTE_BOARD_UNKNOWN},
};
struct Fd {
    int n;
    explicit Fd(const char* p): n(open(p, O_RDONLY | O_CLOEXEC | O_NOFOLLOW)) {
        if (n < 0) throw std::runtime_error("open failed");
    }
    ~Fd() { close(n); }
    Fd(const Fd&) = delete;
};
void Require(bool value, const char* reason) {
    if (!value) throw std::runtime_error(reason);
}
uint32_t U32(const uint8_t* p) {
    return uint32_t(p[0]) | uint32_t(p[1]) << 8 | uint32_t(p[2]) << 16 | uint32_t(p[3]) << 24;
}
uint64_t U64(const uint8_t* p) { return U32(p) | uint64_t(U32(p + 4)) << 32; }
std::vector<uint8_t> ReadAt(int fd, uint64_t offset, size_t length) {
    Require(offset <= uint64_t(std::numeric_limits<off_t>::max()) - length, "offset overflow");
    std::vector<uint8_t> data(length);
    size_t done = 0;
    while (done < length) {
        ssize_t got = pread(fd, data.data() + done, length - done, off_t(offset + done));
        if (got < 0 && errno == EINTR) continue;
        Require(got > 0, "short read");
        done += size_t(got);
    }
    return data;
}
std::string ReadText(const char* path, size_t maximum) {
    Fd fd(path);
    std::string result;
    char buffer[1024];
    ssize_t n;
    while ((n = read(fd.n, buffer, sizeof(buffer))) > 0) {
        Require(result.size() + size_t(n) <= maximum, "oversized input");
        result.append(buffer, size_t(n));
    }
    Require(n == 0 && result.find('\0') == std::string::npos, "invalid input");
    return result;
}
[[maybe_unused]] uint64_t Number(const std::string& text) {
    Require(!text.empty(), "missing number");
    uint64_t value = 0;
    size_t i = 0;
    for (; i < text.size() && text[i] >= '0' && text[i] <= '9'; ++i) {
        Require(value <= (UINT64_MAX - uint64_t(text[i] - '0')) / 10, "number overflow");
        value = value * 10 + uint64_t(text[i] - '0');
    }
    Require(i != 0 && (i == text.size() || (i + 1 == text.size() && text[i] == '\n')), "invalid number");
    return value;
}
std::vector<uint8_t> Header(int fd, uint64_t lba, uint64_t other, uint64_t sectors) {
    auto h = ReadAt(fd, lba * 512, 512);
    Require(!memcmp(h.data(), "EFI PART", 8), "GPT signature");
    Require(U32(&h[8]) == 0x10000 && U32(&h[12]) == 92 && U32(&h[20]) == 0, "GPT header format");
    uint32_t crc = U32(&h[16]);
    memset(&h[16], 0, 4);
    Require(crc32(0, h.data(), 92) == crc, "GPT header CRC");
    Require(U64(&h[24]) == lba && U64(&h[32]) == other, "GPT reciprocal headers");
    Require(U64(&h[40]) == 34 && U64(&h[48]) == sectors - 34, "GPT usable range");
    Require(U32(&h[80]) == 128 && U32(&h[84]) == 128, "GPT entry geometry");
    Require(U64(&h[72]) == (lba == 1 ? 2 : sectors - 33), "GPT table location");
    return h;
}
void Partition(const std::vector<uint8_t>& table, unsigned index, const char* name, uint64_t start, uint64_t count) {
    const auto* p = &table.at((index - 1) * 128);
    uint8_t nonzero = 0;
    for (unsigned i = 0; i < 16; ++i) nonzero |= p[i];
    Require(nonzero && U64(p + 32) == start && U64(p + 40) == start + count - 1, "partition range");
    size_t length = strlen(name);
    Require(length < 36, "partition name bound");
    for (unsigned i = 0; i < 36; ++i) {
        uint16_t ch = p[56 + i * 2] | uint16_t(p[57 + i * 2]) << 8;
        Require(ch == (i < length ? uint8_t(name[i]) : 0), "partition name");
    }
}
#ifndef M3NOTE_TEST_HOST
void Node(const char* name, uint64_t start, uint64_t sectors) {
    std::string prefix = std::string("/sys/class/block/") + name + "/";
    Require(Number(ReadText((prefix + "start").c_str(), 64)) == start, "block start");
    Require(Number(ReadText((prefix + "size").c_str(), 64)) == sectors, "block size");
    std::string dev = ReadText((prefix + "dev").c_str(), 64);
    auto colon = dev.find(':');
    Require(colon != std::string::npos, "block device number");
    uint64_t ma = Number(dev.substr(0, colon)), mi = Number(dev.substr(colon + 1));
    Fd fd((std::string("/dev/block/") + name).c_str());
    struct stat st{};
    Require(fstat(fd.n, &st) == 0 && S_ISBLK(st.st_mode) && major(st.st_rdev) == ma && minor(st.st_rdev) == mi, "block node identity");
}
#endif
std::string Inspect(int fd, const std::string& line) {
    auto m = m3note_factory_parse(line.c_str(), pairs, sizeof(pairs) / sizeof(pairs[0]) - 1, M3NOTE_BOARD_M681);
    auto l = m3note_factory_parse(line.c_str(), pairs, sizeof(pairs) / sizeof(pairs[0]) - 1, M3NOTE_BOARD_L681);
    Require((m == M3NOTE_BOARD_M681) != (l == M3NOTE_BOARD_L681), "factory pair not admitted");
    bool is_m = m == M3NOTE_BOARD_M681;
    uint64_t size = 0;
#ifdef M3NOTE_TEST_HOST
    struct stat st{};
    Require(fstat(fd, &st) == 0 && S_ISREG(st.st_mode) && st.st_size >= 0, "fixture disk size");
    size = uint64_t(st.st_size);
#else
    struct stat st{};
    Require(fstat(fd, &st) == 0 && S_ISBLK(st.st_mode) && ioctl(fd, BLKGETSIZE64, &size) == 0, "physical disk size");
#endif
    uint64_t sectors = is_m ? 30535680 : 61071360;
    Require(size == sectors * 512, "unreviewed storage capacity");
    auto first = Header(fd, 1, sectors - 1, sectors);
    auto last = Header(fd, sectors - 1, 1, sectors);
    Require(!memcmp(&first[56], &last[56], 16), "GPT disk GUID mismatch");
    auto entries = ReadAt(fd, 2 * 512, 128 * 128);
    auto backup = ReadAt(fd, (sectors - 33) * 512, 128 * 128);
    Require(entries == backup && crc32(0, entries.data(), entries.size()) == U32(&first[88]) &&
        crc32(0, backup.data(), backup.size()) == U32(&last[88]), "GPT table CRC or mismatch");
    uint64_t previous = 33;
    for (unsigned i = 0; i < 128; ++i) {
        const auto* p = &entries[i * 128];
        uint8_t nonzero = 0;
        for (unsigned j = 0; j < 16; ++j) nonzero |= p[j];
        if (!nonzero) continue;
        uint64_t begin = U64(p + 32), end = U64(p + 40);
        Require(begin > previous && end >= begin && end <= sectors - 34, "GPT overlapping or out of bounds");
        previous = end;
    }
    Partition(entries, 1, "recovery", 64, 32768);
    Partition(entries, 3, "custom", 33856, 1048576);
    Partition(entries, 7, "nvdata", 1105472, 65536);
    Partition(entries, 11, "protect1", 1291840, 16384);
    Partition(entries, 12, "protect2", 1308224, 18880);
    Partition(entries, 22, "boot", 1447936, 32768);
    Partition(entries, 29, "system", 1572864, 5242880);
    Partition(entries, 30, "cache", 6815744, 884736);
    Partition(entries, 31, "userdata", 7700480, sectors - 32801 - 7700480);
    Partition(entries, 32, "flashinfo", sectors - 32801, 32768);
#ifndef M3NOTE_TEST_HOST
    Node("mmcblk0p22", 1447936, 32768);
    Node("mmcblk0p29", 1572864, 5242880);
#endif
    return is_m ? "m681" : "l681";
}
[[maybe_unused]] std::string Hash(int fd, uint64_t offset, uint64_t length) {
    EVP_MD_CTX* context = EVP_MD_CTX_new();
    Require(context != nullptr, "hash allocation");
    bool ok = EVP_DigestInit_ex(context, EVP_sha256(), nullptr) == 1;
    for (uint64_t done = 0; ok && done < length;) {
        auto bytes = ReadAt(fd, offset + done, size_t(std::min<uint64_t>(1024 * 1024, length - done)));
        ok = EVP_DigestUpdate(context, bytes.data(), bytes.size()) == 1;
        done += bytes.size();
    }
    unsigned char digest[EVP_MAX_MD_SIZE]; unsigned n = 0;
    ok = ok && EVP_DigestFinal_ex(context, digest, &n) == 1 && n == 32;
    EVP_MD_CTX_free(context);
    Require(ok, "hash failed");
    char hex[65];
    for (unsigned i = 0; i < 32; ++i) snprintf(hex + i * 2, 3, "%02x", digest[i]);
    return hex;
}
}
int main(int argc, char** argv) {
    try {
#ifdef M3NOTE_TEST_HOST
        Require(argc == 4 && !strcmp(argv[1], "--inspect"), "host test usage");
        auto cmdline = ReadText(argv[2], 65536);
        Fd disk(argv[3]);
        puts(Inspect(disk.n, cmdline).c_str());
#else
        Require((argc == 2 && !strcmp(argv[1], "--inspect")) || (argc == 4 && !strcmp(argv[1], "--hash")), "usage");
        auto cmdline = ReadText("/proc/cmdline", 65536);
        Fd disk("/dev/block/mmcblk0");
        auto board = Inspect(disk.n, cmdline);
        if (argc == 2) { puts(board.c_str()); return 0; }
        uint64_t length = Number(argv[3]), start = 0, cap = 0;
        if (!strcmp(argv[2], "boot")) { start = 1447936; cap = 16777216; }
        if (!strcmp(argv[2], "system")) { start = 1572864; cap = 2684354560ULL; }
        Require(cap && length && length <= cap, "hash range");
        puts(Hash(disk.n, start * 512, length).c_str());
#endif
        return 0;
    } catch (const std::exception& e) {
        fprintf(stderr, "m3note_probe: %s\n", e.what());
        return 2;
    }
}

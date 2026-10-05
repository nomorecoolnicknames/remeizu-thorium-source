/* Copyright 2026 ReMeizu contributors
 * SPDX-License-Identifier: Apache-2.0
 * Read-only telemetry for the own U10/U20 MT6755 kernel interfaces.
 */
#include <ctype.h>
#include <dirent.h>
#include <errno.h>
#include <inttypes.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <hardware/thermal.h>

/* Both selected own configs/DTS describe these eight CPUs. No GPU alias. */
#define CPU_COUNT 8
static const char *const cpu_names[CPU_COUNT] = {
    "cpu0", "cpu1", "cpu2", "cpu3", "cpu4", "cpu5", "cpu6", "cpu7"
};

static int read_text(const char *path, char *text, size_t capacity) {
    FILE *file = fopen(path, "re");
    if (!file) return -errno;
    int result = 0;
    errno = 0;
    if (!fgets(text, capacity, file)) result = -(errno ? errno : EIO);
    else if (!strchr(text, '\n') && !feof(file)) result = -EOVERFLOW;
    if (fclose(file) && !result) result = -errno;
    return result;
}

static int read_integer(const char *path, int64_t *value) {
    char text[64], *end;
    int result = read_text(path, text, sizeof(text));
    if (result) return result;
    errno = 0;
    int64_t parsed = strtoll(text, &end, 10);
    if (errno || end == text) return -(errno ? errno : EINVAL);
    while (isspace((unsigned char)*end)) ++end;
    if (*end) return -EINVAL;
    *value = parsed;
    return 0;
}

static float cpu_temperature(void) {
    DIR *dir = opendir("/sys/class/thermal");
    if (!dir) return UNKNOWN_TEMPERATURE;
    struct dirent *entry;
    char path[128], type[64];
    float value = UNKNOWN_TEMPERATURE;
    unsigned matches = 0;
    while ((entry = readdir(dir))) {
        if (strncmp(entry->d_name, "thermal_zone", 12)) continue;
        const char *number = entry->d_name + 12;
        if (!*number) continue;
        bool valid = true;
        for (const char *p = number; *p; ++p)
            if (!isdigit((unsigned char)*p)) valid = false;
        if (!valid || strlen(number) > 4) continue;
        snprintf(path, sizeof(path), "/sys/class/thermal/%s/type", entry->d_name);
        if (read_text(path, type, sizeof(type))) continue;
        type[strcspn(type, "\r\n")] = '\0';
        if (strcmp(type, "mtktscpu")) continue;
        ++matches;
        snprintf(path, sizeof(path), "/sys/class/thermal/%s/temp", entry->d_name);
        int64_t milli_celsius;
        /* Own driver documents zero as not resumed, and invalid reads fail. */
        if (!read_integer(path, &milli_celsius) && milli_celsius != 0)
            value = (float)milli_celsius / 1000.0f;
    }
    closedir(dir);
    return matches == 1 ? value : UNKNOWN_TEMPERATURE;
}

static float battery_temperature(void) {
    int64_t present, deci_celsius;
    if (read_integer("/sys/class/power_supply/battery/present", &present) || present != 1)
        return UNKNOWN_TEMPERATURE;
    if (read_integer("/sys/class/power_supply/battery/temp", &deci_celsius))
        return UNKNOWN_TEMPERATURE;
    /* Own BAT_PRESENT starts at one while BAT_batt_temp starts at zero.
     * No initialization-generation flag distinguishes that zero from real0C.
     */
    if (deci_celsius == 0) return UNKNOWN_TEMPERATURE;
    return (float)deci_celsius / 10.0f;
}

static ssize_t temperatures(thermal_module_t *module, temperature_t *list, size_t size) {
    (void)module;
    if (!list) return 2;
    const temperature_t snapshot[2] = {
        {DEVICE_TEMPERATURE_CPU, "mtktscpu", cpu_temperature(),
         UNKNOWN_TEMPERATURE, UNKNOWN_TEMPERATURE, UNKNOWN_TEMPERATURE},
        {DEVICE_TEMPERATURE_BATTERY, "battery", battery_temperature(),
         UNKNOWN_TEMPERATURE, UNKNOWN_TEMPERATURE, UNKNOWN_TEMPERATURE}
    };
    for (size_t i = 0; i < size && i < 2; ++i) list[i] = snapshot[i];
    return 2;
}

static int ticks_to_ms(uint64_t ticks, uint64_t hz, uint64_t *value) {
    if (ticks / hz > UINT64_MAX / 1000) return -EOVERFLOW;
    uint64_t whole = (ticks / hz) * 1000;
    uint64_t fraction = ((ticks % hz) * 1000) / hz;
    if (UINT64_MAX - whole < fraction) return -EOVERFLOW;
    *value = whole + fraction;
    return 0;
}

static ssize_t cpu_usages(thermal_module_t *module, cpu_usage_t *list) {
    (void)module;
    char present[64];
    int result = read_text("/sys/devices/system/cpu/present", present, sizeof(present));
    if (result) return result;
    present[strcspn(present, "\r\n")] = '\0';
    if (strcmp(present, "0-7")) return -ENODEV;
    if (!list) return CPU_COUNT;
    long hz = sysconf(_SC_CLK_TCK);
    if (hz <= 0 || hz > 1000000) return -EINVAL;
    FILE *file = fopen("/proc/stat", "re");
    if (!file) return -errno;
    cpu_usage_t snapshot[CPU_COUNT] = {{0}};
    bool seen[CPU_COUNT] = {false};
    char line[512];
    while (fgets(line, sizeof(line), file)) {
        if (strncmp(line, "cpu", 3) || !isdigit((unsigned char)line[3])) continue;
        unsigned cpu;
        uint64_t ticks[8];
        int fields = sscanf(line, "cpu%u %" SCNu64 " %" SCNu64 " %" SCNu64 " %" SCNu64
                            " %" SCNu64 " %" SCNu64 " %" SCNu64 " %" SCNu64,
                            &cpu, &ticks[0], &ticks[1], &ticks[2], &ticks[3],
                            &ticks[4], &ticks[5], &ticks[6], &ticks[7]);
        if (fields != 9 || cpu >= CPU_COUNT || seen[cpu]) { result = -EINVAL; break; }
        uint64_t total = 0;
        for (size_t i = 0; i < 8; ++i) {
            if (UINT64_MAX - total < ticks[i]) { result = -EOVERFLOW; break; }
            total += ticks[i];
        }
        if (result) break;
        /* guest/guest_nice are already included in user/nice; do not add twice. */
        result = ticks_to_ms(total, (uint64_t)hz, &snapshot[cpu].total);
        if (!result) result = ticks_to_ms(total - ticks[3] - ticks[4], (uint64_t)hz,
                                         &snapshot[cpu].active);
        if (result) break;
        seen[cpu] = true;
    }
    if (ferror(file) && !result) result = -(errno ? errno : EIO);
    if (fclose(file) && !result) result = -errno;
    if (result) return result;
    for (unsigned cpu = 0; cpu < CPU_COUNT; ++cpu) {
        char path[80];
        int64_t online;
        snprintf(path, sizeof(path), "/sys/devices/system/cpu/cpu%u/online", cpu);
        result = read_integer(path, &online);
        if (result) return result;
        if (online != 0 && online != 1) return -EINVAL;
        if (online && !seen[cpu]) return -EAGAIN; /* Hotplug raced the snapshot. */
        snapshot[cpu].name = cpu_names[cpu];
        snapshot[cpu].is_online = online == 1;
        /* Offline counters are ignored by the legacy API; not measured zero. */
    }
    memcpy(list, snapshot, sizeof(snapshot));
    return CPU_COUNT;
}

static ssize_t cooling_devices(thermal_module_t *module, cooling_device_t *list, size_t size) {
    (void)module; (void)list; (void)size;
    /* MTK frequency/power coolers are not FAN_RPM; no fan telemetry contract. */
    return -ENOSYS;
}

static struct hw_module_methods_t methods = {.open = NULL};
thermal_module_t HAL_MODULE_INFO_SYM = {
    .common = {
        .tag = HARDWARE_MODULE_TAG,
        .module_api_version = THERMAL_HARDWARE_MODULE_API_VERSION_0_1,
        .hal_api_version = HARDWARE_HAL_API_VERSION,
        .id = THERMAL_HARDWARE_MODULE_ID,
        .name = "Meizu own MT6755 read-only thermal telemetry",
        .author = "ReMeizu",
        .methods = &methods,
    },
    .getTemperatures = temperatures,
    .getCpuUsages = cpu_usages,
    .getCoolingDevices = cooling_devices,
};

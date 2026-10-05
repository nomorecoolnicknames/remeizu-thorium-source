#include <android/log.h>
#include <errno.h>
#include <fcntl.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

int main(void)
{
    const char *path = "/dev/spm";
    struct stat before, after;
    int fd;

    if (lstat(path, &before) != 0 || !S_ISCHR(before.st_mode)) {
        __android_log_print(ANDROID_LOG_ERROR, "meizu-spm-loader",
                            "SPM character device is unavailable");
        return 1;
    }

    /* The board driver's open callback requests its six PCM firmware files. */
    fd = open(path, O_RDONLY | O_CLOEXEC | O_NOFOLLOW);
    if (fd < 0) {
        __android_log_print(ANDROID_LOG_ERROR, "meizu-spm-loader",
                            "Cannot open SPM device: %s", strerror(errno));
        return 1;
    }
    if (fstat(fd, &after) != 0 || !S_ISCHR(after.st_mode) ||
        after.st_dev != before.st_dev || after.st_ino != before.st_ino ||
        after.st_rdev != before.st_rdev) {
        close(fd);
        __android_log_print(ANDROID_LOG_ERROR, "meizu-spm-loader",
                            "SPM device identity changed");
        return 1;
    }
    if (close(fd) != 0) {
        __android_log_print(ANDROID_LOG_ERROR, "meizu-spm-loader",
                            "Cannot close SPM device: %s", strerror(errno));
        return 1;
    }
    /* open() does not report whether all firmware requests succeeded. */
    __android_log_print(ANDROID_LOG_INFO, "meizu-spm-loader",
                        "SPM firmware loading requested; inspect kernel status");
    return 0;
}

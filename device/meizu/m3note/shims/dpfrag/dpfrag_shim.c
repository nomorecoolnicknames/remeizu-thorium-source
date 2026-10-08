#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#include <android/log.h>

struct DpFragStream;
struct DpBasicBufferPool;

#if defined(__LP64__)
#define DPFRAG_BASIC_POOL 32
#define DPFRAG_DST_BUF_ID 68
#define DPFRAG_DST_UV_PITCH 88
#else
#define DPFRAG_BASIC_POOL 16
#define DPFRAG_DST_BUF_ID 48
#define DPFRAG_DST_UV_PITCH 68
#endif

#define FIELD(self, off, type) ((type *) ((char *) (self) + (off)))

/* libdpframework.so of the m681 set */
extern int _ZN12DpFragStream12setDstConfigE13DP_COLOR_ENUMiii(
        struct DpFragStream *self, int format, int width, int height, int pitch);
extern int _ZN12DpFragStream11dequeueFragEPiP13DP_COLOR_ENUMPPvS0_S0_S0_S0_S0_b(
        struct DpFragStream *self, int *bufId, int *format, void **va,
        int *a, int *b, int *c, int *d, int *e, bool waitBuf);
extern int _ZN17DpBasicBufferPool16unregisterBufferEi(
        struct DpBasicBufferPool *pool, int bufId);
extern int _ZN17DpBasicBufferPool16registerBufferFDEiPjiPi(
        struct DpBasicBufferPool *pool, int fd, uint32_t *size, int planes,
        int *bufId);

/* DpFragStream::setDstConfig(DP_COLOR_ENUM, int, int, int, int) */
int _ZN12DpFragStream12setDstConfigE13DP_COLOR_ENUMiiii(
        struct DpFragStream *self, int format, int width, int height,
        int pitch, int uvPitch)
{
    int ret = _ZN12DpFragStream12setDstConfigE13DP_COLOR_ENUMiii(
            self, format, width, height, pitch);
    *FIELD(self, DPFRAG_DST_UV_PITCH, int) = uvPitch;
    return ret;
}

/* DpFragStream::setDstBuffer(int, unsigned*, unsigned) */
int _ZN12DpFragStream12setDstBufferEiPjj(struct DpFragStream *self, int fd,
        uint32_t *size, uint32_t planes)
{
    struct DpBasicBufferPool *pool =
            *FIELD(self, DPFRAG_BASIC_POOL, struct DpBasicBufferPool *);
    int *bufId = FIELD(self, DPFRAG_DST_BUF_ID, int);

    if (planes > 3) {
        __android_log_print(ANDROID_LOG_ERROR, "m3note-dpfrag",
                "setDstBuffer(fd): invalid plane count %u", planes);
        return -1;
    }
    if (*bufId != -1) {
        _ZN17DpBasicBufferPool16unregisterBufferEi(pool, *bufId);
        *bufId = -1;
    }
    return _ZN17DpBasicBufferPool16registerBufferFDEiPjiPi(pool, fd, size,
            (int) planes, bufId);
}

/* DpFragStream::dequeueFrag(int*, DP_COLOR_ENUM*, void**, int*, int*, int*,
 *                           int*, int*, int*, bool) */
int _ZN12DpFragStream11dequeueFragEPiP13DP_COLOR_ENUMPPvS0_S0_S0_S0_S0_S0_b(
        struct DpFragStream *self, int *bufId, int *format, void **va,
        int *ringFd, int *a, int *b, int *c, int *d, int *e, bool waitBuf)
{
    int ret = _ZN12DpFragStream11dequeueFragEPiP13DP_COLOR_ENUMPPvS0_S0_S0_S0_S0_b(
            self, bufId, format, va, a, b, c, d, e, waitBuf);
    if (ret == 0 && ringFd != NULL)
        *ringFd = -1;
    return ret;
}

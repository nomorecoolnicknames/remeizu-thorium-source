#include <stdbool.h>

struct JpgEncHal;

/* JpgEncHal::setEncSize(unsigned, unsigned, EncFormat) -- libJpgEncPipe.so */
extern bool _ZN9JpgEncHal10setEncSizeEjjNS_9EncFormatE(struct JpgEncHal *self,
        unsigned int width, unsigned int height, int fmt);

/* JpgEncHal::setEncSize(unsigned, unsigned, EncFormat, bool) */
bool _ZN9JpgEncHal10setEncSizeEjjNS_9EncFormatEb(struct JpgEncHal *self,
        unsigned int width, unsigned int height, int fmt, bool flag)
{
    (void) flag;
    return _ZN9JpgEncHal10setEncSizeEjjNS_9EncFormatE(self, width, height, fmt);
}

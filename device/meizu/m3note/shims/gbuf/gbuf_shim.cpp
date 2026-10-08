#include <malloc.h>

#include <new>

#include <log/log.h>
#include <ui/GraphicBuffer.h>

using android::GraphicBuffer;

void* m3note_gbuf_from_anwb(GraphicBuffer* self, ANativeWindowBuffer* buffer,
        bool keepOwnership)
        __asm__("_ZN7android13GraphicBufferC1EP19ANativeWindowBufferb");

void* m3note_gbuf_from_anwb(GraphicBuffer* self, ANativeWindowBuffer* buffer,
        bool keepOwnership) {
    size_t room = malloc_usable_size(self);
    LOG_ALWAYS_FATAL_IF(room < sizeof(GraphicBuffer),
            "m3note-gbuf: GraphicBuffer needs %zu bytes, allocation has %zu",
            sizeof(GraphicBuffer), room);
    uint32_t layerCount = buffer->layerCount ? buffer->layerCount : 1;
    new (self) GraphicBuffer(buffer->handle,
            keepOwnership ? GraphicBuffer::TAKE_HANDLE : GraphicBuffer::WRAP_HANDLE,
            buffer->width, buffer->height, buffer->format, layerCount,
            buffer->usage, buffer->stride);
    return self;
}

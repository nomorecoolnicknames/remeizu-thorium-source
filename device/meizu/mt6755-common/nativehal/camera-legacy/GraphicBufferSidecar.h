// SPDX-License-Identifier: Apache-2.0
#pragma once
#include <cstdint>
#include <memory>
#include <mutex>
#include <unordered_map>

namespace android {
// Keep modern transport and BufferHub ownership out of the fixed-size legacy
// GraphicBuffer. Pointer keys live only as long as the actual buffer object.
// Transport fields have the same caller synchronization requirement as the
// original object members; map ownership and detached-handle changes are locked.
template<class Buffer, class DetachedHandle>
class GraphicBufferSidecar {
public:
    struct State {
        uint32_t transportNumFds = 0;
        uint32_t transportNumInts = 0;
        std::unique_ptr<DetachedHandle> detached;
    };

    static State& state(const Buffer* buffer) {
        auto& store = storage();
        std::lock_guard<std::mutex> lock(store.mutex);
        auto& entry = store.buffers[buffer];
        if (!entry) entry.reset(new State());
        return *entry;
    }

    static bool hasDetached(const Buffer* buffer) {
        auto& store = storage();
        std::lock_guard<std::mutex> lock(store.mutex);
        const auto found = store.buffers.find(buffer);
        return found != store.buffers.end() && found->second->detached &&
                found->second->detached->isValid();
    }

    static void setDetached(const Buffer* buffer, std::unique_ptr<DetachedHandle> handle) {
        // Destroy any previous handle after unlocking; channel destruction can
        // reenter buffer code. This also preserves single ownership on replace.
        std::unique_ptr<DetachedHandle> previous;
        {
            auto& store = storage();
            std::lock_guard<std::mutex> lock(store.mutex);
            auto& entry = store.buffers[buffer];
            if (!entry) entry.reset(new State());
            previous = std::move(entry->detached);
            entry->detached = std::move(handle);
        }
    }

    static std::unique_ptr<DetachedHandle> takeDetached(const Buffer* buffer) {
        auto& store = storage();
        std::lock_guard<std::mutex> lock(store.mutex);
        const auto found = store.buffers.find(buffer);
        return found == store.buffers.end() ? nullptr : std::move(found->second->detached);
    }

    static void forget(const Buffer* buffer) {
        std::unique_ptr<State> previous;
        {
            auto& store = storage();
            std::lock_guard<std::mutex> lock(store.mutex);
            const auto found = store.buffers.find(buffer);
            if (found == store.buffers.end()) return;
            previous = std::move(found->second);
            store.buffers.erase(found);
        }
    }

private:
    struct Storage {
        std::mutex mutex;
        std::unordered_map<const Buffer*, std::unique_ptr<State>> buffers;
    };
    static Storage& storage() {
        // Deliberately process-lifetime storage, like the gralloc singletons.
        // Actual buffer/handle state is still released by every buffer destructor.
        static Storage* const store = new Storage();
        return *store;
    }
};
} // namespace android

/*
 * Copyright 2026 ReMeizu contributors
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *     http://www.apache.org/licenses/LICENSE-2.0
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 */
#pragma once
#include <cstdint>
#include <memory>
#include <mutex>
#include <unordered_map>

namespace android {
// Owners serialize direct-channel operations with their existing mLock.
// Only sidecar map ownership uses this separate lock. Binder references must
// be destroyed after releasing it, because destruction can reenter libsensor.
template <typename Owner, typename ConnectionPointer>
class SensorManagerSidecar {
public:
    struct State {
        std::unordered_map<int, ConnectionPointer> directConnections;
        int32_t nextHandle = 1;
    };
    static State& state(const Owner* owner) {
        auto& storage = getStorage();
        std::lock_guard<std::mutex> lock(storage.mutex);
        auto& entry = storage.states[owner];
        if (!entry) entry.reset(new State());
        return *entry;
    }
    static void forget(const Owner* owner) {
        std::unique_ptr<State> released;
        auto& storage = getStorage();
        {
            std::lock_guard<std::mutex> lock(storage.mutex);
            auto i = storage.states.find(owner);
            if (i != storage.states.end()) {
                released = std::move(i->second);
                storage.states.erase(i);
            }
        }
    }
private:
    struct Storage {
        std::mutex mutex;
        std::unordered_map<const Owner*, std::unique_ptr<State>> states;
    };
    static Storage& getStorage() {
        // Like the platform's process-wide SensorManager instance registry,
        // storage outlives object destruction during process teardown.
        static Storage* storage = new Storage();
        return *storage;
    }
};
} // namespace android

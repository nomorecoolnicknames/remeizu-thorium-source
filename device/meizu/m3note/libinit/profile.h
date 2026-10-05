#pragma once

#include <string>

namespace meizu {
std::string BoardFromHandoff(const std::string& handoff);
std::string BoardFromCompatible(const std::string& compatible);
bool ActivateProfile(const std::string& vendor, const std::string& board,
                     std::string* error);
}

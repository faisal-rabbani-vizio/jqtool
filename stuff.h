#pragma once

#include <functional>
#include <string>
#include <string_view>
#include <vector>

std::vector<std::string>
getTokens(std::string_view str, std::string_view delims,
          std::function<bool(std::string_view)> accept);
std::string withinQuotes(const std::string line);
std::string fileToStr(std::string_view file);
void strToFile(std::string_view file, std::string_view string);

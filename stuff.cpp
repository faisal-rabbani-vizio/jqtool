#include "stuff.h"

#include <cstdio>
#include <sstream>

std::vector<std::string>
getTokens(std::string_view str, std::string_view delims,
          std::function<bool(std::string_view)> accept) {
  std::vector<std::string> list;
  auto len = str.size();
  char *tmp = new char[len + 1];
  strcpy(tmp, str.data());
  char *tok = strtok(tmp, delims.data());
  while (tok) {
    if (accept(tok))
      list.emplace_back(tok);
    tok = strtok(nullptr, delims.data());
  }
  delete[] tmp;
  return list;
}

std::string withinQuotes(const std::string line) {
  std::string test = "\"";
  char name[256];
  auto pos = line.find(test);
  auto pos2 = line.find(test, pos + 1);
  int len = line.copy(name, (pos2 - pos - 1), pos + 1);
  name[len] = '\0';
  return name;
}

std::string fileToStr(std::string_view file) {
  char buffer[1024];
  FILE *fp = fopen(file.data(), "r");
  if (!fp)
    return "???";

  std::stringstream ss;
  while (fgets(buffer, sizeof(buffer), fp)) {
    ss << buffer;
  }
  fclose(fp);
  return ss.str();
}

void strToFile(std::string_view file, std::string_view string) {
  int len = strlen(string.data());

  FILE *fp = fopen(file.data(), "w");
  if (!fp) {
    printf("error: couldn't open file '%s' for writing\n", file.data());
  }
  if (fp) {
    if (len && len != fprintf(fp, "%s", string.data())) {
      printf("error: failed to write %d bytes to file '%s'\n", len,
             file.data());
    }
    fclose(fp);
  }
}

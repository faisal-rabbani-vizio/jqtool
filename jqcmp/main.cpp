#include <cstdio>
#include <cstdlib>
#include <cstring>

#include <sstream>
#include <string>

#include "json.hpp"
#include "json_fwd.hpp"

using json = nlohmann::json;

std::string fileToStr(std::string_view file) {
  char buffer[1024];
  FILE *fp = fopen(file.data(), "r");
  if (!fp) {
    printf("failed to open json file '%s'\n", file.data());
    return "???";
  }
  std::stringstream ss;
  while (fgets(buffer, sizeof(buffer), fp)) {
    ss << buffer;
  }
  fclose(fp);
  return ss.str();
}

void compareJson(std::string_view file, std::string_view file2) {
  json j, j2;
  j = json::parse(fileToStr(file).c_str());
  j2 = json::parse(fileToStr(file2).c_str());
  auto str = j.dump();
  auto str2 = j2.dump();
  // printf("*********\n");
  // printf("%s\n", str.c_str());
  // printf("*********\n");
  // printf("%s\n", str2.c_str());
  // printf("*********\n");
  if (0 == strcmp(str.c_str(), str2.c_str())) {
    printf("THEY MATCH!\n");
  } else {
    printf("aww...\n");
  }
}

int main(int argc, char *args[]) {
  printf("hello world...\n");
  if (argc < 3) {
    printf("provide 2 json files to compare you whore!\n");
  } else
    compareJson(args[1], args[2]);
  printf("goodbye!\n");
  return 0;
}

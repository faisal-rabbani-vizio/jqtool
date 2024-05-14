#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <ctime>

#include "shell.h"

#include "json.hpp"
#include "json_fwd.hpp"

extern "C" {
#include "jq.h"
#include "jv.h"
}

Shell shell;

using json = nlohmann::json;

void buildJq() {
  std::map<std::string, bool> jqLibs;
  std::set<std::string> erasures;
  std::set<std::string> incs;

  auto libs = fileToStr("libs.txt");
  auto names = getTokens(libs, " \n", [](std::string_view s) {
    return nullptr != strstr(s.data(), ".jq");
  });
  for (auto name : names)
    jqLibs[name] = false;

  printf("JQ files:\n");
  for (auto [name, added] : jqLibs) {
    printf(" * '%s'\n", name.c_str());
  }

  for (auto [name, added] : jqLibs) {
    std::stringstream ss;
    ss << "grep ";
    ss << "\"include \\\"\" ";
    ss << ("libs/" + name);
    auto res = shell.exec(ss.str().c_str());
    auto tokens = getTokens(res, "\n", [](std::string_view s) {
      return strstr(s.data(), "include");
    });
    for (auto tok : tokens)
      erasures.insert(tok);
  }

  printf("Includes:\n");
  for (auto s : erasures) {
    std::string name = withinQuotes(s) + ".jq";
    printf(" * '%s' -> %s\n", s.c_str(), name.c_str());
    incs.insert(name);
    jqLibs[name] = false;
  }
  printf("JQ Files to Concat:\n");
  for (auto [name, _] : jqLibs) {
    printf("file: %s\n", name.c_str());
  }

  std::stringstream ss;
  for (auto name : incs) {
    if (!jqLibs[name]) {
      std::string fl = ("libs/" + name);
      printf("adding '%s'...\n", fl.c_str());
      ss << fileToStr(fl);
      jqLibs[name] = true;
    }
  }
  for (auto &[name, added] : jqLibs) {
    if (!added) {
      std::string fl = ("libs/" + name);
      printf("adding '%s'...\n", fl.c_str());
      ss << fileToStr(fl);
      added = true;
    }
  }

  std::string j = ss.str();
  auto erase = [&](const std::string &token) {
    while (true) {
      auto pos = j.find(token);
      if (pos == std::string::npos)
        break;
      printf("found %s to erase...\n", token.c_str());
      j[pos] = '#';
      // j.erase(pos, token.length());
    }
  };
  for (auto s : erasures) {
    erase(s);
  }
  strToFile("uber.jq", j);
}

void compareJson() {
  json j, j2;
  j = json::parse(fileToStr("o.json").c_str());
  j2 = json::parse(fileToStr("out/o.txt").c_str());
  auto str = j.dump();
  auto str2 = j.dump();
  if (0 == strcmp(str.c_str(), str2.c_str())) {
    printf("...success?\n");
  } else {
    printf("aww...\n");
  }
}

void runJq() {
  jq_state *jq = NULL;
  jq = jq_init();

  std::string filter = fileToStr("jq.run");
  std::string payload = fileToStr("i.json");

  if (jq == NULL) {
    printf("dafuq...?\n");
    return;
  }
  jq_set_attr(jq, jv_string("JQ_ORIGIN"), jv_string("./"));

  if (!jq_compile(jq, filter.c_str())) {
    printf("unfuck your filter, yo...\n");
    return;
  }
  // Process to jv_parse and then jv_next
  jv input = jv_parse(payload.c_str());
  if (!jv_is_valid(input)) {
    printf("unfuck your json, son...\n");
    jq_teardown(&jq);
    return;
  }

  auto geterr = [](jv msg) {
    if (jv_get_kind(msg) == JV_KIND_STRING)
      return std::string(jv_string_value(msg));
    else {
      msg = jv_dump_string(jv_copy(msg), 0);
      std::string s(jv_string_value(msg));
      jv_free(msg);
      return s;
    }
    return std::string("...");
  };

  jq_start(jq, input, 0);
  jv result = jq_next(jq);
  if (jq_halted(jq)) {
    jv error = jq_get_error_message(jq);
    printf("SHIT!!! %s\n", geterr(error).c_str());
    jv_free(error);
  } else if (!jv_is_valid(result)) {
    jv msg = jv_invalid_get_msg(jv_copy(result));
    printf("WHAT??? %s\n", jv_string_value(msg));
    jv_free(msg);
  } else {
    printf("W00T!!!\n");
    result = jv_dump_string(result, 0);
    strToFile("o.json", jv_string_value(result));
  }

  jv_free(result);
  jq_teardown(&jq);
}

int main(int argc, char *args[]) {
  printf("hello world...\n");

  buildJq();
  auto filter = fileToStr("uber.jq") + fileToStr("filter.jq");
  strToFile("jq.run", filter);
  runJq();
  shell.exec("jq jq.run -f i.json");
  compareJson();
  return 0;
}

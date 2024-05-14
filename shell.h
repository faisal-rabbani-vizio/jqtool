#pragma once

#include <map>
#include <mutex>
#include <optional>
#include <set>
#include <sstream>
#include <string>
#include <sys/_pthread/_pthread_mutex_t.h>
#include <vector>

#include "stuff.h"

class Shell {
  std::mutex mut;
  bool first = true;
  void sleep(long msecs = 250) {
    struct timespec ts;
    int res;

    if (msecs < 0) {
      errno = EINVAL;
      return;
    }
    ts.tv_sec = msecs / 1000;
    ts.tv_nsec = (msecs % 1000) * 1000000;
    do {
      res = nanosleep(&ts, &ts);
    } while (res && errno == EINTR);
  }

public:
  std::string exec(std::string_view command) {
    const std::string ofile = "out/o.txt";
    if (first) {
      strToFile(ofile, "");
      first = false;
    }

    char buffer[256];
    std::stringstream ss;
    // ss << command << " | tee o.txt";
    ss << command << "  &> " << ofile;
    strToFile("out/cmd.txt", ss.str().c_str());
    {
      std::lock_guard<std::mutex> lg(mut);
      printf("executing...\n");
      system(ss.str().c_str());
      printf("done!\n");
    }

    auto maybe_get = [&]() -> std::optional<std::string> {
      std::lock_guard<std::mutex> lg(mut);
      char buffer[1024];
      FILE *fp = fopen(ofile.c_str(), "r");
      if (!fp)
        return std::nullopt;

      std::stringstream ss;
      while (fgets(buffer, sizeof(buffer), fp)) {
        ss << buffer;
      }
      fclose(fp);
      return ss.str();
    };

    std::optional<std::string> s;
    for (int i = 0; i < 10; i++) {
      s = maybe_get();
      if (s.has_value())
        break;
      sleep();
    }

    return s.has_value() ? *s : "???";
  }
};

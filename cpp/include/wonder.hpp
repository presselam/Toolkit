#pragma once

#include <chrono>
#include <string>

using namespace std::chrono;

namespace toolkit {

class Wonder {
 public:
  Wonder(int total, int frequency = 20);
  ~Wonder();

  void reset();
  void tick();

 private:
  void banner();
  std::string timeString(long millis);

  milliseconds _start;
  long _tick;
  long _total;
  int _frequency;
  int _wide;
  bool _header;
};
}

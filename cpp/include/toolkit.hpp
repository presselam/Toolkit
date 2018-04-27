#pragma once

#include <iomanip>
#include <iostream>

namespace toolkit {
enum Code {
  FG_RED = 31,
  FG_GREEN = 32,
  FG_BLUE = 34,
  FG_DEFAULT = 39,
  BG_RED = 41,
  BG_GREEN = 42,
  BG_BLUE = 44,
  BG_DEFAULT = 49
};

class color {
 public:
  color(Code pCode) : code(pCode) {}
  friend std::ostream& operator<<(std::ostream& os, const color& mod) { return os << "\033[" << mod.code << "m"; }

 private:
  Code code;
};

class streamer {
 public:
  streamer(std::ostream& _out) : out(_out) {}

  template <typename T>
  const streamer& operator<<(const T& v) const {
    cout << typeid(v).name() << endl;
    out << "[\033[32m" << v << "\033[0m]";
    return *this;
  }

  streamer const& operator<<(std::ostream& (*f)(std::ostream&)) const {
    out << f;
    return *this;
  }

 protected:
  std::ostream& out;
};

const streamer& quick(std::cout);
}  // namespace toolkit

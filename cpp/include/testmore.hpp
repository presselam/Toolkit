/*
 * Copyright(C) NextGen Federal Systems, LLC - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 *
 * Proprietary and confidential
 */

#include <iomanip>
#include <iostream>
#include <string>

int test_index = 0;

using namespace std;

template <typename T>
bool is(T actual, T expected, std::string label) {
  test_index++;

  if (actual == expected) {
    cout << "ok " << test_index << " - " << label << "\n";
    return true;
  }

  cout << "not ok " << test_index << " - " << label << "\n"
       << "#  Failed Test '" << label << "'\n"
       << "#         got: '" << actual << "'\n"
       << "#    expected: '" << expected << "'\n";
  return false;
}

template <>
bool is<double>(double actual, double expected, std::string label) {
  test_index++;
  // Close enough for doubles
  if (abs(actual - expected) < 0.00001) {
    cout << "ok " << test_index << " - " << label << "\n";
    return true;
  }

  cout << "not ok " << test_index << " - " << label << "\n"
       << "#  Failed Test '" << fixed << label << "'\n"
       << "#         got: '" << actual << "'\n"
       << "#    expected: '" << expected << "'\n";
  return false;
}

template <>
bool is<const char*>(const char* actual, const char* expected, std::string label) {
  test_index++;

  if (strcmp(actual, expected) == 0) {
    cout << "ok " << test_index << " - " << label << "\n";
    return true;
  }

  cout << "not ok " << test_index << " - " << label << "\n"
       << "#  Failed Test '" << label << "'\n"
       << "#         got: '" << actual << "'\n"
       << "#    expected: '" << expected << "'\n";
  return false;
}

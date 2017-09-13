#include "Wonder.h"

#include <iostream>
#include <iomanip>
#include <sstream>

Wonder::Wonder(int total, int frequency){
  _total = total;
  _frequency = frequency;
  reset();
}

Wonder::~Wonder(){}

void Wonder::reset(){
  _header = true;
  _start = duration_cast<milliseconds>(system_clock::now().time_since_epoch());
  _tick = 0;
  _wide = 0;
  int n = _total;
  while( n ){
    _wide++;
    n /= 10;
  }

}

void Wonder::tick(){
  _tick++;
  if( (_tick  % ((_total/_frequency)+1)) == 0 || (_tick == _total) ){
    banner();
  }
}

void Wonder::banner(){
  if( _header ){
    _header = false;
    std::cout
      << std::setw(_wide) << "Done" << "  "
      << std::setw(_wide) << "Total" << "  "
      << std::setw(5) << "%" << "  "
      << std::setw(12) << "Elapsed" << "  "
      << std::setw(8) << "Rate/s" << " "
      << std::setw(12) << "Estimate"
      << std::endl;
  }

  milliseconds now = duration_cast<milliseconds>(system_clock::now().time_since_epoch());
  long delta = (now.count() - _start.count());
  float rate = ((float)_tick / delta);
  long estimate = (long)((_total - _tick) / rate);

  std::cout
    << std::setw(_wide) << _tick << "  "
    << std::setw(_wide) << _total << "  "
    << std::setw(5) << std::fixed <<  std::setprecision(1) << ((float)_tick / _total) * 100 << "  "
    << std::setw(12) << timeString(delta) << "  "
    << std::setw(8) << (rate*1000) << " "
    << std::setw(12) << timeString(estimate)
    << std::endl;
}

std::string Wonder::timeString(long millis){
  int hr = (int)(millis / 3600000);
  millis = millis % 3600000;
  int mn = (int)(millis / 60000);
  millis %= 60000;
  int sc = (int)(millis / 1000);
  millis %= 1000;

  std::ostringstream buffer;
  buffer << std::setw(2) << std::setfill('0') << hr << ':'
    << std::setw(2) << std::setfill('0') << mn << ':'
    << std::setw(2) << std::setfill('0') << sc << '.'
    << std::setw(3) << std::setfill('0') << millis;
  return buffer.str();
}

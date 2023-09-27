#include <iostream>
#include <cstdlib>
#include <string>
#include <filesystem>
#include <unistd.h>
#include <memory>
#include <vector>
#include <sstream>
#include <functional>
#include <algorithm>

using namespace std;


std::string userPlate();
std::string cwdPlate();
std::string gitBranchPlate();
std::string gitStatusPlate();
std::string dockerPlate();
std::vector<std::string> qx(const char* cmd);

struct plate {
  int fg;
  int bg;
  int mask;
  std::function<std::string()> sub;
};


int main(const int argc, const char** argv){
  int mask = 31;

  const char* value = std::getenv("PROMPT_MASK");
  if( value != nullptr ){
    mask = std::atoi(value);
  }

  int upbg = 234;
  value = std::getenv("VIRTUAL_ENV");
  if( value != nullptr ){
    upbg = 100;
  }

  std::vector<plate> plates = {
    { 91,  upbg, 16, userPlate      },
    { 255,  235,  8, cwdPlate       },
    { 255,  237,  4, gitBranchPlate },
    { 255,  239,  2, gitStatusPlate },
    { 255,   53,  1, dockerPlate    }
  };

  int sz = plates.size();
  for( int i=0; i<sz; ++i){
    auto p = plates[i];

    int nfg = 0;
    int nbg = 0;
    if( i+1 < sz ){
      plate next = plates[i+1];
      nfg = next.fg;
      nbg = next.bg;
    }

    std::string data = "";
    if( mask & p.mask ){
      data = p.sub();
    }

    std::cout << "\u001b[48;5;" << p.bg << "m\u001b[38;5;" << p.fg << 'm' << data 
              << "\u001b[48;5;" << nbg << "m\u001b[38;5;" << p.bg << 'm' << "\uE0B0";
  }

  std::cout << "\u001b[0m" << std::endl;
}

std::string userPlate(){
  char* value = std::getenv("VIRTUAL_ENV");
  if( value != nullptr ){
    return std::filesystem::path(value).filename();
  }

  value = std::getenv("WORKPRE");
  if( value != nullptr ){
    return std::string(value);
  }

  return std::getenv("USER");
}

std::string cwdPlate(){
  return std::filesystem::current_path().filename();
}

std::string gitBranchPlate(){
  std::vector<std::string> output = qx("git rev-parse --abbrev-ref HEAD 2>/dev/null");
  if( output.size() == 0 ){
    return "";
  }

  if( output[0] == "HEAD" ){
    output = qx("git describe --tags");
  }


  return "\uE0A0" + output[0].substr(output[0].rfind('/')+1);
}

std::string gitStatusPlate(){
  std::vector<std::string> output = qx("git status --branch --porcelain 2> /dev/null");
  if( output.size() == 0 ){
    return "";
  }

  int ahead = 0;
  int behind = 0;
  int untrack = 0;
  int staged = 0;
  int modified = 0;

  for(auto i : output){
    if( i.rfind("??", 0) == 0 ){ untrack++; }
    if( i.rfind("A ", 0) == 0 ){ staged++; }
    if( i.rfind(" M", 0) == 0 ){ modified++; }
    if( i.rfind("##", 0) == 0 ){
      std::stringstream ss(i);
      std::string tmpstr;
      while( getline(ss, tmpstr, ' ') ){
        if( tmpstr.find("behind") != std::string::npos ){
          getline(ss, tmpstr, ' ');
          behind = std::stoi(tmpstr);
        }
        if( tmpstr.find("ahead") != std::string::npos ){
          getline(ss, tmpstr, ' ');
          ahead = std::stoi(tmpstr);
        }
      }
    }
  }

  std::string retval;
  if( ahead ){    retval += "\u2BC5" + std::to_string(ahead)    + " "; }
  if( behind ){   retval += "\u2BC6" + std::to_string(behind)   + " "; }
  if( modified ){ retval += "\u271A" + std::to_string(modified) + " "; }
  if( untrack ){  retval += "\u22EF" + std::to_string(untrack)  + " "; }
  if( staged ){   retval += "\u2B24" + std::to_string(staged)   + " "; }

  return retval;
}

int cleanInt(std::string& token){
  token.erase(
    std::remove_if(
      std::begin(token),
      std::end(token),
      [](auto ch){ return !std::isdigit(ch); }),
    token.end()
  );

  return std::stoi(token);
}

std::string dockerPlate(){
  std::vector<std::string> output = qx("docker info --format '{{json .}}'");
  if( output.size() == 0 ){
    return "";
  }

  int total = 0;
  int running = 0;
  int paused = 0;
  int stopped = 0;

  for(auto i : output){
    std::stringstream ss(i);
    std::string token;
    while( getline(ss, token, '"') ){
      if( token == "Containers" ){
        getline(ss, token, '"');
        total = cleanInt(token);
      }

      if( token == "ContainersRunning" ){
        getline(ss, token, '"');
        running = cleanInt(token);
      }

      if( token == "ContainersPaused" ){
        getline(ss, token, '"');
        paused = cleanInt(token);
      }

      if( token == "ContainersStopped" ){
        getline(ss, token, '"');
        stopped = cleanInt(token);
      }
    }
  }

  std::string retval = "\U0001F40B";
  if( total ){
    retval = "\U0001F433 ";

    if( running ){ retval += "\U000025CF" + std::to_string(running) + " "; }
    if( paused ) { retval += "~" + std::to_string(paused) + " "; }
    if( stopped ){ retval += "\U00002715" + std::to_string(stopped) + " "; }
  }

  return retval;
}

std::vector<std::string> qx(const char* cmd){
  char buffer[128];
  std::string output;

  std::unique_ptr<FILE, decltype(&pclose)> pipe(popen(cmd, "r"), pclose);
  if( !pipe ){
    throw std::runtime_error("popen() failed");
  }

  while(std::fgets(buffer, 128, pipe.get()) != nullptr ){
    output += buffer;
  }

  std::vector<std::string> retval;
  std::stringstream ss(output);
  std::string token;
  while(std::getline(ss, token, '\n')){
     retval.push_back(token);
  }

  return retval;
}

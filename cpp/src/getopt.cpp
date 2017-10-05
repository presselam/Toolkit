#include "getopt.hpp"
#include <iostream>
#include <vector>

Options getOptions(const int argc, const char** argv, OptionsDef& known){
  Options retval;
  bool errors = false;
  for( int i = 1; i < argc; ++i ){
    string arg = argv[i];
    short mode = 0;
    while( arg.front() == '-' ){
      arg.erase(0, 1);
      mode++;
    }

    int stop = arg.find('=');
    if( -1 == stop ){
      stop = arg.length();
    }

    if( mode == 0 ){
      continue;
    }

    vector<string> matched;
    list<string>::iterator it = known.begin();
    for( it = known.begin(); it != known.end(); ++it ){
      string param = *it;
      bool match = true;
      for( int c = 1; c <= stop; ++c ){
        if( strncmp(arg.c_str(), param.c_str(), c) != 0 ){
          match = false;
        }
      }

      if( match ){
        matched.push_back(param);
        if( mode == 2 ){
          if( stop == arg.length() ){
            retval[param] = "true";
          } else{
            retval[param] = arg.substr(stop + 1);
          }
        }
        if( mode == 1 ){
          if( i + 1 == argc || argv[i + 1][0] == '-' ){
            retval[param] = "true";
          } else{
            retval[param] = argv[i + 1];
          }
        }
      }
    }
    if( matched.size() == 0 ){
      errors = true;
      cout << "Unknown option: " << arg << endl;
    }
    if( matched.size() > 1 ){
      errors = true;
      cout << "Option " << arg << " is ambiguous (";
      for( vector<string>::iterator it = matched.begin(); it != matched.end();
          ++it ){
        cout << *it;
        if( (it + 1) != matched.end() ){
          cout << ",";
        }
      }
      cout << ")\n";
    }
  }

  if( errors ){
    exit(9);
  }

  return retval;
}

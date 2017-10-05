#ifndef _GETOPT_H
#define _GETOPT_H

#include <list>
#include <map>
#include <string>

using namespace std;

typedef list<string> OptionsDef;
typedef map<string, string> Options;

Options getOptions(const int agrc, const char** argv, OptionsDef& known);

#endif  // !_GETOPT_H

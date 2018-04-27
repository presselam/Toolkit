#include <toolkit.hpp>
#include <wonder.hpp>

using namespace toolkit;
using namespace std;

int main(int argc, char* argv[]) {
  quick << "hello world" << endl;
  quick << "hello" << setw(5) << 8 << 10 + 7 << setprecision(2) << 43.098922;
  return 0;
}

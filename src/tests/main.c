#include "tests.h"

int main() {
  int fail = 0;
  if (test_call_fn()) {
    write_stdout("test_call_fn: ok\n");
  } else {
    write_stdout("test_call_fn: fail\n");
    fail = 1;
  }

  if (!fail)
    write_stdout("pass\n");

  return 0;
}

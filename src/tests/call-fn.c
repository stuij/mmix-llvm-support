#include "tests.h"

int plus(int a, int b) {
  return a + b;
}

int test_call_fn(void) {
  if (plus(1, 2) == 3) {
    write_stdout("plus: ok\n");
    return 1;
  } else {
    write_stdout("plus: fail\n");
    return 0;
  }
}

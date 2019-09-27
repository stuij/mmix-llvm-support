extern void write_stdout(char* string);

int plus(int a, int b) {
  return a + b;
}

int main() {
  int res = plus(1, 2);
  if(res == 3)
    write_stdout("pass\n");
  return 1;
}

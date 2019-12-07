CC = clang

TEST_DIR = src/tests
BUILD_DIR = build
LIB_DIR = $(BUILD_DIR)/lib
BIN_DIR = $(BUILD_DIR)/bin
DIRS= $(BUILD_DIR) $(LIB_DIR) $(BIN_DIR)
INC_DIR = $(BUILD_DIR)/include

TEST_ELF = $(BIN_DIR)/test.elf
TEST_BIN = $(BIN_DIR)/test.mmo
CRT0 = $(LIB_DIR)/crt0.o

SRC = $(wildcard $(TEST_DIR)/*.c)

$(shell mkdir -p $(DIRS))
$(shell ln -fs ../src/include $(INC_DIR))

.PHONY: all clean run run-interactive test

all: $(CRT0) $(TEST_BIN) test

$(CRT0):
	$(CC) src/lib/crt0.s --target=mmix -c -o $@

$(TEST_ELF):
	$(CC) --target=mmix --sysroot=$(BUILD_DIR) -O0 -o $@ $(SRC)

$(TEST_BIN): $(TEST_ELF)
	mmix-objcopy -O mmo $(TEST_ELF) $(TEST_BIN)

run:
	mmix $(TEST_BIN) || true

run-interactive:
	mmix -i $(TEST_BIN)

# poor man's unit test framework
test:
	mmix $(TEST_BIN) | tee /dev/stderr | grep -q pass

clean:
	rm -r build/*

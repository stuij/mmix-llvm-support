#!/usr/bin/python
import random

# print_3op_list(op_list_3)
op_list_3 = [
    ["stb", 0xa0],
    ["stbu", 0xa2],
    ["stw", 0xa4],
    ["stwu", 0xa6],
    ["stt", 0xa8],
    ["sttu", 0xaa],
    ["sto", 0xac],
    ["stou", 0xae],
]


# print_2op_list(op_list_2)
op_list_2 = [
    ["seth", 0xe0],
]


def rand16():
    return random.randint(0, 255)

def rand16_fmt():
    return format(rand16(), 'x').zfill(2)

op2 = """# CHECK-INST: {0} ${1},0x{2}{3}
# CHECK: encoding: [0x{4},0x{5},0x{2},0x{3}]
# CHECK-DISASS: {4} {5} {2} {3}     {0} ${1},0x{2}{3}
  {0} ${1},0x{2}{3}"""

def print_op2(op, code):
    reg1_val = rand16()
    reg1 = "{0}".format(reg1_val)
    reg1_hex = format(reg1_val, 'x').zfill(2)
    imm1 = rand16_fmt()
    imm2 = rand16_fmt()

    out = op2.format(op, reg1, imm1, imm2, code, reg1_hex)
    print(out)

op3 = """# CHECK-INST: {0} ${1},${2},{3}
# CHECK: encoding: [0x{4},0x{5},0x{6},0x{7}]
# CHECK-DISASS: {4} {5} {6} {7}     {0} ${1},${2},{3}
  {0} ${1},${2},{3}"""

def print_op3(op, code, regp):
    reg1_val = rand16()
    reg1 = "{0}".format(reg1_val)
    reg1_hex = format(reg1_val, 'x').zfill(2)

    reg2_val = rand16()
    reg2 = "{0}".format(reg2_val)
    reg2_hex = format(reg2_val, 'x').zfill(2)

    reg3_val = rand16()
    reg3 = "${0}".format(reg3_val)
    reg3_hex = format(reg3_val, 'x').zfill(2)

    imm1 = rand16()
    imm1_bare = format(imm1, 'x').zfill(2)
    imm1_nofill = "0x" + format(imm1, 'x')
    imm1_fmt = "0x" + imm1_bare

    nr3 = reg3
    nr7 = reg3_hex
    if not regp:
        nr3 = imm1_nofill
        nr7 = imm1_bare

    out = op3.format(op, reg1, reg2, nr3, code, reg1_hex, reg2_hex, nr7)
    print(out)


def print_3op_both(op, code):
    code1 = format(code, 'x').zfill(2)
    code2 = format(code + 1, 'x').zfill(2)
    print_op3(op, code1, True)
    print()
    print_op3(op, code2, False)

def print_list(fn, op_list):
    for i in op_list:
        fn(i[0], i[1])
        print()

def print_3op_list(a_list):
    print_list(print_3op_both, a_list)

def print_2op_list(a_list):
    print_list(print_op2, a_list)

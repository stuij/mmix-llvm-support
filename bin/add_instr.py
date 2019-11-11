#!/usr/bin/env python3
# This file creates test strings for valid MMIX assembly lit tests.
# You hand the `print-instr` function an instruction mnemonic, an opcode and
# a list of operators of varying sizes, and it will construct the appropriate
# test string. Scaling up, you can create a list of the same opcode class
# instructions, and print them all out in one go.
# See the bottom of this file for plenty of examples.

import random
from enum import Enum, auto
from functools import reduce
from io import StringIO
from operator import add

def rand(val_size):
    return random.randint(0, val_size)

def sprintf(buf, fmt, *args):
    buf.write(fmt.format(*args))

class OpType(Enum):
    imm = auto()
    reg = auto()
    null = auto()

class Op():
    def __init__(self, op_type, byte_size=1, val_size=None):
        self.op_type = op_type
        self.byte_size = byte_size
        self.val_size = val_size
        if not val_size:
            self.val_size = 2 ** (byte_size * 8)
        if self.op_type is OpType.null:
            self.val = 0
        else:
            self.val = rand(self.val_size -1)

        val_bytestring = self.val.to_bytes(3, byteorder='little')
        mv = memoryview(val_bytestring).cast('B')
        self.val_bytes = [mv[i] for i in range(byte_size -1, -1, -1)]

        # assembly print representation
        if op_type is OpType.reg:
            self.op_ass = "${0}".format(self.val)
        else:
            self.op_ass = "0x" + format(self.val, 'x')

        self.op_hex = ",".join(["0x{0}".format(format(i, 'x').zfill(2)) for i in self.val_bytes])
        self.op_dis = " ".join(["{0}".format(format(i, 'x').zfill(2)) for i in self.val_bytes])

# example: print_instr("addi", 0x31, [Op(OpType.reg), Op(OpType.imm, byte_size=2), Op(OpType.imm, val_size=5)])
def print_instr(instr, code, op_list):
    assert(reduce(add, [i.byte_size for i in op_list]) <= 3)

    code_hex = format(code, 'x').zfill(2)

    buf = StringIO()
    ass_repr = "{0} {1}".format(instr, ",".join([i.op_ass for i in op_list if i.op_type is not OpType.null]))

    sprintf(buf, "# CHECK-INST: {0}\n", ass_repr)

    ops_hex = ",".join(["{0}".format(i.op_hex) for i in op_list])
    sprintf(buf, "# CHECK: encoding: [0x{0},{1}]\n", code_hex, ops_hex)

    ops_dis = " ".join([i.op_dis for i in op_list])
    sprintf(buf, "# CHECK-DISASS: {0} {1}   {2}\n", code_hex, ops_dis, ass_repr)

    sprintf(buf, "  {0}".format(ass_repr))
    print(buf.getvalue())

def print_list(fn, op_list):
    for i in op_list:
        fn(i[0], i[1])
        print()


### instruction classes

# leftovers
# print_list(print_imm_imm_imm, imm_imm_imm_list)
imm_imm_imm_list = [
    ["trap", 0x00],
    ["swym", 0xfd],
    ["trip", 0xff],
]
def print_imm_imm_imm(op, code):
    print_instr(op, code, [Op(OpType.imm), Op(OpType.imm), Op(OpType.imm)])

def print_irregulars():
    print_instr("resume", 0xf9, [Op(OpType.null, byte_size=2), Op(OpType.imm)])
    print()
    print_instr("save", 0xfa, [Op(OpType.reg), Op(OpType.null, byte_size=2)])
    print()
    print_instr("unsave", 0xfb, [Op(OpType.null, byte_size=2), Op(OpType.reg)])
    print()
    print_instr("sync", 0xfc, [Op(OpType.null, byte_size=2), Op(OpType.imm)])

## flp3plain, plain floating point
# print_list(print_flp3plain, flp3plain_list)
flp3plain_list = [
    ["fcmp",  0x01],
    ["fun",   0x02],
    ["feql",  0x03],
    ["fadd",  0x04],
    ["fsub",  0x06],
    ["fmul",  0x10],
    ["fcmpe", 0x11],
    ["fune",  0x12],
    ["feqle", 0x13],
    ["fdiv",  0x14],
    ["frem",  0x16],
]

def print_flp3plain(op, code):
    print_instr(op, code, [Op(OpType.reg), Op(OpType.reg), Op(OpType.reg)])

## flp2p5, floating point op with optional y, which atm you always need to specify
# print_list(print_flp2p5, flp2p5_list)
flp2p5_list = [
    ["fix",   0x05],
    ["fixu",  0x07],
    ["fsqrt", 0x15],
    ["fint",  0x17],
]

def print_flp2p5(op, code):
    print_instr(op, code, [Op(OpType.reg), Op(OpType.imm, val_size=5), Op(OpType.reg)])

## flp3multi floating point operations can take both reg or imm for z op
# print_list(print_flp3multi, flp3multi_list)
flp3multi_list = [
    ["flot",   0x08],
    ["flotu",  0x0a],
    ["sflot",  0x0c],
    ["sflotu", 0x0e],
]

def print_flp3multi(op, code):
    print_instr(op, code, [Op(OpType.reg), Op(OpType.imm, val_size=5), Op(OpType.reg)])
    print()
    print_instr(op, code + 1, [Op(OpType.reg), Op(OpType.imm, val_size=5), Op(OpType.imm)])
    
## xyz_multi
# it's a common pattern, mostly used by ALU instrs
# print_list(print_xyz_multi, xyz_multi_list)
alu3multi_list = [
    ["mul", 0x18],
    ["mulu", 0x1a],
    ["div", 0x1c],
    ["divu", 0x1e],

    ["sl", 0x38],
    ["slu", 0x3a],
    ["sr", 0x3c],
    ["sru", 0x3e],

    ["bdif", 0xd0],
    ["wdif", 0xd2],
    ["tdif", 0xd4],
    ["odif", 0xd6],
    ["mux", 0xd8],
    ["sadd", 0xda],
    ["mor", 0xdc],
    ["mxor", 0xde],
]

xyz_multi_list = [
    ["ldsf",  0x90],
    ["ldht",  0x92],
    ["ldvts", 0x98],
    ["stsf",  0xb0],
    ["stht",  0xb2],
    ["stco",  0xb4],
]

def print_xyz_multi(op, code):
    print_instr(op, code, [Op(OpType.reg), Op(OpType.reg), Op(OpType.reg)])
    print()
    print_instr(op, code + 1, [Op(OpType.reg), Op(OpType.reg), Op(OpType.imm)])

## directives
# print_list(print_di_multi, di_multi_list)
di_multi_list = [
    ["preld",  0x9a],
    ["prego",  0x9c],
    ["syncd",  0xb8],
    ["prest",  0xba],
    ["syncid", 0xbc],    
]

def print_di_multi(op, code):
    print_instr(op, code, [Op(OpType.imm), Op(OpType.reg), Op(OpType.reg)])
    print()
    print_instr(op, code + 1, [Op(OpType.imm), Op(OpType.reg), Op(OpType.imm)])

## wyde
# print_list(print_wyde, wyde_list)
wyde_list = [
    ["inch", 0xe4],
    ["incmh", 0xe5],
    ["incml", 0xe6],
    ["incl", 0xe7],

    ["andh", 0xec],
    ["andmh", 0xed],
    ["andml", 0xee],
    ["andl", 0xef],
]

def print_wyde(op, code):
    print_instr(op, code, [Op(OpType.reg), Op(OpType.imm, byte_size=2)])

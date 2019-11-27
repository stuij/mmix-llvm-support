  .text
.globl _start
_start:
  # set amount of local registers to 32
  setl $255,0x20
  put  rG,$255
  # set up stack
  seth $254,0x7fff
  ormh $254,0xffff
  orml $254,0xffff
  orl  $254,0xffff

  pushj $0,main
  trap 0,0,0

.globl write_stdout
.type  write_stdout, @function
write_stdout:
  add $255,$231,0
  # fputs the incoming argument to stdout
  trap 0,7,1
  pop 0,0

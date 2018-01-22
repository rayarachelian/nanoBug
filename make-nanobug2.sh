#!/bin/bash

rm nanobug.dc42
./lisafsh-tool --new nanobug2.dc42 400k <<ENDEND
loadbin 0x1c NANOBUG2.BIN
0
edittag 4 aa aa
quit
ENDEND

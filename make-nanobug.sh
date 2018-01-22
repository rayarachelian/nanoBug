#!/bin/bash

rm nanobug.dc42
./lisafsh-tool --new nanobug.dc42 400k <<ENDEND
loadsec 0x1c NANOBUG.BIN
edittag 4 aa aa
quit
ENDEND

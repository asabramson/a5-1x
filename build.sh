#!/bin/sh

# Exit on error
set -e

# Compile to C++
verilator --Mdir obj_A51 --timing --top-module A51_STREAM --sc --exe RUN_NLFSR.cpp A51_STREAM.v -CFLAGS -DMODULE_NAME=VA51_STREAM -CFLAGS -DMODULE_HDR=\\\"VA51_STREAM.h\\\"
verilator --Mdir obj_A51_EXT --timing --top-module A51_EXT_STREAM --sc --exe RUN_NLFSR.cpp A51_EXT_STREAM.v -CFLAGS -DMODULE_NAME=VA51_EXT_STREAM -CFLAGS -DMODULE_HDR=\\\"VA51_EXT_STREAM.h\\\"

# Compile the C++
cd obj_A51
make -f VA51_STREAM.mk -j8

# encode
./VA51_STREAM $(cat ../../secretkey.txt) ../../secret.txt ../../hidden-secret.txt
./VA51_STREAM $(cat ../../secretkey.txt) ../../hidden-secret.txt ../../unhidden-secret.txt

if cmp -s "../../secret.txt" "../../unhidden-secret.txt"; then
    echo "VA51 Round trip success"
else
    echo "VA51 Round trip failure"
fi

cd ..
cd obj_A51_EXT
make -f VA51_EXT_STREAM.mk -j8

./VA51_EXT_STREAM $(cat ../../secretkey.txt) ../../secret.txt ../../hidden-secret.txt
./VA51_EXT_STREAM $(cat ../../secretkey.txt) ../../hidden-secret.txt ../../unhidden-secret.txt

if cmp -s "../../secret.txt" "../../unhidden-secret.txt"; then
    echo "VA51 EXT Round trip success"
else
    echo "VA51 EXT Round trip failure"
fi
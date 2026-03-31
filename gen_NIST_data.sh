#!/bin/sh

# Exit on error
set -e

# This might take a few seconds
#./obj_A51/VA51_STREAM $(cat ./example_key.txt) --keystream 16000000 > A51-nist_data.txt

./obj_A51_EXT/VA51_EXT_STREAM $(cat ./example_key.txt) --keystream 16000000 > A51-EXT-nist_data.txt

# ./assess 20000
# HYBRID_NLFSR/nist_data.txt
# Test Selection Code: 111110000010011
# How many bitstreams? 200
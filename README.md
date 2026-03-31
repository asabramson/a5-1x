# Verilog Implementation of A5/1 and modified A5/1 stream ciphers.

We implement both A5/1 verbatim and a modified version of A5/1 with the intention
to mitigate known weaknesses against A5/1 as well as other percieved weaknesses.

The generated keystream a 98.65% average with select NIST sts suite tests.
See A51-finalAnalysisReport.txt for more details.

https://csrc.nist.gov/projects/random-bit-generation/documentation-and-software

### Verification

The A5/1 replica which was initially made as a proof of concept was confirmed to generate
the exact same keystream as another independent A5/1.

### Building

It may be compiled on Linux provided that verilator is installed. Since the
cipher is symmetric the generated binary can be used to both encrypt/decrypt
data.

Then ./build.sh can be run in this directory.

You can then provide a secret.txt and secretkey.txt in the directory
above this directory for the program to automatically encrypt and subsequently
decrypt with the same key to ensure that the generated key stream is stable
between runs oif the simulation and that the original plaintext can be recovered.
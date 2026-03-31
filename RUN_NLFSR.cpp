#include <verilated.h>
#include MODULE_HDR

using namespace sc_core;

void ERROR(const char* msg) {
    fprintf(stderr, "%s", msg);
    fprintf(stderr, "\n");
    exit(1);
}

#define ROTL8(x,shift) ((uint8_t) ((x) << (shift)) | ((x) >> (8 - (shift))))

uint8_t sbox[256];
void init_sbox() {
	uint8_t p = 1, q = 1;
	do {
		p = p ^ (p << 1) ^ (p & 0x80 ? 0x1B : 0);
		q ^= q << 1;
		q ^= q << 2;
		q ^= q << 4;
		q ^= q & 0x80 ? 0x09 : 0;
		uint8_t xformed = q ^ ROTL8(q, 1) ^ ROTL8(q, 2) ^ ROTL8(q, 3) ^ ROTL8(q, 4);
		sbox[p] = xformed ^ 0x63;
	} while (p != 1);
	sbox[0] = 0x63;
}

int sc_main(int argc, char** argv)
{
    int print_keystream = 0;
    if (argc == 4 && std::string(argv[2])=="--keystream") {
        print_keystream = 1;
    }
    else if (argc < 4) {
        ERROR(
            "usage: <key-data (bin)> <input-file-path> <output-file-path>\n"
            "OR usage: <key-data (bin)> --keystream <keystream-length (dec)>\n"
        );
    }

    init_sbox();
 
    sc_signal<bool> sig_out;
    sc_signal<bool> data_in;
    sc_signal<bool> enable_setkey;
    sc_signal<bool> clk;

    auto pulse = [&](){
        clk.write(0);
        sc_start(100, SC_NS);
        clk.write(1);
        sc_start(100, SC_NS);
    };

    MODULE_NAME top{"top"};
    top.clk(clk);
    top.data_in(data_in);
    top.enable_setkey(enable_setkey);
    top.sig_out.bind(sig_out);

    vluint64_t time = 0;

    long keylen = strlen(argv[1]);
    if (keylen != 64) ERROR("Invalid key length!");

    enable_setkey.write(1);
    for (int i = 0; i < 64; i++) {
        if (argv[1][i] == '1') {
            data_in.write(1);
        } else if (argv[1][i] == '0') {
            data_in.write(0);
        } else {
            ERROR("Unexpected character in key stream");
        }
        pulse();
        time++;
    }
    enable_setkey.write(0);

    if (print_keystream) {
        int amt = std::stoi(std::string(argv[3]));
        for (int i=0; i<amt; i++) {
            pulse();
            int ks = sig_out.read();
            printf("%d",ks);
        }
    }
    else {
        std::ifstream istrm(argv[2], std::ios::binary);
        if (!istrm.is_open()) ERROR("Failed to open plaintext file");

        std::ofstream ostrm(argv[3], std::ios::binary | std::ios::trunc);
        if (!ostrm.is_open()) ERROR("Failed to open ciphertext output file");

        char c;
        while (istrm.get(c)) {
            char o = 0;
            for (int i=0; i<8; i++) {
                pulse();
                
                int inp = (c&(1<<i))!=0;
                int ks = sig_out.read();

                o|=((((ks^inp)&1)<<i));
            }
            ostrm.write(&o, 1);
        }
    }

    return 0;
}
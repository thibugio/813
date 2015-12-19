/* bitpack.cpp */

#include <math.h>
#include <vector>
#include <cstring>
#include <string.h>
#include <cstdint>
#include <cstdlib>
#include <iostream>
#include <fstream>
#include <sstream>

#define NOP "0000"
#define LD "0001"
#define STR "0010"
#define BRA "0011"
#define XOR "0100"
#define ADD "0101"
#define ROT "0110"
#define SHF "0111"
#define CMP "1000"
#define HLT "1001"

#define A "0000"
#define P "0001"
#define E "0010"
#define C "0011"
#define N "0100"
#define Z "0101"
#define NC "0110"
#define PO "0111"

#define SREG 0
#define SMEM 0
#define SIMM 1
#define DREG 0
#define DMEM 1

#define BUSW 32
#define INDW 12

using namespace std;

enum opcode_t {nop, ld, str, bra, xxor, add, rot, shf, hlt, cmp};
enum ccode_t {a, p, e, c, n, z, nc, po};

struct instr {
    opcode_t op;
    ccode_t cc;
    int stype;
    int dtype;
    int dstind;
    int srcind;
};

void format_err(int line) {
    printf("WARNING: line %d improperly formatted\n", line);
}

void usage() {
    printf("usage: ./bitpack <filein> <fileout>\n\n");
    exit(EXIT_FAILURE);
}

void packAsBits(char bits[], int I, int bitw) {
    I = I % (int)(pow(2, bitw)) + 1;
    int count = bitw;
    while (count > 0) {
        if ((I-pow(2, count-1)) > 0) {
            bits[bitw - count] = '1';
            I -= pow(2, count-1);
        } else {
            bits[bitw - count] = '0';
        }
        count--;
    }
}

void parse_dst_src(std::string dststr, std::string srcstr, struct instr& I, int linecount) {
    size_t loc_dstsplit = dststr.find(":");
    size_t loc_srcsplit = srcstr.find(":");
    
    std::string typestr = dststr.substr(0, loc_dstsplit);
    std::string indstr = dststr.substr(loc_dstsplit + 1);
    if (!strcmp(typestr.c_str(), "R")) {
        I.dtype = DREG;
    } else if (!strcmp(typestr.c_str(), "M")) {
        I.dtype = DMEM;
    } else {
        format_err(linecount);
        return;
    }
    I.dstind = atoi(indstr.c_str());

    typestr = srcstr.substr(0, loc_srcsplit);
    indstr = srcstr.substr(loc_srcsplit + 1);
    if (!strcmp(typestr.c_str(), "M")) {
        I.stype = SMEM;
    } else if (!strcmp(typestr.c_str(), "L")) {
        I.stype = SIMM;
    } else if (!strcmp(typestr.c_str(), "R")) {
        I.stype = SREG;
    } else {
        format_err(linecount);
        return;
    }
    I.srcind = atoi(indstr.c_str());
}

void parse_line(std::string line, std::vector<struct instr>& instructions, 
                std::vector<std::string>& data, int linecount) {

    if (line[0] == '#' || line[0] == '\n') return;
    
    if (line[0] == '.') {
        if (line.size() == BUSW+1) {
            data.push_back(line.substr(1, BUSW));
        } else {
            format_err(linecount);
        }
        return;
    }

    size_t loc_op = 0;
    size_t loc_dst = line.find(" ", loc_op) + 1;
    size_t loc_src = line.find(" ", loc_dst) + 1;

    if (!(loc_op < loc_dst < loc_src)) {
        if (!(line.size() >= 3 && line[0] == 'H' && line[1] == 'L' && line[2] == 'T')) {
            format_err(linecount);
            return;
        }
    }

    struct instr I;
    std::string opstr = line.substr(loc_op, loc_dst - loc_op - 1);
    std::string dststr = line.substr(loc_dst, loc_src - loc_dst - 1);
    std::string srcstr = line.substr(loc_src, line.size() - loc_src);
    
    printf("opcode: %s, src: %s, dst: %s\n", opstr.c_str(), dststr.c_str(), srcstr.c_str());
    
    if (!strcmp(opstr.c_str(), "NOP")) {
        I.op = nop;
        instructions.push_back(I);
    } else if (!strcmp(opstr.c_str(), "LD")) {
        I.op = ld;
        parse_dst_src(dststr, srcstr, I, linecount);
        instructions.push_back(I);
    } else if (!strcmp(opstr.c_str(), "STR")) {
        I.op = str;
        parse_dst_src(dststr, srcstr, I, linecount);
        instructions.push_back(I);
    } else if (!strcmp(opstr.c_str(), "BRA")) {
        I.op = bra;
        I.dstind = atoi(dststr.c_str());
        if (!strcmp(srcstr.c_str(), "A")) {
            I.cc = a;
        } else if (!strcmp(srcstr.c_str(), "P")) {
            I.cc = p;
        } else if (!strcmp(srcstr.c_str(), "E")) {
            I.cc = e;
        } else if (!strcmp(srcstr.c_str(), "C")) {
            I.cc = c;
        } else if (!strcmp(srcstr.c_str(), "N")) {
            I.cc = n;
        } else if (!strcmp(srcstr.c_str(), "Z")) {
            I.cc = z;
        } else if (!strcmp(srcstr.c_str(), "NC")) {
            I.cc = nc;
        } else if (!strcmp(srcstr.c_str(), "PO")) {
            I.cc = po;
        } else {
            format_err(linecount);
            return;
        }
        instructions.push_back(I);
    } else if (!(strcmp(opstr.c_str(), "XOR"))) {
        I.op = xxor;
        parse_dst_src(dststr, srcstr, I, linecount);
        instructions.push_back(I);
    } else if (!(strcmp(opstr.c_str(), "ADD"))) {
        I.op = add;
        parse_dst_src(dststr, srcstr, I, linecount);
        instructions.push_back(I);
    } else if (!(strcmp(opstr.c_str(), "ROT"))) {
        I.op = rot;
        parse_dst_src(dststr, srcstr, I, linecount);
        instructions.push_back(I);
    } else if (!(strcmp(opstr.c_str(), "SHF"))) {
        I.op = shf;
        parse_dst_src(dststr, srcstr, I, linecount);
        instructions.push_back(I);
    } else if (!(strcmp(opstr.c_str(), "HLT"))) {
        I.op = hlt;
        I.dtype = DMEM;
        I.dstind = instructions.back().dstind;
        instructions.push_back(I);
    } else if (!(strcmp(opstr.c_str(), "CMP"))) {
        I.op = cmp;
        parse_dst_src(dststr, srcstr, I, linecount);
        instructions.push_back(I);
    } else { 
        format_err(linecount);
        return; 
    }
}

int main(int argc, char * argv[]) {
    
    //get the input and ouput file pointers 
    
    if (argc < 2) {
        usage();
    } 

    std::ifstream fileIn;
    std::ofstream fileOut;

    fileIn.open(argv[1]);
    fileOut.open(argv[2]);

    if (fileIn.bad() || fileOut.bad()) {
        printf("error opening file\n");
        usage();
    }
    
    //parse the input file

    std::vector<struct instr> instructions;
    std::vector<std::string> data;

    int pc=0;
    int linecount=0;
    std::string line;

    while (getline(fileIn, line)) {
        parse_line(line, instructions, data, linecount);
        linecount++;
    }
    
    fileIn.close();
    
    //write the output file

    pc = data.size();
    
    fileOut << pc << '\n';
    
    for (int i=0; i<pc; i++) {
        fileOut << data[i].c_str() << '\n';
    }

    struct instr I;
    char index[INDW];
    for (int i=0; i<instructions.size(); i++) {
        I = instructions[i];
        switch (I.op) {
        case nop:
            fileOut << NOP << I.stype << I.dtype << "00";
            break;
        case ld:
            fileOut << LD << I.stype << I.dtype << "00";
            break;
        case str:
            fileOut << STR << I.stype << I.dtype << "00";
            break;
        case bra:
            fileOut << BRA;
            switch (I.cc) {
            case a:
                fileOut << A;
                break;
            case p:
                fileOut << P;
                break;
            case e:
                fileOut << E;
                break;
            case c:
                fileOut << C;
                break;
            case n:
                fileOut << N;
                break;
            case z:
                fileOut << Z;
                break;
            case nc:
                fileOut << NC;
                break;
            case po:
                fileOut << PO;
                break;
            }
            break;
        case xxor:
            fileOut << XOR << I.stype << I.dtype << "00";
            break;
        case add:
            fileOut << ADD << I.stype << I.dtype << "00";
            break;
        case rot:
            fileOut << ROT << I.stype << I.dtype << "00";
            break;
        case shf:
            fileOut << SHF << I.stype << I.dtype << "00";
            break;
        case hlt:
            fileOut << HLT << I.stype << I.dtype << "00";
            break;
        case cmp:
            fileOut << CMP << I.stype << I.dtype << "00";
            break;
        }
        packAsBits(index, I.srcind, INDW);
        fileOut << index;
        packAsBits(index, I.dstind, INDW);
        fileOut << index << '\n';
    }

    fileOut.close();
    
    return 0;
}

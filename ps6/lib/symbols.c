/* symbols.c */

#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>

#include "symbols.h"

enum logic3 bool_to_logic3(bool b) {
    if (b)  
        return L1;
    else
        return L0;
}

char* print_logic3(enum logic3 l) { 
    switch(l) {
        case L0: return "0";
                 break;
        case L1: return "1";
                 break;
        case LX: return "X";
                 break;
    }
    return "";
}

char* print_gate(enum gate g) {
    switch(g) {
        case AND: return "AND";
        case OR:  return "OR";
        case XOR: return "XOR";
        case NOT: return "NOT";
        case BUF: return "BUF";
        case DFF: return "DFF";
        case PI: return "PI";
        case PO: return "PO";
    }
    return "";
}
        
char* print_ext_gate(enum ext_gate g) {
    switch (g) {
        case tinput: return "input";
        case toutput: return "output";
        case tbuf: return "buffer";
        case tnot: return "not";
        case tor: return "or";
        case tand: return "and";
        case tnor: return "nor";
        case tnand: return "nand";
        case txor: return "xor";
        case txnor: return "xnor";
        case tdff: return "dff";
    }
    return "";
}

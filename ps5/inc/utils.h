/* utils.h */

#ifndef UTILS_H
#define UTILS_H

#include <stdlib.h>
#include <string.h>
#include "ll.h"

enum tgate { tinput=-1, toutput=0, tbuf=1, tnot, tor, tand, tnor, tnand, txor, txnor, tdff };

struct gate {
    const char* name;
    enum tgate gate_type;
    int level;
    struct gate* fanin;
    struct gate* fanout;
    struct gate* next;
};

const char* tgatestr(enum tgate g) {
    switch (g) {
        case tinput: return "input";
        case toutput: return "output";
        case tbuf: return "buffer";
        case tnot: return "not";
        case tor: return "or";
        case tnor: return "nor";
        case tand: return "and";
        case tnand: return "nand";
        case txor: return "xor";
        case txnor: return "xnor";
        case tdff: return "dff";
        default: return "";
    }
}

void print_gate(struct gate* g) {
    printf("%s;%s;%d;", g->name, tgatestr(g->gate_type), g->level);
}

void print_gate_fnc(void* node) {
    struct gate* g = (struct gate*)node;
    print_gate(g);
}

void* next_gate_fnc(void* node) {
    struct gate* g = (struct gate*)node;
    return (void*)(g->next);
}

void print_gate_list(struct gate* head) {
    llprint_any((void*)head, &print_gate_fnc, &next_gate_fnc);
}

int strnicmp(const char* s1, const char* s2, int nmax) {
    size_t ls1 = strlen(s1);
    size_t ls2 = strlen(s2);

    int max = (ls1 > ls2 ? ls1 : ls2);

    int i; 
    int err = 0;
    for (i = 0; i<max; i++) {
        if (i == nmax) 
            break;
        else if (i >= ls1)
            err += s2[i];
        else if (i >= ls2)
            err += s1[i];
        else
            err += ((s1[i] - s2[i]) % ('a' - 'A'));
    }
    return err;
}

int stricmp(const char* s1, const char* s2) {
    size_t ls1 = strlen(s1);
    size_t ls2 = strlen(s2);
    int max = (ls1 > ls2 ? ls1 : ls2);
    return strnicmp(s1, s2, max);
}

#endif

/* Gate.h */

#ifndef STRUCT_GATE_H
#define STRUCT_GATE_H

#include <stdbool.h>
#include <stdlib.h>
#include <stdint.h>

#include "symbols.h"

struct Gate {
    char name[MAX_NAME_LEN];
    enum gate type;
    bool inv;
    bool output;
    unsigned int level;
    unsigned int sched;
    enum logic3 state;
    unsigned int nfanin;
    unsigned int nfanout;
    unsigned int* fanin;
    unsigned int* fanout;
};

void set_Gate_type(struct Gate* g, enum ext_gate t);

void debug_print_Gate(struct Gate g);

void debug_print_Gates(struct Gate* gates, unsigned int ngates);
#endif

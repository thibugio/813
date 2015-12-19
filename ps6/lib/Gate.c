/* Gate.c */
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>

#include "Gate.h"
#include "symbols.h"
#include "utils.h"

void set_Gate_type(struct Gate* g, enum ext_gate t) {
    switch (t) {
        case tinput: g->type = PI;
                     g->inv = false;
                     break;
        case toutput: g->type = PO;
                      g->inv = false;
                      break;
        case tbuf: g->type = BUF;   
                   g->inv = false;
                   break;
        case tnot: g->type = NOT;
                   g->inv = true;
                   break;
        case tor: g->type = OR;
                  g->inv = false;
                  break;
        case tnor: g->type = OR;
                   g->inv = true;
                   break;
        case tand: g->type = AND;
                   g->inv = false;
                   break;
        case tnand: g->type = AND;
                    g->inv = true;
                    break;
        case txor: g->type = XOR;
                   g->inv = false;
                   break;
        case txnor: g->type = XOR;
                    g->inv = true;
                    break;
        case tdff: g->type = DFF;
                   g->inv = false;
                   break;
    }
}

void debug_print_Gate(struct Gate g) {
    printf("name: %s\n", g.name);
    printf("type: %s\n", print_gate(g.type));
    printf("is output?: %d\n", g.output);
    printf("level: %d\n", g.level);
    printf("sched: %d\n", g.sched);
    printf("state: %s\n", print_logic3(g.state));
    printf("nfanin: %d\t", g.nfanin);
    unsigned int i;
    for (i=0; i<g.nfanin; i++)  
        printf("%d ", g.fanin[i]);
    printf("\n");
    printf("nfanout: %d\t", g.nfanout);
    for (i=0; i<g.nfanout; i++)  
        printf("%d ", g.fanout[i]);
    printf("\n\n");
}

void debug_print_Gates(struct Gate* gates, unsigned int ngates) {
    unsigned int i;
    for (i = 0; i < ngates; i++) {
        printf("GATE %u\n", i);
        debug_print_Gate(gates[i]);
    }
}


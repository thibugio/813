#include <stdlib.h>
#include <stdbool.h>
#include <stdio.h>
#include <string.h>

#include "gate.h"

#define DEBUG 1

const char* tgatestr(enum tgate g) {
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

struct gate* create_nameless_gate() {
    struct gate* g = (struct gate*)malloc(sizeof(struct gate));
    g->gate_type = -2;
    g->level = -1;
    g->output = false;
    g->indegree = -1;
    g->nfanin = 0;
    g->nfanout = 0;
    g->fanin = NULL;
    g->fanout = NULL;
    g->next = NULL;
    g->id = -1;
    return g;
}

struct gate* create_gate(const char* name) {
    struct gate* g = create_nameless_gate();
    safe_strcpy_to_array(g->name, name, MAX_NAME_LEN);
    return g;
}

struct gate* create_buffer_gate(const char* fanin, const char* fanout, unsigned int id) {
    char name[MAX_NAME_LEN];
    sprintf(name, "%s%d", "mybuf",id);
    
    struct gate* buf = create_gate(name);
    buf->id = id; 
    buf->gate_type = tbuf;
    
    if (fanin != NULL) {
        buf->indegree = 1;
        buf->nfanin = 1;
        add_name_to_fanin(buf, fanin);
    }
    
    if (fanout != NULL) {
        buf->nfanout = 1;
        add_name_to_fanout(buf, fanout);
    } 
    
    return buf;
}

struct gatelistnode* create_gatelistnode(const char* name) {
    struct gatelistnode* gnode = (struct gatelistnode*)malloc(sizeof(struct gatelistnode));
    safe_strcpy_to_array(gnode->name, name, MAX_NAME_LEN);
    gnode->next = NULL;
    return gnode;
}

void add_name_to_fanin(struct gate* g, const char* name) {
    struct gatelistnode* fanin = create_gatelistnode(name);
    LIST_INSERT_HEAD(g->fanin, fanin)
}

void add_name_to_fanout(struct gate* g, const char* name) {
    struct gatelistnode* fanout = create_gatelistnode(name);
    LIST_INSERT_HEAD(g->fanout, fanout);
}

void remove_name_from_faninlist(struct gatelistnode* fanin, const char* name) {
}

void remove_name_from_fanoutlist(struct gatelistnode* fanout, const char* name) {
}

int gate_sort_by_indegree(void* g1, void* g2) {
    int g1_indegree = ((struct gate*)g1)->indegree;
    int g2_indegree = ((struct gate*)g2)->indegree;
    return g1_indegree - g2_indegree;
}

void print_gatelist_names_to_file(FILE* fd, struct gatelistnode* node) {
    while (node != NULL) {
        fprintf(fd, "%s ", node->name);
        node = node->next;
    }
}

void print_gatelist_names(struct gatelistnode* node) {
    print_gatelist_names_to_file(stdout, node); 
    printf("\n");
}

void simple_print_gate(struct gate* g) {
    printf("%s;%s;%d;", g->name, tgatestr(g->gate_type), g->level);
}

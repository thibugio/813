#ifndef GATE_H
#define GATE_H

#include <stdlib.h>
#include <stdbool.h>
#include <stdio.h>
#include <string.h>

#include "utils.h"

#define MAX_NAME_LEN 34

enum tgate { tinput, toutput, tbuf, tnot, tor, tand, tnor, tnand, txor, txnor, tdff };

struct gatelistnode {
    char name[MAX_NAME_LEN];
    struct gatelistnode* next;
};

struct gate {
    //const char* name;
    char name[MAX_NAME_LEN];
    enum tgate gate_type;
    int level;
    bool output;
    int indegree;
    int nfanin;
    int nfanout;
    struct gatelistnode* fanin;
    struct gatelistnode* fanout;
    struct gate* next;
    unsigned int id;
};

const char* tgatestr(enum tgate g);

void set_gate_name(char gatename[], const char* name);

struct gate* create_nameless_gate();

struct gate* create_gate(const char* name);

struct gatelistnode* create_gatelistnode(const char* name);

void add_name_to_front(struct gatelistnode* g, const char* name_to_add);

void add_name_to_fanin(struct gate* g, const char* name);

void add_name_to_fanout(struct gate* g, const char* name);

void remove_name_from_faninlist(struct gatelistnode* fanin, const char* name);

void remove_name_from_fanoutlist(struct gatelistnode* fanout, const char* name);

struct gate* create_buffer_gate(const char* fanin, const char* fanout, unsigned int id);

int gate_sort_by_indegree(void* g1, void* g2);

void simple_print_gate(struct gate* g);

void print_gatelist_names(struct gatelistnode* g);

void print_gatelist_names_to_file(FILE* fd, struct gatelistnode* g);

#endif

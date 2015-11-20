#ifndef DXGRAPH_H
#define DXGRAPH_H

#include <stdbool.h>
#include <stdlib.h>
#include <stdio.h>

#include "dll.h"

struct dxgraph {
    int v;
    int e;
    //struct dll* adjlists; //list of lists
    void* adjlists[];
    int capacity;
};

struct dxgraph* createDXGraph() {
    struct dxgraph* g = (struct dxgraph*)malloc(sizeof(struct dxgraph));
    g.v = 0;
    g.e = 0;
    g.capacity = 10;
    g.adjlists = malloc(sizeof(void*)*g.capacity);
    return g;
}

bool add_vertex(struct dxgraph* g, void* data) {
    struct dll* vertex = createDLL();
    add_to_front(dll, data);
    g.v++;
    if (g.v >= g.capacity) {
        void* adj = g.adjlists;
        g.capacity += 10;
        g.adjlists = malloc(sizeof(void*)*g.capacity);
        g.adjlists = adj;
    }
    g.adjlists[g.v-1] = vertex;
    return vertex.size;
}

bool add_edge(struct dxgraph* g, int index1, int index2) {
    if (index1 >= g.v || index2 >= g.v || index1 < 0 || index2 < 0)
        return false;
    g.e++;
    add_to_back(g.adjlists[index1], g.adjlists[index2].head);
    return g.adjlists[index1].size;
}

#endif

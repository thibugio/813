#ifndef BINARY_HEAP_2_H
#define BINARY_HEAP_2_H

#include <stdlib.h>

#include "gate.h"

struct binaryheap2 {
    int capacity;
    int size;
    struct gate** items;
};

int sort(struct gate* g1, struct gate* g2);

int _binaryheap2_left_kid(int k);

int _binaryheap2_right_kid(int k);

int _binaryheap2_parent(int k);

void _binaryheap2_grow(struct binaryheap2* H);

void _binaryheap2_bubble_down(struct binaryheap2* H, int i);

void _binaryheap2_bubble_up(struct binaryheap2* H, int i);

/** "public" **/

void binaryheap2_heapify(struct binaryheap2* H);

struct gate* binaryheap2_top(struct binaryheap2* H);

void binaryheap2_insert(struct binaryheap2* H, struct gate* g);

struct gate* binaryheap2_pop(struct binaryheap2* H);

struct binaryheap2* binaryheap2_merge(struct binaryheap2* H1, struct binaryheap2* H2);

/** constructors **/

struct binaryheap2* binaryheap2_create(int cap);

struct binaryheap2* binaryheap2_create_from_array(int cap, struct gate* items[], int nitems);

void print_heap(struct binaryheap2* bh);

#endif

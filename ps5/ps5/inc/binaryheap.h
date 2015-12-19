#ifndef BINARY_HEAP_2_H
#define BINARY_HEAP_2_H

#include <stdlib.h>

#include "gate.h"

struct binaryheap {
    int capacity;
    int size;
    struct gate** items;
};

int sort(struct gate* g1, struct gate* g2);

int _binaryheap_left_kid(int k);

int _binaryheap_right_kid(int k);

int _binaryheap_parent(int k);

void _binaryheap_grow(struct binaryheap* H);

void _binaryheap_bubble_down(struct binaryheap* H, int i);

void _binaryheap_bubble_up(struct binaryheap* H, int i);

/** "public" **/

void binaryheap_heapify(struct binaryheap* H);

struct gate* binaryheap_top(struct binaryheap* H);

void binaryheap_insert(struct binaryheap* H, struct gate* g);

struct gate* binaryheap_pop(struct binaryheap* H);

struct binaryheap* binaryheap_merge(struct binaryheap* H1, struct binaryheap* H2);

/** constructors **/

struct binaryheap* binaryheap_create(int cap);

struct binaryheap* binaryheap_create_from_array(int cap, struct gate* items[], int nitems);

void print_heap(struct binaryheap* bh);

#endif

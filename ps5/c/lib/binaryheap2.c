#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <math.h>

#include "binaryheap2.h"

int _binaryheap2_sort(struct gate* g1, struct gate* g2) {
    return g1->indegree - g2->indegree;
}

int _binaryheap2_left_kid(int k) {
    return 2*k + 1;
}

int _binaryheap2_right_kid(int k) {
    return 2*(k+1);
}

int _binaryheap2_parent(int k) {
    return (int)ceil(k/2) - 1;
}

void _binaryheap2_grow(struct binaryheap2* H) {
    int old_capacity = H->capacity;
    int size = H->size;
    struct gate** items = (struct gate**)malloc(old_capacity * sizeof(struct gate*));
    memmove(items, H->items, old_capacity * sizeof(struct gate));

    H = binaryheap2_create_from_array(old_capacity + 50, items, size);
}

void _binaryheap2_bubble_down(struct binaryheap2* H, int i) {
    if (H->size <= 1) return;

    int left = _binaryheap2_left_kid(i);
    int right = _binaryheap2_right_kid(i);
    int last = _binaryheap2_parent(H->size-1);  //last non-leaf node
    struct gate* save;
    while (i <= last) {
        if (_binaryheap2_sort(H->items[left], H->items[i]) < 0) { //left kid smaller than i
            //swap i with left kid
            save = H->items[i];
            H->items[i] = H->items[left];
            H->items[left] = save;
            
            i = left;
        } else if (right < H->size && _binaryheap2_sort(H->items[right], H->items[i]) < 0) {
            //swap i with right kid
            save = H->items[i];
            H->items[i] = H->items[right];
            H->items[right] = save;
            
            i = right;
        } else { //both left (and right) kid greater than i
            break;
        }
        left = _binaryheap2_left_kid(i);
        right = _binaryheap2_right_kid(i);
    }
}

void _binaryheap2_bubble_up(struct binaryheap2* H, int i) {
    if (H->size <= 1) return;

    int parent = _binaryheap2_parent(i);
    struct gate* save;
    while (parent >= 0) {
        if (_binaryheap2_sort(H->items[i], H->items[parent]) >= 0)
            break;
        //swap i with parent
        save = H->items[i];
        H->items[i] = H->items[parent];
        H->items[parent] = save;
        
        i = parent;
        parent = _binaryheap2_parent(i);
    }
}

void binaryheap2_heapify(struct binaryheap2* H) {
    if (H->size > 1) {
        int i;
        //start at last non-leaf node
        for (i = _binaryheap2_parent(H->size-1); i>=0; i--) {
            _binaryheap2_bubble_down(H, i);
        }
    }
}

struct gate* binaryheap2_top(struct binaryheap2* H) {
    return H->items[0];
}

void binaryheap2_insert(struct binaryheap2* H, struct gate* g) {
    if (H->size + 1 >= H->capacity) 
        _binaryheap2_grow(H);
    H->items[H->size] = g;
    H->size++;
    _binaryheap2_bubble_up(H, H->size);
}

struct gate* binaryheap2_pop(struct binaryheap2* H) {
    if (H->size == 0) return NULL;
    struct gate* top = H->items[0];
    H->size--;
    if (H->size > 0) {
        H->items[0] = H->items[H->size-1];
        _binaryheap2_bubble_down(H, 0);
    }
    return top;
}

struct binaryheap2* binaryheap2_merge(struct binaryheap2* H1, struct binaryheap2* H2) {
    int i;
    for (i = 0; i<H2->size; i++) {
        binaryheap2_insert(H1, H2->items[i]);
    }
    return H1;
}

/** constructors **/

struct binaryheap2* binaryheap2_create(int cap) {
    struct binaryheap2* H = (struct binaryheap2*)malloc(sizeof(struct binaryheap2));
    H->items = (struct gate**)malloc(cap * sizeof(struct gate));
    H->capacity = cap;
    H->size = 0;
    return H;
}

struct binaryheap2* binaryheap2_create_from_array(int cap, struct gate* items[], int nitems) {
    int capacity = (cap > nitems ? cap : nitems);
    struct binaryheap2* H = binaryheap2_create(capacity);
    H->size = nitems;
    memmove(H->items, items, nitems * sizeof(struct gate));
    binaryheap2_heapify(H);
    return H;
}

void print_heap(struct binaryheap2* bh) {
    int k = 0, level = 0;
    printf("\nheap:\n");
    for (k=0; k < bh->size; k++)
        printf("%s:%d\n", bh->items[k]->name, bh->items[k]->indegree);
    printf("\n");
    
    k = 0;
    while (k < bh->size) {
        for (; k < ((int)pow(2, level+1)-1) && k < bh->size; k++)
            printf("%d ", bh->items[k]->indegree);
        printf("\n");
        level++;
    }
    printf("\n");
}


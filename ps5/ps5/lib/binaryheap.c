#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <math.h>

#include "binaryheap.h"

int _binaryheap_sort(struct gate* g1, struct gate* g2) {
    return g1->indegree - g2->indegree;
}

int _binaryheap_left_kid(int k) {
    return 2*k + 1;
}

int _binaryheap_right_kid(int k) {
    return 2*(k+1);
}

int _binaryheap_parent(int k) {
    return (int)ceil(k/2) - 1;
}

void _binaryheap_grow(struct binaryheap* H) {
    int old_capacity = H->capacity;
    int size = H->size;
    struct gate** items = (struct gate**)malloc(old_capacity * sizeof(struct gate*));
    memmove(items, H->items, old_capacity * sizeof(struct gate));

    H = binaryheap_create_from_array(old_capacity + 50, items, size);
}

void _binaryheap_bubble_down(struct binaryheap* H, int i) {
    if (H->size <= 1) return;

    int left = _binaryheap_left_kid(i);
    int right = _binaryheap_right_kid(i);
    int last = _binaryheap_parent(H->size-1);  //last non-leaf node
    struct gate* save;
    while (i <= last) {
        if (_binaryheap_sort(H->items[left], H->items[i]) < 0) { //left kid smaller than i
            //swap i with left kid
            save = H->items[i];
            H->items[i] = H->items[left];
            H->items[left] = save;
            
            i = left;
        } else if (right < H->size && _binaryheap_sort(H->items[right], H->items[i]) < 0) {
            //swap i with right kid
            save = H->items[i];
            H->items[i] = H->items[right];
            H->items[right] = save;
            
            i = right;
        } else { //both left (and right) kid greater than i
            break;
        }
        left = _binaryheap_left_kid(i);
        right = _binaryheap_right_kid(i);
    }
}

void _binaryheap_bubble_up(struct binaryheap* H, int i) {
    if (H->size <= 1) return;

    int parent = _binaryheap_parent(i);
    struct gate* save;
    while (parent >= 0) {
        if (_binaryheap_sort(H->items[i], H->items[parent]) >= 0)
            break;
        //swap i with parent
        save = H->items[i];
        H->items[i] = H->items[parent];
        H->items[parent] = save;
        
        i = parent;
        parent = _binaryheap_parent(i);
    }
}

void binaryheap_heapify(struct binaryheap* H) {
    if (H->size > 1) {
        int i;
        //start at last non-leaf node
        for (i = _binaryheap_parent(H->size-1); i>=0; i--) {
            _binaryheap_bubble_down(H, i);
        }
    }
}

struct gate* binaryheap_top(struct binaryheap* H) {
    return H->items[0];
}

void binaryheap_insert(struct binaryheap* H, struct gate* g) {
    if (H->size + 1 >= H->capacity) 
        _binaryheap_grow(H);
    H->items[H->size] = g;
    H->size++;
    _binaryheap_bubble_up(H, H->size);
}

struct gate* binaryheap_pop(struct binaryheap* H) {
    if (H->size == 0) return NULL;
    struct gate* top = H->items[0];
    H->size--;
    if (H->size > 0) {
        H->items[0] = H->items[H->size-1];
        _binaryheap_bubble_down(H, 0);
    }
    return top;
}

struct binaryheap* binaryheap_merge(struct binaryheap* H1, struct binaryheap* H2) {
    int i;
    for (i = 0; i<H2->size; i++) {
        binaryheap_insert(H1, H2->items[i]);
    }
    return H1;
}

/** constructors **/

struct binaryheap* binaryheap_create(int cap) {
    struct binaryheap* H = (struct binaryheap*)malloc(sizeof(struct binaryheap));
    H->items = (struct gate**)malloc(cap * sizeof(struct gate));
    H->capacity = cap;
    H->size = 0;
    return H;
}

struct binaryheap* binaryheap_create_from_array(int cap, struct gate* items[], int nitems) {
    int capacity = (cap > nitems ? cap : nitems);
    struct binaryheap* H = binaryheap_create(capacity);
    H->size = nitems;
    memmove(H->items, items, nitems * sizeof(struct gate));
    binaryheap_heapify(H);
    return H;
}

void print_heap(struct binaryheap* bh) {
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


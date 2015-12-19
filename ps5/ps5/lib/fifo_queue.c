#include <stdlib.h>
#include <stdio.h>

#include "fifo_queue.h"

void fifo_queue_push(struct fifo_queue* fq, struct gate* g) {
    struct fifo_queue_record* new_record = (struct fifo_queue_record*)malloc(sizeof(struct fifo_queue_record));
    new_record->data = g;
    new_record->next = NULL;
    
    if (fq->size == 0) {    
        fq->first = new_record;
        fq->last = fq->first;
    } else {
        fq->last->next = new_record;
        fq->last = new_record;
    }
    fq->size++;
}

struct gate* fifo_queue_pop(struct fifo_queue* fq) {
    if (fq->size == 0)  
        return NULL;
    struct gate* to_pop = fq->first->data;
    fq->size--;
    if (fq->size == 0) {
        fq->first = NULL;
        fq->last = NULL;
    } else {
        fq->first = fq->first->next;
    }
    return to_pop;
}

struct fifo_queue* fifo_queue_create() {
    struct fifo_queue* fq = (struct fifo_queue*)malloc(sizeof(struct fifo_queue));
    fq->size = 0;
    fq->first = NULL;
    fq->last = NULL;
    return fq;
}

void fifo_queue_clear(struct fifo_queue* fq) {
    free(fq);
    fq = fifo_queue_create();
}

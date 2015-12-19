#include <stdlib.h>

#include "gate.h"

struct fifo_queue_record {
    struct gate* data;
    struct fifo_queue_record* next;
};

struct fifo_queue { 
    unsigned int size;
    struct fifo_queue_record* first;
    struct fifo_queue_record* last;
};

// "public" //
void fifo_queue_push(struct fifo_queue* fq, struct gate* g);

struct gate* fifo_queue_pop(struct fifo_queue* fq);

struct fifo_queue* fifo_queue_create();

void fifo_queue_clear(struct fifo_queue* fq);

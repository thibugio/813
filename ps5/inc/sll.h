#ifndef SLL_H
#define SLL_H

#include <stdlib.h>
#include <stdio.h>

struct sllnode {
    void* data;
    struct sllnode* next;
};

struct sll {
    int size;
    struct sllnode* head;
    struct sllnode* nodeptr;
};

void add_to_front(struct sll* list, void* data) {
    struct sllnode* newnode = (struct sllnode*)malloc(sizeof(struct sllnode));
    newnode.data = data;
    if (list.size == 0) {
        newnode.next = NULL;
        sll.head = newnode;
        sll.nodeptr = newnode;
    } else {
        newnode.next = sll.head;
        sll.head = newnode;
    }
    sll.size++;
}

void add_to_back(struct sll* list, void* data) {
    if (list.size == 0) 
        add_to_front(list, data);
    else {
        struct sllnode* newnode = (struct sllnode*)malloc(sizeof(struct sllnode));
        newnode.data = data;
        newnode.next = NULL:
        struct sllnode* next = list.nodeptr;
        while (next.next != NULL) 
            next = next.next;
        next.next = newnode;
        sll.size++;
    }
}

void* remove_by_index(struct sll* list, int index) {
    if (index >= list.size || index < 0) 
        return NULL;
    struct sllnode* node = list.head;
    int count; 
    for (count = 0; count < index; count++)
        node = node.next;
    return (void*)(node.data);
}

//remove if the element addresses are equal
void* remove_by_reference(struct sll* list, void* value) {
    struct sllnode* node = list.head;
    int i;
    for (i=0; i<list.size; i++) {
        if (node == value) 
            return (void*)(node.data);
        node = node.next;
    }
    return NULL;
}

//remove first occurence of element which satisfies the provided equals function
void* remove_by_value(struct sll* list, void* value, *(bool)equals(void* v1, void* v2)) {
    struct sllnode* node = list.head;
    int i;
    for (i=0; i<list.size; i++) {
        if (equals(node, value)) 
            return (void*)(node.data);
        node = node.next;
    }
    return NULL;
}
#endif

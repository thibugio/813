#ifndef DLL_H
#define DLL_H

#include <stdlib.h>
#include <stdio.h>

struct dllnode {
    void* data;
    struct sllnode* prev;
    struct sllnode* next;
};

struct dll {
    int size;
    struct dllnode* head;
    struct dllnode* tail;
    struct dllnode* nodeptr;
};

struct dll* createDLL() {
    struct dll* dll = (struct dll*)malloc(sizeof(struct dll));
    clear_list(dll);
    return dll;
}

void clear_list(struct dll* list) {
    list.size = 0;
    list.head = NULL;
    list.tail = NULL;
    list.nodeptr = NULL;
}

void add_to_front(struct dll* list, void* data) {
    struct dllnode* newnode = (struct dllnode*)malloc(sizeof(struct dllnode));
    newnode.data = data;
    if (list.size == 0) {
        newnode.next = NULL;
        newnode.prev = NULL;
        dll.head = newnode;
        dll.tail = newnode;
        dll.nodeptr = newnode;
    } else {
        newnode.next = dll.head;
        newnode.prev = NULL; //dll.tail for circular
        dll.head = newnode;
    }
    dll.size++;
}

void add_to_back(struct dll* list, void* data) {
    if (list.size == 0) 
        add_to_front(list, data);
    else {
        struct dllnode* newnode = (struct dllnode*)malloc(sizeof(struct dllnode));
        newnode.data = data;
        newnode.next = NULL: //dll.head for circular
        newnode.prev = dll.tail;
        dll.tail.next = newnode;
        dll.size++;
    }
}

void* remove_by_index(struct dll* list, int index) {
    if (index >= list.size || index < 0) 
        return NULL;
    else if (index > (int)(list.size/2)) {
        struct dllnode* node = list.tail;
        int count; 
        for (count = list.size-1; count > index; count--)
            node = node.prev;
        return (void*)(node.data);
    } else {
        struct dllnode* node = list.head;
        int count; 
        for (count = 0; count < index; count++)
            node = node.next;
        return (void*)(node.data);
    }
}

//remove if the element addresses are equal
void* remove_by_reference(struct dll* list, void* value) {
    struct dllnode* node = list.head;
    int i;
    for (i=0; i<list.size; i++) {
        if (node == value) 
            return (void*)(node.data);
        node = node.next;
    }
    return NULL;
}

//remove first occurence of element which satisfies the provided equals function
void* remove_by_value(struct dll* list, void* value, *(bool)equals(void* v1, void* v2)) {
    struct dllnode* node = list.head;
    int i;
    for (i=0; i<list.size; i++) {
        if (equals(node, value)) 
            return (void*)(node.data);
        node = node.next;
    }
    return NULL;
}
#endif

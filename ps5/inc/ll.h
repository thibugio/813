/* ll.h */

#ifndef LL_H
#define LL_H

#include <stdlib.h>
#include <stdint.h>
#include <stdio.h>

struct node {
    int data;
    struct node * next;
};

void print_node(struct node* n) {
    printf("%d", n->data);
}

void print_node_fnc(void* node) {
    struct node* n = (struct node*)node;
    print_node(n);
}

void* next_node_fnc(void* node) {
    struct node* n = (struct node*)node;
    return (void*)(n->next);
}

void llprint_any(void* head, void (*print_fnc)(void*), void* (*next_fnc)(void*)) {
    void* temp = head;
    printf("[ ");
    while (temp != NULL) {
        print_fnc(temp);
        printf(" ");
        temp = next_fnc(temp);
    }
    printf("]\n");
}

void llprint(struct node* head) {
    struct node* temp = head;
    printf("[ ");
    while (temp != NULL) {
        printf("%d ", temp->data);
        temp = temp->next;
    }
    printf("]\n");
}

void lltest() {
    struct node* head = NULL;
    int i;
    for (i=0; i<10; i++) {
        struct node* n = (struct node*)malloc(sizeof(struct node));
        n->data = i;
        n->next = head;
        head = n;
    }
    llprint(head);
    llprint_any((void*)head, &print_node_fnc, &next_node_fnc);
}

#endif

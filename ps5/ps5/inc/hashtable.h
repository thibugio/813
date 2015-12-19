#ifndef HASHTABLE_H
#define HASHTABLE_H

#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <stdio.h>

#include "utils.h"

#define KEYLEN 34

enum status {empty, full, deleted};

struct hashrecord {
    enum status status;
    char key[KEYLEN];
    void* value;
};

struct hashtable {
    unsigned int size;
    unsigned int capacity;
    double max_lf;
    struct hashrecord* records;
};

unsigned int _get_capacity(unsigned int n, double lf);

void _grow_hashtable(struct hashtable* H); 

unsigned int _hashfunction(struct hashtable* H, const char* key);

unsigned int _probe(struct hashtable* H, unsigned int h);

int _find_index(struct hashtable* H, const char* key);

/* "public" */
struct hashtable* hashtable_create(unsigned int capacity, double lf);

void hashtable_stash(struct hashtable* H, const char* key, void* value);

void* hashtable_find(struct hashtable* H, const char* key);

bool hashtable_remove(struct hashtable* H, const char* key);

void hashtable_update(struct hashtable* H, const char* key, void* value);

void hashtable_squeeze_keys(struct hashtable* H, char* keys[]);

void hashtable_squeeze_values(struct hashtable* H, void* values[]);

#endif

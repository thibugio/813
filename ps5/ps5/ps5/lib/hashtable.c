#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <math.h>

#include "hashtable.h"

struct hashtable* hashtable_create(unsigned int suggested_capacity, double lf) {
    int i;
    double l = ((lf > 0 && lf < 1) ? lf : 0.5);
    unsigned int capacity = (suggested_capacity > 0 ? _get_capacity(suggested_capacity, l) : _get_capacity(100, l) );
    
    struct hashtable* H = (struct hashtable*)malloc(sizeof(struct hashtable));
    
    H->records = (struct hashrecord*)malloc(sizeof(struct hashrecord) * capacity);
    H->capacity = capacity;
    H->max_lf = l;
    H->size = 0;
    
    for (i=0; i<capacity; i++)
        H->records[i].status = empty; //could also try augmented hash table-- list of hash tables w/ 2 hfs
    return H;
}

void hashtable_stash(struct hashtable* H, const char* key, void* value) {
    if (((double)(H->size + 1) / H->capacity) > H->max_lf)  
        _grow_hashtable(H);
    unsigned int h = _hashfunction(H, key);
    while (H->records[h].status == full) {
        h = _probe(H, h);
        printf("hash collision for key %s!\n", key); //TODO- remove
    }
    H->records[h].status = full;
    if (strlen(key) < KEYLEN)
        strcpy(H->records[h].key, key);
    else {
        memmove(H->records[h].key, key, KEYLEN-1);
        H->records[h].key[KEYLEN-1] = '\0';
    }
    //memmove(H->records[h].value, value, sizeof(void*));
    //H->records[h].key = key;
    H->records[h].value = value;
    H->size++;
}

void* hashtable_find(struct hashtable* H, const char* key) {
    unsigned int h = _hashfunction(H, key);
    if (H->records[h].status == empty) return NULL;
    unsigned int count = 0;
    while (H->records[h].status == full && strcmp(H->records[h].key, key) && ((count++) < H->size))
        h = _probe(H, h);
    if (H->records[h].status == empty || count >= H->size)
        return NULL;
    return H->records[h].value;
}

bool hashtable_remove(struct hashtable* H, const char* key) {
    unsigned int h = _hashfunction(H, key);
    unsigned int count = 0;
    while (strcmp(H->records[h].key, key)) {
        h = _probe(H, h);
        if ((++count) > H->capacity) 
            return false;
    }
    H->records[h].status = deleted;
    H->size--;
    return true;
}

void hashtable_update(struct hashtable* H, const char* key, void* value) {
    int h = _find_index(H, key);
    if (h > 0) H->records[h].value = value;
}

void hashtable_squeeze_keys(struct hashtable* H, char* keys[]) {
    int i; 
    unsigned int index = 0;
    for (i=0; i<H->capacity; i++) {
        if (H->records[i].status == full) {
            //strcpy(keys[index], H->records[i].key);
            keys[index] = H->records[i].key;
            index++;
        }
    }
}

void hashtable_squeeze_values(struct hashtable* H, void* values[]) {
    int i; 
    unsigned int index = 0;
    for (i=0; i<H->capacity; i++) {
        if (H->records[i].status == full) {
            //memmove(values[index], H->records[i].value, sizeof(void*));
            values[index] = H->records[i].value;
            index++;
        }
    }
}

int _find_index(struct hashtable* H, const char* key) {
    unsigned int h = _hashfunction(H, key);
    if (H->records[h].status == empty) return -1;
    unsigned int count = 0;
    while (H->records[h].status == full && strcmp(H->records[h].key, key) && ((count++) < H->size))
        h = _probe(H, h);
    if (H->records[h].status == empty || count >= H->size)
        return -1;
    return h;
}

unsigned int _get_capacity(unsigned int n, double lf) {
    int mersenne_prime_powers[8] = {2,3,5,7,13,17,19,31};
    unsigned int _c = 0;
    unsigned int i,c;
    for (i=0; i<8; i++ ) {
        c = (2 << mersenne_prime_powers[i])-1;
        if (c >= (unsigned int)(n/lf)) {
            _c = c;
            break;
        }
    }
    if (_c != c)
        return next_prime((unsigned int)(n/lf));
    else 
        return c;
}

void _grow_hashtable(struct hashtable* H) {
    struct hashrecord* save_records = H->records;
    unsigned int old_capacity = H->capacity;
    unsigned int new_capacity = next_prime(old_capacity * 2 - 1);
    free(H->records);
    H->records = (struct hashrecord*)malloc(sizeof(struct hashrecord) * new_capacity);
    memmove(H->records, save_records, old_capacity * sizeof(struct hashrecord));
    free(save_records);
}

void _grow_hashtable_old(struct hashtable* H) {
    double max_lf = H->max_lf;
    unsigned int size = H->size;
    unsigned int old_capacity = H->capacity;
    unsigned int new_capacity = next_prime(old_capacity*2 - 1);
    struct hashrecord* records = (struct hashrecord*)malloc(sizeof(struct hashrecord) * old_capacity);
    memmove(records, H->records, sizeof(struct hashrecord) * old_capacity);

    H = hashtable_create(new_capacity, max_lf);

    H->size = size;
    memmove(H->records, records, sizeof(struct hashrecord) * old_capacity);
}

unsigned int _hashfunction(struct hashtable* H, const char* key) {
    int n = strlen(key);
    unsigned int h = 0;
    int i;
    for (i=0; i<n; i++)
        h += key[i] * (unsigned int)pow(31, n-1-i);
    h = h % H->capacity;
    if (h < 0) 
        h += H->capacity;
    return h;
}

unsigned int _probe(struct hashtable* H, unsigned int h) {
    //quadratic probing
    //double hashing
    
    //linear probing
    return ((h + 4) % H->capacity);
}


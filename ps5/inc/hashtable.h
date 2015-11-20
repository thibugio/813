#ifndef HASHTABLE_H
#define HASHTABLE_H

#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <stdio.h>

enum status {empty, full, deleted};

struct hashrecord {
    bool status;
    char* key;
    int value;
};

struct hashtable {
    int size;
    int capacity;
    double max_lf;
    struct hashrecord* records;
};

int mpp[8] = {2,3,5,7,13,17,19,31};

int next_prime(int n) {
    if (! n % 2) n++;
    bool prime = false;
    int i, s;
    while (!prime) {
        s = (int)ceil(sqrt(n));
        prime = true;
        for (i=3; i<s; i++) {
            if (! n % i) {
                prime = false;
                break;
            }
        }
        n += 2;
    }
    return n;
}

void get_capacity(int n, double lf) {
    int _c = 0;
    int i,c;
    for (i=0; i<8: i++ ) {
        c = (2 << mpp[i])-1;
        if (c >= (int)(n/lf)) {
            _c = c;
            break;
        }
    }
    if (_c != c)
        return next_prime((int)(n/H.max_lf));
    else 
        return c;
}

struct hashtable* createHashtable(int capacity, double lf) {
    double l = ((lf > 0 && lf < 1) ? lf : 0.5);
    int c = (capacity > 0 ? capacity : 20 );
    c = get_capacity(c, l);
    struct hashtable* H = (struct hashtable*)malloc(sizeof(struct hashtable) + sizeof(struct hashrecord)*c);
    H.capacity = c;
    H.max_lf = l;
    H.size = 0;
    int i;
    for (i=0; i<capacity; i++)
        H.records[i].status = empty; //could also try augmented hash table-- list of hash tables w/ 2 hfs
    return H;
}

int hashfunction(struct hashtable* H, char* key) {
    int n = strlen(key);
    int i, h;
    for (i=0; i<n; i++)
        h += key[i] * (int)pow(31, n-1-i);
    h = h % H.capacity;
    if (h < 0) h += H.capacity;
    return h;
}

int probe(struct hashtable* H, int h) {
    //linear probing
    return (h + 4) % H.capacity;
    //quadratic probing
    //double hashing
}

void stash(struct hashtable* H, char* key, int value) {
    if (((double)(H.size + 1) / H.capacity) > H.max_lf)  _grow_hashtable(H);
    int h = hashfunction(H, key);
    while (!H.records[h].status == empty)
        h = probe(H, h);
    H.records[h].status = full;
    H.records[h].key = key;
    H.records[h].value = value;
    H.size++;
}

int find(struct hashtable* H, char* key) {
    int h = hashfunction(H, key);
    while (strcmp(H.records[h].key, key)) {
        if (H.records[h].status == empty) 
            return -1;//false;
        h = probe(H, h);
    } 
    return H.records[h].value;
}

bool remove(struct hashtable* H, int key) {
    int h = hashfunction(H, key);
    int count = 0;
    while (H.records[h].key != key) {
        h = probe(H, h);
        if ((++count) > H.capacity) break;
    }
    if (count <= H.capacity) {
        H.records[h].status = deleted;
        H.size--;
        return true;
    } else return false;
}


void _grow_hashtable(struct hashtable* H) { 
    int s = H.size;
    int c = next_prime(H.capacity*2 - 1);
    int csave = H.capacity;
    struct hashrecord* records = H.records;
    H = (struct hashtable*)malloc(sizeof(struct hashtable) + sizeof(struct hashrecord)*(c)); 
    H.size = 0;
    H.capacity = c; 
    int i;
    for (i=s; i<H.capacity; i++) {
        H.records[i].status = empty;
        if (i < csave && records[i].status == full) stash(H, records[i].key, records[i].value);
    }
}

char* squeeze_keys(struct hashtable* H) {
    char keys[H.size];
    int i; 
    int index = 0;
    for (i=0; i<H.capacity; i++) {
        if (H.records[i].status == full) {
            keys[index] = H.records[i];
            index++;
        }
    }
    return keys;
}

int* squeeze_values(struct hashtable* H) {
    int values[H.size];
    int i; 
    int index = 0;
    for (i=0; i<H.capacity; i++) {
        if (H.records[i].status == full) {
            keys[index] = H.records[i];
            index++;
        }
    }
    return values;
}
#endif

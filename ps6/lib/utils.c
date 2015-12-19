#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdbool.h>
#include <math.h>

#include "utils.h"

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

void safe_strcpy_until(char arr[], const char* str, unsigned int length, char stop_char) {
    unsigned int i;
    for (i=0; i<length-1; i++) {
        if (str[i] == '\0' || str[i] == stop_char) {
           arr[i] = '\0';
           break;
        } else {
           arr[i] = str[i];
        }
    }
    if (i == length-1) {
        arr[i] = '\0';
    }
}

void safe_strcpy_to_array(char gatename[], const char* name, unsigned int length) {
    if ((strlen(name) + 1) >= length) {
        memmove(gatename, name, length-1);
        gatename[length-1] = '\0';
    } else {
        memmove(gatename, name, strlen(name) + 1);
    }
}

int my_strnicmp(const char* s1, const char* s2, int nmax) {
    size_t ls1 = strlen(s1);
    size_t ls2 = strlen(s2);

    int max = (ls1 > ls2 ? ls1 : ls2);

    int i; 
    int err = 0;
    for (i = 0; i<max; i++) {
        if (i == nmax) 
            break;
        else if (i >= ls1)
            err += s2[i];
        else if (i >= ls2)
            err += s1[i];
        else
            err += ((s1[i] - s2[i]) % ('a' - 'A'));
    }
    return err;
}

int my_stricmp(const char* s1, const char* s2) {
    size_t ls1 = strlen(s1);
    size_t ls2 = strlen(s2);
    int max = (ls1 > ls2 ? ls1 : ls2);
    return my_strnicmp(s1, s2, max);
}

void utils_out_of_mem() {
    printf("out of memory! exiting...\n\n");
    exit(EXIT_FAILURE);
}

#include <stdlib.h>
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

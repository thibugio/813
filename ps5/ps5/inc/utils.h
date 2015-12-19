#ifndef UTILS_H
#define UTILS_H

#include <stdlib.h>

#define LIST_INSERT_HEAD(old_head, new_head) new_head->next = old_head;\
                                             old_head = new_head;
#define STR_SAFE_CREATE_COPY(tostr, fromstr) const char* tostr = (const char*)malloc(strlen(fromstr) + 1);\
                                             memmove((void*)tostr, (void*)fromstr, strlen(fromstr) + 1);

int next_prime(int n);

void safe_strcpy_to_array(char gatename[], const char* name, unsigned int length);

int my_strnicmp(const char* s1, const char* s2, int nmax);

int my_stricmp(const char* s1, const char* s2);

#endif

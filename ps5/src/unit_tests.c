/* unit_tests.c */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "utils.h"

int main(int argc, char* argv[]) {
    printf("stricmp test:\n");
    printf("HELLO, hello: %d\n", stricmp("HELLO", "hello"));
    
    printf("\nstrtok test:\n");
    const char delims[8] = " =(,)\n\r";
    if (argc > 1) {
        FILE* fin = fopen(argv[1], "r");
        char inbuf[80];
        char* line_read;
        line_read = fgets(inbuf, 80, fin);
        char* tok;
        while (line_read != NULL) {
            tok = strtok(inbuf, delims);
            while (tok != NULL) {
                printf("%s;", tok);
                tok = strtok(NULL, delims);
            }
            printf("\n");
            line_read = fgets(inbuf, 80, fin);
        }
    } else {
        char s[14] = "g5 = dff(g10)";
        printf("%s\n", s);
        char* tok = strtok(s, delims);
        while (tok != NULL) {
            printf("%s;", tok);
            tok = strtok(NULL, delims);
        }
    }

    printf("\n\nstrlen test:\n");
    char s2[14] = "g5 = dff(g10)";
    const char match[] = "A";
    size_t locA = strcspn(s2, match);
    size_t lens2 = strlen(s2);
    printf("first match of %s in %s: %d\n", match, s2, (int)locA);
    printf("length of %s: %d\n", s2, (int)lens2);

    printf("\n\nll test:\n");
    lltest();

    printf("\n\ngate test:\n");
    char* names[5] = {"g1", "g2", "g3", "g4", "g5"};
    struct gate* head = NULL;
    int i;
    for (i=0; i<5; i++) {
        struct gate* n = (struct gate*)malloc(sizeof(struct gate));
        n->level = i;
        n->name = names[i];
        n->gate_type = tinput;
        
        n->next = head;
        head = n;
    }
    print_gate_list(head);

    return 0;
}

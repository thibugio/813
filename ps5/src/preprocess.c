/* pre.c */

#include <stdlib.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include "utils.h"

void usage() {
    printf("usgae: ./preprocess <inpath> <outpath>\n");
    printf("\tinpath: \tthe path to the circuit description to process, or - to read from stdin\n");
    printf("\toutpath: \tthe path to the file to dump the result to, or - to write to stdout\n\n");
    exit(EXIT_FAILURE);
}

int main(int argc, char* argv[]) {
    if (argc < 3) usage();
    
    FILE* fin = strncmp(argv[1], "-",8) ? fopen(argv[1], "r") : stdin;
    FILE* fout = strncmp(argv[2], "-",8) ? fopen(argv[2], "w") : stdout;

    if (fin == NULL || fout == NULL) usage();

    struct gate* head = NULL;
    int gate_count = 0;
    
    char inbuf[80];
    char* line_read;
    line_read = fgets(inbuf, 80, fin);

    //char* names[3] = {"betsy", "ross", "julie"};
    const char delims[9] = " =(,)\r\n\t";
    
    int primary = 1;
    int i;
    while (line_read != NULL) {
        if (!(line_read[0] == '\n' || line_read[0] == '\r' || line_read[0] == '#')) {
            struct gate* g = (struct gate*)malloc(sizeof(struct gate));
            primary = 1;
            for (i=0;;i++) {
                char* tok = (i==0 ? strtok(line_read, delims) : strtok(NULL, delims));
                if (tok == NULL) break;
                if (i==0) {
                    if (!stricmp("input", tok)) {  
                        g->gate_type = tinput;
                        g->level = 0;
                    } else if (!stricmp("output", tok)) {
                        g->gate_type = toutput;
                        g->level = -1;
                    } else {
                        //g->name = names[gate_count % 3];
                        const char* name = (const char*)malloc(strlen(tok)*sizeof(char));
                        memcpy((void*)name, (void*)tok, strlen(tok));
                        g->name = name;
                        
                        g->level = -1;
                        g->fanout = NULL;
                        g->fanin = NULL;
                        primary = 0;
                    }
                } else if (i==1) {
                    if (primary) {
                        //g->name = names[gate_count % 3];
                        const char* name = (const char*)malloc(strlen(tok)*sizeof(char));
                        memcpy((void*)name, (void*)tok, strlen(tok));
                        g->name = name;
                        
                        g->fanin = NULL;
                        g->fanout = NULL;
                        break;
                    } else {
                        if (!stricmp("dff", tok))
                            g->gate_type = tdff;
                        else if (!stricmp("not", tok))
                            g->gate_type = tnot;
                        else if (!stricmp("and", tok))
                            g->gate_type = tand;
                        else if (!stricmp("nand", tok))
                            g->gate_type = tnand;
                        else if (!stricmp("or", tok))
                            g->gate_type = tor;
                        else if (!stricmp("nor", tok))
                            g->gate_type = tnor;
                        else if (!stricmp("xor", tok))
                            g->gate_type = txor;
                        else if (!stricmp("xnor", tok))
                            g->gate_type = txnor;
                    }
                } else {
                    struct gate* gtemp = (struct gate*)malloc(sizeof(struct gate));
                    //g->name = names[gate_count % 3];
                    const char* name = (const char*)malloc(strlen(tok)*sizeof(char));
                    memcpy((void*)name, (void*)tok, strlen(tok));
                    g->name = name;
                    
                    gtemp->fanout = g;
                    g->fanin = gtemp;
                }
                //tok = strtok(NULL, delims);
            }
            print_gate(g);
            printf("\n");

            g->next = head;
            head = g;

            gate_count++;
        }
        line_read = fgets(inbuf, 80, fin);
    }

    fclose(fin);

    printf("\n\ngatelist:\n");
    print_gate_list(head);

    fclose(fout);

    return 0;
}

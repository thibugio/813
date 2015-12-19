/* pre.c */

#include <stdlib.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include <time.h>

#include "utils.h"
#include "gate.h"
#include "binaryheap2.h"
#include "hashtable.h"
#include "fifo_queue.h"

#define DEBUG 1

void usage() {
    printf("usgae: ./preprocess <inpath> <outpath>\n");
    printf("\tinpath: \tthe path to the circuit description to process, or - to read from stdin\n");
    printf("\toutpath: \tthe path to the file to dump the result to, or - to write to stdout\n\n");
    exit(EXIT_FAILURE);
}

bool unittest_gate_ids(struct hashtable* ht) {
    unsigned int gate_count = ht->size;
    unsigned int i;
    bool gate_ids[gate_count];
    bool missing = false;
    
    struct gate* gates[gate_count];
    hashtable_squeeze_values(ht, (void**)gates);
    
    for (i=0; i<gate_count; i++) 
        gate_ids[i] = false;
    for (i=0; i<gate_count; i++)
        gate_ids[gates[i]->id] = true;
    for (i=0; i<gate_count; i++) {
        if (!gate_ids[i]) {
            printf("unittest_gate_ids(): NOTE: missing gate id %d\n", i);
            missing = true;
        }
    }
    if (!missing)
        printf("unittest_gate_ids(): TEST PASSED: no gate ids are missing.\n");
    else
        printf("unittest_gate_ids(): TEST FAILED: some gate ids are missing.\n");
    return !missing;
}

bool unittest_gate_fanoutlist(struct hashtable* ht) {
    unsigned int gate_count = ht->size;
    unsigned int i;
    unsigned int fan_count;
    bool test_ok = true;
    struct gatelistnode* fannode;

    struct gate* gates[gate_count];
    hashtable_squeeze_values(ht, (void**)gates);
    
    for (i=0; i<gate_count; i++) {
        fan_count = 0;
        fannode = gates[i]->fanout;
        while (fannode != NULL) {
            fan_count++;
            fannode = fannode->next;
        }
        if (fan_count != gates[i]->nfanout) {
            printf("unittest_gate_fanoutlist(): NOTE: gate %s: length (%d) of fanout list != nfanout (%d)\n", gates[i]->name, fan_count, gates[i]->nfanout);
            printf("\t%s->fanout:\t",gates[i]->name);
            print_gatelist_names(gates[i]->fanout);
            test_ok = false;
        }
    }
    if (test_ok)
        printf("unittest_gate_fanoutlist(): TEST PASSED: length of fanout list matches g->nfanout for all g\n");
    else
        printf("unittest_gate_fanoutlist(): TEST FAILED: length of fanout list does not match g->nfanout for some g\n");
    return test_ok;
}

bool unittest_gate_faninlist(struct hashtable* ht) {
    unsigned int gate_count = ht->size;
    unsigned int i;
    unsigned int fan_count;
    bool test_ok = true;
    struct gatelistnode* fannode;

    struct gate* gates[gate_count];
    hashtable_squeeze_values(ht, (void**)gates);
    
    for (i=0; i<gate_count; i++) {
        fan_count = 0;
        fannode = gates[i]->fanin;
        while (fannode != NULL) {
            fan_count++;
            fannode = fannode->next;
        }
        if (fan_count != gates[i]->nfanin) {
            printf("unittest_gate_faninlist(): NOTE: gate %s: length (%d) of fanin list != nfanin (%d)\n", gates[i]->name, fan_count, gates[i]->nfanin);
            printf("\t%s->fanin:\t",gates[i]->name);
            print_gatelist_names(gates[i]->fanin);
            test_ok = false;
        }
    }
    if (test_ok)
        printf("unittest_gate_faninlist(): TEST PASSED: length of fanin list matches g->nfanin for all g\n");
    else
        printf("unittest_gate_faninlist(): TEST FAILED: length of fanin list does not match g->nfanin for some g\n");
    return test_ok;
}

void run_unittests(struct hashtable* ht) {
    int passed_tests = 0;
    printf("running unit tests...\n");
    printf("\nrunning unittest_gate_ids()...\n");
    if (unittest_gate_ids(ht))
        passed_tests++;
    printf("\nrunning unittest_gate_faninlist()...\n");
    if (unittest_gate_faninlist(ht))
        passed_tests++;
    printf("\nrunning unittest_gate_fanoutlist()...\n");
    if (unittest_gate_fanoutlist(ht))
        passed_tests++;
    printf("\n%d / 3 tests passed.\n\n", passed_tests);
}

void print_fan_list_ids(FILE* fd, struct gatelistnode* fnode, struct hashtable* ht) {
    if (fd == NULL) return;
    struct gate* f;
    while (fnode != NULL) { 
        f = hashtable_find(ht, fnode->name);
        fprintf(fd, "%d ", f->id);
        fnode = fnode->next;
    }
}

void print_gate_to_file(FILE* fd, struct gate* g, struct hashtable* ht) {
    if (fd == NULL) return;
    fprintf(fd, "%d ", g->gate_type);
    if (g->output)  
        fprintf(fd, "1 ");
    else
        fprintf(fd, "0 ");
    
    fprintf(fd, "%d %d ", g->level, g->nfanin);
    print_fan_list_ids(fd, g->fanin, ht);

    fprintf(fd, "%d ", g->nfanout);
    print_fan_list_ids(fd, g->fanout, ht);

    fprintf(fd, "%s\n", g->name);
}

void print_gates_to_file(FILE* fd, struct hashtable* ht) {
    if (fd == NULL) return;
    unsigned int i;
    unsigned int gate_count = ht->size;

    struct gate* gates[gate_count];
    hashtable_squeeze_values(ht, (void**)gates);

    for (i=0; i<gate_count; i++)
        print_gate_to_file(fd, gates[i], ht);
}

void pretty_print_gate_to_file(FILE* fd, struct gate* g) {
    if (fd == NULL) return;
    fprintf(fd, "gate id: %d \t", g->id);
    fprintf(fd, "type:%s \t", tgatestr(g->gate_type));
    
    if (g->output)
        fprintf(fd, "print=YES \t");
    else
        fprintf(fd, "print=NO \t");
    
    fprintf(fd, "level:%d \t", g->level);
    
    fprintf(fd, "nfanin:%d \t", g->nfanin);
    if (g->fanin == NULL)   
        fprintf(fd, "<>");
    else
        print_gatelist_names_to_file(fd, g->fanin);
    fprintf(fd, " \t\t");
    
    fprintf(fd, "nfanout:%d \t", g->nfanout);
    if (g->fanout == NULL)
        fprintf(fd, "<>");
    else
        print_gatelist_names_to_file(fd, g->fanout); 
    fprintf(fd, " \t\t");
    
    fprintf(fd, "name:%s\n", g->name);
}

void pretty_print_gates_to_file(FILE* fd, struct hashtable* ht) {
    if (fd == NULL) return;
    unsigned int i;
    unsigned int gate_count = ht->size;

    struct gate* gates[gate_count];
    hashtable_squeeze_values(ht, (void**)gates);
    
    for (i=0; i<gate_count; i++)
        pretty_print_gate_to_file(fd, gates[i]);
}

struct gatelistnode* read_gates_from_file(FILE* fin, struct hashtable* ht) {
    unsigned int gate_count = 0;
    struct gatelistnode* inputgates = NULL;
    char inbuf[80];
    char* line_read;
    line_read = fgets(inbuf, 80, fin);

    const char delims[9] = " =(,)\r\n\t";
    
    int primary = 1;
    int i;
    while (line_read != NULL) {
        if (!(line_read[0] == '\n' || line_read[0] == '\r' || line_read[0] == '#')) {
            struct gate* g = create_nameless_gate();
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
                        g->output = true;
                    } else {
                        STR_SAFE_CREATE_COPY(name, tok)
                        safe_strcpy_to_array(g->name, name, MAX_NAME_LEN);
                        primary = 0;
                    }
                } else if (i==1) {
                    if (primary) {
                        STR_SAFE_CREATE_COPY(name, tok)
                        safe_strcpy_to_array(g->name, name, MAX_NAME_LEN);
                        if (g->gate_type == tinput) {
                            struct gatelistnode* input = create_gatelistnode(name);
                            LIST_INSERT_HEAD(inputgates, input)
                        }
                        break;
                    } else {
                        if (!stricmp("dff", tok)) {
                            g->gate_type = tdff;
                            g->level = 0;
                        } else if (!stricmp("not", tok))
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
                } else { // i > 1
                    //this name refers to a fanin to gate g
                    STR_SAFE_CREATE_COPY(name, tok)
                    
                    g->nfanin++;

                    struct gate* gfanin = (struct gate*)hashtable_find(ht, name);
                    if (gfanin != NULL) { // already created this fanin gate
                        
                        gfanin->nfanout++;
                        
                        if (gfanin->nfanout <= 1) {
                            // first fanout; do not need a buffer
                            add_name_to_fanout(gfanin, g->name);
                            add_name_to_fanin(g, gfanin->name); 
                        } else {
                            struct gate* buf = create_buffer_gate(gfanin->name, g->name, gate_count);
                            gate_count++;
                            if (gfanin->nfanout == 2) {
                                // second fanout; insert two buffers
                                struct gate* buf2 = create_buffer_gate(gfanin->name, gfanin->fanout->name, gate_count);
                                gate_count++;
                                
                                hashtable_stash(ht, buf2->name, buf2); 

                                //replace fanin of fanout with new buffer
                                struct gate* gfaninfanout = hashtable_find(ht, gfanin->fanout->name);
                                struct gatelistnode* tempnode = gfaninfanout->fanin;
                                while (tempnode != NULL) {
                                    if (!strcmp(tempnode->name, gfanin->name))
                                        memmove(tempnode->name, buf2->name, MAX_NAME_LEN);
                                    tempnode = tempnode->next;
                                }
                                hashtable_update(ht, gfanin->fanout->name, gfaninfanout);
                                
                                gfanin->fanout = create_gatelistnode(buf->name); //replace current fanout with buffers
                                add_name_to_fanout(gfanin, buf2->name);
                                
                                add_name_to_fanin(g, buf->name);
                            } else {
                                // additional fanout; insert a buffer
                                add_name_to_fanout(gfanin, buf->name);
                                add_name_to_fanin(g, buf->name);
                            } 
                            hashtable_stash(ht, buf->name, buf); 
                        } 
                        hashtable_update(ht, name, gfanin);
                    } else { //gfanin == NULL; add a new gate to the hashtable for this fanin
                        gfanin = create_gate(name);
                        gfanin->id = gate_count;
                        gate_count++;
                        
                        gfanin->nfanout = 1;
                        add_name_to_fanout(gfanin, g->name);
                        
                        add_name_to_fanin(g, gfanin->name);
                        
                        hashtable_stash(ht, name, gfanin);
                    }
                }
            }
            //store g
            struct gate* g_temp = (struct gate*)hashtable_find(ht, g->name);
            if (g_temp != NULL) { //created as another gate's fanin, or an output label
                // add buffer for output gates
                if (g_temp->output) {
                    struct gate* outputbuf = create_buffer_gate(g->name, NULL, g_temp->id);
                    outputbuf->nfanout = 0;
                    outputbuf->output = true;

                    g->nfanout++;
                    add_name_to_fanout(g, outputbuf->name);
                    g->id = gate_count;
                    gate_count++;
                    hashtable_stash(ht, outputbuf->name, outputbuf);
                } else {
                    g->id = g_temp->id;
                    g->nfanout = g_temp->nfanout;
                    g->fanout = g_temp->fanout;
                }
                hashtable_update(ht, g->name, g);
            } else {
                g->id = gate_count;
                gate_count++;
                hashtable_stash(ht, g->name, g);
            }
        }
        line_read = fgets(inbuf, 80, fin);
    }
    return inputgates;
}

void reset_indegrees(struct hashtable* ht) {
    unsigned int gate_count = ht->size;

    struct gate* gates[gate_count];
    hashtable_squeeze_values(ht, (void**)gates);
    
    unsigned int i;
    for (i=0; i < gate_count; i++) {    
        gates[i]->indegree = gates[i]->nfanin;
        hashtable_update(ht, gates[i]->name, gates[i]);
    }
}

unsigned int sum_fanin_indegrees(struct gate* g, struct hashtable* ht) {
    unsigned int sum = 0;
    struct gate* temp;
    struct gatelistnode* fanin_node = g->fanin;
    while (fanin_node != NULL) {
        temp = hashtable_find(ht, fanin_node->name);
        sum += temp->indegree;
        fanin_node = fanin_node->next;
    }
    return sum;
}

void gate_set_level(struct gate* g, struct hashtable* ht) {
    if (g->gate_type == tdff) {
        g->level = 0;
        return;
    }
    int maxlevel = -1;
    struct gate* temp;
    struct gatelistnode* tempnode = g->fanin;
    while (tempnode != NULL) {
        temp = hashtable_find(ht, tempnode->name);
        if (temp->level > maxlevel) 
            maxlevel = temp->level;
        tempnode = tempnode->next;
    }
    g->level = maxlevel + 1;
    hashtable_update(ht, g->name, g);
}

//not actually used for anything except to tickle my own interest, but does work.
bool has_cycle(struct hashtable* ht) {
    bool abool = true, bbool = false;
    unsigned int finished_gates = 0;
    unsigned int gate_count = ht->size;
    struct gatelistnode* fanout_node;
    struct gate* top; 
    struct gate* fanout;

    struct gate* gates[gate_count];
    hashtable_squeeze_values(ht, (void**)gates);
    
    struct binaryheap2* bh = binaryheap2_create_from_array(gate_count, gates, gate_count);
    if (DEBUG) print_heap(bh);
    
    // topological sort on the gates by indegree
    while (finished_gates < gate_count) {
        if (abool == bbool) {
            printf("\n\nCYCLE DETECTED. HALTING\n\n");
            return true;
        }
        if (abool) abool = false;
        
        top = binaryheap2_top(bh);
        while (top->indegree == 0) {
            //set g's level as max(fanin_j->level) + 1
            gate_set_level(top, ht);
            //decrease the indegree of g's fanouts 
            fanout_node = top->fanout;
            while (fanout_node != NULL) {
                fanout = hashtable_find(ht, fanout_node->name);
                fanout->indegree--;
                hashtable_update(ht, fanout_node->name, fanout);
                fanout_node = fanout_node->next;
            }
            hashtable_update(ht, top->name, top);
            binaryheap2_pop(bh);
            top = binaryheap2_top(bh);
            finished_gates++;
            abool = true;
        }
        //reheap
        binaryheap2_heapify(bh);
        if (DEBUG) print_heap(bh);
    }
    printf("NO CYCLES\n");
    return false;
}

void set_gate_levels_bfs(struct hashtable* ht, struct gatelistnode* inputs) {
    while (inputs != NULL) {
        struct fifo_queue* fq = fifo_queue_create();
        struct gate* next = hashtable_find(ht, inputs->name);
        struct gatelistnode* successor_node;
        struct gate* successor;

        //mark this gate as visited-- should already be 0 since it's a primary input
        next->indegree = 0;
        fifo_queue_push(fq, next);
        
        while (fq->size > 0) {
            next = fifo_queue_pop(fq);
            successor_node = next->fanout;
            if (next->gate_type != tdff) {
                gate_set_level(next, ht);
            }
            while (successor_node != NULL) {
                successor = hashtable_find(ht, successor_node->name);
                if (successor->indegree > 0) {
                    successor->indegree--;
                    hashtable_update(ht, successor_node->name, successor);
                    fifo_queue_push(fq, successor);
                }
                successor_node = successor_node->next;
            }
        }
        inputs = inputs->next;
    }
}

void set_gate_levels_dfs_r(struct hashtable* ht, struct gate* next, bool visited[], struct fifo_queue* fq) {
    if (next == NULL) return;
    
    //mark this gate as visited (id is unique number 0...gate_count-1)
    visited[next->id] = true;

    //visit each of the gates in this gate's fanout list
    struct gate* temp;
    struct gatelistnode* fanout_node = next->fanout;
    while (fanout_node != NULL) {
        temp = hashtable_find(ht, fanout_node->name);
        if (!visited[temp->id]) {
            if (DEBUG) printf("visited gate %s, level=%d, indegree=%d\n", temp->name, temp->level, temp->indegree);
            temp->indegree--;
            fifo_queue_push(fq, temp);
            hashtable_update(ht, fanout_node->name, temp);
            set_gate_levels_dfs_r(ht, temp, visited, fq);
        }
        fanout_node = fanout_node->next;
    }

    //set the level of this gate
    while (fq->size > 0) {
        temp = fifo_queue_pop(fq);
        gate_set_level(temp, ht);
        if (DEBUG) printf("set gate %s level=%d\n", temp->name, temp->level);
    }
}

void set_gate_levels_dfs(struct hashtable* ht, struct gatelistnode* inputs) {
    struct gate* inputgate;
    struct fifo_queue* fq = fifo_queue_create();
    bool visited[ht->size];
    unsigned int i;

    while (inputs != NULL) {
        for (i=0; i < ht->size; i++)
            visited[i] = false;
        fifo_queue_clear(fq);
        inputgate = hashtable_find(ht, inputs->name);
        fifo_queue_push(fq, inputgate);
        if (DEBUG) printf("\nstarting dfs from input gate %s...\n", inputgate->name);
        set_gate_levels_dfs_r(ht, inputgate, visited, fq);
        inputs = inputs->next;
    }
}

void set_gate_levels(struct hashtable* ht, struct gatelistnode* inputgates) {
    if (inputgates == NULL) return;
    reset_indegrees(ht);
    set_gate_levels_dfs(ht, inputgates);
    //set_gate_levels_bfs(ht, inputgates);
}

int main(int argc, char* argv[]) {
    if (argc < 3) usage();
    
    FILE* fin = strncmp(argv[1], "-",8) ? fopen(argv[1], "r") : stdin;
    FILE* fout = strncmp(argv[2], "-",8) ? fopen(argv[2], "w") : stdout;
    if (fin == NULL || fout == NULL) usage();

    struct hashtable* ht = hashtable_create(500, 0.5);
    struct gatelistnode* inputgates = (struct gatelistnode*)malloc(sizeof(struct gatelistnode));
    
    clock_t start, stop;
    double runtime;

    start = clock();

    // read the gates from the files; store into hashtable by gatename
    inputgates = read_gates_from_file(fin, ht);
    fclose(fin);
   
    if (!ht->size) {
        printf("unable to read input file.\n");
        fclose(fout);
        exit(EXIT_FAILURE);
    }
    
    if (DEBUG) {
        pretty_print_gates_to_file(stdout, ht);
        printf("input gates:  ");
        print_gatelist_names(inputgates);
        run_unittests(ht);
    }

    // process gate levels    
    set_gate_levels(ht, inputgates);

    if (DEBUG) pretty_print_gates_to_file(stdout, ht);

    // print the intermediate file
    print_gates_to_file(fout, ht);

    stop = clock();
    runtime = (double)(stop - start)/CLOCKS_PER_SEC;
    printf("program finished in %5.5fs\n", runtime);
    
    fclose(fout);
    return 0;
}

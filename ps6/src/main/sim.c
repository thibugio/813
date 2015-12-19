/* sim.c */
#include <stdint.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#include <stdio.h>
#include <time.h>

#include "symbols.h"
#include "tables.h"
#include "utils.h"
#include "Gate.h"

#define MAX_NINPUTS 256
#define debug 0

void usage() {
    printf("usage: \t./sim <gate-list> <vec-list> <output>\n\
            \tgate-list: input file containing list of all gates to simulate in the format:\n\
            \t\tType Output Level Nfanin <fanin> Nfanout <fanout> Name\n\
            \tvec-list:  input file containing list of primary input vectors for simulation\n\
            \toutput:    file (- for stdout) to write simulation output to.\n\
            exiting...\n\n");
    exit(EXIT_FAILURE);
}

unsigned int read_num_gates_from_file(FILE* f) {
    char line[32];

    fgets(line, 32, f);
    
    unsigned int ngates = atoi(line);
    return ngates;
}

void read_gates_from_file(FILE* f, struct Gate gates[], unsigned int ngates) {
    char line[1024];
    //first line already read
    unsigned int line_count = 0;
    const char delim[2] = " ";
    while (fgets(line, 1024, f) != NULL && line_count < ngates) {
        char* tok = strtok(line, delim);
        unsigned int tok_count = 0;
        while (tok != NULL) {
            if (tok_count == 0)
                set_Gate_type(&(gates[line_count]), atoi(tok));
            else if (tok_count == 1)
                gates[line_count].output = (atoi(tok) > 0);
            else if (tok_count == 2) 
                gates[line_count].level = atoi(tok);
            else if (tok_count ==3) { 
                gates[line_count].nfanin = atoi(tok);
                gates[line_count].fanin = malloc(sizeof(unsigned int) * gates[line_count].nfanin);
            } else if ((tok_count - 4) < gates[line_count].nfanin)
                gates[line_count].fanin[tok_count - 4] = atoi(tok);
            else if ((tok_count - 4) == gates[line_count].nfanin) {
                gates[line_count].nfanout = atoi(tok);
                gates[line_count].fanout = malloc(sizeof(unsigned int) * gates[line_count].nfanout);
            } else if ((tok_count - 5 - gates[line_count].nfanin) < gates[line_count].nfanout)
                gates[line_count].fanout[tok_count - 5 - gates[line_count].nfanin] = atoi(tok);
            else
                safe_strcpy_until(gates[line_count].name, tok, MAX_NAME_LEN, '\n');
            tok_count++;
            tok = strtok(NULL, delim);
        }
        line_count++;
    }
}

void find_maxlevel_ninputs_nstates_noutputs(struct Gate gates[], unsigned int ngates, 
                                             unsigned int* max_level, unsigned int* ninputs,
                                             unsigned int* nstates, unsigned int* noutputs) {
    *max_level = 0;
    *ninputs = 0;
    *nstates = 0;
    *noutputs = 0;
    unsigned int i;
    for (i=0; i<ngates; i++) {  
        if (gates[i].level > *max_level)
            *max_level = gates[i].level;
        if (gates[i].type == PI)
            *ninputs = *ninputs + 1;
        else if (gates[i].type == DFF)
            *nstates = *nstates + 1;
        else if (gates[i].output)
            *noutputs = *noutputs + 1;
    }
}

void print_gate_values_by_type(enum gate type, struct Gate* gates, unsigned int ngates, 
                                unsigned int how_many, FILE* f) {
    if (how_many < 0) how_many = ngates;
    unsigned int i;
    unsigned int count = 0;
    for (i = 0; i < ngates && count < how_many; i++) {  
        if (gates[i].type == type) {
            fprintf(f, "%u ", gates[i].state);
            count++;
        }
    }
    fprintf(f, "\n");
}

void print_primary_inputs(struct Gate* gates, unsigned int ngates, unsigned int ninputs, FILE* output_file) {
    fprintf(output_file, "INPUT: ");
    print_gate_values_by_type(PI, gates, ngates, ninputs, output_file);
}

void print_current_states(struct Gate* gates, unsigned int ngates, unsigned int nstates, FILE* output_file) {
    fprintf(output_file, "STATE: ");
    print_gate_values_by_type(DFF, gates, ngates, nstates, output_file);
}

void print_primary_outputs(struct Gate* gates, unsigned int ngates, unsigned int noutputs, FILE* output_file) {
    fprintf(output_file, "OUTPUT: ");
    unsigned int i;
    unsigned int output_count = 0;
    for (i=0; i<ngates && output_count < noutputs; i++) {
        if (gates[i].output) {
            fprintf(output_file, "%u ", gates[i].state);
            output_count++;
        }
    }
    fprintf(output_file, "\n");
}

bool read_inputs_from_file(enum logic3* inputs, unsigned int ninputs, FILE* f) {
    char line[2*ninputs];
    if (fgets(line, 2*ninputs, f) != NULL) {
        if (line[0] != '\n') {
            unsigned int i;
            for (i=0; i<ninputs; i++) {
                if (line[i] == '1')
                    inputs[i] = L1;
                else 
                    inputs[i] = L0;
            }
            return true;
        }
    }
    return false;
}

void schedule_fanout(unsigned int g, struct Gate* gates, 
                     unsigned int* levels, unsigned int dummy_gate) {
    unsigned int i, gf;
    for (i = 0; i < gates[g].nfanout; i++) {
        gf = gates[g].fanout[i];
        if (gates[gf].type != DFF && gates[gf].sched == dummy_gate) {
            //add fanout to front of levels list
            gates[gf].sched = levels[gates[gf].level];
            levels[gates[gf].level] = gf;
            if (debug) {
                printf("scheduled gate at level %d:\n", gates[gf].level);
                debug_print_Gate(gates[gf]); 
            }
        }
    }
}

void sched_fanout_changed_primary_inputs(enum logic3* inputs, unsigned int ninputs, 
                                         struct Gate* gates, unsigned int ngates, 
                                         unsigned int* levels, unsigned int dummy_gate) {
    unsigned int i;
    unsigned int input_count = 0;
    for (i=0; i < ngates && input_count < ninputs; i++) {
        if (gates[i].type == PI) {
            if (gates[i].state != inputs[input_count]) {
                gates[i].state = inputs[input_count];
                schedule_fanout(i, gates, levels, dummy_gate);
            }
            input_count++;
        }
    }
    if (debug) printf("found %d primary inputs\n", input_count);
}

void sched_fanout_load_next_state(struct Gate* gates, unsigned int ngates, unsigned int nstates,
                                  unsigned int* levels, unsigned int dummy_gate) {
    unsigned int i;
    unsigned int state_count = 0;
    for (i=0; i<ngates && state_count < nstates; i++) {
        if (gates[i].type == DFF) {
            if (gates[i].state != gates[gates[i].fanin[0]].state) {
                gates[i].state = gates[gates[i].fanin[0]].state;
                schedule_fanout(i, gates, levels, dummy_gate);
            }
            state_count++;
        }
    }
}

enum logic3 evaluate_gate_scan(unsigned int g, struct Gate* gates) {
    if (gates[g].nfanin == 0) { //@DEBUG should never happen
        printf("called evaluate_gate() on a primary input!\n");
        exit(EXIT_FAILURE);
    }

    unsigned int i;
    enum logic3 fanin0_state = gates[gates[g].fanin[0]].state;
    switch (gates[g].type) {
        case NOT: return LUT[XOR][L1][fanin0_state]; 
        case BUF: return fanin0_state;
        case AND:
        case OR:;
            enum logic3 c = CV[gates[g].type];
            enum logic3 state;
            bool undef = false;
            for (i = 0; i < gates[g].nfanin; i++) {
                state = gates[gates[g].fanin[i]].state;
                if (state == c)
                    return c ^ gates[g].inv; //return LUT[XOR][c][gates[g].inv];
                if (state == LX)
                    undef = true;
            }
            if (undef) return LX;
            else return (!c) ^ gates[g].inv; //return LUT[XOR][LUT[XOR][L1][c]][gates[g].inv];
        case XOR:;
            enum logic3 faninN_state = gates[gates[g].fanin[1]].state;
            enum logic3 result = LUT[XOR][fanin0_state][faninN_state];
            for (i = 2; i < gates[g].nfanin; i++) { 
                faninN_state = gates[gates[g].fanin[i]].state;
                result = LUT[XOR][result][faninN_state];
            }
            if (gates[g].inv)   
                return LUT[XOR][L1][result];
            return result;
        default:
            printf("I SMELL A BUG...\n");
            exit(EXIT_FAILURE);
    }
}

enum logic3 evaluate_gate_table(unsigned int g, struct Gate* gates) {
    if (gates[g].nfanin == 0) { //@DEBUG should never happen
        printf("called evaluate_gate() on a primary input!\n");
        exit(EXIT_FAILURE);
    }

    enum logic3 fanin0_state = gates[gates[g].fanin[0]].state;
    switch (gates[g].type) {
        case NOT: return LUT[XOR][L1][fanin0_state];
        case BUF: return fanin0_state;
        case AND:
        case OR:
        case XOR:;
            enum logic3 faninN_state = gates[gates[g].fanin[1]].state;
            enum logic3 result = LUT[gates[g].type][fanin0_state][faninN_state];
            unsigned int i;
            for (i = 2; i<gates[g].nfanin; i++) {
                faninN_state = gates[gates[g].fanin[i]].state;
                result = LUT[gates[g].type][result][faninN_state];
            }
            if (gates[g].inv)
                return LUT[XOR][L1][result];
            return result;
        default:
            printf("I SMELL A BUG...\n");
            exit(EXIT_FAILURE);
    }
}

enum logic3 evaluate_gate(unsigned int g, struct Gate* gates) {
    // use one of the two evaluation strategies: table lookup or input scanning
    return evaluate_gate_table(g, gates);
    //return evaluate_gate_scan(g, gates);
}

void run_simulation(struct Gate* gates, unsigned int ngates, unsigned int ninputs, unsigned int nstates, 
                    unsigned int noutputs, unsigned int* levels, unsigned int max_level, 
                    unsigned int dummy_gate, FILE* input_file, FILE* output_file) {
    if (debug) printf("ENTERING SIMULATOR\n");
    enum logic3* inputs = malloc(sizeof(enum logic3) * ninputs);
    enum logic3 new_state;
    unsigned int i=0;
    unsigned int gate_n = 0; 
    unsigned int temp_n = 0;
        unsigned int ml = 1;
    while (1<2) {
        print_primary_inputs(gates, ngates, ninputs, output_file);
        print_current_states(gates, ngates, nstates, output_file);
        print_primary_outputs(gates, ngates, noutputs, output_file);
        
        if (!read_inputs_from_file(inputs, ninputs, input_file)) {
            printf("NO MORE INPUT\n");
            break;
        }
        if (debug) {printf("read inputs: "); for (i=0; i<ninputs; i++) printf("%u ", inputs[i]); printf("\n");}
        
        sched_fanout_changed_primary_inputs(inputs, ninputs, gates, ngates, levels, dummy_gate);
        sched_fanout_load_next_state(gates, ngates, nstates, levels, dummy_gate);
        i = 1;//0;
        while (i <= max_level) {
            gate_n = levels[i];
            if (debug) printf("level: %d\n", i);
            while (gate_n != dummy_gate) {
                if (i > ml) ml = i;
                new_state = evaluate_gate(gate_n, gates);
                if (debug) printf("gate_n: %d\tlast: %d\tnew: %d\n", gate_n, gates[gate_n].state, new_state);
                if (new_state != gates[gate_n].state) {
                    gates[gate_n].state = new_state;
                    schedule_fanout(gate_n, gates, levels, dummy_gate);
                }
                //next gate in levels[i]...
                temp_n = gates[gate_n].sched;
                gates[gate_n].sched = dummy_gate;
                gate_n = temp_n;
            }
            levels[i] = dummy_gate;
            i++;
        }
    }
        printf("max level evaluated: %d\n", ml);
    if (debug) printf("SIMULATION FINISHED\n");
}

int main(int argc, char* argv[]) {
    
    if (argc < 4) usage();
    const char* gatelist_file = argv[1];
    const char* veclist_file = argv[2];
    const char* output_file = argv[3];

    FILE* f_gatelist = fopen(gatelist_file, "r");
    FILE* f_veclist = fopen(veclist_file, "r");
    FILE* f_output = (strcmp(argv[3], "-") ? fopen(output_file, "w") : stdout);

    if (f_gatelist == NULL ||f_veclist == NULL || f_output == NULL) {
        printf("error: bad file specified.\n");
        exit(EXIT_FAILURE);
    }

    unsigned int i;
    unsigned int max_level;
    unsigned int ninputs;
    unsigned int nstates;
    unsigned int noutputs;
    unsigned int dummy_gate = -1;
    
    // read the number of gates in the design from the input file
    unsigned int ngates = read_num_gates_from_file(f_gatelist);
    if (debug) printf("there are %d gates in the file\n", ngates);
    
    // read the gates from the input file into gates array
    struct Gate* gates = malloc(ngates * sizeof(struct Gate));
    for (i=0; i<ngates; i++) {
        gates[i].sched = dummy_gate;
        gates[i].state = LX;
        gates[i].name[0] = '\0';
    }
    
    read_gates_from_file(f_gatelist, gates, ngates);
    fclose(f_gatelist);

    if (debug && ngates < 100) debug_print_Gates(gates, ngates);
    
    // initialize levels array
    unsigned int* levels = malloc((max_level+1) * sizeof(unsigned int));
    for (i=0; i<=max_level; i++)
        levels[i] = dummy_gate;
    printf("initialized levels array\n");
    
    // find the maximum depth of the design
    find_maxlevel_ninputs_nstates_noutputs(gates, ngates, &max_level, &ninputs, &nstates, &noutputs);
    
    if (debug) printf("max level in design: %d\n", max_level);
    printf("max level in design: %d\n", max_level);
    if (debug) printf("number of primary inputs in design: %d\n", ninputs);
    if (debug) printf("number of primary outputs in design: %d\n", noutputs);
    if (debug) printf("number of states in design: %d\n", nstates);
    
    // simulate the design
    clock_t start = clock();
    run_simulation(gates, ngates, ninputs, nstates, noutputs, 
                    levels, max_level, dummy_gate, f_veclist, f_output);
    double runtime = (double)(clock() - start) / CLOCKS_PER_SEC;
    printf("CPU time: %fs\n", runtime);

    fclose(f_veclist);
    fclose(f_output);

    return 0;
}

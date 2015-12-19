/* symbols.h */

#ifndef SYMBOLS_H
#define SYMBOLS_H

#include <stdint.h>

#define MAX_NAME_LEN 32

enum logic3 { L0=0, L1=1, LX=2 };

enum gate { AND=0, OR=1, XOR=2, NOT, BUF, DFF, PI, PO };
enum ext_gate { tinput, toutput, tbuf, tnot, tor, tand, tnor, tnand, txor, txnor, tdff };

enum logic3 bool_to_logic3(bool b);

char* print_logic3(enum logic3 l);

char* print_gate(enum gate g);
        
char* print_ext_gate(enum ext_gate g);

#endif

/* tables.h */
#ifndef TABLES_H
#define TABLES_H

#include <stdint.h>
#include <stdlib.h>

#include "symbols.h"

enum logic3 LUT[3][3][3] = {
    //AND
    {
        {L0,    L0,     L0},
        {L0,    L1,     LX},
        {L0,    LX,     LX},
    },
    //OR
    {
        {L0,    L1,     LX},
        {L1,    L1,     L1},
        {LX,    L1,     LX}
    },
    //XOR
    {
        {L0,    L1,     LX},
        {L1,    L0,     LX},
        {LX,    LX,     L0}
    }
};

enum logic3 CV[2] = {L0, L1};//AND, OR

#endif

CC=gcc
CFLAGS=-g -Wall

#directories

DINC=./inc
DSRC_MAIN=./src/main
DSRC_TEST=./src/test
DBIN=./bin
DCLIB=./lib

#source files

SRCS_=sim.c
TEST_SRCS_=test_Gate.c#test_lut.c
LIB_SRCS_=Gate.c symbols.c utils.c

SRCS=
TEST_SRCS=
LIB_SRCS=

#external libraries
EXTLIBS_=m
EXTLIBS=

#output files
TARGET_MAIN=$(DBIN)/sim
TARGET_TEST=$(DBIN)/test_Gate#test_lut

ifneq ($(strip $(LIB_SRCS_)),)
    LIB_SRCS=$(foreach src,$(LIB_SRCS_),$(DCLIB)/$(src))
endif

ifneq ($(strip $(SRCS_)),)
    SRCS=$(foreach src,$(SRCS_),$(DSRC_MAIN)/$(src))
    ifneq ($(strip $(LIB_SRCS_)),)
        SRCS+=$(LIB_SRCS)
    endif
endif

ifneq ($(strip $(TEST_SRCS_)),)
    TEST_SRCS=$(foreach src,$(TEST_SRCS_),$(DSRC_TEST)/$(src))
    ifneq ($(strip $(LIB_SRCS_)),)
        TEST_SRCS+=$(LIB_SRCS)
    endif
endif

ifneq ($(strip $(EXTLIBS_)),)
    EXTLIBS=$(foreach lib,$(EXTLIBS_),-l$(lib))
endif

all:
	$(CC) $(CFLAGS) -o $(TARGET_MAIN) -I $(DINC) $(SRCS) $(EXTLIBS)

test:
	$(CC) $(CFLAGS) -o $(TARGET_TEST) -I $(DINC) $(TEST_SRCS) $(EXTLIBS)


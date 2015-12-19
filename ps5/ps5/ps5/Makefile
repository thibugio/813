CC=gcc
CFLAGS=-g -Wall

DINC=inc/
DLIB=lib/
DSRC=src/
DOUT=bin/

CLIB=hashtable.c binaryheap.c fifo_queue.c gate.c utils.c 
CSRC=
TARGETS=preprocess unit_tests

EXTLIB=m

INCS=$(foreach d,$(DINC),-I$(d))
CLIBS=$(foreach s,$(CLIB),$(DLIB)$(s))
EXTLIBS=$(foreach l,$(EXTLIB),-l$(l))
BINS=$(foreach t,$(TARGETS),$(DOUT)$(t))

all:
	$(CC) $(CFLAGS) $(INCS) $(EXTLIBS) -o $(DOUT)preprocess $(DSRC)preprocess.c $(CLIBS)

.PHONY: clean
clean:
	rm -f *.o *~ $(DOUT)*.o $(DOUT)*~ $(BINS)


CC=gcc
CFLAGS=-g -Wall

DINC=inc/
DLIB=lib/
DSRC=src/
DOUT=bin/

SLIB=
SSRC=
TARGETS=preprocess unit_tests

INCS=$(foreach d,$(DINC),-I$(d))
LIBS=$(foreach s,$(SLIB),$(DLIB)$(s))
BINS=$(foreach t,$(TARGETS),$(DOUT)$(t))

all:
	$(CC) $(CFLAGS) -o $(DOUT)preprocess $(DSRC)preprocess.c $(LIBS) $(INCS)
test:
	$(CC) $(CFLAGS) -o $(DOUT)unit_tests $(DSRC)unit_tests.c $(LIBS) $(INCS)

.PHONY: clean
clean:
	rm -f *.o *~ $(DOUT)*.o $(DOUT)*~ $(BINS)


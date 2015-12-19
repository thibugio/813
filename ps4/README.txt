rmf61 hw4 README

ps4p1_proc.v: problem 1 
    -problems 2 and 3 are embedded within the code for the 'memory' entity where the ram array signal
        is initialized. The program is hard-coded into memory because I could not think of an intuitive
        way to pass it a variable length- program easily and coordinate that with the processor, besides
        creating a separate 'loader' entity which would send a control signal to memory, write the program
        1 word at a time, unassert the control signal (to both memory and processor), then feed the pc start
        and stop bounds to the processor, and let them both go on their merry way. I suppose such an approach
        would have been more realistic (program get compiled, linked, then the loader process loads the program
        into memory), but this seemed like an unecessary layer of complication for this assignment. Anyways,
        all three required programs can be found under the 'memory' entity; mnuemonic constants are used
        to initialize the memory and that block is well-commented, so it should be easy enough to read.

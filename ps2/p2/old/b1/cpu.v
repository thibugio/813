/* cpu.v: responsible for executing instructions for the processor */
module cpu(clk, IReg, PsrIn, RegDbusIn, mutexLow, PsrOut, rrwen, RegInd, RegDbusOut);
    // these need to be passed in!
    parameter BUSW=1;
    parameter RINDW=1;
    parameter PSRW=1;
    parameter REGTYPE=1'b0;
    parameter IMMTYPE=1'b0;
    parameter REN=1'b0;
    parameter WEN=1'b0;
    parameter NOP = 4'b0000,
               LD  = 4'b0000,
               STR = 4'b0000,
               BRA = 4'b0000,
               XOR = 4'b0000,
               ADD = 4'b0000,
               ROT = 4'b0000,
               SHF = 4'b0000,
               HLT = 4'b0000,
               CMP = 4'b0000;


    input clk;
    input reg [31:0] IReg;
    input reg [PSRW-1:0] PsrIn;
    input reg [BUSW-1:0] RegDbusIn;

    output mutexLow, rrwen;
    input reg [PSRW-1:0] PsrOut;
    output reg [BUSW-1:0] RegDbusOut;
    output reg [RINDW-1:0] RegInd;



endmodule

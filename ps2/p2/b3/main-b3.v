/* main-b3.v */

module main_b3();
    parameter BUSW=32;
    parameter PSRW=5;
    parameter IRW=BUSW;
    parameter IR_SRCIND_CNT=12;
    parameter IR_DSTIND=0;
    parameter IR_DSTTYPE=26;
    parameter IR_SRCTYPE=27;
    parameter IR_CC=24;
    parameter IR_OP=28;
    parameter OPW=4; //opcode bit-width
    parameter CCW=4; //cond. code bit-width
    parameter CNTW=5; //+-16 2's comp. shift/rotate count bit-width
    parameter MINDW=12; //12-bit memory index
    parameter MWORDS=4096; //2**12
    parameter RINDW=4; //4-bit register bank index
    parameter RWORDS=16; //2**4
    parameter REGTYPE=1'b0;
    parameter IMMTYPE=1'b1;
    parameter MEMTYPE=1'b1;
    parameter NOP = 4'b0000, //opcodes
              LD  = 4'b0001,
              STR = 4'b0010,
              BRA = 4'b0011,
              XOR = 4'b0100,
              ADD = 4'b0101,
              ROT = 4'b0110,
              SHF = 4'b0111,
              HLT = 4'b1000,
              CMP = 4'b1001;
    parameter CC_A = 4'b0000, //always
              CC_P = 4'b0001, //parity
              CC_E = 4'b0010, //even
              CC_C = 4'b0011, //carry
              CC_N = 4'b0100, //negative
              CC_Z = 4'b0101, //zero
              CC_NC = 4'b0110, //no carry
              CC_PO = 4'b0111; //positive
    reg clk;
    reg [BUSW*MWORDS-1:0] Mem;    
    reg [BUSW*RWORDS-1:0] Reg;
    reg [IRW-1:0] IReg;
    reg [PSRW-1:0] Psr;
    reg [PSRW-1:0] PsrLast;
    reg ret;
    wire [IRW-1:0] PCntr; //program counter

    `define OPCODE IReg[IR_OP+OCW-1:IR_OP]
    `define CCODE  IReg[IR_CC+CCW-1:IR_CC]
    `define SRCTYPE IReg[IR_SRCTYPE]
    `define DSTTYPE IReg[IR_DSTTYPE]
    `define SRCMIND IReg[IR_SRCIND_CNT+MINDW-1:IR_SRCIND_CNT]
    `define SRCRIND IReg[IR_SRCIND_CNT+RINDW-1:IR_SRCIND_CNT]
    `define DSTMIND IReg[IR_DSTIND+MINDW-1:IR_DSTIND]
    `define DSTRIND IReg[IR_DSTIND+RINDW-1:IR_DSTIND]
    `define SHFROTC IReg[IR_SRCINT_CNT+CNTW-1:IR_SRCINT_CNT]

    cpu #() cpu0();
    
    initial begin
        clk = 0;
        ret = fClearReg(Mem);
            defparam fClearReg.RBITS=BUSW*MWORDS;
        ret = fClearReg(Reg);
            defparam fClearReg.RBITS=BUSW*RWORDS;
        ret = fClearReg(IReg);
            defparam fClearReg.RBITS=IRW;
        ret = fClearReg(Psr);
            defparam fClearReg.RBITS=PSRW;
        ret = fClearReg(PsrLast);
            defparam fClearReg.RBITS=PSRW;

        // load a program into memory

        forever begin
            #1 clk = !clk;
        end
    end

    always @(posdedge clk) begin
        IReg = Mem[BUSW*(PCntr+1)-1:BUSW*PCntr];
    end

    function [0:0] fClearReg;
    parameter RBITS=1;
    input reg [RBITS-1:0] RegToClear;
    begin
        for (i=0; i<RBITS; i=i+1) begin
            RegToClear[i] = 0;
        end
        fClearReg = 1'b1; //return 'success'
    end
    endfunction

endmodule

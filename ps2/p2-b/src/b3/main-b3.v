/* main-b3.v 
search 'README'
*/

module main_b3();
    parameter BUSW=32;
    parameter MINDW=12; //12-bit memory index
    parameter MWORDS=4096; //2**12
    parameter RINDW=4; //4-bit register bank index
    parameter RWORDS=16; //2**4
    parameter IRW=BUSW;
    parameter IR_SRCIND_CNT=12;
    parameter IR_DSTIND=0;
    parameter IR_SRCTYPE=27;
    parameter IR_DSTTYPE=26;
    parameter IR_CC=24;
    parameter IR_OP=28;
    parameter OPW=4; //opcode bit-width
    parameter CCW=4; //cond. code bit-width
    parameter CNTW=5; //+-16 2's comp. shift/rotate count bit-width
    parameter SRCINDW=MINDW; //src address bit-width
    parameter DSTINDW=MINDW; //dst address bit-width
    parameter REGTYPE=1'b0;
    parameter IMMTYPE=1'b1;
    parameter SMEMTYPE=REGTYPE;
    parameter DMEMTYPE=1'b1;
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
    parameter CARRY=0,
              PARITY=1,
              EVEN=2,
              NEGATIVE=3,
              ZERO=4;
    
    reg clk;
    reg [BUSW*MWORDS-1:0] Mem;    
    reg [BUSW*RWORDS-1:0] Reg;
    reg [IRW-1:0] IReg;
    reg ret;
    reg [MINDW-1:0] PCntr; //program counter
    reg [MINDW-1:0] PCntrNext; 
    reg mutexLow; //lock on memory
    reg [PSRW-1:0] Psr;

    `define OPCODE IReg[IR_OP+OCW-1:IR_OP]
    `define CCODE  IReg[IR_CC+CCW-1:IR_CC]
    `define SRCTYPE IReg[IR_SRCTYPE]
    `define DSTTYPE IReg[IR_DSTTYPE]
    `define SRCMIND IReg[IR_SRCIND_CNT+MINDW-1:IR_SRCIND_CNT]
    `define SRCRIND IReg[IR_SRCIND_CNT+RINDW-1:IR_SRCIND_CNT]
    `define DSTMIND IReg[IR_DSTIND+MINDW-1:IR_DSTIND]
    `define DSTRIND IReg[IR_DSTIND+RINDW-1:IR_DSTIND]
    `define SHFROTS IReg[IR_SRCIND_CNT+CNTW-1]
    `define SHFROTC IReg[IR_SRCIND_CNT+CNTW-2:IR_SRCIND_CNT]
    `define DSTREG Reg[fR(`DSTRIND+1)-1:fR(`DSTRIND)]
    `define DSTMEM Mem[fM(`DSTMIND+1)-1:fM(`DSTMIND)]
    `define SRCREG Reg[fR(`SRCRIND+1)-1:fR(`SRCRIND)]
    `define SRCMEM Mem[fM(`SRCMIND+1)-1:fM(`SRCMIND)]
    `define CAR Psr[CARRY]
    `define PAR Psr[PARITY]
    `define EVN Psr[EVEN]
    `define NEG Psr[NEGATIVE]
    `define ZER Psr[ZERO]

//    cpu #(BUSW, IRW, IR_SRCIND_CNT, IR_DSTIND, IR_SRCTYPE, IR_DSTTYPE, IR_CC, IR_OP, OPW, CCW, CNTW, MINDW, MWORDS, RINDW, RWORDS, REGTYPE, IMMTYPE, MEMTYPE, NOP, LD, STR, BRA, XOR, ADD, ROT, SHF, HLT, CMP, CC_A, CC_P, CC_E, CC_C, CC_N, CC_Z, CC_NC, CC_PO) cpu0(.clk(clk), .IReg(IReg), .mutexLow(mutexLow), .PCntrNext(PCntr));
    
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

        //load a program into memory
        //returns the memory index of the first instruction as the program counter
        PCntr = fLoadProgram(113);

        forever begin
            #1 clk = !clk;
        end
    end

    always @(negedge clk) begin
        if (mutexLow === 1'b1) begin
            PCntr = PCntrNext;
            IReg = Mem[fM(PCntr+1)-1:fM(PCntr)];
        end
    end

    always @(posedge clk) begin
        case (`OPCODE)
        LD: tLOAD;
        STR: tSTORE; 
        BRA: tBRANCH; 
        XOR: tXOR;
        ADD: tADD;
        ROT: tROTATE;
        SHF: tSHIFT;
        HLT: begin
            mutexLow <= 1'b1; 
            done <= 1'b1;
            end
        CMP: tCOMPLEMENT;
        default: begin //NOP or garbage
            mutexLow <= 1'b1; 
            end 
        endcase
    
    /**************** tasks ****************/
    
    task tCOMPLEMENT;
    begin
        mutexLow = 1'b0; 
        if (`SRCTYPE === IMMTYPE) begin
            `DSTREG = ~{{(BUSW-RINDW){1'b0}},`SRCRIND}; 
        end else begin
            `DSTREG = ~`SRCREG;
        end
        tSETPSR(`DSTREG, 1'b0);
        PCntrNext = PCntr+1;
        mutexLow = 1'b1; 
    end
    endtask

    //implemented as rotate-through-carry since we have the last carry value available from Psr
    task tROTATE;
    reg carry=`CAR;
    integer i;
    begin
        mutexLow=1'b0;
        if (`SHFROTS === 1'b1) begin //negative-- rotate >> right
            for (i=0; i<`SHFROTC; i=i+1) begin
                {`DSTREG, carry} = {carry, `DSTREG}; 
            end
        end else begin //rotate << left
            for (i=0; i<`SHFROTC; i=i+1) begin
                {`DSTREG, carry} = {Reg[fR(`DSTRIND+1)-2:fR(`DSTRIND)], carry, Reg[fR(`DSTRIND+1)-1]};
            end
        end
        tSETPSR(`DSTREG, carry);
        PCntrNext = PCntr+1;
        mutexLow=1'b1;
    end
    endtask


    task tSHIFT;
    reg carry;
    begin
        mutexLow=1'b0;
        if (`SHFROTS === 1'b1) begin //negative-- shift >> right
            carry = 1'b0;
            `DSTREG = `DSTREG >> ((~{`SHFROTS,`SHFROTC})+1);
        end else begin //shift << left
            {carry, `DSTREG} = `DSTREG << `SHFROTC;
        end
        tSETPSR(`DSTREG, carry);
        PCntrNext = PCntr+1;
        mutexLow=1'b1;
    end
    endtask

    
    task tADD;
    reg carry;
    begin
        mutexLow = 1'b0; 
        if (`SRCTYPE === IMMTYPE) begin
            {carry,`DSTREG} = `DSTREG + {{(BUSW-RINDW){1'b0}},`SRCRIND}; 
        end else begin
            {carry,`DSTREG} = `DSTREG + `SRCREG;
        end
        tSETPSR(`DSTREG, carry);
        PCntrNext = PCntr+1;
        mutexLow = 1'b1; 
    end
    endtask
   
    
    task tXOR;
    begin
        mutexLow = 1'b0; 
        if (`SRCTYPE === IMMTYPE) begin
            `DSTREG = `DSTREG ^ {{(BUSW-RINDW){1'b0}},`SRCRIND}; 
        end else begin
            `DSTREG = `DSTREG ^ `SRCREG;
        end
        tSETPSR(`DSTREG, 1'b0);
        PCntrNext = PCntr+1;
        mutexLow = 1'b1; 
    end
    endtask
    

    task tBRANCH;
    begin
        mutexLow = 1'b0;
        case (`CCODE)
        CC_A:  PCntrNext = `DSTMIND;
        CC_C:  PCntrNext = (`CAR === 1'b1 ? `DSTMIND : PCntr+1);
        CC_NC: PCntrNext = (`CAR === 1'b0 ? `DSTMIND : PCntr+1);
        CC_P:  PCntrNext = (`PAR === 1'b1 ? `DSTMIND : PCntr+1);
        CC_E:  PCntrNext = (`EVN === 1'b1 ? `DSTMIND : PCntr+1);
        CC_N:  PCntrNext = (`NEG === 1'b1 ? `DSTMIND : PCntr+1);
        CC_PO: PCntrNext = (`NEG === 1'b0 ? `DSTMIND : PCntr+1);
        CC_Z:  PCntrNext = (`ZER === 1'b1 ? `DSTMIND : PCntr+1);
        endcase
        mutexLow = 1'b1;
    end
    endtask

    
    task tSTORE;
    begin
        mutexLow = 1'b0;
        if (`SRCTYPE === IMMTYPE) begin
            `DSTMEM = {{(BUSW-RINDW){1'b0}},`SRCRIND}; //interpret index as literal value
        end else begin
            `DSTMEM = `SRCREG;
        end 
        tSETPSR(`DSTMEM, 1'b0); 
        PCntrNext = PCntr + 1;
        mutexLow = 1'b1;
    end
    endtask
   
    
    task tLOAD;
    begin   
        mutexLow = 1'b0;
        if (`SRCTYPE === IMMTYPE) begin
            `DSTREG = {{(BUSW-MINDW){1'b0}},`SRCMIND}; //interpret index as literal value
        end else begin
            `DSTREG = `SRCMEM;
        end 
        tSETPSR(`DSTREG, 1'b0); 
        PCntrNext = PCntr + 1;
        mutexLow = 1'b1;
    end
    endtask

    
    task tSETPSR;
    input carry;
    input reg [BUSW-1:0] Val;
    begin
        `CAR = carry; //Carry
        `PAR = fPARITY(Val); //Parity
        `EVN = ~Val[0]; //Even
        `NEG = Val[BUSW-1]; //Negative
        `ZER = (Val === {BUSW{1'b0}} ? 1'b1 : 1'b0); //Zero
    end
    endtask


    /************** functions *****************/

    function [0:0] fPARITY;
    input [BUSW-1:0] Val;
    begin:COUNTPAR
        fPARITY=1'b0;
        integer i;
        for(i=0; i<BUSW; i=i+1) begin
            if (Val[i]) begin
                fPARITY = ~fPARITY;
            end
        end
    end
    endfunction

    function [MINDW-1:0] fLoadProgram;
    input reg [BUSW*-1:0] Arg;
    begin
        Mem[fM(1)-1:fM(0)] = Arg; //arbitrary number between 0 and BUSW-1.
        Mem[fM(2)-1:fM(1)] = 0; //initialize location to store result.
        Mem[fM(3)-1:fM(2)] = {LD,{CCW{1'b0}},SMEMTYPE,REGTYPE,fFitSrcInd(0),fFitDstInd(0)};
        Mem[fM(4)-1:fM(3)] = {LD,{CCW{1'b0}},IMMTYPE,REGTYPE,fFitSrcInd(0),fFitDstInd(1)};
        Mem[fM(5)-1:fM(4)] = {SHF,{CCW{1'b0}},simmtype,regtype,fFitSrcInd(1),fFitDstInd(0)};
        Mem[fM(6)-1:fM(5)] = {BRA,CC_NC,{SRCINDW{1'b0}},fFitDstInd(fM(7))};
        Mem[fM(7)-1:fM(6)] = {ADD,{CCW{1'b0}},IMMTYPE,REGTYPE,fFitSrcInd(1),fFitDstInd(1)};
        Mem[fM(8)-1:fM(7)] = {BRA,CC_Z,{SRCINDW{1'b0}},fFitDstInd(fM(9))};
        Mem[fM(9)-1:fM(8)] = {BRA,CC_A,{SRCINDW{1'b0}},fFitDstInd(fM(4))};
        Mem[fM(10)-1:fM(9)] = {STR,{CCW{1'b0}},REGTYPE,DMEMTYPE,fFitSrcInd(1),fFitDstInd(1)};
        Mem[fM(11)-1:fM(10)] = {HLT,{IRW-OPW{1'b0}}};
        fLoadProgram=fM(2);
    end
    endfunction

    function [SRCINDW-1:0] fFitSrcInd;
    input integer I;
    begin
        fFitSrcInd=I;
    end
    endfunction

    function [DSTINDW-1:0] fFitDstInd;
    input integer I;
    begin
        fFitDstInd=I;
    end
    endfunction

    function [RINDW-1:0] fR;
    input [RINDW-1:0] Ind;
    begin
        fR=BUSW*Ind;
    end
    endfunction

    function [MINDW-1:0] fM;
    input [MINDW-1:0] Ind;
    begin
        fM=BUSW*Ind;
    end
    endfunction

endmodule

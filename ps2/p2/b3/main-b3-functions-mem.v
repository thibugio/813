/* main-b3-functions-mem.v */

module main_b3_functions_mem();
    parameter BUSW=32;
    parameter PSRW=5;
    parameter MINDW=12; //12-bit memory index
    parameter MWORDS=4096; //2**12
    parameter RINDW=4; //4-bit register bank index
    parameter RWORDS=16; //2**4
    parameter IRW=BUSW;
    parameter IR_DSTIND=0;
    parameter IR_SRCIND_CNT=12;
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
    
    reg [BUSW-1:0] Mem[MINDW-1:0]; //RAM memory- array of vectors   
    reg [BUSW-1:0] Reg[RINDW-1:0];
    reg [IRW-1:0] IReg;
    reg [MINDW-1:0] PCntr; //program counter
    reg [PSRW-1:0] Psr;


    `define OPCODE IReg[IR_OP+OPW-1:IR_OP]
    `define CCODE  IReg[IR_CC+CCW-1:IR_CC]
    `define SRCTYPE IReg[IR_SRCTYPE]
    `define DSTTYPE IReg[IR_DSTTYPE]
    `define SRCIMM IReg[IR_SRCIND_CNT+SRCINDW-1:IR_SRCIND_CNT]
    `define SRCMIND IReg[IR_SRCIND_CNT+MINDW-1:IR_SRCIND_CNT]
    `define SRCRIND IReg[IR_SRCIND_CNT+RINDW-1:IR_SRCIND_CNT]
    `define DSTMIND IReg[IR_DSTIND+MINDW-1:IR_DSTIND]
    `define DSTRIND IReg[IR_DSTIND+RINDW-1:IR_DSTIND]
    `define SHFROTS IReg[IR_SRCIND_CNT+CNTW-1]
    `define SHFROTC IReg[IR_SRCIND_CNT+CNTW-2:IR_SRCIND_CNT]
    `define DSTREG Reg[`DSTRIND]
    `define DSTMEM Mem[`DSTMIND]
    `define SRCREG Reg[`SRCRIND]
    `define SRCMEM Mem[`SRCMIND]
    `define CAR Psr[CARRY]
    `define PAR Psr[PARITY]
    `define EVN Psr[EVEN]
    `define NEG Psr[NEGATIVE]
    `define ZER Psr[ZERO]

    reg clk;
    reg done;
    time tstart;
    
    initial begin
        $dumpfile("main.vcd");
        $dumpvars;
    end
    
    initial begin
        begin:CLEARALL
        integer i;
        for (i=0;i<MWORDS;i=i+1) begin
            Mem[i] = {BUSW{1'b0}};
        end
        for (i=0;i<RWORDS;i=i+1) begin
            Reg[i] = {BUSW{1'b0}};
        end
        Psr = {PSRW{1'b0}};
        end //CLEARALL
        
        //load a program into memory
        //returns the memory index of the first instruction as the program counter
        PCntr = fLoadProgram(32'b1001_0010_0100_1001_0010_0100_1001_0010);
        IReg = Mem[PCntr];

        /*begin:PRINT_PROG
        integer i;
        for (i=0; i<11; i=i+1) begin
            tPRINT_IREG;
            PCntr=PCntr+1;
            IReg = Mem[PCntr];
        end
        $finish;
        end //PRINT_PROG*/

        clk = 0;
        done = 1'b0;
        tstart = $time;
        forever begin
            #1 clk = !clk;
        end
    end

    //execute the next instruction
    always @(posedge clk) begin
        case (`OPCODE)
        LD:  PCntr<=fLOAD(1'b1);
        STR: PCntr<=fSTORE(1'b1); 
        BRA: PCntr<=fBRANCH(1'b1); 
        XOR: PCntr<=fXOR(1'b1);
        ADD: PCntr<=fADD(1'b1);
        ROT: PCntr<=fROTATE(1'b1);
        SHF: PCntr<=fSHIFT(1'b1);
        CMP: PCntr<=fCOMPLEMENT(1'b1);
        HLT: done<=1'b1;
        default: PCntr <= PCntr + 1; //NOP
        endcase
    end

    //load the next instruction if cpu has finished executing previous instruction
    always @(PCntr) begin
        IReg = Mem[PCntr];
        tPRINT_IREG;
    end

    always @(*) begin
        if (done) tFINISH;
    end
    
    /**************** functions ****************/


    task tFINISH;
    begin
        $display("Program execution finished.");
        $display("Last value stored: %d \tPsr: %b\nTotal runtime: %t\n\n\n", `DSTREG, Psr, $time-tstart);
        $finish;
    end
    endtask

    
    function fCOMPLEMENT;
    input foo;
    reg ret;
    begin
        if (`SRCTYPE === IMMTYPE) begin
            `DSTREG = ~{{(BUSW-SRCINDW){1'b0}},`SRCIMM}; 
        end else begin
            `DSTREG = ~`SRCREG;
        end
        ret=fSETPSR(`DSTREG, 1'b0);
        fCOMPLEMENT = PCntr+1;
    end
    endfunction

    //implemented as rotate-through-carry since we have the last carry value available from Psr
    function [MINDW-1:0] fROTATE;
    input foo;
    reg carry, ret;
    integer i;
    begin
        carry=`CAR;
        if (`SHFROTS === 1'b1) begin //negative-- rotate >> right
            for (i=0; i<`SHFROTC; i=i+1) begin
                {`DSTREG, carry} = {carry, `DSTREG}; 
            end
        end else begin //rotate << left
            for (i=0; i<`SHFROTC; i=i+1) begin
                {`DSTREG, carry} = {Reg[`DSTRIND][BUSW-2:0], carry, Reg[`DSTRIND][BUSW-1]};
            end
        end
        ret=fSETPSR(`DSTREG, carry);
        fROTATE = PCntr+1;
    end
    endfunction


    function [MINDW-1:0] fSHIFT;
    input foo;
    reg carry, ret;
    begin
        if (`SHFROTS === 1'b1) begin //negative-- shift >> right
            carry = 1'b0;
            `DSTREG = `DSTREG >> ((~{`SHFROTS,`SHFROTC})+1);
        end else begin //shift << left
            carry = Reg[`DSTRIND][BUSW-1];
            `DSTREG = `DSTREG << `SHFROTC;
        end
        ret=fSETPSR(`DSTREG, carry);
        fSHIFT = PCntr+1;
    end
    endfunction

    
    function [MINDW-1:0] fADD;
    input foo;
    reg carry,ret;
    begin
        if (`SRCTYPE === IMMTYPE) begin
            {carry,`DSTREG} = `DSTREG + {{(BUSW-SRCINDW){1'b0}},`SRCIMM};
        end else begin
            {carry,`DSTREG} = `DSTREG + `SRCREG;
        end
        ret=fSETPSR(`DSTREG, carry);
        fADD = PCntr+1;
    end
    endfunction
   
    
    function [MINDW-1:0] fXOR;
    input foo;
    reg ret;
    begin
        if (`SRCTYPE === IMMTYPE) begin
            `DSTREG = `DSTREG ^ {{(BUSW-SRCINDW){1'b0}},`SRCIMM};
        end else begin
            `DSTREG = `DSTREG ^ `SRCREG;
        end
        ret=fSETPSR(`DSTREG, 1'b0);
        fXOR = PCntr+1;
    end
    endfunction
    

    function [MINDW-1:0] fBRANCH;
    input foo;
    begin
        case (`CCODE)
        CC_C:  fBRANCH = (`CAR === 1'b1 ? `DSTMIND : PCntr+1);
        CC_NC: fBRANCH = (`CAR === 1'b0 ? `DSTMIND : PCntr+1);
        CC_P:  fBRANCH = (`PAR === 1'b1 ? `DSTMIND : PCntr+1);
        CC_E:  fBRANCH = (`EVN === 1'b1 ? `DSTMIND : PCntr+1);
        CC_N:  fBRANCH = (`NEG === 1'b1 ? `DSTMIND : PCntr+1);
        CC_PO: fBRANCH = (`NEG === 1'b0 ? `DSTMIND : PCntr+1);
        CC_Z:  fBRANCH = (`ZER === 1'b1 ? `DSTMIND : PCntr+1);
        default:  fBRANCH = `DSTMIND; //CC_A
        endcase
    end
    endfunction

    
    function [MINDW-1:0] fSTORE;
    input foo;
    begin
        if (`SRCTYPE === IMMTYPE) begin
            `DSTMEM = {{(BUSW-SRCINDW){1'b0}},`SRCIMM}; //interpret index as literal value
        end else begin
            `DSTMEM = `SRCREG;
        end 
        Psr = {PSRW{1'b0}};
        fSTORE = PCntr + 1;
    end
    endfunction
   
    
    function [MINDW-1:0] fLOAD;
    input foo;
    reg ret;
    begin   
        if (`SRCTYPE === IMMTYPE) begin
            `DSTREG = {{(BUSW-SRCINDW){1'b0}},`SRCIMM}; //interpret index as literal value
        end else begin
            `DSTREG = `SRCMEM;
        end 
        ret=fSETPSR(`DSTREG, 1'b0); 
        fLOAD = PCntr + 1;
    end
    endfunction

    
    function fSETPSR;
    input carry;
    input reg [BUSW-1:0] Val;
    begin
        `CAR = carry; //Carry
        `PAR = fPARITY(Val); //Parity
        `EVN = ~Val[0]; //Even
        `NEG = Val[BUSW-1]; //Negative
        `ZER = (Val === {BUSW{1'b0}} ? 1'b1 : 1'b0); //Zero
        fSETPSR = 1'b1;
    end
    endfunction


    /************** functions *****************/

    function [0:0] fPARITY;
    input [BUSW-1:0] Val;
    integer i;
    begin
        fPARITY=1'b0;
        for(i=0; i<BUSW; i=i+1) begin
            if (Val[i]) begin
                fPARITY = ~fPARITY;
            end
        end
    end
    endfunction


    function [MINDW-1:0] fLoadProgram;
    input reg [BUSW-1:0] Arg;
    begin
        Mem[0] = Arg; //arbitrary number between 0 and BUSW-1.
        Mem[1] = 0; //initialize location to store result.
        Mem[2] = {LD,SMEMTYPE,REGTYPE,{(CCW-2){1'b0}},fFitSrcInd(0),fFitDstInd(0)};
        Mem[3] = {LD,IMMTYPE,REGTYPE,{(CCW-2){1'b0}},fFitSrcInd(0),fFitDstInd(1)};
        Mem[4] = {SHF,IMMTYPE,REGTYPE,{(CCW-2){1'b0}},fFitSrcInd(1),fFitDstInd(0)};
        Mem[5] = {BRA,CC_NC,{SRCINDW{1'b0}},fFitDstInd(7)};
        Mem[6] = {ADD,IMMTYPE,REGTYPE,{(CCW-2){1'b0}},fFitSrcInd(1),fFitDstInd(1)};
        Mem[7] = {BRA,CC_Z,{SRCINDW{1'b0}},fFitDstInd(9)};
        Mem[8] = {BRA,CC_A,{SRCINDW{1'b0}},fFitDstInd(4)};
        Mem[9] = {STR,REGTYPE,DMEMTYPE,{(CCW-2){1'b0}},fFitSrcInd(1),fFitDstInd(1)};
        Mem[10] = {HLT,{CCW+SRCINDW{1'b0}},Mem[9][IR_DSTIND+DSTINDW-1:IR_DSTIND]};
        fLoadProgram=2;
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


    task tPRINT_IREG;
    begin   
        $display("t=%t, \tPC=%d, \tnext instruction:", $time, PCntr);
        case(`OPCODE)
        LD: begin
            if (`SRCTYPE === IMMTYPE) begin
                $display("LD R%d \'%d\'\n", `DSTRIND, `SRCIMM);
            end else begin
                $display("LD R%d M%d (%d)\n", `DSTRIND, `SRCMIND, `SRCMEM);
            end
            end
        STR: begin
            if (`SRCTYPE === IMMTYPE) begin
                $display("STR M%d \'%d\'\n", `DSTMIND, `SRCIMM);
            end else begin
                $display("STR M%d R%d (%d)\n", `DSTMIND, `SRCRIND, `SRCREG);
            end
            end
        BRA: begin
            case (`CCODE)
            CC_A: $display("BRA: <always> GOTO M%d\n", `DSTMIND);
            CC_P: $display("BRA: <if parity> GOTO M%d\n", `DSTMIND);
            CC_E: $display("BRA: <if even> GOTO M%d\n", `DSTMIND);
            CC_C: $display("BRA: <if carry> GOTO M%d\n", `DSTMIND);
            CC_N: $display("BRA: <if negative> GOTO M%d\n", `DSTMIND);
            CC_Z: $display("BRA: <if zero> GOTO M%d\n", `DSTMIND);
            CC_NC: $display("BRA: <if no carry> GOTO M%d\n", `DSTMIND);
            CC_PO: $display("BRA: <if positive> GOTO M%d\n", `DSTMIND);
            endcase
            end
        XOR: begin
            if (`SRCTYPE === IMMTYPE) begin
                $display("XOR R%d (%d) \'%d\'\n", `DSTRIND, `DSTREG, `SRCIMM);
            end else begin
                $display("XOR R%d (%d) R%d (%d)\n", `DSTRIND, `DSTREG, `SRCRIND, `SRCREG);
            end
            end
        ADD: begin
            if (`SRCTYPE === IMMTYPE) begin
                $display("ADD R%d \'%d\'\n", `DSTRIND, `SRCIMM);
            end else begin
                $display("ADD R%d (%d) R%d (%d)\n", `DSTRIND, `DSTREG, `SRCRIND, `SRCREG);
            end
            end
        ROT: begin
            if (`SHFROTS === 1'b1) begin
                $display("ROT R%d (%d) left %d\n", `DSTRIND, `DSTREG, `SHFROTC);
            end else begin
                $display("ROT R%d (%d) right %d\n", `DSTRIND, `DSTREG, `SHFROTC);
            end
            end
        SHF: begin
            if (`SHFROTS === 1'b1) begin
                $display("SHF R%d (%d) left %d\n", `DSTRIND, `DSTREG, `SHFROTC);
            end else begin
                $display("SHF R%d (%d) right %d\n", `DSTRIND, `DSTREG, `SHFROTC);
            end
            end
        CMP: begin
            if (`SRCTYPE === IMMTYPE) begin
                $display("CMP R%d \'%d\'\n", `DSTRIND, `SRCIMM);
            end else begin
                $display("CMP R%d R%d (%d)\n", `DSTRIND, `SRCRIND, `SRCREG);
            end
            end
        HLT: begin
            $display("HLT\n");
            end
        NOP: begin
            $display("NOP\n");
            end
        endcase
    end
    endtask

endmodule

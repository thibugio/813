/* main-b3-functions-mem.v */

module main_b4();
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
    localparam EOF = -1;
    
//    reg [BUSW-1:0] Mem[MINDW-1:0]; //RAM memory- array of vectors   
//    reg [BUSW-1:0] Reg[RINDW-1:0];
    reg [BUSW-1:0] Mem[MWORDS-1:0];
    reg [BUSW-1:0] Reg[RWORDS-1:0];
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
        $dumpfile("main-b4.vcd");
        $dumpvars;
    end
    
    initial begin:REG_INIT_BLOCK
        integer i;
        reg [MINDW-1:0] PCntrSave;

        for (i=0;i<MWORDS;i=i+1) begin
            #1 Mem[i] = {BUSW{1'b0}};
        end
        for (i=0;i<RWORDS;i=i+1) begin
            #1 Reg[i] = {BUSW{1'b0}};
        end
        Psr = {PSRW{1'b0}};
        
        //load a program into memory
        PCntr = fLoadProgram(32'b1001_0010_0100_1001_0010_0100_1001_0010);
        //PCntrSave = PCntr;
        //for (i=3; i<14; i=i+1) begin
        //    $display("Mem[%d]: %b", i, Mem[i]);
        //    #1 PCntr = PCntr + 1;
        //end
        //PCntr = PCntrSave;
        //$finish;

        
        clk = 0;
        done = 1'b0;
        $display("beginning program executing. PCntr=%d, T=%t\n", PCntr, $time);
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
            $display("taking the CMPlement of %b = %b", {{(BUSW-SRCINDW){1'b0}},`SRCIMM}, `DSTREG);
        end else begin
            `DSTREG = ~`SRCREG;
            $display("taking the CMPlement of %b = %b", `SRCREG, `DSTREG);
        end
        ret=fSETPSR(`DSTREG, 1'b0);
        fCOMPLEMENT = PCntr+1;
    end
    endfunction

    //implemented as rotate-through-carry since we have the last carry value available from Psr
    function [MINDW-1:0] fROTATE;
    input foo;
    reg carry, ret;
    reg [CNTW-2:0] Shift; //lose the upper sign bit
    integer i;
    begin
        carry=`CAR;
        if (`SHFROTS === 1'b1) begin //negative-- rotate >> right
            Shift = ((~{`SHFROTS,`SHFROTC})+1);
            $display("ROTating %b right by %d = ...", `DSTREG, Shift);
            for (i=0; i<Shift; i=i+1) begin
                {`DSTREG, carry} = {carry, `DSTREG}; 
            end
        end else begin //rotate << left
            $display("ROTating %b left by %d = ...", `DSTREG, `SHFROTC);
            for (i=0; i<`SHFROTC; i=i+1) begin
                {`DSTREG, carry} = {Reg[`DSTRIND][BUSW-2:0], carry, Reg[`DSTRIND][BUSW-1]};
            end
        end
        $display("\t...%b with carryout %b", `DSTREG, carry);
        ret=fSETPSR(`DSTREG, carry);
        fROTATE = PCntr+1;
    end
    endfunction


    function [MINDW-1:0] fSHIFT;
    input foo;
    reg carry, ret;
    reg [CNTW-2:0] Shift; //lose the upper sign bit
    begin
        if (`SHFROTS === 1'b1) begin //negative-- shift >> right (divide)
            carry = 1'b0;
            Shift = ((~{`SHFROTS,`SHFROTC})+1);
            $display("SHFting %b >> %d = ...", `DSTREG, Shift);
            `DSTREG = `DSTREG >> Shift;
        end else begin //positive-- shift << left (multiply)
            carry = Reg[`DSTRIND][BUSW-1];
            $display("SHFting %b << %d = ...", `DSTREG, `SHFROTC);
            `DSTREG = `DSTREG << `SHFROTC;
        end
        $display("\t...%b with carryout %b", `DSTREG, carry);
        ret=fSETPSR(`DSTREG, carry);
        fSHIFT = PCntr+1;
    end
    endfunction

    
    function [MINDW-1:0] fADD;
    input foo;
    reg carry,ret;
    begin
        if (`SRCTYPE === IMMTYPE) begin
            $display("ADDing %b + %b = ...", `DSTREG, {{(BUSW-SRCINDW){1'b0}},`SRCIMM});
            {carry,`DSTREG} = `DSTREG + {{(BUSW-SRCINDW){1'b0}},`SRCIMM};
        end else begin
            $display("ADDing %b + %b = ...", `DSTREG, `SRCREG);
            {carry,`DSTREG} = `DSTREG + `SRCREG;
        end
        $display("\t...%b with carryout %b", `DSTREG, carry);
        ret=fSETPSR(`DSTREG, carry);
        fADD = PCntr+1;
    end
    endfunction
   
    
    function [MINDW-1:0] fXOR;
    input foo;
    reg ret;
    begin
        if (`SRCTYPE === IMMTYPE) begin
            $display("XORing %b xor %b = ...", `DSTREG, {{(BUSW-SRCINDW){1'b0}},`SRCIMM});
            `DSTREG = `DSTREG ^ {{(BUSW-SRCINDW){1'b0}},`SRCIMM};
        end else begin
            $display("XORing %b xor %b = ...",`DSTREG, `SRCREG);
            `DSTREG = `DSTREG ^ `SRCREG;
        end
        $display("\t...%b", `DSTREG);
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
        $display("encountered Branch. Next PCntr: %d", fBRANCH);
    end
    endfunction

    
    function [MINDW-1:0] fSTORE;
    input foo;
    begin
        if (`SRCTYPE === IMMTYPE) begin
            `DSTMEM = {{(BUSW-SRCINDW){1'b0}},`SRCIMM}; //interpret index as literal value
            $display("Storing IMMVAL %b into memory slot %d", {{(BUSW-SRCINDW){1'b0}},`SRCIMM}, `DSTMIND);
        end else begin
            `DSTMEM = `SRCREG;
            $display("Loading REGVAL %b into memory slot %d", `SRCREG, `DSTMIND);
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
            $display("Loading IMMVAL %b into register %d", {{(BUSW-SRCINDW){1'b0}},`SRCIMM}, `DSTRIND);
        end else begin
            `DSTREG = `SRCMEM;
            $display("Loading MEMVAL %b into register %d", `SRCMEM, `DSTRIND);
        end 
        ret=fSETPSR(`DSTREG, 1'b0); 
        fLOAD = PCntr + 1;
    end
    endfunction

    
    function fSETPSR;
    input reg [BUSW-1:0] Val;
    input carry;
    begin
        `CAR = carry; //Carry
        `PAR = fPARITY(Val); //Parity
        `EVN = ~Val[0]; //Even
        `NEG = Val[BUSW-1]; //Negative
        `ZER = (Val === {BUSW{1'b0}} ? 1'b1 : 1'b0); //Zero
        fSETPSR = 1'b1;
        $display("Psr for Val %b: Carry=%b, Parity=%b, Even=%b, Negative=%b, Zero=%b", Val, `CAR, `PAR, `EVN, `NEG, `ZER);
    end
    endfunction


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
        /*Mem[0] = Arg; //arbitrary number between 0 and BUSW-1.
        Mem[1] = 0; //initialize location to store result.
        Mem[2] = {LD,SMEMTYPE,REGTYPE,{(CCW-2){1'b0}},fFitSrcInd(0),fFitDstInd(0)};
        Mem[3] = {LD,IMMTYPE,REGTYPE,{(CCW-2){1'b0}},fFitSrcInd(0),fFitDstInd(1)};
        Mem[4] = {SHF,IMMTYPE,REGTYPE,{(CCW-2){1'b0}},fFitSrcInd(1),fFitDstInd(0)};
        Mem[5] = {BRA,CC_NC,{SRCINDW{1'b0}},fFitDstInd(7)};
        Mem[6] = {ADD,IMMTYPE,REGTYPE,{(CCW-2){1'b0}},fFitSrcInd(1),fFitDstInd(1)};
        Mem[7] = {BRA,CC_Z,{SRCINDW{1'b0}},fFitDstInd(9)};
        Mem[8] = {BRA,CC_A,{SRCINDW{1'b0}},fFitDstInd(4)};
        Mem[9] = {STR,REGTYPE,DMEMTYPE,{(CCW-2){1'b0}},fFitSrcInd(1),fFitDstInd(1)};
        Mem[10] = {HLT,REGTYPE,DMEMTYPE,{(CCW-2){1'b0}},fFitSrcInd(1),fFitDstInd(1)};
        fLoadProgram=2;*/
        $display("initializing program. T=%t", $time);
        Mem[0] = Arg;
        Mem[1] = 0;
        Mem[2] = {BUSW{1'b1}};
        Mem[3] = {LD, SMEMTYPE, REGTYPE, {(CCW-2){1'b0}}, fFitSrcInd(0), fFitDstInd(0)};
        Mem[4] = {LD, SMEMTYPE, REGTYPE, {(CCW-2){1'b0}}, fFitSrcInd(1), fFitDstInd(1)};
        Mem[5] = {LD, SMEMTYPE, REGTYPE, {(CCW-2){1'b0}}, fFitSrcInd(2), fFitDstInd(2)};
        Mem[6] = {SHF, IMMTYPE, REGTYPE, {(CCW-2){1'b0}}, 12'b0000_0000_0001, fFitDstInd(0)};
        Mem[7] = {BRA, CC_NC, fFitSrcInd(0), fFitDstInd(9)};
        Mem[8] = {ADD, IMMTYPE, REGTYPE, {(CCW-2){1'b0}}, fFitSrcInd(1), fFitDstInd(1)};
        Mem[9] = {SHF, IMMTYPE, REGTYPE, {(CCW-2){1'b0}}, {12{1'b1}}, fFitDstInd(2)};
        Mem[10] = {BRA, CC_Z, fFitSrcInd(0), fFitDstInd(12)};
        Mem[11] = {BRA, CC_A, fFitSrcInd(0), fFitDstInd(6)};
        Mem[12] = {STR, REGTYPE, DMEMTYPE, {(CCW-2){1'b0}}, fFitSrcInd(1), fFitDstInd(1)};
        Mem[13] = {HLT, REGTYPE, DMEMTYPE, {(CCW-2){1'b0}}, fFitSrcInd(1), fFitDstInd(1)};

        /*Mem[0] = 32'b1001_0010_0100_1001_0010_0100_1001_0010;
        Mem[1] = 32'b0000_0000_0000_0000_0000_0000_0000_0000;
        Mem[2] = 32'b1111_1111_1111_1111_1111_1111_1111_1111;
        Mem[3] = 32'b0001_0000_0000_0000_0001_0000_0000_0001;
        Mem[4] = 32'b0001_0000_0000_0000_0010_0000_0000_0010;
        Mem[5] = 32'b0001_0000_0000_0000_0011_0000_0000_0011;
        Mem[6] = 32'b0111_1000_0000_0000_0001_0000_0000_0000;
        Mem[7] = 32'b0011_0110_0000_0000_0000_0000_0000_0000;
        Mem[8] = 32'b0101_1000_0000_0000_0001_0000_0000_0001;
        Mem[9] = 32'b0111_1000_1111_1111_1111_0000_0000_0010;
        Mem[10] = 32'b0011_0101_0000_0000_0000_0000_0000_1100;
        Mem[11] = 32'b0011_0000_0000_0000_0000_0000_0000_0110;
        Mem[12] = 32'b0010_0100_0000_0000_0001_0000_0000_0001;
        Mem[13] = 32'b1000_0100_0000_0000_0001_0000_0000_0001;*/
        fLoadProgram = 3;
        $display("done initializing program. T=%t", $time);
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
                $display("LD R%d \'%b\'\n", `DSTRIND, `SRCIMM);
            end else begin
                $display("LD R%d M%d (%b)\n", `DSTRIND, `SRCMIND, `SRCMEM);
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
        ROT: begin:DISP_ROT
            reg [CNTW-2:0] Shift;
            if (`SHFROTS === 1'b1) begin //negative-- right (divide)
                Shift = (~{`SHFROTS,`SHFROTC})+1;
                $display("ROT R%d (%d) right %d\n", `DSTRIND, `DSTREG, Shift);
            end else begin
                $display("ROT R%d (%d) left %d\n", `DSTRIND, `DSTREG, `SHFROTC);
            end
            end
        SHF: begin:DIST_SHF
            reg [CNTW-2:0] Shift;
            if (`SHFROTS === 1'b1) begin
                Shift = (~{`SHFROTS,`SHFROTC})+1;
                $display("SHF R%d (%d) right %d\n", `DSTRIND, `DSTREG, Shift);
            end else begin
                $display("SHF R%d (%d) left %d\n", `DSTRIND, `DSTREG, `SHFROTC);
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
        default: $display("No match. IReg contains %b", IReg);
        endcase
    end
    endtask

endmodule

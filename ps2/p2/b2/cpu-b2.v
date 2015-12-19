/* cpu-b2.v: responsible for executing instructions for the processor */
//search README
module cpu(clk, IReg, PsrIn, mutexLow, PsrOut, DstVal);
    // these need to be passed in!
    parameter BUSW=1;
    parameter PSRW=1;
    parameter REGTYPE=1'b1;
    parameter MEMTYPE=1'b1;
    parameter IMMTYPE=1'b1;
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
    parameter OPW = 1;
    parameter CCW = 1;
    parameter CNTW = 1;
    parameter IRW=1;
    parameter IR_SRCIND_CNT=1;
    parameter IR_DSTIND=1;
    parameter IR_DSTTYPE=1;
    parameter IR_SRCTYPE=1;
    parameter IR_CC=1;
    parameter IR_OP=1;

    localparam CC_A = 4'b0000, //always
               CC_P = 4'b0001, //parity
               CC_E = 4'b0010, //even
               CC_C = 4'b0011, //carry
               CC_N = 4'b0100, //negative
               CC_Z = 4'b0101, //zero
               CC_NC = 4'b0110, //no carry
               CC_PO = 4'b0111; //positive
    localparam MINDW=12; //12-bit memory addresses
    localparam MWORDS=4096; //2**MINDW
    localparam RINDW=4;  //4-bit register bank addresses
    localparam RWORDS=16; //2**RINDW
    
    input clk;
    input reg [IRW-1:0] IReg;
    input reg [PSRW-1:0] PsrIn;

    output reg [0:0] mutexLow;
    output reg [PSRW-1:0] PsrOut;
    output reg [BUSW-1:0] DstVal;


    reg [BUSW-1:0] DbusIn;  //convenience variable for operations
    reg [BUSW*MWORDS-1:0] Mem;  //RAM memory array
    reg [BUSW*RWORDS-1:0] Reg;  //Register Bank


    always @(posedge clk) begin
        if (IReg[IR_DSTTYPE] === MEMTYPE) begin
            DstVal <= Mem[BUSW*IReg[IR_DSTIND+MINDW-1:IR_DSTIND]-1 : (BUSW-1)*IReg[IR_DSTIND+MINDW-1:IR_DSTIND]];
        end
        if (IReg[IR_OP+OPW-1:IR_OP] === HLT) begin
            mutexLow <= 1'b1; //release
        end else begin
            mutexLow <= 1'b0; //hold
        end
    end
    
    
    always @(posedge clk) begin
        case (IReg[IR_OP+OPW-1:IR_OP])
        NOP: begin:NO_OP
            end
        LD: begin
            //fLOAD(SrcMemVal, DstRegInd, srcType)
            PsrOut = fLOAD(IReg[IR_SRCIND_CNT+MINDW-1:IR_SRCIND_CNT],
                           IReg[IR_DSTIND+RINDW-1:IR_DSTIND], 
                           IReg[IR_SRCTYPE]);
            end
        STR: begin
            //fSTORE(SrcRegIndOrVal, DstMemInd, srcType)
            PsrOut = fSTORE(IReg[IR_SRCIND_CNT+MINDW-1:IR_SRCIND_CNT],
                            IReg[IR_DSTIND+MINDW-1:IR_DSTIND], 
                            IReg[IR_SRCTYPE]);
            end
        BRA: begin
            //fBRANCH(CondCode, DstMemInd)
            PsrOut = fBRANCH(IReg[IR_CC+CCW-1:IR_CC], 
                             IReg[IR_DSTIND+MINDW-1:IR_DSTIND]);
            end
        XOR: begin
            //fXOR(SrcRegIndOrVal, DstRegInd, srcType)
            PsrOut = fXOR(IReg[IR_SRCIND_CNT+MINDW-1:IR_SRCIND_CNT],
                          IReg[IR_DSTIND+RINDW-1:IR_DSTIND],
                          IReg[IR_SRCTYPE]);
            end
        ADD: begin
            //fADD(SrcRegIndOrVal, DstRegInd, srcType)
            PsrOut = fADD(IReg[IR_SRCIND_CNT+MINDW-1:IR_SRCIND_CNT],
                          IReg[IR_DSTIND+RINDW-1:IR_DSTIND],
                          IReg[IR_SRCTYPE]);
            end
        ROT: begin
            //fROTATE(RotCnt, DstRegInd)
            PsrOut = fROTATE(IReg[IR_SRCIND_CNT+CNTW-1:IR_SRCIND_CNT],
                             IReg[IR_DSTIND+RINDW-1:IR_DSTIND]);
            end
        SHF: begin
            //fSHIFT(ShiftCnt, DstRegInd)
            PsrOut = fSHIFT(IReg[IR_SRCIND_CNT+CNTW-1:IR_SRCIND_CNT],
                             IReg[IR_DSTIND+RINDW-1:IR_DSTIND]);
            end
        HLT: begin
            end
        CMP: begin
            //fCOMPLEMENT(SrcRegIndOrVal, DstRegInd, srcType)
            PsrOut = fCOMPLEMENT(IReg[IR_SRCIND_CNT+MINDW-1:IR_SRCIND_CNT],
                          IReg[IR_DSTIND+RINDW-1:IR_DSTIND],
                          IReg[IR_SRCTYPE]);
            end
        default: NO_OP;
        endcase //Opcode (IReg[31:28])
    end //always@(posedge clk)
    
    //README: difference between shift and rotate? 
    function [PSRW-1:0] fROTATE;
    input [CNTW-1:0] RotCnt;
    input [RINDW-1:0] DstRegInd;
    begin
        reg carry;
        if (RotCnt[CNTW-1] === 1'b1) begin //negative
            carry = 1'b0;
            Reg[BUSW*DstRegInd-1:(BUSW-1)*DstRegInd] =
                Reg[BUSW*DstRegInd-1:(BUSW-1)*DstRegInd] >> ((~RotCnt)+1);
        end else begin
            {carry, Reg[BUSW*DstRegInd-1:(BUSW-1)*DstRegInd]} =
                Reg[BUSW*DstRegInd-1:(BUSW-1)*DstRegInd] << RotCnt;
        end
        fROTATE = fPSR(Reg[BUSW*DstRegInd-1:(BUSW-1)*DstRegInd],carry);
    end
    endfunction

    
    function [PSRW-1:0] fSHIFT;
    input [CNTW-1:0] ShiftCnt;
    input [RINDW-1:0] DstRegInd;
    begin
        reg carry;
        if (ShiftCnt[CNTW-1] === 1'b1) begin //negative
            carry = 1'b0;
            Reg[BUSW*DstRegInd-1:(BUSW-1)*DstRegInd] =
                Reg[BUSW*DstRegInd-1:(BUSW-1)*DstRegInd] >> ((~ShiftCnt)+1);
        end else begin
            {carry, Reg[BUSW*DstRegInd-1:(BUSW-1)*DstRegInd]} =
                Reg[BUSW*DstRegInd-1:(BUSW-1)*DstRegInd] << ShiftCnt;
        end
        fSHIFT = fPSR(Reg[BUSW*DstRegInd-1:(BUSW-1)*DstRegInd],carry);
    end
    endfunction

  
    function [PSRW-1:0] fCOMPLEMENT;
    input [MINDW-1:0] SrcRegIndOrVal;
    input [RINDW-1:0] DstRegInd;
    input srcType;
    begin
        if (srcType === IMMTYPE) begin
            DbusIn = {{(BUSW-MINDW){1'b0}},SrcRegIndOrVal};
        end else begin
            DbusIn = Reg[BUSW*SrcRegIndOrVal-1:(BUSW-1)*SrcRegIndOrVal];
        end
        Reg[BUSW*DstRegInd-1:(BUSW-1)*DstRegInd] = ~DbusIn;
        fCOMPLEMENT = fPSR(Reg[BUSW*DstRegInd-1:(BUSW-1)*DstRegInd],1'b0);
    end
    endfunction


    function [PSRW-1:0] fADD;
    input [MINDW-1:0] SrcRegIndOrVal;
    input [RINDW-1:0] DstRegInd;
    input srcType;
    begin
        reg carry;
        if (srcType === IMMTYPE) begin
            DbusIn = {{(BUSW-MINDW){1'b0}},SrcRegIndOrVal};
        end else begin
            DbusIn = Reg[BUSW*SrcRegIndOrVal-1:(BUSW-1)*SrcRegIndOrVal];
        end
        //README: 2's complement?
        {carry, Reg[BUSW*DstRegInd-1:(BUSW-1)*DstRegInd]} =
            Reg[BUSW*DstRegInd-1:(BUSW-1)*DstRegInd] + 
            DbusIn + 
            PsrIn[0]; //carry-in
        fADD = fPSR(Reg[BUSW*DstRegInd-1:(BUSW-1)*DstRegInd],carry);
    end
    endfunction
    
    
    function [PSRW-1:0] fXOR;
    input [MINDW-1:0] SrcRegIndOrVal;
    input [RINDW-1:0] DstRegInd;
    input srcType;
    begin
        if (srcType === IMMTYPE) begin
            DbusIn = {{(BUSW-MINDW){1'b0}},SrcRegIndOrVal};
        end else begin
            DbusIn = Reg[BUSW*SrcRegIndOrVal-1:(BUSW-1)*SrcRegIndOrVal];
        end
        Reg[BUSW*DstRegInd-1:(BUSW-1)*DstRegInd] =
            Reg[BUSW*DstRegInd-1:(BUSW-1)*DstRegInd] ^ DbusIn;
        fXOR = fPSR(Reg[BUSW*DstRegInd-1:(BUSW-1)*DstRegInd],1'b0);
    end
    endfunction


    function [PSRW-1:0] fBRANCH;
    input [CCW-1:0] CondCode;
    input [MINDW-1:0] DstMemInd;
    begin
        reg setBit=1'b0;
        case (CondCode)
        CC_A: begin
            setBit = 1'b1;
            end
        CC_P: begin
            setBit = PsrOut[1];
            end
        CC_E: begin
            setBit = PsrOut[2];
            end
        CC_C: begin
            setBit = PsrOut[0];
            end
        CC_N: begin
            setBit = PsrOut[3];
            end
        CC_Z: begin
            setBit = PsrOut[4];
            end
        CC_NC: begin
            setBit = ~PsrOut[0];
            end
        CC_PO: begin
            setBit = ~PsrOut[3];
            end
        endcase
        Mem[BUSW*DstMemInd-1:(BUSW-1)*DstMemInd] = {{(BUSW-1){1'b0}},setBit};
        fBRANCH = PsrOut;
    end
    endfunction


    function [PSRW-1:0] fSTORE;
    input [MINDW-1:0] SrcRegIndOrVal;
    input [MINDW-1:0] DstMemInd;
    input srcType;
    begin
        if (srcType === IMMTYPE) begin
            DbusIn = {{(BUSW-MINDW){1'b0}},SrcRegIndOrVal};
        end else begin
            DbusIn = Reg[BUSW*SrcRegIndOrVal-1:(BUSW-1)*SrcRegIndOrVal];
        end
        Mem[BUSW*DstMemInd-1:(BUSW-1)*DstMemInd] = DbusIn;
        fSTORE = {PSRW{1'b0}};
    end
    endfunction
    
    function [PSRW-1:0] fLOAD;
    input [MINDW-1:0] SrcMemIndOrVal;
    input [RINDW-1:0] DstRegInd;
    input srcType;
    begin
        if (srcType === IMMTYPE) begin
            DbusIn = {{(BUSW-MINDW){1'b0}},SrcMemIndOrVal}; //lit val
        end else begin
            DbusIn = Mem[BUSW*SrcMemIndOrVal-1:(BUSW-1)*SrcMemIndOrVal]; 
        end 
        Reg[BUSW*DstRegInd-1:(BUSW-1)*DstRegInd] = DbusIn;
        fLOAD = fPSR(DbusIn, 1'b0);
    end
    endfunction

    function [PSRW-1:0] fPSR;
    input [BUSW-1:0] Val;
    input carry;
    begin
        fPSR[0] = carry; //Carry
        fPSR[1] = fPARITY(Val); //Parity
        fPSR[2] = ~Val[0]; //Even
        fPSR[3] = Val[BUSW-1]; //Negative
        fPSR[4] = (Val === {BUSW{1'b0}} ? 1'b1 : 1'b0); //Zero
    end
    endfunction

    function [0:0] fPARITY;
    input [BUSW-1:0] Val;
    begin
        fPARITY=0;
        for(i=0; i<BUSW; i=i+1) begin
            if (Val[i]) begin
                fPARITY = ~fPARITY;
            end
        end
    end
    endfunction

/*
    function [VBITS-1:0] f2s;
    input [VBITS-1:0] Val;
    parameter VBITS=1;
    begin
        f2s = (~Val) + 1;
    end
    endfunction
*/
 
endmodule

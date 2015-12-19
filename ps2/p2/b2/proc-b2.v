/* proc-b2.v: top level module for the 10-instruction processor */
module proc(clk, Opcode, DstOp, SrcOp, srcIsImm, Res, resvalid, PsrOut);
    parameter BUSW=1; //these need to be passed in!
    parameter PSRW=1;
    parameter OPW=1;
    parameter CCW=1;
    parameter CNTW=1;
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
   
    localparam REGTYPE=1'b0;
    localparam MEMTYPE=1'b1;
    localparam IMMTYPE=1'b1;
    localparam IRW=32;
    localparam IR_SRCIND_CNT=12;
    localparam IR_DSTIND=0;
    localparam IR_DSTTYPE=26;
    localparam IR_SRCTYPE=27;
    localparam IR_CC=24;
    localparam IR_OP=28;

    input clk, srcIsImm;
    input reg[OPW-1:0] Opcode;
    input reg[BUSW-1:0] DstOp, SrcOp;

    output resvalid; 
    output reg [BUSW-1:0] Res; 
    output reg [PSRW-1:0] PsrOut;
   
    
    reg [IRW-1:0] IReg; //insruction register
    reg [PSRW-1:0] PsrIn;
    
    
    cpu #(BUSW, PSRW, REGTYPE, MEMTYPE, IMMTYPE, NOP, LD, STR, BRA, XOR, ADD, ROT, SHF, HLT, CMP, OPW, CCW, CNTW, IRW, IR_SRCIND_CNT, IR_DSTIND, IR_DSTTYPE, IR_SRCTYPE, IR_CC, IR_OP) cpu0(.clk(clk), .IReg(IReg), .PsrIn(PsrIn), .mutexLow(resvalid), .PsrOut(PsrOut), .DstVal(Res));

    always @(posedge clk) begin
        PsrIn <= PsrOut;
    end

    always @(posedge clk) begin
        //populate instruction register based on opcode, dst, src 
        case (Opcode)
        NOP: begin:NO_OPERATION
            IReg[IRW-1:IR_OP] <= NOP;
            end
        LD: begin:LOAD
            IReg[IRW-1:IR_OP] <= LD;
            IReg[IR_SRCTYPE] <= (srcIsImm ? IMMTYPE : REGTYPE);
            IReg[IR_DSTTYPE] <= REGTYPE; 
            IReg[IR_SRCIND_CNT+MINDW-1:IR_SRCIND_CNT] <= SrcOp; 
            IReg[IR_DSTIND+MINDW-1:IR_DSTIND] <= DstOp;  
            end
        STR: begin:STORE
            IReg[IRW-1:IR_OP] <= STR;
            IReg[IR_SRCTYPE] <= (srcIsImm ? IMMTYPE : REGTYPE); 
            IReg[IR_DSTTYPE] <= MEMTYPE; 
            IReg[IR_SRCIND_CNT+MINDW-1:IR_SRCIND_CNT] <= SrcOp; 
            IReg[IR_DSTIND+MINDW-1:IR_DSTIND] <= DstOp;  
            end
        BRA: begin:BRANCH
            IReg[IRW-1:IR_OP] <= BRA;
            IReg[IR_DSTTYPE] <= MEMTYPE;
            IReg[IR_CC+CCW-1:IR_CC] <= SrcOp[CCW-1:0]; 
            IReg[IR_DSTIND+MINDW-1:IR_DSTIND] <= DstOp;  
            end
        XOR: begin:EXCLUSIVE_OR
            IReg[IRW-1:IR_OP] <= XOR;
            IReg[IR_SRCTYPE] <= (srcIsImm ? IMMTYPE : REGTYPE); 
            IReg[IR_DSTTYPE] <= REGTYPE; 
            IReg[IR_SRCIND_CNT+MINDW-1:IR_SRCIND_CNT] <= SrcOp; 
            IReg[IR_DSTIND+MINDW-1:IR_DSTIND] <= DstOp;  
            end
        ADD: begin:ADDITION
            IReg[IRW-1:IR_OP] <= ADD;
            IReg[IR_SRCTYPE] <= (srcIsImm ? IMMTYPE : REGTYPE); 
            IReg[IR_DSTTYPE] <= REGTYPE; 
            IReg[IR_SRCIND_CNT+MINDW-1:IR_SRCIND_CNT] <= SrcOp; 
            IReg[IR_DSTIND+MINDW-1:IR_DSTIND] <= DstOp;  
            end
        ROT: begin:ROTATE
            IReg[IRW-1:IR_OP] <= ROT;
            IReg[IR_SRCTYPE] <= IMMTYPE; 
            IReg[IR_DSTTYPE] <= REGTYPE;
            IReg[IR_SRCIND_CNT+MINDW-1:IR_SRCIND_CNT] <= SrcOp; 
            IReg[IR_DSTIND+MINDW-1:IR_DSTIND] <= DstOp;  
            end
        SHF: begin:SHIFT
            IReg[IRW-1:IR_OP] <= SHF;
            IReg[IR_SRCTYPE] <= IMMTYPE; 
            IReg[IR_DSTTYPE] <= REGTYPE;
            IReg[IR_SRCIND_CNT+MINDW-1:IR_SRCIND_CNT] <= SrcOp; 
            IReg[IR_DSTIND+MINDW-1:IR_DSTIND] <= DstOp;  
            end
        HLT: begin:HALT
            IReg[IRW-1:IR_OP] <= HLT;
            end
        CMP: begin COMPLEMENT
            IReg[IRW-1:IR_OP] <= CMP; 
            IReg[IR_SRCTYPE] <= (srcIsImm ? IMMTYPE : REGTYPE); 
            IReg[IR_DSTTYPE] <= REGTYPE; 
            IReg[IR_SRCIND_CNT+MINDW-1:IR_SRCIND_CNT] <= SrcOp; 
            IReg[IR_DSTIND+MINDW-1:IR_DSTIND] <= DstOp;  
            end
        default: NO_OPERATION; 
        endcase
    end

endmodule

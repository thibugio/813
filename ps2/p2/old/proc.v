/* proc.v: top level module for the 10-instruction processor */
module proc(clk, Opcode, DstOp, SrcOp, dstIsReg, srcIsImm, Res, resvalid, Status);
    parameter BUSW=12; //this many bits on the bus
    parameter MWORDS=8;  //this many words (of length busw) in the memory
    parameter RWORDS=8;  //this many words (of length busw) in the register
    parameter PSRW=5;  //this many status codes
    localparam MINDW=$bits(MWORDS);    //mem index needs to be this many bits to cover all ram words
    localparam RINDW=$bits(RWORDS);
    localparam REGTYPE=1'b0;
    localparam IMMTYPE=1'b1;
    localparam REN=1'b0;
    localparam WEN=1'b1;
    localparam NOP = 4'b0000,
               LD  = 4'b0001,
               STR = 4'b0010,
               BRA = 4'b0011,
               XOR = 4'b0100,
               ADD = 4'b0101,
               ROT = 4'b0110,
               SHF = 4'b0111,
               HLT = 4'b1000,
               CMP = 4'b1001;

    input clk, dstIsReg, srcIsImm;
    input reg[3:0] Opcode; //opcode
    input reg[BUSW-1:0] DstOp, SrcOp;

    output resvalid; //flag when the result returned by the instruction (if any) is valid
    output reg [BUSW-1:0] Res;  //result of the instruction, if any. convenience variable for testbench.
    output reg [PSRW-1:0] Status; //error code, i.e., psr


   
    reg [31:0] IReg; //insruction register
    reg [BUSW-1:0] MemDbusIn, MemDbusOut, RegDbusIn, RegDbusOut;
    reg [MINDW-1:0] MemInd; 
    reg [RINDW-1:0] RegInd;
    reg memrwen, regrwen, mutexLow;
    wire [PSRW-1:0] StatusLast;

    assign StatusLast = Status;

    ram mem0(MemDbusIn, memrwen, MemInd, MemDbusOut);
    
    regbank reg0(RegDbusIn, regrwen, RegInd, RegDbusOut);
    
    cpu cpu0 #(BUSW, MINDW, RINDW, PSRW, REGTYPE, IMMTYPE, REN, WEN, NOP, LD, STR, BRA, XOR, ADD, ROT, SHF, HLT, CMP) (.clk(clk), .IReg(IReg), .dstIsReg(dstIsReg), .PsrIn(StatusLast), .MemDbusIn(MemDbusIn), .RegDbusIn(RegDbusIn), .mutexLow(mutexLow), .PsrOut(Status), .mrwen(memrwen), .rrwen(regrwen), .MemInd(MemInd), .RegInd(RegInd), .MemDbusOut(MemDbusOut), .RegDbusOut(RegDbusOut));

    always @(posedge mutexLow) begin
        case (dstIsReg) 
        1'b1: begin
            regrwen <= REN;
            RegInd <= DstOp[RINDW-1:0];
            @(posedge clk) begin
                resvalid <= 1'b1; 
                Res <= RegDbusOut;
            end
            end
        1'b0: begin
            memrwen <= REN;
            MemInd <= DstOp[MINDW-1:0];
            @(posedge clk) begin
                resvalid <= 1'b1;
                Res <= MemDbusOut;
            end
            end
        endcase
    end

    always @(posedge clk) begin
        //populate instruction register based on opcode (instdst, src)
        case (Opcode)
        NOP: begin:NO_OPERATION
            IReg[31:28] <= NOP;
            end
        LD: begin:LOAD
            IReg[31:28] <= LD;
            IReg[27] <= (srcIsImm ? IMMTYPE : REGTYPE); //src-- mem1 (mem index or immediate val)
            IReg[26] <= REGTYPE; //dst
            IReg[23:12] <= SrcOp; // src addr, imm value, shift/rot count
            IReg[11:0] <= DstOp;  //dst addr
            end
        STR: begin:STORE
            IReg[31:28] <= STR;
            IReg[27] <= (srcIsImm ? IMMTYPE : REGTYPE); //src-- src (reg index or immediate val)
            IReg[26] <= REGTYPE; //dst
            IReg[23:12] <= SrcOp; // src addr, imm value, shift/rot count
            IReg[11:0] <= DstOp;  //dst addr
            end
        BRA: begin:BRANCH
            IReg[31:28] <= BRA;
            IReg[27] <= 0'b0;  
            IReg[26:24] <= SrcOp[2:0]; //condition code
            IReg[11:0] <= DstOp;  //dst addr
            end
        XOR: begin:EXCLUSIVE_OR
            IReg[31:28] <= XOR;
            IReg[27] <= (srcIsImm ? IMMTYPE : REGTYPE); //src-- src (reg index or immediate val)
            IReg[26] <= REGTYPE; //dst
            IReg[23:12] <= SrcOp; // src addr, imm value, shift/rot count
            IReg[11:0] <= DstOp;  //dst addr
            end
        ADD: begin:ADDITION
            IReg[31:28] <= ADD;
            IReg[27] <= (srcIsImm ? IMMTYPE : REGTYPE); //src-- src (reg index or immediate val)
            IReg[26] <= REGTYPE; //dst
            IReg[23:12] <= SrcOp; // src addr, imm value, shift/rot count
            IReg[11:0] <= DstOp;  //dst addr
            end
        ROT: begin:ROTATE
            IReg[31:28] <= ROT;
            IReg[27] <= IMMTYPE; //src-- rotate count
            IReg[26] <= REGTYPE; //dst
            IReg[23:12] <= SrcOp; // src addr, imm value, shift/rot count
            IReg[11:0] <= DstOp;  //dst addr
            end
        SHF: begin:SHIFT
            IReg[31:28] <= SHF;
            IReg[27] <= IMMTYPE; //src-- shift count
            IReg[26] <= REGTYPE; //dst
            IReg[23:12] <= SrcOp; // src addr, imm value, shift/rot count
            IReg[11:0] <= DstOp;  //dst addr
            end
        HLT: begin:HALT
            IReg[31:28] <= HLT;
            end
        CMP: begin COMPLEMENT
            IReg[31:28] <= CMP; 
            IReg[27] <= REGTYPE; //src
            IReg[26] <= (srcIsImm ? IMMTYPE : REGTYPE); //src-- src (reg index or immediate val)
            IReg[23:12] <= SrcOp; // src addr, imm value, shift/rot count
            IReg[11:0] <= DstOp;  //dst addr
            end
        default: begin
            IReg[31:28] <= NOP;
            end
        endcase
    end


endmodule

/* proc.v: top level module for the 10-instruction processor */
module proc(clk, Opcode, DstOp, SrcOp, srcIsImm, Res, resvalid, Status);
    parameter BUSW=32; //this many bits on the bus
    parameter PSRW=5;  //this many status codes
    localparam MINDW=12;    //12 bit index into memory (stores up to 4096 32-bit words)
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

    input clk, srcIsImm;
    input reg[3:0] Opcode; //opcode
    input reg[BUSW-1:0] DstOp, SrcOp;

    output resvalid; //flag when the result returned by the instruction (if any) is valid
    output reg [BUSW-1:0] Res;  //result of the instruction, if any. convenience variable for testbench.
    output reg [PSRW-1:0] Status; //psr


   
    reg [31:0] IReg; //insruction register
    
    wire [BUSW-1:0] Cpu_MemDbusOut;
    wire [BUSW-1:0] Proc_MemDbusOut;
    
    wire [MINDW-1:0] Cpu_MemInd; 
    reg [MINDW-1:0] Proc_MemInd; 
    
    wire cpu_mrwen, mutexLow;
    reg proc_mrwen;
    
    reg [PSRW-1:0] PsrLast;

    
    
    ram mem0(Cpu_MemDbusOut, proc_mrwen, Proc_MemInd, Proc_MemDbusOut);
    
    cpu cpu0 #(BUSW, MINDW, PSRW, REGTYPE, IMMTYPE, REN, WEN, NOP, LD, STR, BRA, XOR, ADD, ROT, SHF, HLT, CMP) (.clk(clk), .IReg(IReg), .PsrIn(PsrLast), .MemDbusIn(Proc_MemDbusOut), .mutexLow(mutexLow), .PsrOut(Status), .mrwen(cpu_mrwen), .MemInd(Cpu_MemInd), .MemDbusOut(Cpu_MemDbusOut));

    always @(posedge clk) begin
        case (mutexLow)
        1'b0: begin  //cpu in control of memory
            proc_mrwen <= cpu_mrwen;
            Proc_MemInd <= Cpu_MemInd;
            end
        1'b1: begin
            case (Opcode) 
            STR, BRA, HLT: begin
                proc_mrwen <= REN;
                Proc_MemInd <= DstOp[MINDW-1:0];
                @(posedge clk) begin
                    resvalid <= 1'b1;
                    Res <= Proc_MemDbusOut;
                    end
                end
            default: begin
                resvalid <= 1'b0;
                end
            endcase //Opcode
        endcase //mutexLow
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

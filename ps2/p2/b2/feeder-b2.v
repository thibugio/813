module feeder(clk, Program, Res, done):
    parameter BUSW=1; 
    parameter PROGLEN=1; //these need to be passed in!
    parameter PLLEN=1; //length of each line in the program
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
    parameter OPW=1; 
   
    localparam PSRW=5;  //this many status codes
    localparam CCW=4; //condition code bit-width
    localparam CNTW=5; //shift-rotate count bit-width
    
    input clk;
    input reg [PLLEN*PROGLEN-1:0] Program; 
    output reg [BUSW-1:0] Res; //if any
    output done;
    
    unsigned integer PC=0;  //program counter
    
    reg [OPW-1:0] OpCode;
    reg [BUSW-1:0] DstOp, SrcOp;
    reg srcIsLitVal;
    wire [PSRW-1:0] Status;
    wire [BUSW-1:0] Res;

    //README: probably don't need to output PSR from processor
    proc #(BUSW, PSRW, OPW, CCW, CNTW, NOP, LD, STR, BRA, XOR, ADD, ROT, SHF, HLT, CMP) proc0(.clk(clk), .OpCode(OpCode), .DstOp(DstOp), .SrcOp(SrcOp), .srcIsImm(srcIsLitVal), .Res(Res), .resvalid(done), .PsrOut(Status));

    always @(posedge clk) begin
        if ((PC < PROGLEN) && 
          !(Program[PLLEN*(PC+1)-1:PLLEN*PC+(2*BUSW)]===HLT)) begin
            srcIsLitVal <= Program[PLLEN*PC];
            OpCode <= Program[PLLEN*(PC+1)-1:PLLEN*PC+(2*BUSW)+1];
            DstOp <= Program[PLLEN*PC+(2*BUSW)-1:PLLEN*PC+BUSW+1];
            DstOp <= Program[PLLEN*PC+BUSW-1:PLLEN*PC+1];
        end
    end

endmodule

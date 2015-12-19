module test_program();
    parameter BUSW=32; 
    parameter OPW=4; //opcode bit-width
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
    localparam PROGLEN=5; 
    localparam PLLEN=OCW+BUSW+BUSW+1;

    reg clk;
    reg [PLLEN*PROGLEN-1:0] Program;

    feeder #(BUSW, PROGLEN, PLLEN, NOP, LD, STR, BRA, XOR, ADD, ROT, SHF, HLT, CMP) feeder0(clk, Program, Res, done):
    
    initial begin
        $dumfile("test_program.vcd");
        $dumpvars;
    end
    
    initial begin
        clk = 1'b0;
        /*
        the test program: add '3' to '2'
        STR 1 '2' //store the literal value '2' into RAM slot 1
        LD 1 1 //load the previous value into the first register 
        ADD 1 '3' //add the literal value '3' to value in first register
        STR 2 1 //store the result from register 1 into RAM slot 2
        HLT //stop program execution
        */
        Program[0*PLLEN] <= 1'b1; //srcIsLitVal bits 
        Program[1*PLLEN] <= 1'b0; 
        Program[2*PLLEN] <= 1'b1; 
        Program[3*PLLEN] <= 1'b0; 
        Program[4*PLLEN] <= 1'b0; 
        Program[0*PLLEN+BUSW-1:0*PLLEN+1] <= 2; //srcOp bits
        Program[1*PLLEN+BUSW-1:1*PLLEN+1] <= 1;
        Program[2*PLLEN+BUSW-1:2*PLLEN+1] <= 3;
        Program[3*PLLEN+BUSW-1:3*PLLEN+1] <= 1;
        Program[4*PLLEN+BUSW-1:4*PLLEN+1] <= 0;
        Program[0*PLLEN+(2*BUSW)-1:0*PLLEN+BUSW+1] <= 1; //dstOp bits
        Program[1*PLLEN+(2*BUSW)-1:1*PLLEN+BUSW+1] <= 1;
        Program[2*PLLEN+(2*BUSW)-1:2*PLLEN+BUSW+1] <= 1;
        Program[3*PLLEN+(2*BUSW)-1:3*PLLEN+BUSW+1] <= 2;
        Program[4*PLLEN+(2*BUSW)-1:4*PLLEN+BUSW+1] <= 0;
        Program[1*PLLEN-1:0*PLLEN+(2*BUSW)+1] <= STR; //opcode bits
        Program[2*PLLEN-1:1*PLLEN+(2*BUSW)+1] <= LD; 
        Program[3*PLLEN-1:2*PLLEN+(2*BUSW)+1] <= ADD; 
        Program[4*PLLEN-1:3*PLLEN+(2*BUSW)+1] <= STR;
        Program[5*PLLEN-1:4*PLLEN+(2*BUSW)+1] <= HLT;
        forever begin
            #1 clk = !clk;
        end
    end

    always @(posedge clk) begin
        #100;
        while (!(done === 1'b1)) begin
            #1;
        end
        $display("%t: %b", $time, Res);
        $finish;
    end
endmodule

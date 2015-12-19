/* testfifo.v
    testbench for the fifo queue (test functionality before integrating it with ssp module)
    
    input pclk,             // buffer operations synchronized to clk signal
    input en,               // active high enable 
    input clear,            // active low reset/clear signal
    input rw,               // 0 => request to read from buffer, 1=> request to write to buffer
    input [7:0] wordIn,     // if rw high, the word to be written to the buffer

    output [7:0] wordOut,   // if rw low, the word to be read from the buffer
    output intr             // if buffer is full, it will pull this signal high
*/

module testfifo;
    reg clk, en, clear, rw;
    reg [7:0] wordIn;
    wire [7:0] wordOut;
    wire intr;

    reg done;
    reg [4:0] counter;

    fifo f(.pclk(clk), .en(en), .clear(clear), .rw(rw), .wordIn(wordIn), .wordOut(wordOut), .intr(intr));

    initial begin
        clk = 1'b0;
        en = 1'b0;
        clear = 1'b0;
        done = 1'b0;
        counter = 5'b0000;
        #10;
        forever begin
            #1 clk = !clk;
        end
    end

    initial begin
        $dumpfile("testfifo.vcd");
        $dumpvars;
        $monitor("time=%d, counter=%b, clk=%b, en=%b, clear=%b, rw=%b, wordIn=%c, wordOut=%c, intr=%b", $time, counter, clk, en, clear, rw, wordIn, wordOut, intr);
    end

//    always @(negedge clk) begin
//    end
    
    always @(posedge clk) begin
        case (counter)
            5'b00000: begin
                if (done) begin
                    $finish;
                end else begin
                    clear = 1'b1;
                end
            end
            5'b00001: en = 1'b1;
            5'b00010: rw = 1'b0;  // request to read from empty buffer
            5'b00011: begin
                rw <= 1'b1; 
                wordIn <= 8'b01100011;
            end
            5'b00100: wordIn = 8'b01100001;
            5'b00101: wordIn = 8'b01110100;
            5'b00110: wordIn = 8'b01110011;
            5'b00111,
            5'b01000,
            5'b01001,
            5'b01010: rw = 1'b0;
            5'b01011: begin
                rw <= 1'b1;
                wordIn <= 8'b01100010;
            end
            5'b01100: wordIn = 8'b01101001;
            5'b01101: wordIn = 8'b01110010;
            5'b01110: wordIn = 8'b01100100;
            5'b01111: begin
                wordIn <= 8'b01110011;  // request to write to full buffer
                done <= 1'b1;
            end
        endcase
        if (counter < 31) begin
            counter = counter + 1;
        end else begin
            counter = 5'b0;
        end

    end

    always @(posedge intr) begin
        $display("interrupt.");
        $finish;
    end

endmodule

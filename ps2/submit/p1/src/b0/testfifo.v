/* testfifo.v
    testbench for the fifo queue (test functionality before integrating it with ssp module)
    
    input pclk,             // buffer operations synchronized to clk signal
    input en,               // active high enable 
    input clear,            // active low reset/clear signal
    input rw,               // 0 => request to read from buffer, 1=> request to write to buffer
    input [7:0] wordIn,     // if rw high, the word to be written to the buffer

    output [7:0] wordOut,   // if rw low, the word to be read from the buffer
    output intr             // if buffer is full, it will pull this signal high
    output nempty           // if buffer is not empty, it will pull this signal high
*/

module testfifo;
    reg clk, en, clear, rw;
    reg [7:0] wordIn;
    wire [7:0] wordOut;
    wire intr, hasWord;

    reg done;
    reg [3:0] counter;

    fifo f(.pclk(clk), .en(en), .clear(clear), .rw(rw), .wordIn(wordIn), .wordOut(wordOut), .intr(intr), .nempty(hasWord));

    initial begin
        clk = 1'b0;
        en = 1'b0;
        clear = 1'b0;
        done = 1'b0;
        counter = 4'b0000;
        #10;
        forever begin
            #1 clk = !clk;
        end
    end

    initial begin
        $dumpfile("testfifo.vcd");
        $dumpvars;
        $monitor("time=%d, counter=%b, clk=%b, en=%b, clear=%b, rw=%b, wordIn=%c, wordOut=%c, intr=%b, hasWord=%b", $time, counter, clk, en, clear, rw, wordIn, wordOut, intr, hasWord);
    end

    always @(posedge clk) begin
        case (counter)
            4'b0000: begin
                if (done) begin
                    $finish;
                end else begin
                    clear = 1'b1;
                end
            end
            4'b0001: en = 1'b1;
            4'b0010: rw = 1'b0;  // request to read from empty buffer
            4'b0011: begin
                rw <= 1'b1; 
                wordIn <= 8'b01100011;
            end
            4'b0100: wordIn = 8'b01100001;
            4'b0101: wordIn = 8'b01110100;
            4'b0110: wordIn = 8'b01110011;
            4'b0111,
            4'b1000,
            4'b1001,
            4'b1010: rw = 1'b0;
            4'b1011: begin
                rw <= 1'b1;
                wordIn <= 8'b01100010;
            end
            4'b1100: wordIn = 8'b01101001;
            4'b1101: wordIn = 8'b01110010;
            4'b1110: wordIn = 8'b01100100;
            4'b1111: begin
                wordIn <= 8'b01110011;  // request to write to full buffer
                done <= 1'b1;
            end
        endcase
        counter = counter + 1;

    end

    always @(posedge intr) begin
        $display("interrupt.");
        $finish;
    end

endmodule

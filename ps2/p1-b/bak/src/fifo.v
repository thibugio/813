/* fifo.v 
    FIFO buffer
    * holds 4 8-bit words
*/

/* README: when a read request hasn't just been sent, should wordOut be set to high impedance, like a bus?
*/

module fifo(input pclk,             // buffer operations synchronized to clk signal
            input en,               // active high enable 
            input clear,            // active low reset/clear signal
            input write,            // 0 => request to read from buffer, 1=> request to write to buffer
            input read,
            input [7:0] wordIn,     // if rw high, the word to be written to the buffer

            output [7:0] wordOut,   // if rw low, the word to be read from the buffer
            output nempty,
            output intr);           // if buffer is full, it will pull this signal high

    localparam zWord = 8'bz;
    
    reg [31:0] queue = 32'b0;  // holds 4 8-bit words
    reg [3:0]  size = 4'b0;    // holds the number of words currently in the queue (each index is a word)
    reg wordOutEn = 1'b0;      // internal enable signal for wordOut

    assign wordOut = (wordOutEn ? queue[7:0] : zWord);
    assign intr = (rw && size[3]);  // this is an interrupt signal and thus should be continuous assignment
    assign nempty = (size > 0);

    always @(posedge pclk) begin
        if (clear == 1'b0) begin
            size = 4'b0;
            queue = 32'b0;
        end else begin      
            if (en) begin
                case ({read,write})
                    2'b01: begin // write request only
                            case (size)
                                4'b0000: begin
                                            queue[7:0] <= wordIn;
                                            size <= 4'b0001;
                                        end
                                4'b0001: begin 
                                            queue[15:8] <= wordIn;
                                            size <= 4'b0010;
                                        end
                                4'b0010: begin 
                                            queue[23:16] <= wordIn;
                                            size <= 4'b0100;
                                        end
                                4'b0100: begin 
                                            queue[31:24] <= wordIn;
                                            size <= 4'b1000;
                                        end
                                default: queue = queue;
                            endcase
                        end
                    2'b10: begin // read request only
                            wordOutEn = (size > 0); 
                        end
                    2'b11: begin  // simultaneous read and write requests
                            case (size)
                                4'b0000:    // queue empty; write only
                                    queue[7:0] <= wordIn;
                                    size <= 4'b0001;
                                4'b0001:
                                    wordOutEn <= 1'b1;
                                    queue[15:8] <= wordIn;
                                    size <= 4'b0010;
                                4'b0010:
                                    wordOutEn <= 1'b1;
                                    queue[23:16] <= wordIn;
                                    size <= 4'b0100;
                                4'b0100:
                                    wordOutEn <= 1'b1;
                                    queue[31:24] <= wordIn;
                                    size <= 4'b1000;
                                4'b1000:    // queue full; read only
                                    wordOutEn = 1'b1;
                            endcase
                        end
                    default:  // nop
                        wordOutEn = 1'b0;
                endcase
            /*
                case (rw)
                    1'b1: begin // write request
                            case (size)
                                4'b0000: begin
                                            queue[7:0] <= wordIn;
                                            size <= 4'b0001;
                                        end
                                4'b0001: begin 
                                            queue[15:8] <= wordIn;
                                            size <= 4'b0010;
                                        end
                                4'b0010: begin 
                                            queue[23:16] <= wordIn;
                                            size <= 4'b0100;
                                        end
                                4'b0100: begin 
                                            queue[31:24] <= wordIn;
                                            size <= 4'b1000;
                                        end
                                default: queue = queue;
                            endcase
                        end
                    1'b0: begin // read request
                            wordOutEn = (size > 0); 
                        end
                    //default:
                    //   wordOutEn = 1'b0;
                endcase // rw
                */
            end  // endif en
        end  // endif clear
    end  // endalways @(posedge pclk)

    always @(negedge pclk) begin
        if (wordOutEn == 1'b1) begin    // a read has just occured on the last posedge of pclk
            queue[31:0] <= {8'b0, queue[31:8]};   // shift the queue forward
            wordOutEn   <= 1'b0;
            size        <= (size >> 1);  // 'decrement' size
        end  // endif wordOutEn
    end  // endalways @(negedge pclk)

endmodule

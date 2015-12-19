/* talker.v
    implements transmit/receive logic
*/

module talker(input [7:0] txdata,       // word received 
              input pclk,               // ssp clk 
              input clear,              // active low clear
              input sspclkin,           // synchronization clk for data received, period = 2*pclk 
              input sspfssin,           // frame control signal for data received 
              input ssprxd,             // 1-bit input 
              input txhasword,          // pulled high whevener tx buffer is not empty -> txdata should have valid data.
              input rxfifoint,          // pulled high whenever rx fifo queue is full

              output txfifo_rw,         // request to read (and write) data from (to) the tx fifo queue (1==write)
              output rxfifo_rw,         // request to (read and) write data to (from) the rx fifo queue
              output [7:0] rxdata,      // word to be transferred 
              output sspoe_b,           // active low enable for data transmission 
              output ssptxd,            // 1-bit output 
              output sspclkout,         // synchronization clk for data transferred, period = 2*pclk 
              output sspfssout);        // frame control signal for data transferred  

    localparam zWord = 8'bz;
    
    reg sspfssout, ssptxd;
    
    reg [7:0] wordtosend, wordreceived; // store the next word to send and the last word received.
    reg _rx_write_en;   // internal signal to know when to initiate write request to rxfifo

    // rw == 0 -> read request; rw == 1 -> write request
    assign txfifo_rw = ((txhasword === 1'b1 && rxfifoint === 1'b0) ? 1'b0 : 1'b1);
    assign rxfifo_rw = (_rx_write_en ? 1'b1 : 1'b0);
    assign rxdata = (rxfifowrite === 1'b1 ? wordtosend : zWord);


    /* write:
        trigger: there is a word at the bottom of the TX FIFO queue (from input PWDATA)
        action:
            -wait for ssprxintr signal to be LOW
            -sspfssout pulsed HIGH for ONE sspclkout period
                -at negedge of sspclkout, sspoe_b pulled LOW
            -after sspfssout goes LOW (next posedge of sspclkout):
                -starting with MSB, data word at bottom of TX FIFO queue is serially pumped 1 bit
                 at a time onto the ssptxd pin
            -at next negegde after LSB shifted onto ssptxd pin, sspoe_b pulled HIGH, unless another word
             is waiting to be transferred
                *note: sspoe_b should trigger on posedge of sspfssout, where it should be set LOW 
                       at next negedge of sspclkout
       read:
        trigger: sspfss{out,in} is HIGH
        action:
            -if RX FIFO queue is full, pull ssprxintr HIGH; else, on next posedge of sspclkin after sspfssin 
            goes HIGH, start reading data from ssprxd (1-bit serial input) into the RX FIFO.
            -(set output PRDATA to bottom word in RX FIFO queue)

    */

    // write
    always @ (posedge pclk, txfiforead) begin
        if (txfiforead === 1'b1) begin
            wordtosend = txdata;
            @ (posedge sspclkout) begin
                sspfssout = 1'b1;
                @ (negedge sspclkout) begin
                    sspoe_b = 1'b0;
                end
                for (i=0; i<8; i=i+1) begin
                    @ (posedge sspclkout) begin
                        if (i==0) begin
                            sspfssout = 1'b0;
                        end
                        ssptxd = wordtosend[7-i];
                        #1;
                    end 
                end //endfor
            end //end@ posedge sspclkout
        end //endif txfiforead
    end //endalways @ (posedge pclk, txfiforead)

    // read
    always @ (posedge sspfssin) begin
        for (i=0; i<8; i=i+1) begin
            @ (posedge pclk) begin
                wordreceived[7-i] = ssprxd;
            end
        end
        _rx_write_en = 1'b1;
    end

endmodule

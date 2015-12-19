/* ssp.v
    this is the top level module, ssp => Synchronous Serial Port
    * uses 8-bit words
    * performs parallel-to-serial conversion on output data
    * performs serial-to-parallel conversion on input data
    * buffers input and output with 2 32-bit (4-word) FIFO queues
*/

module ssp(input PCLK,              // ssp clock -> all interface, FIFO operations synched to this
           input CLEAR_B,           // active low clear signal for initializing ssp
           input PSEL,              // active high chip select -> controls data flow into/out of ssp (only affects dataflow on PWDATA and PRDATA lines)
           input PWRITE,            // 1 -> write to ssp; 0 -> read from ssp 
           input [7:0] PWDATA,      // data word to be transmitted 
           input SSPCLKIN,          // synchronization clk for reception data, connected to SSPCLKOUT
           input SSPFSSIN,          // receive frame control signal. read data at next posedge of SSPCLKIN 
           input SSPRXD,            // 1-bit serial data input

           output [7:0] PRDATA,     // data word received 
           output SSPOE_B,          // active low enable during transmission (negedge before to negedge after)
           output SSPTXD,           // 1-bit serial data output
           output SSPCLKOUT,        // synchronization clk for transmission data, period = 2*PCLK
           output SSPFSSOUT,        // transmission frame control signal 
           output SSPTXINTR,        // pulled high when TX FIFO buffer is full
           output SSPRXINTR);       // pulled high when RX FIFO buffer is full

    localparam zWord = 8'bz;
    reg [7:0] txdata, rxdata;
    wire txhasword, rxhasword, txfifo_rw, rxfifo_rw;
    

/*     always, regardless of psel:
        -data already in the TX FIFO queue should be written
        -data already in the RX FIFO queue should be read/processed

    -can it be assumed that PWRITE is only 1 when it needs to write a value to the txfifo, 
     only 0 when it needs to read a value from the rxfifo, and Z otherwise?


module fifo(input pclk,             // buffer operations synchronized to clk signal
            input en,               // active high enable 
            input clear,            // active low reset/clear signal
            input rw,            // 0 => request to read from buffer, 1=> request to write to buffer
            input [7:0] wordIn,     // if rw high, the word to be written to the buffer

            output [7:0] wordOut,   // if rw low, the word to be read from the buffer
            output nempty,          // 1 if not empty
            output intr);           // if buffer is full, it will pull this signal high

module talker(input [7:0] txdata,       // word received 
              input pclk,               // ssp clk 
              input clear,              // active low clear
              input sspclkin,           // synchronization clk for data received, period = 2*pclk 
              input sspfssin,           // frame control signal for data received 
              input ssprxd,             // 1-bit input 
              input txhasword,          // pulled high whevener there is >= 1 word in the tx fifo queue
              input rxfifoint,          // pulled high whenever rx fifo queue is full

              output txfiforead,        // request to read data from the tx fifo queue
              output rxfifowrite,       // request to write data to the rx fifo queue
              output [7:0] rxdata,      // word to be transferred 
              output sspoe_b,           // active low enable for data transmission 
              output ssptxd,            // 1-bit output 
              output sspclkout,         // synchronization clk for data transferred, period = 2*pclk 
              output sspfssout);        // frame control signal for data transferred  
*/

    fifo txfifo(.pclk(PCLK),   //inputs
                .clear(CLEAR_B), 
                .en(PSEL), 
                .rw(PWRITE),
                .intrw(txfifo_rw),
                .wordIn(PWDATA), 
                .intWordIn(zWord), // t-r logic never writes to txfifo
                .wordOut(txdata),  //outputs
                .nempty(txhasword),
                .intr(SSPTXINTR));

    fifo rxfifo(.pclk(PCLK),   //inputs
                .clear(CLEAR_B), 
                .en(PSEL), 
                .rw(PWRITE), 
                .intrw(rxfifo_rw),
                .wordIn(zWord),  //processor never writes to rxfifo
                .intWordIn(rxdata),
                .wordOut(PRDATA),  //outputs
                .nempty(rxhasword),
                .intr(SSPRXINTR));

    talker logicbox(.txdata(txdata),  //inputs
                    .pclk(PCLK),
                    .clear(CLEAR_B),
                    .sspclkin(SSPCLKIN),
                    .sspfssin(SSPFSSIN),
                    .txhasword(txhasword),
                    .rxfifoint(SSPRXINTR),
                    .ssprxd(SSPRXD),
                    .txfifo_rw(txfifo_rw),  //outputs
                    .rxfifo_rw(rxfifo_rw),
                    .rxdata(rxdata),
                    .sspoe_b(SSPOE_B),
                    .ssptxd(SSPTXD),
                    .sspclkout(SSPCLKOUT),
                    .sspfssout(SSPFSSOUT));

    always @ (posedge PCLK) begin
        if (CLEAR_B === 1'b0) begin
            // initialize ssp
            txdata = zWord;
            rxdata = zWord;
        end 
        /*else begin
            // if there is data already in the tx or rx fifos, do something about it.
            // if there is data on the pwdata line or pwrite==0 and psel==1, do something about it.
            if (txhasword===1'b1) begin
            end

            if (ssprxd===1'b1 || ssprxd===1'b0) begin //i.e, not high-z or undefined
            end

            if (PSEL===1'b1) begin
                case (PWRITE)
                    1'b1:
                    1'b0:
                endcase
            end
        end*/
    end

endmodule

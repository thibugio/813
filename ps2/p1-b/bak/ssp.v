/* ssp.v
    this is the top level module, ssp => Synchronous Serial Port
    * uses 8-bit words
    * performs parallel-to-serial conversion on output data
    * performs serial-to-parallel conversion on input data
    * buffers input and output with 2 32-bit (4-word) FIFO queues
*/

module ssp(input PCLK,              // ssp clock -> all interface, FIFO operations synched to this
           input CLEAR_B,           // active low clear signal for initializing ssp
           input PSEL,              // active high chip select -> controls data flow into/out of ssp 
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

endmodule

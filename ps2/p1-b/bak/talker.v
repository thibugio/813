/* talker.v
    implements transmit/receive logic
*/

module talker(input [7:0] txdata,       // word received 
              input pclk,               // ssp clk 
              input clear,              // active low clear
              input sspclkin,           // synchronization clk for data received, period = 2*pclk 
              input sspfssin,           // frame control signal for data received 
              input ssprxd,             // 1-bit input 

              output [7:0] rxdata,      // word to be transferred 
              output sspoe_b,           // active low enable for data transmission 
              output ssptxd,            // 1-bit output 
              output sspclkout,         // synchronization clk for data transferred, period = 2*pclk 
              output sspfssout);        // frame control signal for data transferred 

endmodule

/* testssp.v
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
    testbench for ssp module
*/

module testssp;

    //inputs
    reg pclk, clear_b, psel, sspclkin, sspfssin;  //common to both
    reg pwrite_master, ssprxd_master; 
    reg pwrite_slave, ssprxd_slave;
    reg [7:0] pwdata_master;
    reg [7:0] pwdata_slave;
    //outputs
    wire sspoe_b, sspclkout, sspfssout;  //common to both
    wire ssptxd_master, ssptxintr_master, ssprxintr_master;
    wire ssptxd_slave, ssptxintr_slave, ssprxintr_slave;
    wire [7:0] prdata_master;
    wire [7:0] prdata_slave;

    ssp ssp_master(.PCLK(pclk), 
                   .CLEAR_B(clear_b), 
                   .PSEL(psel), 
                   .PWRITE(pwrite_master), 
                   .PWDATA(pwdata_master), 
                   .SSPCLKIN(sspclkin), 
                   .SSPFSSIN(sspfssin), 
                   .SSPRXD(ssprxd_master), 
                   .PRDATA(prdata_master), 
                   .SSPOE_B(sspoe_b), 
                   .SSPTXD(ssptxd_master), 
                   .SSPCLKOUT(sspclkout), 
                   .SSPFSSOUT(sspfssout), 
                   .SSPTXINTR(ssptxintr_master), 
                   .SSPRXINTR(ssprxintr_master));

    ssp ssp_slave(.PCLK(pclk), 
                  .CLEAR_B(clear_b), 
                  .PSEL(psel), 
                  .PWRITE(pwrite_slave), 
                  .PWDATA(pwdata_slave), 
                  .SSPCLKIN(sspclkout), 
                  .SSPFSSIN(sspfssout), 
                  .SSPRXD(ssprxd_slave), 
                  .PRDATA(prdata_slave), 
                  .SSPOE_B(sspoe_b), 
                  .SSPTXD(ssptxd_slave), 
                  .SSPCLKOUT(sspclkin), 
                  .SSPFSSOUT(sspfssin), 
                  .SSPTXINTR(ssptxintr_slave), 
                  .SSPRXINTR(ssprxintr_slave));
endmodule

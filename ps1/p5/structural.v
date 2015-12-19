// file: structural.v
// structural Verilog model for the logic circuit in Problem 5.

module structural(clk, x, z1, z2, y1, y2);
    input clk, x;
    output z1, z2, y1, y2;

    wire not0_out, and0_out, and1_out, and2_out, and3_out, nor0_out, or0_out, or1_out;

    // gate(output, intputs...)
    not not0(not0_out, x);
    and and0(and0_out, not0_out, (!y2));
    and and1(and1_out, x, y2);
    and and2(and2_out, (!y1), y1);
    and and3(and3_out, y1, y2);
    nor nor0(nor0_out, and0_out, and1_out);
    or  or0 (or0_out, y1, x);
    or  or1 (or1_out, and2_out, not0_out);

    jkff jkff0(.j(x),     .k(nor0_out), .clk(clk), .q(y1));
    jkff jkff1(.j((!y1)), .k(or0_out),  .clk(clk), .q(y2));

    assign z1 = and3_out;
    assign z2 = or1_out;

endmodule

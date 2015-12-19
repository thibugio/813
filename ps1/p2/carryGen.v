// file: carryGen.v
// create the 'carry' signal for the lookahead adder

module carryGen(ci, Ps, Gs, cn);

    parameter n=0;
    parameter delay = 10;

    input ci;
    input [n-1:0] Ps, Gs;

    output cn;

    wire [n*n:0] andWires;
    wire [n:0] orWires, gWires, pWires;

    assign gWires[0] = ci;
    assign pWires[n] = 1;

    assign Gs = gWires[n:1];
    assign Ps = pWires[n-1:0];

    // gate(output, inputs...)
    genvar i;
    generate
    for (i=0; i<=n; i=i+1) begin : AND
        and #delay and_i(orWires[i], gWires[i], pWires[n:i]);
    end
    endgenerate

    or  #delay or0 (cn, orWires[n:0]);

endmodule

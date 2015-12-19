// file: pgGen.v
// create the 'propagate' and 'generate' signals for the lookahead adder

module pgGen(a, b, g, p);

    input a, b;
    output g, p;

    parameter delay = 10;

    // gate(output, inputs....)
    and #delay     and0(g,a,b);
    xor #(2*delay) xor0(p,a,b);

endmodule

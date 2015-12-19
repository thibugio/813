// file: nb_csa.v
// adds 3 n-bit words; returns n-bit sum and n-bit carry

module nb_csa(X, Y, Z, S, Cout);

    parameter n = 4;

    input  [n-1:0] X, Y, Z;
    output [n-1:0] S, Cout;

    genvar i;
    generate
        for (i=0; i<n; i=i+1) begin : ADDER
            adder a(.a(X[i]), .b(Y[i]), .ci(Z[i]), .s(S[i]), .co(Cout[i]));
        end
    endgenerate

endmodule

module adder(a, b, ci, s, co);
    input a, b, ci;
    output s, co;

    assign s = a^b^ci;
    assign co = (a&b) | (a&c) | (b&c);
endmodule

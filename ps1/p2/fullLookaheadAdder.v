// file: fullLookaheadAdder.v

module fullLookaheadAdder(A, B, ci, sumAB, cAB);

    parameter n = 4;

    input [n-1:0] A, B;
    input ci;

    output [n-1:0] sumAB;
    output cAB;

    wire [n:0] carries;
    wire [n-1:0] Ps;
    wire [n-1:0] Gs;

    carries[0] = ci;

    genvar i;
    generate
    for (i=0; i<n; i=i+1) begin : LOOKAHEAD_ADDER
        lookaheadAdder #(i) la(an.(A[i]), bn.(B[i]), cn_1.(carries[i]), Ps.(Ps), Gs.(Gs), pn.(Ps[i]), gn.(Gs[i]), sn.(sumAB[i]), .cn(carries[i+1]);
    end
    endgenerate

    cAB = carries[n];

endmodule

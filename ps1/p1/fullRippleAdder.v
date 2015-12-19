// file: fullRippleAdder.v
// an N-bit ripple adder with a carry bit

module fullRippleAdder(A, B, ci, S, co);

    parameter n = 8;

    input [n-1:0] A, B;
    input ci;
    output [n-1:0] S;
    output co;

    wire [n:0] cn;
    assign cn[0] = ci;
    assign co = cn[n];

    genvar i;
    generate 
    for (i = 0; i < n; i = i + 1) begin : RIPPLE_ADDER 
        rippleAdder ra(.a(A[i]), .b(B[i]), .ci(cn[i-1]), .s(S[i]), .co(cn[i]));
    end
    endgenerate

//    input [7:0] A, B;
//    input ci;
//    output [7:0] S;
//    output co;
//    wire [6:0] cn;

//    rippleAdder a0(.a(A[0]), .b(B[0]), .ci(ci),    .s(S[0]), .co(cn[0]));
//    rippleAdder a1(.a(A[1]), .b(B[1]), .ci(cn[0]), .s(S[1]), .co(cn[1]));
//    rippleAdder a2(.a(A[2]), .b(B[2]), .ci(cn[1]), .s(S[2]), .co(cn[2]));
//    rippleAdder a3(.a(A[3]), .b(B[3]), .ci(cn[2]), .s(S[3]), .co(cn[3]));
//    rippleAdder a4(.a(A[4]), .b(B[4]), .ci(cn[3]), .s(S[4]), .co(cn[4]));
//    rippleAdder a5(.a(A[5]), .b(B[5]), .ci(cn[4]), .s(S[5]), .co(cn[5]));
//    rippleAdder a6(.a(A[6]), .b(B[6]), .ci(cn[5]), .s(S[6]), .co(cn[6]));
//    rippleAdder a7(.a(A[7]), .b(B[7]), .ci(cn[6]), .s(S[7]), .co(co));
    
endmodule

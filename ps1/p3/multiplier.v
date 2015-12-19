// file: multiplier.v
// multiplies signed n-bit operands and return a 2n-bit product in 2's complement form.

module multiplier(A, B, P);

    parameter n = 5; //number of bits in the (signed) operands

    reg sumReady = 1'b0;

    input [n-1:0] A, B;
    output [(2*n)-1:0] P;


    reg a = (A[n-1] ? ~A + 1 : A);
    reg b = (B[n-1] ? ~B + 1 : B);
    reg signP = A[n-1] ^ B[n-1];

    reg [n*(2*n-1)-1:0] partials;  // n (2n-1)-bit parial products
    reg c;  // throwaway carry
    reg [(2*n-1)-1:0] tempB, tempS;

    genvar i;
    generate
        for (i=0; i<n; i=i+1) begin : PARTIAL_PRODUCT
            partialProduct #(.n(n),.index(i)) pp(.multiplicand(a), 
                                     .multiplierBit(b[i]),
                                     .partial(partials[(i+1)*(2*n-1)-1 : i*(2*n-1)]));
        end
    endgenerate

    // add the n partial products
    generate
        for (i=1; i<n; i=i+1) begin : FULL_LOOKAHEAD_ADDER
            if (i==1) begin
                tempB = partials[2*n-1 : 0];
            end else 
                tempB = tempS;
            end

            fullAdder #(2*n-1) fla(.A(partials[(i+1)*(2*n-1)-1:i*(2*n-1)]), 
                                            .B(tempB),
                                            .ci(0), 
                                            .sumAB(tempS),
                                            .co(c));

            if (i==(n-1)) begin
                sumReady = 1'b1;
            end
        end
    endgenerate

    assign P = (sumReady ? {signP, tempS[(n-2)*(2*n-1)-1 : (n-3)*(2*n-1)]} : 0);

endmodule

// wrapper for an adder (this way we only have to change 1 line of code if we want to use a different adder)
module fullAdder(A, B, ci, S, co);
    parameter n=4;
    input [n-1:0] A, B;
    input ci;
    output [n-1:1] S;
    output co;

    fullLookaheadAdder #(n) a0(A, B, ci, S, co);
endmodule

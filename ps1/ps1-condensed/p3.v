module partialProduct(multiplicand, multiplierBit, partial);

    parameter n=5; // number of bits in operator
    parameter index = 0; //index into the multiplier; <= n

    input [n-1:0] multiplicand;
    input multiplierBit;

    output [2*n-2:0] partial;  // (2n-1)-bit partial product

    assign partial = {(2*n-1){multiplierBit}} & ((multiplicand << index) >>> index);

endmodule


module multiplier(A, B, P);

    parameter n = 5; //number of bits in the (signed) operands

//    reg sumReady = 1'b0;

    input [n-1:0] A, B;
    output [(2*n)-1:0] P;


    wire [n-1:0] a, b; 
    wire signP;
    assign a = (A[n-1] ? ~A + 1 : A);
    assign b = (B[n-1] ? ~B + 1 : B);
    assign signP = A[n-1] ^ B[n-1];

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
 //           if (i==1) begin
 //               tempB = partials[2*n-1 : 0];
 //           end else begin
 //               tempB = tempS;
 //           end

        if (i==1) begin
            fullAdder #(2*n-1) fla(.A(partials[(i+1)*(2*n-1)-1:i*(2*n-1)]), 
                                            .B(partials[2*n-1 : 0]),
                                            .ci(0), 
                                            .sumAB(tempS),
                                            .co(c));
        end else begin
            if (i%2) begin
                fullAdder #(2*n-1) fla(.A(partials[(i+1)*(2*n-1)-1:i*(2*n-1)]), 
                                                .B(tempS),
                                                .ci(0), 
                                                .sumAB(tempB),
                                                .co(c));
            end else begin
                fullAdder #(2*n-1) fla(.A(partials[(i+1)*(2*n-1)-1:i*(2*n-1)]), 
                                                .B(tempB),
                                                .ci(0), 
                                                .sumAB(tempS),
                                                .co(c));
            end
        end

//            if (i==(n-1)) begin
//                sumReady = 1'b1;
//            end
        end
    endgenerate

    assign P = {signP, tempS[(n-2)*(2*n-1)-1 : (n-3)*(2*n-1)]};
//    assign P = (sumReady ? {signP, tempS[(n-2)*(2*n-1)-1 : (n-3)*(2*n-1)]} : 0);

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


module testMultiplier();

    reg [5-1:0] A, B;
    reg [(2*5)-1:0] P;
        
    multiplier #(5) test0(.A(A), .B(B), .P(P));

    initial begin
        $dumpfile("testMultiplier.vcd");
        $dumpvars;
    end

    initial begin
        A <= 5'b10110;     // -10
        B <= 5'b00100;     // 4
    end

    always begin
        #1000;
        $display("%d * %d = %d\n", A, B, P);
 
        A <= 5'b01011;     // 11
        B <= 5'b11101;     // -3
        #1000;
        $display("%d * %d = %d\n", A, B, P);

        A <= 5'b10110;     // -10
        B <= 5'b10101;     // -11
        #1000;
        $display("%d * %d = %d\n", A, B, P);

        $finish;
    end

endmodule

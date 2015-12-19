// file: full_csa.v
// chain k n-bit csa stages together followed by a regular n-bit adder to add k n-bit words.

module full_csa(In, S, co);

    parameter n=8;   // n-bits each word
    parameter k=10;  // k words

    integer cbits = $bits(k-1);  // max number of carry bits
    integer sbits = n+cbits;     // sum bits

    input  [n*k-1:0] In;    // all of the words to be added, in a sequence
    output [sbits-1:0] S;       // the final sum
    output co;              // carry-out 

    reg csa_bits = n;
    reg sumReady = 1'b0;

    /* option 1
    wire [(k-1)*(sbits)-1:0] sums = {((k-1)*(sbits)){1'b0}};
    wire [(k-2)*(sbits)-1:0] carries = {((k-1)*(sbits)){1'b0}};
    genvar i;
    generate
        for (i=0; i<k-1; i++) begin : FULL_CSA
            csa_bits = (i<cbits ? n+i : sbits);
            if (i==0) begin
                nb_csa #(csa_bits) csa(.X(In[3*n-1:2*n]), 
                                       .Y(In[2*n-1:n]), 
                                       .Z(In[n-1:0]), 
                                       .S(sums[csa_bits-1:0]), 
                                       .Cout(carries[csa_bits-1:0]));
            end else if (i < (k-2)) begin
                nb_csa #(csa_bits) csa(.X(carries[(i-1)*(sbits)+csa_bits-1:(i-1)*(sbits)]<<1),
                                       .Y(sums[(i-1)*(sbits)+csa_bits-1:(i-1)*(sbits)]), 
                                       .Z(In[(3+i)*n-1:(2+i)*n]), 
                                       .S(sums[i*sbits+csa_bits-1:i:sbits]), 
                                       .Cout(carries[i*sbits+csa_bits-1:i*sbits));
            end else
                fullAdder #(sbits) an(.A(carries[(k-2)*sbits-1:(k-3)*sbits]), 
                                      .B(carries[(k-2)*sbits-1:(k-3)*sbits]), 
                                      .ci(0), .S(S), .co(co));
            end
        end
    endgenerate

    */

    reg [cbits-1:0] cSum, lastCSum; // carry sum
    reg [n-1:0] nbSum, lastNbSum;   // n-bit sum
    reg cSum_co, nbSum_co; 
    
    genvar i;
    generate
        for (i=0; i<k-1; i=i+1) begin : FULL_CSA
            if (i==0) begin
                lastNbSum = In[n-1:0];
            end else
                lastNbSum = nbSum;
                if (i==1) begin
                    lastCSum = 0;
                end else 
                    lastCSum = cSum;
                end
                    fullAdder #(cbits) fa_cSum(.A(c), 
                                               .B(lastCSum), 
                                               .ci(nbSum_co), 
                                               .S(cSum), 
                                               .co(cSum_co));
            end
            
            fullAdder #(n) fa_nbSum(.A(In[((i+1)*k*n)-1:i*k*n]), 
                                    .B(lastNbSum), 
                                    .ci(0), 
                                    .S(nbSum), 
                                    .co(c));
            if (i==(k-2)) begin
                sumReady = 1'b1;
            end
        end
    endgenerate

    assign S = (sumReady ? {cSum, nbSum} : 0);

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

module nb_csa(X, Y, Z, S, Cout);

    parameter n = 4;

    input  [n-1:0] X, Y, Z;
    output [n-1:0] S, Cout;

    genvar i;
    generate
        for (i=0; i<n; i=i+1) begin : ADDER_1B
            adder_1b a(.a(X[i]), .b(Y[i]), .ci(Z[i]), .s(S[i]), .co(Cout[i]));
        end
    endgenerate

endmodule

module adder_1b(a, b, ci, s, co);
    input a, b, ci;
    output s, co;

    assign s = a^b^ci;
    assign co = (a&b) | (a&ci) | (b&ci);
endmodule


module full_csa(In, S, co);

    parameter n=8;   // n-bits each word
    parameter k=10;  // k words
    parameter cbits = 0;  // max number of carry bits

//    localparam cbits = $bits(k-1);  // max number of carry bits
    localparam sbits = n+cbits;     // sum bits

    input  [n*k-1:0] In;    // all of the words to be added, in a sequence
    output [sbits-1:0] S;       // the final sum
    output co;              // carry-out 

    reg csa_bits = n;
//    reg sumReady = 1'b0;

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
                fullAdder #(n) fa_nbSum(.A(In[((i+1)*k*n)-1:i*k*n]), 
                                        .B(In[n-1:0]), 
                                        .ci(0), 
                                        .S(nbSum), 
                                        .co(c));
            end else begin
                if ((i%2)==1) begin
                    fullAdder #(n) fa_nbSum(.A(In[((i+1)*k*n)-1:i*k*n]), 
                                            .B(nbSum), 
                                            .ci(0), 
                                            .S(lastNbSum), 
                                            .co(c));
                    if (i==1) begin 
                        fullAdder #(cbits) fa_cSum(.A(c), 
                                                   .B(0), 
                                                   .ci(nbSum_co), 
                                                   .S(cSum), 
                                                   .co(cSum_co));
                    end else begin
                        fullAdder #(cbits) fa_cSum(.A(c), 
                                                   .B(lastCSum), 
                                                   .ci(nbSum_co), 
                                                   .S(cSum), 
                                                   .co(cSum_co));
                    end
                end else begin
                    fullAdder #(n) fa_nbSum(.A(In[((i+1)*k*n)-1:i*k*n]), 
                                            .B(lastNbSum), 
                                            .ci(0), 
                                            .S(nbSum), 
                                            .co(c));
                    
                    fullAdder #(cbits) fa_cSum(.A(c), 
                                               .B(cSum), 
                                               .ci(nbSum_co), 
                                               .S(lastCSum), 
                                               .co(cSum_co));
                end
            end
            
//            if (i==(k-2)) begin
//                sumReady = 1'b1;
//            end
        end
    endgenerate

    assign S = {cSum, nbSum};
//    assign S = (sumReady ? {cSum, nbSum} : 0);

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


module test_full_csa();
    parameter n1=4, k1=10;
    parameter n2=5, k2=8;

//    localparam s1bits=n1+$size(k1-1);
//    localparam s2bits=n2+$size(k2-1);
    localparam c1bits = 4;
    localparam s1bits = n1+c1bits;
    localparam c2bits = 3;
    localparam s2bits = n2+c2bits;

    reg [n1*k1-1:0] seq1;
    reg [n2*k2-1:0] seq2;

    reg [s1bits-1:0] sum1;
    reg [s2bits-1:0] sum2;

    reg co1, co2;

    full_csa #(.n(n1), .k(k1), .cbits(c1bits)) csa1(.In(seq1), .S(sum1), .co(co1));
    full_csa #(.n(n2), .k(k2), .cbits(c2bits)) csa2(.In(seq2), .S(sum2), .co(co2));

    initial begin
        $dumpfile("test_full_csa.vcd");
        $dumpvars;
    end

    initial begin
        seq1[1*n1-1:0*n1] <= 4'b1011;
        seq1[2*n1-1:1*n1] <= 4'b0010;
        seq1[3*n1-1:2*n1] <= 4'b1101;
        seq1[4*n1-1:3*n1] <= 4'b0100;
        seq1[5*n1-1:4*n1] <= 4'b0101;
        seq1[6*n1-1:5*n1] <= 4'b0110;
        seq1[7*n1-1:6*n1] <= 4'b0111;
        seq1[8*n1-1:7*n1] <= 4'b1000;
        seq1[9*n1-1:8*n1] <= 4'b1001;
        seq1[10*n1-1:9*n1] <= 4'b1010;

        seq2[1*n2-1:0*n2] <= 5'b00011;
        seq2[2*n2-1:1*n2] <= 5'b01110;
        seq2[3*n2-1:2*n2] <= 5'b00101;
        seq2[4*n2-1:3*n2] <= 5'b00110;
        seq2[5*n2-1:4*n2] <= 5'b00111;
        seq2[6*n2-1:5*n2] <= 5'b01000;
        seq2[7*n2-1:6*n2] <= 5'b10011;
        seq2[8*n2-1:7*n2] <= 5'b01010;

        sum1 <= {s1bits{1'b0}};
        sum2 <= {s2bits{1'b0}};

        co1 <= 0;
        co2 <= 0;
    end

    always begin
        #1000;
        $display("sum1: %d, \tsum2: %d\n", sum1, sum2);
        $finish;
    end

endmodule

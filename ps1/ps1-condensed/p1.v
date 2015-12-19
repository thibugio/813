module rippleAdder(a, b, ci, s, co);

    input a, b, ci;
    output s, co;
    wire z, y, x;
    
    // gate(output, inputs...)
    xor #20 xor0(z, a, b); 
    xor #20 xor1(s, z, ci);
    and #10 and0(y, ci, z);
    and #10 and1(x, a, b);
    or  #10 or0(co, y, x);

endmodule

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

endmodule

module testFullRippleAdder();

    parameter n=8;

    reg [n-1:0] A, B, sumAB, sum, maxA, maxB;
    reg ci, cAB, clk;

    integer delta_t, save_t, t, max_delta, iter;

    fullRippleAdder #(n) fra(.A(A), .B(B), .ci(ci), .S(sumAB), .co(cAB));
    
    initial begin
        $monitor("max delay: %d (A=%b, B=%b, co=%b)\n", max_delta, maxA, maxB, cAB);
        $dumpfile("test_fullRippleAdder.vcd");
        $dumpvars;
    end

    initial begin
        ci        <= 0;
        cAB       <= 0;
        clk       <= 0;
        A         <= {n{1'b0}};
        B         <= {n{1'b0}};
        sum       <= {n{1'b0}};
        sumAB     <= {n{1'b0}};
        maxA      <= {n{1'b0}};
        maxB      <= {n{1'b0}};
        delta_t   <= 0;
        save_t    <= 0;
        t         <= 0;
        max_delta <= 0;
        iter      <= ((1<<n)*((1<<n)+1));
    end

    always begin
        while (iter) begin
            if (B == {n{1'b1}}) begin
                B = {n{1'b0}};
                if (A == {n{1'b1}}) begin
                    ci = !ci;
                    A = {n{1'b0}};
                end else begin
                    A = A + 1;
                    B = A;
                end
            end else begin 
                B = B + 1;
            end

            sum = A + B;    // check result of ripple adder against this

            save_t = $stime;

            while (sum != sumAB) begin
                t = $stime;
            end

            delta_t = t - save_t;
            
            if (delta_t > max_delta) begin
                max_delta = delta_t;
                maxA = A;
                maxB = B;
            end

            iter = iter - 1;
            #1;
        end

        $display("testing finished. max delay: %d (A=%b, B=%b, co=%b)\n", max_delta, maxA, maxB, cAB);
        $finish;
    end

endmodule

// file: testFullLookaheadAdder.v

module testFullLookaheadAdder();

    parameter n=8;

    reg [n-1:0] A, B, sumAB, sum, maxA, maxB;
    reg ci, cAB, clk;

    integer delta_t, save_t, t, max_delta, iter;

    initial begin
        $monitor("max delay: %d (A=%b, B=%b, cAB=%b)\n", max_delta, maxA, maxB, cAB);
        $dumpfile("testFullLookaheadAdder.vcd");
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

    initial begin
        fullLookaheadAdder #(n) la(.A(A), .B(B), .ci(ci), .S(sumAB), .co(cAB));
    end

    always begin
        while (iter) begin 
            if (B == {n{1'b1}}) begin
                B = {n{1'b0}};
                if (A == {n{1'b1}}) begin
                    c = !ci;
                    A = {n{1'b0}};
                end else
                    A = A + 1;
                    B = A;
                end
            end else 
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

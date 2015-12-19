// file: testMultiplier.v

module testMultiplier();

    reg [5-1:0] A, B;
    reg [(2*5)-1:0] P;

    initial begin
        $dumpfile("testMultiplier.vcd");
        $dumpvars;
    end

    initial begin
        A <= 5'b10110;     // -10
        B <= 5'b00100;     // 4
    end

    always begin
        multiplier #(5) test0(.A(A), .B(B), .P(P));
        #100 
        $display("%d * %d = %d\n", A, B, P);
 
        A <= n'b01011;     // 11
        B <= n'b11101;     // -3
        multiplier #(5) test1(.A(A), .B(B), .P(P));
        #100 
        $display("%d * %d = %d\n", A, B, P);

        A <= n'b10110;     // -10
        B <= n'b10101;     // -11
        multiplier #(5) test2(.A(A), .B(B), .P(P));
        #100 
        $display("%d * %d = %d\n", A, B, P);

        $finish
    end

endmodule

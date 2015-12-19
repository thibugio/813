// file: test_full_csa.v
// simulate the CSA using specified test sequences

module test_full_csa();
    parameter n1=4, k1=10;
    parameter n2=5, k2=8;

    reg [n1*k1-1:0] seq1;
    reg [n2*k2-1:0] seq2;

    reg [n1+$bits(k1-1)-1:0] sum1;
    reg [n2+$bits(k2-1)-1:0] sum2;

    reg co1, co2;

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

        sum1 <= {(n1+$bits(k1-1)){1'b0}};
        sum2 <= {(n2+$bits(k2-1)){1'b0}};

        co1 <= 0;
        co2 <= 0;
    end

    always begin
        #10
        full_csa #(.n(n1), .k(k1)) csa1(.In(seq1), .S(sum1), .co(co1));
        full_csa #(.n(n2), .k(k2)) csa2(.In(seq2), .S(sum2), .co(co2));
        #1000
        $display("sum1: %d, \tsum2: %d\n", sum1, sum2);
        $finish
    end

endmodule

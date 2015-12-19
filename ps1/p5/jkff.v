// file: jkff.v
// a JK-flip-flop

module jkff(j, k, clk, q);

    input j, k, clk;
    output q;
    reg nextQ;

    always @(posedge clk) begin
        q = nextQ;
    end

    always @(j or k) begin
        nextQ = (j&(!q)) | ((!k)&q);
    end

endmodule

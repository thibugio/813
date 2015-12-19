module pgGen(a, b, g, p);

    input a, b;
    output g, p;

    parameter delay = 10;

    // gate(output, inputs....)
    and #delay     and0(g,a,b);
    xor #(2*delay) xor0(p,a,b);

endmodule

module sumGen(cn_1, pn, sn);

    input cn_1, pn;
    output sn;

    parameter delay = 10;

    xor #(2*delay) xor0(sn, cn_1, pn);

endmodule

module carryGen(ci, Ps, Gs, cn);

    parameter n=0;
    parameter delay = 10;

    input ci;
    input [n-1:0] Ps, Gs;

    output cn;

    wire [n*n:0] andWires;
    wire [n:0] orWires, gWires, pWires;

    assign gWires[0] = ci;
    assign pWires[n] = 1;

    assign Gs = gWires[n:1];
    assign Ps = pWires[n-1:0];

    // gate(output, inputs...)
    genvar i;
    generate
    for (i=0; i<=n; i=i+1) begin : AND
        and #delay and_i(orWires[i], gWires[i], pWires[n:i]);
    end
    endgenerate

    or  #delay or0 (cn, orWires[n:0]);

endmodule

module lookaheadAdder(an, bn, cn_1, Ps, Gs, pn, gn, sn, cn);
    
    parameter n=0;

    input an, bn, cn_1;
    input [n-1:0] Ps, Gs;

    output pn, gn, sn, cn;

    pgGen pgN(.a(an), .b(bn), .p(pn), .g(gn));

    assign Ps[n] = pn;
    assign Gs[n] = gn;

    carryGen #(n) carryN(.ci(cn_1), .Ps(Ps), .Gs(Gs), .cn(cn));

    sumGen sumN(.cn_1(gn), .pn(pn), .sn(sn));

endmodule

module fullLookaheadAdder(A, B, ci, sumAB, cAB);

    parameter n = 4;

    input [n-1:0] A, B;
    input ci;

    output [n-1:0] sumAB;
    output cAB;

    wire [n:0] carries;
    wire [n-1:0] Ps;
    wire [n-1:0] Gs;

    reg cABready = 1'b0;

    assign carries[0] = ci;
    assign cAB = carries[n];
//    assign cAB = (cABready ? carries[n] : 0);



    genvar i;
    generate
    for (i=0; i<n; i=i+1) begin : LOOKAHEAD_ADDER
        lookaheadAdder #(i) la(.an(A[i]),     .bn(B[i]),     .cn_1(carries[i]), 
                               .Ps(Ps),       .Gs(Gs), 
                               .pn(Ps[i]),    .gn(Gs[i]), 
                               .sn(sumAB[i]), .cn(carries[i+1]));
//        if (i==(n-1)) begin
//            cABready = 1'b1;
//        end
    end
    endgenerate

endmodule

module testFullLookaheadAdder();

    parameter n=8;

    reg [n-1:0] A, B, sumAB, sum, maxA, maxB;
    reg ci, cAB, clk;

    integer delta_t, save_t, t, max_delta, iter;
    
    fullLookaheadAdder #(n) la(.A(A), .B(B), .ci(ci), .S(sumAB), .co(cAB));

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

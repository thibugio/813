// file: lookaheadAdder.v

module lookaheadAdder(an, bn, cn_1, Ps, Gs, pn, gn, sn, cn);
    
    parameter n=0;
    parameter delay=10;

    input an, bn, cn_1;
    input [n-1:0] Ps, Gs;

    output pn, gn, sn, cn;

    pgGen pgN(.a(an), .b(bn), .p(pn), .g(gn));

    assign Ps[n] = pn;
    assign Gs[n] = gn;

    carryGen #(n) carryN(.ci(cn_1), .Ps(Ps), .Gs(Gs), .cn(cn));

    sumGen sumN(.cn_1(gn), .pn(pn), .sn(sn));

endmodule

// file: rippleAdder.v
// a single bit ripple adder with a carry bit

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

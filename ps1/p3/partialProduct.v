// file: partialProduct.v

module partialProduct(multiplicand, multiplierBit, partial);

    parameter n=5; // number of bits in operator
    parameter index = 0; //index into the multiplier; <= n

    input [n-1:0] multiplicand;
    input multiplierBit;

    output [2*n-2:0] partial;  // (2n-1)-bit partial product

    assign partial = {(2*n-1){multiplierBit}} & ((multiplicand << index) >>> index);

endmodule

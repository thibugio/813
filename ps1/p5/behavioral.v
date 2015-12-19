// file: behavioral.v
// behavioral Verilog model for the logic circuit in Problem 5 based on state diagram

module behavioral(clk, x, y1, y2, z1, z2);

    input clk, x;
    output reg y1, y2, z1, z2;
    
    reg y1_next, y2_next;

    always @(posedge clk) begin
        y1 <= y1_next; 
        y2 <= y2_next; 
    end

    always @(x) begin
        y1_next <= (x&(!y1)) | ((x^y2)&y1);
        y2_next <= (!y1) & ((!x) | (!y2));
        z1 <= y1&y2;
        z2 <= !x;
    end

endmodule

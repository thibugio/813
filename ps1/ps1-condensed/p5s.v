module jkff(j, k, clk, q);

    input j, k, clk;
    output reg q;
    reg nextQ;

    always @(posedge clk) begin
        q = nextQ;
    end

    always @(j or k) begin
        nextQ = (j&(!q)) | ((!k)&q);
    end

endmodule


module structural(clk, x, z1, z2, y1, y2);
    input clk, x;
    output z1, z2, y1, y2;

    wire not0_out, and0_out, and1_out, and2_out, and3_out, nor0_out, or0_out, or1_out;

    // gate(output, intputs...)
    not not0(not0_out, x);
    and and0(and0_out, not0_out, (!y2));
    and and1(and1_out, x, y2);
    and and2(and2_out, (!y1), y1);
    and and3(and3_out, y1, y2);
    nor nor0(nor0_out, and0_out, and1_out);
    or  or0 (or0_out, y1, x);
    or  or1 (or1_out, and2_out, not0_out);

    jkff jkff0(.j(x),     .k(nor0_out), .clk(clk), .q(y1));
    jkff jkff1(.j((!y1)), .k(or0_out),  .clk(clk), .q(y2));

    assign z1 = and3_out;
    assign z2 = or1_out;

endmodule


module testStructural();

    reg x, z1, z2, clk, y1, y2;

    structural(.clk(clk), .x(x), .z1(z1), .z2(z2), .y1(y1), .y2(y2));

    initial begin
        $dumpfile("testStructural.vcd");
        $dumpvars;
    end

    initial begin
        x     <= 0;
        z1    <= 0;
        z2    <= 0;
        clk   <= 0;
        y1    <= 0;
        y2    <= 0;
    end

    always begin
        #1
        clk = !clk;
    end

    always begin
        //x = 0
        #10
        case ({y1, y2})
            2'b00:  if (!(z1==0)) begin
                        $display("error! x=0, y1=0, y2=0, but z1=%b\n",z1); 
                    end else if (!(z2==1)) begin
                        $display("error! x=0, y1=0, y2=0, but z2=%b\n",z2); 
                    end
            2'b01:  if (!(z1==0)) begin
                        $display("error! x=0, y1=0, y2=0, but z1=%b\n",z1); 
                    end else if (!(z2==1)) begin
                        $display("error! x=0, y1=0, y2=0, but z2=%b\n",z2); 
                    end
            2'b10:  if (!(z1==0)) begin
                        $display("error! x=0, y1=0, y2=0, but z1=%b\n",z1); 
                    end else if (!(z2==1)) begin
                        $display("error! x=0, y1=0, y2=0, but z2=%b\n",z2); 
                    end
            2'b11:  if (!(z1==1)) begin
                        $display("error! x=0, y1=0, y2=0, but z1=%b\n",z1); 
                    end else if (!(z2==1)) begin
                        $display("error! x=0, y1=0, y2=0, but z2=%b\n",z2); 
                    end
        endcase

        x=1;
        #10
        case ({y1, y2})
            2'b00:  if (!(z1==0)) begin
                        $display("error! x=0, y1=0, y2=0, but z1=%b\n",z1); 
                    end else if (!(z2==0)) begin
                        $display("error! x=0, y1=0, y2=0, but z2=%b\n",z2); 
                    end
            2'b01:  if (!(z1==0)) begin
                        $display("error! x=0, y1=0, y2=0, but z1=%b\n",z1); 
                    end else if (!(z2==0)) begin
                        $display("error! x=0, y1=0, y2=0, but z2=%b\n",z2); 
                    end
            2'b10:  if (!(z1==0)) begin
                        $display("error! x=0, y1=0, y2=0, but z1=%b\n",z1); 
                    end else if (!(z2==0)) begin
                        $display("error! x=0, y1=0, y2=0, but z2=%b\n",z2); 
                    end
            2'b11:  if (!(z1==1)) begin
                        $display("error! x=0, y1=0, y2=0, but z1=%b\n",z1); 
                    end else if (!(z2==0)) begin
                        $display("error! x=0, y1=0, y2=0, but z2=%b\n",z2); 
                    end
        endcase
        $finish;
    end

endmodule

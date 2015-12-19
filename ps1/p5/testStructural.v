// file: testStructural.v

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

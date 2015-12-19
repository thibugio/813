library verilog;
use verilog.vl_types.all;
entity structural is
    port(
        clk             : in     vl_logic;
        x               : in     vl_logic;
        z1              : out    vl_logic;
        z2              : out    vl_logic;
        y1              : out    vl_logic;
        y2              : out    vl_logic
    );
end structural;

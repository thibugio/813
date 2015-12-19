library verilog;
use verilog.vl_types.all;
entity fullAdder is
    generic(
        n               : integer := 4
    );
    port(
        A               : in     vl_logic_vector;
        B               : in     vl_logic_vector;
        ci              : in     vl_logic;
        S               : out    vl_logic_vector;
        co              : out    vl_logic
    );
end fullAdder;

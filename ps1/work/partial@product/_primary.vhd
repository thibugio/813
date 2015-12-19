library verilog;
use verilog.vl_types.all;
entity partialProduct is
    generic(
        n               : integer := 5;
        index           : integer := 0
    );
    port(
        multiplicand    : in     vl_logic_vector;
        multiplierBit   : in     vl_logic;
        partial         : out    vl_logic_vector
    );
end partialProduct;

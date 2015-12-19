library verilog;
use verilog.vl_types.all;
entity nb_csa is
    generic(
        n               : integer := 4
    );
    port(
        X               : in     vl_logic_vector;
        Y               : in     vl_logic_vector;
        Z               : in     vl_logic_vector;
        S               : out    vl_logic_vector;
        Cout            : out    vl_logic_vector
    );
end nb_csa;

library verilog;
use verilog.vl_types.all;
entity lookaheadAdder is
    generic(
        n               : integer := 0;
        delay           : integer := 10
    );
    port(
        an              : in     vl_logic;
        bn              : in     vl_logic;
        cn_1            : in     vl_logic;
        Ps              : in     vl_logic_vector;
        Gs              : in     vl_logic_vector;
        pn              : out    vl_logic;
        gn              : out    vl_logic;
        sn              : out    vl_logic;
        cn              : out    vl_logic
    );
end lookaheadAdder;

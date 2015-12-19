library verilog;
use verilog.vl_types.all;
entity fifo is
    port(
        pclk            : in     vl_logic;
        en              : in     vl_logic;
        clear           : in     vl_logic;
        rw              : in     vl_logic;
        intrw           : in     vl_logic;
        wordIn          : in     vl_logic_vector(7 downto 0);
        intWordIn       : in     vl_logic_vector(7 downto 0);
        wordOut         : out    vl_logic_vector(7 downto 0);
        nempty          : out    vl_logic;
        intr            : out    vl_logic
    );
end fifo;

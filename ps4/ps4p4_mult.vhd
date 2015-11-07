--problem set 4, problem 4: signed multiplier
library ieee;
use ieee.std_logic_1164.all, ieee.numeric_std.all;

entity ps4p4_mult is
    generic (nbits: integer := 4);
    port (multiplicand, multiplier: in signed(nbits-1 downto 0);
          product: out signed (nbits*2-1 downto 0));
end ps4p4_mult;
architecture beh of ps4p4_mult is
    function print(v: signed) return string is
    begin
        return integer'image(to_integer(v));
    end;
    signal m1, m2: signed(nbits-1 downto 0);
begin
    mult: process
        variable partial, term: signed(nbits*2 -1 downto 0);
    begin
        wait until multiplicand'active or multiplier'active;
        wait until multiplicand'delayed'stable(1 ns) and multiplier'delayed'stable(1 ns);

        if multiplicand=to_signed(0,nbits) or multiplier=to_signed(0,nbits) then
            product <= to_signed(0, nbits*2);
            wait for 1 ns;
        else
            if multiplier(multiplier'high) = '1' then --negative multiplier
                m1 <= (not multiplicand) + 1;
                m2 <= (not multiplier) + 1;
            else
                m1 <= multiplicand;
                m2 <= multiplier;
            end if;
            wait until m1'active and m2'active;
            term := (nbits*2 -1 downto nbits => m1(m1'high)) & m1;
            partial := (others => '0');

            for i in 0 to nbits-1 loop --start with lsb
                if m2(i)='1' then
                    partial := partial + term;
                end if;
                term := shift_left(term, 1);
            end loop;
            product <= partial;
            wait for 1 ns;
        end if;
    end process mult;
end architecture beh;

library ieee;
use ieee.std_logic_1164.all, ieee.numeric_std.all;

entity testbench_ps4p4 is end testbench_ps4p4;
architecture beh of testbench_ps4p4 is
    component ps4p4_mult is
        generic (nbits: integer := 4);
        port (multiplicand, multiplier: in signed(nbits-1 downto 0);
              product: out signed (nbits*2-1 downto 0));
    end component;
    function print(v: signed) return string is
    begin
        return integer'image(to_integer(v));
    end;
    constant n: integer := 5;
    constant ninputs: integer := 3;
    type output_t is array (1 to ninputs) of signed(n*2-1 downto 0);
    signal inputs: output_t := (to_signed(-10,n) & to_signed(4,n),
                               to_signed(11,n) & to_signed(-3,n),
                               to_signed(-10,n) & to_signed(-11,n));
    signal outputs: output_t := (to_signed(-40, 2*n),
                                to_signed(-33, 2*n),
                                to_signed(110, 2*n));
    signal multiplicand, multiplier: signed(n-1 downto 0);
    signal product: signed(n*2-1 downto 0);
begin
    mult0: ps4p4_mult generic map (nbits=>n) 
                      port map (multiplicand=>multiplicand, multiplier=>multiplier, product=>product);
    test: process begin
        for i in 1 to ninputs loop
            report "trial " & integer'image(i);
            
            multiplicand <= inputs(i)(n*2-1 downto n);
            multiplier <= inputs(i)(n-1 downto 0);

            wait until product'active;
            wait until product'delayed'stable(1 ns);

            if product = outputs(i) then
                report "success.";
            else
                report "failed test: product = " & print(product) severity warning;
            end if;
        end loop;
        
        report "simulation finished" severity failure;
    end process test;
end architecture beh;

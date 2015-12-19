--problem 1: multiplier
library ieee;
use ieee.std_logic_1164.all;

package multTypes is
    subtype operand_t is std_logic_vector (3 downto 0);
    subtype product_t is std_logic_vector (7 downto 0);
end package multTypes;

library ieee;
use ieee.std_logic_1164.all;
use work.multTypes.all;

entity testBench_p1 is end testBench_p1;
architecture archTestBench_p1 of testBench_p1 is
    signal X, Y: operand_t;
    signal P: product_t;
    signal clk, cout: std_logic := '0';
    component multiplier
        port (X, Y: in operand_t; P: out product_t; Cout: out std_logic);
    end component;
    function decodeBE(vec: std_logic_vector) return integer is
        variable decval: integer := 0;
    begin
        for i in 0 to vec'length-1 loop --vec'low=MSB
            if vec(i) = '1' or vec(i) = 'H' then
                decval:=decval + 2**(vec'length-i);
            end if;
        end loop;
        return decval;
    end;
    function decodeLE(vec: std_logic_vector) return integer is
        variable decval: integer := 0;
    begin
        for i in 0 to vec'length-1 loop --vec'high=MSB
            if vec(i) = '1' or vec(i) = 'H' then
                decval:=decval + 2**i;
            end if;
        end loop;
        return decval;
    end;
    function encodeLE_9b (val: integer) return std_logic_vector is
        variable vec: std_logic_vector (8 downto 0) := (others => '0');
        variable temp: integer := val;
        variable pow: integer;
    begin
        --little endian: MSB in highest (7, rightmost) memory location
        for i in vec'length-1 downto 0 loop
            pow:=2**i;
            if temp >= pow then
                vec(i):='1';
                temp:=temp-pow;
            else
                vec(i):='0';
            end if;
        end loop;
        return vec;
    end;
    function encodeBE_9b (val: integer) return std_logic_vector is
        variable vec: std_logic_vector (8 downto 0) := (others => '0');
        variable temp: integer := val;
        variable pow: integer;
    begin
        --big endian: MSB in lowest (0, leftmost) memory location
        for i in vec'length-1 downto 0 loop
            pow:=2**i;
            if temp >= pow then
                vec(vec'length-1-i):='1';
                temp:=temp-pow;
            else
                vec(vec'length-1-i):='0';
            end if;
        end loop;
        return vec;
    end;
    function vectostring(vec: std_logic_vector) return string is
        variable str: string(1 to vec'length);
    begin
        for i in vec'low to vec'high loop
            if vec(i)='1' or vec(i)='H' then
                str(1 + i-vec'low) := '1';
            else
                str(1 + i-vec'low) := '0';
            end if;
        end loop;
        return str;
    end;
    signal i, j: integer := 0;
    signal done: boolean := false;
begin
    mult0: multiplier port map (X, Y, P, cout);
    clockGen: process (clk) begin
        if clk='0' then
            clk <= '1' after 1 ns, '0' after 2 ns;
        end if;
    end process;
    stimulus: process 
        variable expected: std_logic_vector (8 downto 0);
        variable strX, strY: string(1 to operand_t'length);
        variable strP: string(1 to product_t'length);
        variable strExp: string(1 to product_t'length+1);
        type input_t is array (0 to 15) of operand_t;
        constant inputs: input_t := (0=>"0000", 1=>"1000", 2=>"0100", 3=>"1100", --little endian
                                     4=>"0010", 5=>"1010", 6=>"0110", 7=>"1110", 
                                     8=>"0001", 9=>"1001", 10=>"0101", 11=>"1101", 
                                     12=>"0011", 13=>"1011", 14=>"0111", 15=>"1111");
    begin
        if not done then
            X <= inputs(i); 
            Y <= inputs(j);
            --wait until Cout'active; --transaction on Cout=> multiplication fininshed.
            wait until clk'event and clk'last_value='0' and clk='1';
            expected:=encodeBE_9b(i*j);
            strX:=vectostring(X);
            strY:=vectostring(Y);
            strP:=vectostring(P);
            strExp:=vectostring(expected);
            assert P(7 downto 0)=expected(7 downto 0) and cout=expected(product_t'high+1) 
                report "i=" & integer'image(i) & ", j="&integer'image(j) & ", X="& strX & 
                    ", Y=" & strY & ", P=" & strP & ", cout=" & std_logic'image(cout) & 
                    ", expected " & strExp
                severity warning;
            if j<15 then j <= j + 1;
            else 
                j <= 0;
                if i<15 then i <= i + 1;
                else 
                    done <= true;
                    assert false report "simulation complete." severity warning;
                end if;
            end if; --incr
        end if; --done
    end process;
end architecture archTestBench_p1;


library ieee;
use ieee.std_logic_1164.all;
use work.multTypes.all;

entity multiplier is
    port (X, Y: in operand_t;
          P: out product_t;
          Cout: out std_logic);
end multiplier;
architecture archMult of multiplier is
    component csa
        port (A, B, Cin, Sin: in std_logic;
              Sout, Cout: out std_logic);
    end component;
    component cpa
        port (A, B, Cin: in std_logic;
              Sout, Cout: out std_logic);
    end component;
    type sout_array_t is array(operand_t'low to operand_t'high) of operand_t;
    type cout_array_t is array(operand_t'low to operand_t'high) of operand_t;
    signal souts: sout_array_t;
    signal couts: cout_array_t;
    signal last_couts: operand_t;
begin
    Gen1: for i in operand_t'low to operand_t'high generate
        Gen2: for j in operand_t'low to operand_t'high generate
            Gen3: if i=operand_t'low generate
                Gen4: if j=operand_t'low generate
                    csa_G4: csa port map (X(i), Y(i), '0', '0', P(product_t'low), couts(i)(j));
                end generate;
            end generate;
            Gen6: if i>operand_t'low generate
                Gen5: if j=operand_t'low generate
                    csa_G5: csa port map(X(i), Y(j), couts(i-1)(j), souts(i-1)(j+1), P(product_t'low+i), couts(i)(j));
                Gen7: if j>operand_t'low and j<operand_t'high generate
                    csa_G7: csa port map (X(i), Y(j), couts(i-1)(j), souts(i-1)(j+1), souts(i)(j), couts(i)(j));
                end generate;
                Gen9: if j=operand_t'high generate
                    csa_G9: csa port map (X(i), Y(j), couts(i-1)(j), '0', souts(i)(j), couts(i)(j));
                end generate;
            end generate;
        end generate;
    end generate;
    Gen10: for j in operand_t'low to operand_t'high generate
        Gen12: if j=operand_t'low generate
            cpa_G12: cpa port map (souts(operand_t'high)(j+1), 
                                   couts(operand_t'high)(j), 
                                   '0', 
                                   P(product_t'low+operand_t'high+(j-operand_t'low)), 
                                   last_couts(j));
        end generate;
        Gen13: if j>operand_t'low and j<operand_t'high generate
            cpa_G13: cpa port map (souts(operand_t'high)(j+1), 
                                   couts(operand_t'high)(j), 
                                   last_couts(j-1), 
                                   P(product_t'low+operand_t'high+(j-operand_t'low)), 
                                   last_couts(j));
        end generate;
        Gen14: if j=operand_t'high generate
            cpa_G14: cpa port map ('0', 
                                    couts(operand_t'high)(j), 
                                    last_couts(j-1), 
                                    P(product_t'low+operand_t'high+(j-operand_t'low)), 
                                    Cout);
            end generate;
        end generate;
    end generate;
end architecture archMult;


library ieee;
use ieee.std_logic_1164.all;

entity csa is 
    port (A, B, Cin, Sin: in std_logic;
          Sout, Cout: out std_logic);
end csa;
architecture archcsa of csa is
begin
    process (A, B, Sin, Cin) begin
        Sout <= (A and B) xor Sin xor Cin;
        Cout <= ((A and B) and Sin) or ((A and B) and Cin) or (Sin and Cin);
    end process;
end architecture archcsa;


library ieee;
use ieee.std_logic_1164.all;

entity cpa is  
    port (A, B, Cin: in std_logic;
          Sout, Cout: out std_logic);
end cpa;
architecture archcpa of cpa is
begin
    process (A, B, Cin) begin
        Sout <= A xor B xor Cin;
        Cout <= (A and B) or (A and Cin) or (B and Cin);
    end process;
end architecture archcpa;

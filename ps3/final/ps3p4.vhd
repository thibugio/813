-- problem 4: carry-save adder

-- imports --
library ieee;
use ieee.std_logic_1164.all, ieee.numeric_std.all;
use work.utils.all;

package wordTypes is
    constant wordlen: integer := 8;
    --assert we are adding >= 2 words; also seems silly to need to add 2**32 - 1 words... saving register space
    subtype nwords_t is integer range 2 to 64; 
    subtype nwords_range_t is integer range 0 to nwords_t'high-nwords_t'low;
    subtype wordin_t is std_logic_vector (wordlen-1 downto 0);
    type wordsin_t is array (nwords_range_t range <>) of wordin_t;
end package;

-- top level --

library ieee;
use ieee.std_logic_1164.all, ieee.numeric_std.all;
use work.wordtypes.all; 
use work.utils.all; --mostly defines testbench utilities for printing stuff

--add 10 8-bit binary numbers
entity testbench_p4 is end testbench_p4;
architecture behavior of testbench_p4 is
    constant nwords: nwords_t := 10;
    --11,2,13,4,5,6,7,8,9,10
    signal seq1: wordsin_t(0 to nwords-1) := (B"00001011", B"00000010", B"00001101", B"00000100", B"00000101",
                                 B"00000110", B"00000111", B"00001000", B"00001001", B"00001010");   
    --3,14,5,6,7,8,19,10
    signal seq2: wordsin_t(0 to nwords-1) := (B"00000011", B"00001110", B"00000101", B"00000110", B"00000111",
                                 B"00001000", B"00010011", B"00001010", B"00000000", B"00000000");   
    signal Sum1, Sum2: std_logic_vector (wordlen+bits(nwords)-1 downto 0);--NO_OF_BITS(seq1'length)-1 downto 0);
    signal co1, co2: std_logic;
    signal clk: std_logic := '0';
    component csa
        generic (nwords: integer := 8);
        port (WordsIn: in wordsin_t(0 to nwords-1);
              Sum: out std_logic_vector (wordlen+bits(nwords)-1 downto 0);
              Co: out std_logic);
    end component;
begin
    csa0 : csa
        generic map (nwords => nwords)
        port map (wordsin=>seq1, sum=>Sum1, co=>co1);
    csa1 : csa
        generic map (nwords => nwords)
        port map (wordsin=>seq2, sum=>Sum2, co=>co2);
    clockGen: process (clk) begin
        if clk='0' then
            clk <= '1' after 1 ns, '0' after 2 ns;
        end if;
    end process;
    test: process (clk)
        variable counter: integer := 0;
    begin
        if clk'event and clk'last_value='0' and clk='1' then
            counter := counter + 1;
            if counter > 100 then
                counter := 0;
                assert decode_le(Sum1)=75 
                    report "Sum 1 was "&vec2str_le(Sum1)&" (LE); expected 75" severity warning;
                assert co1='0' 
                    report "carryout 1 was "&std_logic'image(co1)&"; expected '0'" severity warning; 
                assert decode_le(Sum2)=75 
                    report "Sum 1 was "&vec2str_le(Sum2)&" (LE); expected 72" severity warning;
                assert co2='0' 
                    report "carryout 1 was "&std_logic'image(co2)&"; expected '0'" severity warning;
            end if;
        end if;
    end process;
end behavior;

-- components --

library ieee;
use ieee.std_logic_1164.all, ieee.numeric_std.all;
use work.wordTypes.all, work.utils.all;

entity csa is 
    generic (nwords: nwords_t := 8);
    port (WordsIn: in wordsin_t(0 to nwords-1);
          Sum: out std_logic_vector (wordlen+bits(nwords)-1 downto 0);
          Co: out std_logic);
    constant wordoutlen: integer := wordlen+bits(nwords); 
    constant nstages: nwords_t := nwords-2; --number of csa units needed
    constant delta: nwords_t := bits(nwords); --length change from in->out (also num. unique csa stages)
end csa;
architecture structure of csa is
    component csaStage is
        generic (nbits: integer := 8);
        port (A, B, C: in std_logic_vector (nbits-1 downto 0);
              Sum, Co: out std_logic_vector (nbits-1 downto 0));
    end component csaStage;
    component fulladder is
    generic (nbits: integer := 8);
    port (a, b: in std_logic_vector (nbits-1 downto 0);
          ci: in std_logic;
          s: out std_logic_vector (nbits-1 downto 0);
          co: out std_logic);
    end component;


    signal csasum8b, csaco8b: std_logic_vector (wordlen-1 downto 0); 
    signal csasum9b, csaco9b: std_logic_vector (wordlen downto 0); 
    signal csasum10b, csaco10b: std_logic_vector (wordlen+1 downto 0); 
    signal csasum11b, csaco11b: std_logic_vector (wordlen+2 downto 0); 
    type csastage12b_t is array (0 to nwords-delta-1) of std_logic_vector (wordlen+3 downto 0);
    signal csasum12b, csaco12b: csastage12b_t; 
    --apparently the above signals are not globally static expressions (hence the following KLUDGE code); 
    --this is an issue when designs have clock domain crossings; since there is no clk signal explicitly
    --passed between entities, and the entities contain flip flops (i.e., are not purely combinational
    --since they declare internal signals), each entity implicitly is driven by its own separate clock.
    subtype vec9b_t is std_logic_vector (wordlen downto 0);
    subtype vec10b_t is std_logic_vector (wordlen+1 downto 0);
    subtype vec11b_t is std_logic_vector (wordlen+2 downto 0);
    subtype vec12b_t is std_logic_vector (wordlen+3 downto 0);

    signal csasum9from8: vec9b_t := '0' & csasum8b;
    signal csaco9from8: vec9b_t := csaco8b & '0';
    signal csasum10from9: vec10b_t := '0' & csasum9b;
    signal csaco10from9: vec10b_t := csaco9b & '0';
    signal csasum11from10: vec11b_t := '0' & csasum10b;
    signal csaco11from10: vec11b_t := csaco10b & '0';
    signal csasum12from11: vec12b_t := '0' & csasum11b;
    signal csaco12from11: vec12b_t := csaco11b & '0';
    signal csaco12_0_sll: vec12b_t := std_logic_vector(shift_left(unsigned(csaco12b(0)), 1));
    signal csaco12_1_sll: vec12b_t := std_logic_vector(shift_left(unsigned(csaco12b(1)), 1));
    signal csaco12_2_sll: vec12b_t := std_logic_vector(shift_left(unsigned(csaco12b(2)), 1));
    signal csaco12_3_sll: vec12b_t := std_logic_vector(shift_left(unsigned(csaco12b(3)), 1));
    signal wordin3_9b: vec9b_t := B"0" & wordsin(3);
    signal wordin4_10b: vec10b_t := B"00" & wordsin(4);
    signal wordin5_11b: vec11b_t := B"000" & wordsin(5);
    signal wordin6_12b: vec12b_t := B"0000" & wordsin(6);
    signal wordin7_12b: vec12b_t := B"0000" & wordsin(7);
    signal wordin8_12b: vec12b_t := B"0000" & wordsin(8);
    signal wordin9_12b: vec12b_t := B"0000" & wordsin(9);
begin
    process (wordsin) begin
        csasum9from8 <= '0' & csasum8b;
        csaco9from8 <= csaco8b & '0';
        csasum10from9 <= '0' & csasum9b;
        csaco10from9 <= csaco9b & '0';
        csasum11from10 <= '0' & csasum10b;
        csaco11from10 <= csaco10b & '0';
        csasum12from11 <= '0' & csasum11b;
        csaco12from11 <= csaco11b & '0';
        csaco12_0_sll <= std_logic_vector(shift_left(unsigned(csaco12b(0)), 1));
        csaco12_1_sll <= std_logic_vector(shift_left(unsigned(csaco12b(1)), 1));
        csaco12_2_sll <= std_logic_vector(shift_left(unsigned(csaco12b(2)), 1));
        csaco12_3_sll <= std_logic_vector(shift_left(unsigned(csaco12b(3)), 1));
        wordin3_9b <= B"0" & wordsin(3);
        wordin4_10b <= B"00" & wordsin(4);
        wordin5_11b <= B"000" & wordsin(5);
        wordin6_12b <= B"0000" & wordsin(6);
        wordin7_12b <= B"0000" & wordsin(7);
        wordin8_12b <= B"0000" & wordsin(8);
        wordin9_12b <= B"0000" & wordsin(9);
    end process;
    stage0: csaStage generic map (nbits => wordlen) 
                     port map (wordsin(0), wordsin(1), wordsin(2), csasum8b, csaco8b);
    stage1: csaStage generic map (nbits => wordlen+1) 
                     port map (wordin3_9b, csasum9from8, csaco9from8, csasum9b, csaco9b);
    stage2: csaStage generic map (nbits => wordlen+2) 
                     port map (wordin4_10b, csasum10from9, csaco10from9, csasum10b, csaco10b);
    stage3: csaStage generic map (nbits => wordlen+3) 
                     port map (wordin5_11b, csasum11from10, csaco11from10, csasum11b, csaco11b);
    stage4_0: csaStage generic map (nbits => wordlen+delta) 
                     port map (wordin6_12b, csasum12from11, csaco12from11, csasum12b(0), csaco12b(0));
    stage4_1: csaStage generic map (nbits => wordlen+delta) 
                     port map (wordin7_12b, csasum12b(0), csaco12_0_sll, csasum12b(1), csaco12b(1));
    stage4_2: csaStage generic map (nbits => wordlen+delta) 
                     port map (wordin8_12b, csasum12b(1), csaco12_1_sll, csasum12b(2), csaco12b(2));
    stage4_3: csaStage generic map (nbits => wordlen+delta) 
                     port map (wordin9_12b, csasum12b(2), csaco12_2_sll, csasum12b(3), csaco12b(3));
    adder: fulladder generic map (nbits => wordlen+delta)
                     port map (csasum12b(3), csaco12_3_sll, '0', sum, co);
--    stage0: csaStage generic map (nbits => wordlen) 
--                     port map (wordsin(0), wordsin(1), wordsin(2), csasum8b, csaco8b);
--    stage1: csaStage generic map (nbits => wordlen+1) 
--                     port map ('0' & wordsin(3), '0' & csasum8b, csaco8b & '0', csasum9b, csaco9b);
--    stage2: csaStage generic map (nbits => wordlen+2) 
--                     port map (B"00" & wordsin(4), '0' & csasum9b, csaco9b & '0', csasum10b, csaco10b);
--    stage3: csaStage generic map (nbits => wordlen+3) 
--                     port map (B"000" & wordsin(5), '0' & csasum10b, csaco10b & '0', csasum11b, csaco11b);
--    stage4_0: csaStage generic map (nbits => wordlen+delta) 
--                     port map (B"0000"&wordsin(6), '0'& csasum11b, csaco11b & '0', csasum12b(0), csaco12b(0));
--    stage4_1: csaStage generic map (nbits => wordlen+delta) 
--                     port map (B"0000"&wordsin(7),csasum12b(0), csaco12b(0) sll 1, csasum12b(1), csaco12b(1));
--    stage4_2: csaStage generic map (nbits => wordlen+delta) 
--                     port map (B"0000"&wordsin(8),csasum12b(1), csaco12b(1) sll 1, csasum12b(2), csaco12b(2));
--    stage4_3: csaStage generic map (nbits => wordlen+delta) 
--                     port map (B"0000"&wordsin(9),csasum12b(2), csaco12b(2) sll 1, csasum12b(3), csaco12b(3));
--    adder: fulladder generic map (nbits => wordlen+delta)
--                     port map (csasum12b(3), csaco12b(3)(wordlen+2 downto 0) & '0', '0', sum, co);
end structure;

library ieee;
use ieee.std_logic_1164.all, ieee.numeric_std.all;

entity csaStage is
    generic (nbits: integer := 8);
    port (A, B, C: in std_logic_vector (nbits-1 downto 0);
          Sum, Co: out std_logic_vector (nbits-1 downto 0));
end csaStage;
architecture dataflow of csaStage is
begin
process (A, B, C) begin
    for i in 0 to nbits-1 loop
        Sum(i) <= A(i) xor B(i) xor C(i);
        Co(i) <= (A(i) and B(i)) or (A(i) and C(i)) or (B(i) and C(i));
    end loop;
end process;
end dataflow;

library ieee;
use ieee.std_logic_1164.all, ieee.numeric_std.all;

entity fulladder is
    generic (nbits: integer := 4);
    port (a, b: in std_logic_vector (nbits-1 downto 0);
          ci: in std_logic;
          s: out std_logic_vector (nbits-1 downto 0);
          co: out std_logic);
end fulladder;
architecture procedural of fulladder is
    signal tempci: std_logic := ci;
begin
    process (a, b, ci) begin
    for i in 0 to nbits-1 loop
        s(i) <= a(i) xor b(i) xor tempci; --last value of tempci
        if i < nbits-1 then
            tempci <= (a(i) and b(i)) or (a(i) and tempci) or (b(i) and tempci);
        else
            co <= (a(i) and b(i)) or (a(i) and tempci) or (b(i) and tempci);
        end if;
    end loop;
    end process;
end procedural;

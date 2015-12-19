-- problem 4: carry-save adder

-- imports --
library ieee;
use ieee.std_logic_1164.all;

package myTypes is
    constant WordLen: integer := 8;
    constant nWords: integer := 10;
    constant nstages: integer := nWords - 2; --more accurately: bits(nWords)
    constant maxWordLen: integer := WordLen + nstages;
    subtype WORD_IN is std_ulogic_vector ((WordLen-1) downto 0);
    subtype WORD_OUT is std_ulogic_vector ((maxWordLen-1) downto 0);
    type WORDS_IN is array (0 to nWords-1) of WORD_IN;
    type WORDS_OUT is array (0 to nstages-1) of WORD_OUT;
end package myTypes;

library ieee;
use ieee.std_logic_1164.all;
use work.myTypes.all;

-- top level --

--entity testBench is end testBench;
--architecture archTestBench of testBench is
--end archTestBench;

-- components --

entity csa is 
    port (WordsIn: in WORDS_IN; 
          Sum: out WORD_OUT;
          Co: out bit);
end csa;
architecture archCSA of csa is
    component csaStage is
        generic (nbits: integer := 8);
        port (A, B, C: in std_ulogic_vector (nbits-1 downto 0);
              Sum, Co: out std_ulogic_vector (nbits-1 downto 0));
    end component csaStage;
    component fullAdder
        port (A, B: in WORD_OUT;
              ci: in bit;
              Sum: out WORD_OUT;
              co: out bit);
    end component fullAdder;
begin
    process (WordsIn) 
    signal csaStageSums, csaStageCos: WORDS_OUT;
    signal padA, padB, padC: WORD_OUT;
    begin
        if WordsIn'length > 0 then
            padA<=((WordLen-1 downto 0)<=WordsIn(WordsIn'low), others<=0);
        else 
            padA<=(others<=0); 
        end if;
        if WordsIn'length > 1 then
            padB<=((WordLen-1 downto 0)<=WordsIn(WordsIn'low+1), others<=0);
        else
            padB<=(others<=0); 
        end if;
        if WordsIn'length > 2 then
            padC<=((WordLen-1 downto 0)<=WordsIn(WordsIn'low+2), others<=0);
        else
            padC<=(others<=0); 
        end if;
        csa_stage: csaStage 
            generic map (nbits => WordLen + i)
            port map (padA(Wordlen-1 downto 0), padB(Wordlen-1 downto 0), padC(Wordlen-1 downto 0), csaStageSums(0)(Wordlen-1 downto 0), csaStageCos(0)(Wordlen-1 downto 0));
        G_Stages: for i in 0 to (nstages-1) generate
            padA<=((WordLen-1 downto 0)<=WordsIn(3+i), others<=0);
            csa_stage: csaStage 
                generic map (nbits => WordLen + i)
                port map (padA(WordLen+i-1 downto 0), csaStageSums(i-1)(WordLen+i-1 downto 0), (csaStageSums(i-1)(WordLen+i-1 downto 0) sll 1), csaStageSums(i)(WordLen+i-1 downto 0), csaStageCos(i)(WordLen+i-1 downto 0));
        end generate;
        full_adder: fullAdder port map(csaStageSums(csaStageSums'high), csaStageCos(csaStageCos'high), '0', Sum, Co);
    end process;
end archCSA;


entity csaStage is
    generic (nbits: integer := 8);
    port (A, B, C: in std_ulogic_vector (nbits-1 downto 0);
          Sum, Co: out std_ulogic_vector (nbits-1 downto 0);
end csaStage;
architecture archCsaStage of csaStage is
    component unitCsa
        port (a, b, c: in bit;
              sum, carry: out bit);
    end component unitCsa;
begin
    G_Units: for i in A'low to A'high generate
        unit_csa: unitCsa port map (A(i), B(i), C(i), Sum(i), Co(i));
    end generate;
end archCsaStage;


entity unitCsa is
    port (a, b, c: in bit;
          sum, carry: out bit);
end unitCsa;
architecture archUnitCsa of unitCsa is
    process(a, b, c)
    begin
        sum <= a xor b xor c;
        carry <= (a and b) or (a and c) or (b and c);
    end process;
end archUnitCsa;


entity fullAdder is
    port (A, B: in WORD_OUT;
          ci: in bit;
          Sum: out WORD_OUT;
          co: out bit);
end fullAdder;
architecture archFullAdder of fullAdder is
    process (A, B, ci)
    begin
        Sum <= A + B;
        co <= ((A+B) >= 2**(A'range) ? 1 : 0);
    end process;
end archFullAdder;

-- functions --

function bits(A: integer return integer is
    variable count: integer;
    variable A_: integer;
begin
    count:=0;
    A_:=A;
    while (A > 0) loop
        count:=count+1;
        A srl 1;
    end loop;
    return count;
end bits;

--problem set 4, problem 2: logic circuit
library ieee;
use ieee.std_logic_1164.all;

-------------test_bench------------------
library ieee;
use ieee.std_logic_1164.all, ieee.numeric_std.all;

--Present State           Next State          Ouput
--                        x=0     x=1         x=0     x=1
--y1 y2                   y1 y2   y1 y2       z1 z2   z1 z2
-----------------------------------------------------------
--0  0       (s0)         0  1    1  1        0  1    0  0
--0  1       (s1)         0  1    1  0        0  1    0  0
--1  0       (s2)         1  0    0  0        0  1    0  0
--1  1       (s3)         0  0    1  0        1  1    1  0
-----------------------------------------------------------
--x=0: s0->s1->s1
--x=0: s1->s1
--x=0: s2->s2
--x=0: s3->s0->s1->s1
---------------------
--x=1: s0->s3->s2->s0
--x=1: s1->s2->s0->s3->s2->s0
--x=1: s2->s0->s3->s2->s0
--x=1: s3->s2->s0->s3
entity testbench_ps4p2 is end testbench_ps4p2;
architecture behavior of testbench_ps4p2 is 
    component circuit is port (clk, X: in std_logic; Z1, Z2: out std_logic); end component;
    subtype state_t is std_logic_vector (0 to 1);
    subtype input_t is std_logic_vector (0 to 0);
    subtype psi_t is std_logic_vector (0 to (state_t'length + input_t'length - 1)); --P_resent S_tate, I_nput
    function psi2int(psi: psi_t) return integer is
    begin
        return TO_INTEGER(UNSIGNED(psi));
    end;
    type fsm_t is array psi_t'range of state_t; 
    constant fsm: fsm_t := (psi2int(B"000")=>B"01", psi2int(B"001")=>B"11",
                            psi2int(B"010")=>B"01", psi2int(B"011")=>B"10",
                            psi2int(B"100")=>B"10", psi2int(B"101")=>B"00",
                            psi2int(B"110")=>B"00", psi2int(B"111")=>B"10");
    subtype output_t is std_logic_vector (0 to 1);
    type psio_map_t is array psi_t'range of output_t; --P_resent S_tate, I_nput => O_utput
    constant psio_map: psio_map_t := (psi2int(B"000")=>B"10", psi2int(B"001")=>B"00",
                                      psi2int(B"010")=>B"10", psi2int(B"011")=>B"00",
                                      psi2int(B"100")=>B"10", psi2int(B"101")=>B"00",
                                      psi2int(B"110")=>B"11", psi2int(B"111")=>B"10");
    signal clk, x, z1, z2: std_logic;
begin
    circuit0: circuit port map (clk=>clk, x=>x, z1=>z1; z2=>z2);

    clk_gen: process (clk) begin
        if clk='0' then
            clk <= '1' after 1 ns, '0' after 2 ns;
        end if;
    end process;

    test: process 
        type psi_int_t is integer psi_t'range;
        variable psi_counter: psi_int_t := 0;
    begin
        --set input to circuit
        if psi_counter < psi_int_t'right/2 then
            x <= '0';
        else
            x <= '1';
        end if;
        --wait for change in input to take effect
        wait until clk'event and clk'last_value='0' and clk='1';
        --wait for change in output to take effect
        wait until clk'event and clk'last_value='0' and clk='1';
        --assert circuit has the correct output for the input and present (next) state
        if x='0' then
            assert (z1 & z2) = B"01" report "x=0; circuit not in state 01 w output 01" severity warning;
        else
            case (psi_counter - psi_t'right/2) mod 3) is
                when 0 =>
                    assert (z1 & z2) = B"10" report "x=1; circuit not in state 11 w output 10" severity warning;
                when 1 =>
                    assert (z1 & z2) = B"00" report "x=1; circuit not in state 10 w output 00" severity warning;
                when 2 =>
                    assert (z1 & z2) = B"00" report "x=1; circuit not in state 00 w output 00" severity warning;
            end case;
        --increment counter
        if psi_counter < psi_int_t'right then psi_counter := psi_counter + 1;
        else psi_counter := psi_int_t'left;
        end if;
    end process;
end architecture behavior;


library ieee;
use ieee.std_logic_1164.all;


entity circuit is port (clk, X: in std_logic; Z1, Z2: out std_logic); end circuit;

-------------structure_model---------
architecture structure of circuit is
    component not_gate is port (a: in std_logic; b: out std_logic); end component;
    component and_gate is port (a, b: in std_logic; c: out std_logic); end component;
    component or_gate is port (a, b: in std_logic; c: out std_logic); end component;
    component nor_gate is port (a, b: in std_logic; c: out std_logic); end component;
    component jkff is port (clk, j, k: in std_logic; q, qb: out std_logic); end component;
    signal not0_out, and0_out, and1_out, nor0_out, or0_out, y1, y1b, y2, y2b, and2_out: std_logic := '0';
    --note: and3_out=z1, or1_out=z2
begin
    not0: not_gate port map (a=>X, b=>not0_out);
    and0: and_gate port map (a=>not0_out, b=>y2b, c=>and0_out);
    and1: and_gate port map (a=>x, b=>y2, c=>and1_out);
    nor0: nor_gate port map (a=>and0_out, b=>and1_out, c=>nor0_out);
    or0:  or_gate  port map (a=>y1, b=>X, c=>or0_out);
    jkff0: jkff    port map (clk=>clk, j=>X, k=>nor0_out, q=>y1, qb=>y1b);
    jkff1: jkff    port map (clk=>clk, j=>y1b, k=>or0_out, q=>y2, qb=>y2b);
    and2: and_gate port map (a=>y1b, b=>y1, c=>and2_out);
    and3: and_gate port map (a=>y1, b=>y2, c=>Z1);
    or1:  or_gate  port map (a=>not0_out, b=>and2_out, c=>Z2);
end architecture structure;

--------------behavioral_model----------
--Equations: 
--    z1 = y1*y2
--    z2 = x'
--
--    (jkff: y_next = jy' + k'y)
--
--    j1 = x
--    k1 = (x*y2') + (x'*y2)  // x xor y2
--    y1_next = j1*y1' + k1'*y1 = x*y1' + [(x*y2') + (x'*y2)]*y1
--
--    j2 = y1' 
--    k2 = y1+x 
--    y2_next = j1*y2' + k1'*y2 = y1'*y2' + y1'*x'*y2
--
--
--Present State           Next State          Ouput
--                        x=0     x=1         x=0     x=1
--y1 y2                   y1 y2   y1 y2       z1 z2   z1 z2
-----------------------------------------------------------
--0  0                    0  1    1  1        0  1    0  0
--0  1                    0  1    1  0        0  1    0  0
--1  0                    1  0    0  0        0  1    0  0
--1  1                    0  0    1  0        1  1    1  0
-----------------------------------------------------------
architecture behavior of circuit is
    signal y1, y2: std_logic := '0';
begin
    process (clk)
        variable j1, k1, j2, k2, y1_next, y2_next: std_logic;
    begin
        wait until clk'event and clk'last_value='0' and clk='1';
        j1 := X;
        k1 := (X and not y2) or (not x and y2);
        j2 := not y1;
        k2 := y1 or X;

        y1_next := (j1 and not y1) or (not k1 and y1) or (((X and not y2) or (not X and y2)) and y1);
        y2_next := (j1 and not y2) or (not k1 and y2);
        
        Z1 <= y1 and y2;
        Z2 <= not x;

        y1 <= y1_next;
        y2 <= y2_next;
    end process;
end architecture behavior;

library ieee;
use ieee.std_logic_1164.all;

entity not_gate is port (a: in std_logic; b: out std_logic); end entity not_gate;
architecture dataflow of not_gate is
begin
    b <= not a;
end architecture not_gate;


library ieee;
use ieee.std_logic_1164.all;

entity and_gate is port (a, b: in std_logic; c: out std_logic); end entity and_gate;
architecture dataflow of and_gate is
begin
    c <= a and b;
end architecture and_gate;


library ieee;
use ieee.std_logic_1164.all;

entity or_gate is port (a, b: in std_logic; c: out std_logic); end entity or_gate;
architecture dataflow of or_gate is
begin
    c <= a or b;
end architecture or_gate;


library ieee;
use ieee.std_logic_1164.all;

entity nor_gate is port (a, b: in std_logic; c: out std_logic); end entity nor_gate;
architecture dataflow of nor_gate is
begin
    c <= a nor b;
end architecture nor_gate;


library ieee;
use ieee.std_logic_1164.all;

entity xor_gate is port (a, b: in std_logic; c: out std_logic); end entity xor_gate;
architecture dataflow of xor_gate is
begin
    c <= a xor b;
end architecture xor_gate;


library ieee;
use ieee.std_logic_1164.all;

entity ninput_ninput_nand_gate is 
    generic (n: integer := 2);
    port (a: in std_logic_vector(0 to n-1); c: out std_logic); 
end entity nand_gate;
architecture structure of ninput_nand_gate is
    component nand_gate is port (a, b: in std_logic; c: out std_logic); end component;
    signal nands: std_logic_vector (0 to n-2) := (others=>'0');
begin
    G0: if n>1 generate
    G1: for i in 1 to n-1 generate
            G2: if i=1 generate
                    nand0: nand_gate (a=>A(0), b=>A(1), c=>nands(0));
                end generate;
            G3: if i>1 nand i<n-1 generate
                    inners: nand_gate (a=>nands(i-1), b=>A(i), c=>nands(i));
                end generate;
            G4: if i=(n-1) generate
                    nandN: nand_gate (a=>nands(n-2), b=>A(n-1), c=>c);
                end generate;
        end generate;
        end generate;
end architecture ninput_nand_gate;


library ieee;
use ieee.std_logic_1164.all;

entity jkff is port (clk, j, k: in std_logic; q, qb: out std_logic); end entity jkff;
architecture structure of jkff is
    component ninput_nand_gate is 
        generic (n: integer := 2);
        port (a, b: in std_logic_vector(0 to n-1); c: out std_logic); 
    end component;
    signal nand0_out, nand1_out: std_logic;
    signal qb_j_clk: std_logic_vector (0 to 2) := qb & j & clk;
    signal clk_k_q: std_logic_vector (0 to 2) := clk & k & q;
    signal n0o_qb: std_logic_vector (0 to 1) := nand0_out & qb;
    signal n1o_q: std_logic_vector (0 to 1) := nand1_out & q;
begin
    nand0: ninput_nand_gate
        generic map (n=>3)
        port map (a=>qb_j_clk, b=>nand0_out);
    nand1: ninput_nand_gate
        generic map (n=>3)
        port map (a=>clk_k_q, b=>nand1_out);
    nand2: ninput_nand_gate
        generic map (n=>2)
        port map (a=>n0o_qb, b=>q);
    nand3: ninput_nand_gate
        generic map (n=>2)
        port map (a=>n1o_q, b=>qb);
end architecture structure;

architecture behavior of jkff is
begin
    wait until clk'event and clk'last_value='0' and clk='1';
    if (j xor k) = '1' then
        q <= j;
        qb <= not j;
    end if;
end architecture behavior;


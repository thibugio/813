--processor
library ieee;
use ieee.std_logic_1164.all, ieee.numeric_std.all;

package ps4p1_utils is
    constant ww: integer := 32; --word width of the data-path
    constant aw: integer := 12; --address width of the memory
    subtype code_t is std_logic_vector(3 downto 0);
    subtype memword_t is std_logic_vector(ww-1 downto 0);
    subtype memaddr_t is std_logic_vector(aw-1 downto 0);
    function decode_addr(addr: memaddr_t) return integer;
    constant zbus: memword_t := (others => 'Z');
    constant zero_word: memword_t := (others => '0');
    constant op_nop: code_t := X"0";
    constant op_ld: code_t := X"1";
    constant op_str: code_t := X"2";
    constant op_bra: code_t := X"3";
    constant op_xor: code_t := X"4";
    constant op_add: code_t := X"5";
    constant op_rot: code_t := X"6";
    constant op_shf: code_t := X"7";
    constant op_hlt: code_t := X"8";
    constant op_cmp: code_t := X"9";
    constant cc_a: code_t := X"0";
    constant cc_p: code_t := X"1";
    constant cc_e: code_t := X"2";
    constant cc_c: code_t := X"3";
    constant cc_n: code_t := X"4";
    constant cc_z: code_t := X"5";
    constant cc_nc: code_t := X"6";
    constant cc_po: code_t := X"7";
    constant srcreg: std_logic := '0';
    constant srcmem: std_logic := '0';
    constant srcimm: std_logic := '1';
    constant dstreg: std_logic := '0';
    constant dstmem: std_logic := '1';
end package ps4p1_utils;

package body ps4p1_utils is
    function decode_addr(addr: memaddr_t) return integer is
    begin
        return to_integer(unsigned(addr)); 
    end;
end package body ps4p1_utils;

library ieee;
use ieee.std_logic_1164.all, work.ps4p1_utils.all, ieee.numeric_std.all;

entity unit is 
    port (clk: in bit;
          pc_start, pc_stop: in memaddr_t);
end unit;
architecture beh of unit is
    component memory is
        port (
              mem_rw, mem_en: in bit;
              addr: in memaddr_t; 
              dbus: inout memword_t;
              mem_ready: out bit := '0';
              pload: out bit := '0');
    end component;
    component processor is
        port (clk: in bit;
              pc_start, pc_stop: in memaddr_t;
              mem_ready: in bit;
              pload: in bit;
              dbus: inout memword_t;
              addr: out memaddr_t;
              mem_rw, mem_en: out bit := '0'
              );
    end component;
    signal mem_rw, mem_en, mem_ready, pload: bit := '0';
    signal addr: memaddr_t;
    signal dbus: memword_t;
begin
    mem0: memory port map (mem_rw=>mem_rw, mem_en=>mem_en, 
                           addr=>addr, dbus=>dbus, mem_ready=>mem_ready, pload=>pload);
    proc0: processor port map(clk=>clk, pc_start=>pc_start, pc_stop=>pc_stop, mem_ready=>mem_ready,
                              pload=>pload, addr=>addr, dbus=>dbus, mem_rw=>mem_rw, mem_en=>mem_en);
end architecture beh;

library ieee;
use ieee.std_logic_1164.all, work.ps4p1_utils.all, ieee.numeric_std.all;

entity processor is
    port (clk: in bit;
          pc_start, pc_stop: in memaddr_t;
          mem_ready: in bit;
          pload: in bit;
          dbus: inout memword_t;
          addr: out memaddr_t;
          mem_rw, mem_en: out bit); 
end processor;
architecture beh of processor is
    --local processor signals
    type regfile_t is array (0 to 15) of memword_t;
    signal regfile: regfile_t;
    signal pc: memaddr_t;
    signal ir: memword_t;
    signal psr: std_logic_vector(4 downto 0);
    alias op: code_t is ir(31 downto 28);
    alias cc: code_t is ir(27 downto 24);
    alias src_type: std_logic is ir(27);
    alias dst_type: std_logic is ir(26);
    alias src_addr: memaddr_t is ir(23 downto 12);
    alias shf_cnt: memaddr_t is ir(23 downto 12);
    alias dst_addr: memaddr_t is ir(11 downto 0);
    alias car: std_logic is psr(4);
    alias par: std_logic is psr(3);
    alias eve: std_logic is psr(2);
    alias neg: std_logic is psr(1);
    alias zer: std_logic is psr(0);
    ----convenience-operations----
    function printv(v: std_logic_vector) return string is
    begin
        return integer'image(to_integer(unsigned(v)));
    end;
    function printi(i: integer) return string is
    begin
        return integer'image(i);
    end;
    function increment(vec: std_logic_vector) return std_logic_vector is
    begin
        return std_logic_vector(unsigned(vec) + B"1"); 
    end;
    function imm2word (imm: memaddr_t) return memword_t is
        variable word: memword_t;
        variable len: integer := imm'high - imm'low + 1;
    begin
        --assert len <= (memword_t'high - memword_t'low + 1);
        word := (memword_t'high downto len =>'0') & imm;
        return word;
    end;
    function check_regaddr(addr: in memaddr_t) return integer is
        variable regaddr: integer;
    begin
        regaddr := decode_addr(addr);
        assert regaddr >= regfile_t'low and regaddr <= regfile_t'high
            report "register access out of bounds" severity failure;
        return regaddr;
    end;
    function set_psr(res_word: in memword_t; carry: in std_logic) return std_logic_vector is
        variable parity, even, negative, zero: std_logic := '0';
    begin
        for i in memword_t'range loop
            parity := parity xor res_word(i);
        end loop;
        even := res_word(memword_t'low); 
        negative := res_word(memword_t'high); 
        if res_word=zero_word then
            zero := '1';
        else 
            zero := '0';
        end if;
        return zero & negative & even & parity & carry; --4 downto 0
    end;
begin
    process
        variable pc_int, pc_start_int, pc_stop_int, addr_int, shf_int: integer;
        variable res_word: memword_t;
        variable res_word_carry: std_logic_vector(memword_t'high + 1 downto memword_t'low);
        variable res_car: std_logic;
    begin
        wait until clk'event and clk'last_value='0' and clk='1';
        
        if pload='0' or pc_start'active or pc_stop'active then
            --initialize the program counter
            wait until pc_start'delayed'stable(0.5 ns) and pc_stop'delayed'stable(0.5 ns);
            wait until pload='1';
            pc <= pc_start;
            pc_start_int := to_integer(unsigned(pc_start));
            pc_stop_int := to_integer(unsigned(pc_stop));
        else
            pc_int := to_integer(unsigned(pc));
            
            if pc_int <= pc_stop_int then
                report "program counter: " & printi(pc_int);
                --fetch the next instruction from memory
                addr <= pc;
                mem_rw <= '1'; --read
                mem_en <= '1';
                wait until mem_ready ='1';
                mem_en <= '0';
                ir <= dbus;
                wait until clk'event and clk'last_value='0' and clk='1';
                --execute the instruction
                if op=op_nop then
                    pc <= increment(pc); 
                    wait until pc'active;
                    wait until pc'delayed'stable(0.5 ns);
                    report "nop";
                elsif op=op_ld then
                    addr <= src_addr;
                    mem_rw <= '1'; --read
                    mem_en <= '1';
                    wait until mem_ready='1';
                    mem_en <= '0';
                    res_word := dbus;
                    regfile(check_regaddr(dst_addr)) <= res_word;
                    pc <= increment(pc);
                    psr <= set_psr(res_word, '0');
                    wait until pc'active;
                    wait until pc'delayed'stable(0.5 ns);
                    report "ld: reg " & printv(dst_addr) & " = " & printv(res_word); 
                elsif op=op_str then
                    if src_type=srcreg then
                        dbus <= regfile(check_regaddr(src_addr));
                    else
                        dbus <= imm2word(src_addr);
                    end if;
                    addr <= dst_addr;
                    mem_rw <= '0'; --write
                    mem_en <= '1';
                    wait until mem_ready='1';
                    mem_en <= '0';
                    pc <= increment(pc); 
                    psr <= (others => '0');
                    wait until pc'active;
                    wait until pc'delayed'stable(0.5 ns);
                    report "str: mem " & printv(dst_addr) & " = " & printv(dbus); 
                elsif op=op_bra then
                    if (cc=cc_a) 
                      or (cc=cc_p and par='1') 
                      or (cc=cc_e and eve='1') 
                      or (cc=cc_c and car='1') 
                      or (cc=cc_n and neg='1') 
                      or (cc=cc_z and zer='1') 
                      or (cc=cc_nc and car='0') 
                      or (cc=cc_po and neg='0')  then
                        pc <= dst_addr;
                    else
                        pc <= increment(pc);
                    end if;
                    wait until pc'active;
                    wait until pc'delayed'stable(0.5 ns);
                    report "branch";
                elsif op=op_xor then
                    addr_int := check_regaddr(dst_addr);
                    if src_type=srcreg then
                        res_word := regfile(check_regaddr(src_addr));
                    else
                        res_word := imm2word(src_addr);
                    end if;
                    regfile(addr_int) <= std_logic_vector(unsigned(regfile(addr_int)) xor unsigned(res_word));
                    psr <= set_psr(res_word, '0');
                    pc <= increment(pc); 
                    wait until pc'active;
                    wait until pc'delayed'stable(0.5 ns);
                    report "xor: reg " & printi(addr_int) & " = " & printv(regfile(addr_int));
                elsif op=op_add then
                    if src_type=srcreg then
                        res_word := regfile(check_regaddr(src_addr));
                    else
                        res_word := imm2word(src_addr);
                    end if;
                    addr_int := check_regaddr(dst_addr);
                    res_word_carry := std_logic_vector(unsigned(regfile(addr_int)) + unsigned('0' & res_word));
                    regfile(addr_int) <= res_word_carry(memword_t'range);
                    psr <= set_psr(res_word_carry(memword_t'range), res_word_carry(memword_t'high+1));
                    pc <= increment(pc); 
                    wait until pc'active;
                    wait until pc'delayed'stable(0.5 ns);
                    report "add: reg " & printi(addr_int) & " = " & printv(regfile(addr_int));
                elsif op=op_rot then
                    addr_int := check_regaddr(dst_addr);
                    shf_int := to_integer(signed(shf_cnt));
                    if shf_int < 0 then
                        res_word := std_logic_vector(rotate_right(unsigned(regfile(addr_int)), abs(shf_int)));
                        regfile(addr_int) <= res_word;
                        psr <= set_psr(res_word, '0');
                    else
                        res_word := std_logic_vector(rotate_left(unsigned(regfile(addr_int)), shf_int));
                        regfile(addr_int) <= res_word;
                        psr <= set_psr(res_word, '0');
                    end if;
                    pc <= increment(pc); 
                    wait until pc'active;
                    wait until pc'delayed'stable(0.5 ns);
                    report "rot: reg " & printi(addr_int) & " = " & printv(regfile(addr_int));
                elsif op=op_shf then
                    addr_int := check_regaddr(dst_addr);
                    shf_int := to_integer(signed(shf_cnt));
                    if shf_int < 0 then
                        res_word := std_logic_vector(shift_right(unsigned(regfile(addr_int)), abs(shf_int)));
                        regfile(addr_int) <= res_word;
                        psr <= set_psr(res_word, '0');
                    else
                        res_word_carry := std_logic_vector(shift_left('0'&unsigned(regfile(addr_int)),shf_int));
                        regfile(addr_int) <= res_word_carry(memword_t'range);
                        psr <= set_psr(res_word_carry(memword_t'range), res_word_carry(memword_t'high+1));
                    end if;
                    pc <= increment(pc); 
                    wait until pc'active;
                    wait until pc'delayed'stable(0.5 ns);
                    report "shf: reg " & printi(addr_int) & " = " & printv(regfile(addr_int));
                elsif op=op_hlt then
                    pc <= std_logic_vector(to_unsigned(pc_start_int, memaddr_t'high-memaddr_t'low+1));
                    wait until pc'active;
                    wait until pc'delayed'stable(0.5 ns);
                    report "hlt";
                    wait on pc_start; 
                elsif op=op_cmp then
                    if src_type=srcreg then
                        res_word := regfile(check_regaddr(src_addr));
                    else
                        res_word := imm2word(src_addr);
                    end if;
                    res_word := std_logic_vector(not unsigned(res_word));
                    regfile(check_regaddr(dst_addr)) <= res_word;
                    psr <= set_psr(res_word, '0');
                    pc <= increment(pc); 
                    wait until pc'active;
                    wait until pc'delayed'stable(0.5 ns);
                    report "cmp: reg " & printv(dst_addr) & " = " & printv(res_word);
                else 
                    report "instruction not recognized" severity failure;
                end if;
            end if;
        end if;
    end process;

end architecture beh;

library ieee;
use ieee.std_logic_1164.all, work.ps4p1_utils.all, ieee.numeric_std.all;

entity memory is 
    port (plen: in integer;
          pword: in memword_t;
          pc_start: in memaddr_t;
          mem_rw, mem_en: in bit;
          addr: in memaddr_t; 
          dbus: inout memword_t;
          mem_ready: out bit := '0';
          pload: out bit := '0');
    type mem_t is array (0 to 255) of memword_t;
end memory;
architecture beh of memory is
    signal ram: mem_t := (
                          ---------------------------------------------------------
                          --program 1: compute the 2's complement of mem[0], store result to mem[1]
                          ---------------------------------------------------------
                          X"0000_0006", 
                          X"0000_0000",
                          op_ld & srcmem & dstreg & B"00" & X"000" & X"000",
                          op_cmp & srcreg & dstreg & B"00" & X"000" & X"000",
                          op_add & srcimm & dstreg & B"00" & X"001" & X"000",
                          op_str & srcreg & dstmem & B"00" & X"000" & X"001",
                          op_hlt & X"000_0000", others => X"0000_0000"
                          ---------------------------------------------------------
                          --program 2: count the 1's in mem[0], store result to mem[1]
                          ---------------------------------------------------------
                          --X"0101_0101", 
                          --X"0000_0000",
                          --op_ld & srcmem & dstreg & B"00" & X"000" & X"000",
                          --op_ld & srcimm & dstreg & B"00" & X"001" & X"001",--loop counter
                          --op_ld & srcimm & dstreg & B"00" & X"000" & "X002",--temp result
                          --op_shf & srcimm & dstreg & B"00" & X"001" & X"000",--shift the word
                          --op_bra & cc_nc & X"000" & X"008", --jump forward 2
                          --op_add & srcimm & dstreg & B"00" & X"001" & X"002",--inc result
                          --op_shf & srcimm & dstreg & B"00" & X"001" & X"001",--shift the counter
                          --op_bra & cc_z & X"000" & X"00B", --jump forward 2 
                          --op_bra & cc_a & X"000" & X"005", --jump back 5 ('shift the word')
                          --op_str & srcreg & dstmem & B"00" & X"002" & X"001",
                          --op_hlt & X"000_0000", others => X"0000_0000"
                          ---------------------------------------------------------
                          --program 3: multiply 2 signed 4-b numbers: mem[0]*mem[1]->mem[2]
                          ---------------------------------------------------------
                          --X"0000_000A", --multiplier
                          --X"0000_000B", --multiplicand
                          --X"0000_0000",
                          --op_ld & srcmem & dstreg & B"00" & X"001" & X"001", --multiplicand
                          --op_ld & srcmem & dstreg & B"00" & X"000" & X"000", --multiplier
                          --op_bra & cc_po & X"000" & X"00A", --jump forward 5 ('psr->multiplicand')
                          --op_cmp & srcreg & dstreg & B"00" & X"000" & X"000", --2sComp of multiplier
                          --op_add & srcimm & dstreg & B"00" & X"001" & X"000",
                          --op_cmp & srcreg & dstreg & B"00" & X"001" & X"001", --2sComp of multiplicand
                          --op_add & srcimm & dstreg & B"00" & X"001" & X"001",
                          --op_xor & srcimm $ dstreg & B"00" & X"000" & X"001", --psr->multiplicand
                          --op_bra & cc_po & X"000" & X"00E", --jump forward 3 ('loop counter')
                          --op_ld & srcimm & dstreg & B"00" & X"FF0" & X"003", --sign extend multiplicand
                          --op_xor & srcreg & dstreg & B"00" & X"003" & X"001",
                          --op_ld & srcimm & dstreg & B"00" & X"008" & X"002",--loop counter
                          --op_ld & srcreg & dstreg & B"00" & X"000" & X"003",--term
                          --op_ld & srcimm & dstreg & B"00" & X"000" & X"004",--partial product
                          --op_shf & srcimm & dstreg & B"00" & X"001" & X"000", --shift multiplier L 1
                          --op_shf & srcimm & dstreg & B"00" & X"FFF" & X"000", --shift multiplier R 1
                          --op_bra & cc_e & X"000" & X"015", --jump forward 2 ('shift term L 1')
                          --op_add & srcreg & dstreg & B"00" & X"003" & X"004", --add term to partial
                          --op_shf & srcimm & dstreg & B"00" & X"001" & X"003", --shift term L 1
                          --op_shf & srcimm & dstreg & B"00" & X"FFF" & X"002", --shift loop counter L 1
                          --op_bra & cc_z & X"000" & X"012", --jump back 5 ('shift multiplier R 1')
                          --op_str & srcreg & dstmem & B"00" & X"004" & X"002",
                          --op_hlt & X"000_0000", others => X"0000_0000"
                          );
    signal pload_internal: bit := '0';
begin
    process 
        variable pc_start_int, plen, rwaddr: integer;
    begin
        pload <= '1';
        dbus <= zbus;
        
        wait until mem_en'event and mem_en'last_value='0' and mem_en='1';
        
        if mem_rw='1'then --read request
            mem_ready <= '0';
            
            wait until addr'active;
            wait until addr'delayed'stable(0.5 ns);
            
            rwaddr := decode_addr(addr);
            assert 0 <= rwaddr and rwaddr <= 255
                report "invalid memory access" severity failure;
            dbus <= ram(rwaddr); 
            mem_ready <= '1';
        
        else --write request
            mem_ready <= '0';
            
            wait until addr'active and dbus'active;
            wait until addr'delayed'stable(0.5 ns) and dbus'delayed'stable(0.5 ns);

            rwaddr := decode_addr(addr);
            assert 0 <= rwaddr and rwaddr <= 255
                report "invalid memory access" severity failure;
            ram(rwaddr) <= dbus;
            mem_ready <= '1';
        end if;
        
        wait until mem_en = '0';

    end process;
end architecture beh;


library ieee;
use ieee.std_logic_1164.all, ieee.numeric_std.all, work.ps4p1_utils.all;

entity testbench_ps4p1 is end testbench_ps4p1;
architecture beh of testbench_ps4p1 is
    component unit is 
        port (clk: in bit;
              pc_start, pc_stop: in memaddr_t);
    end component;    
    signal clk: bit := '0';
    signal pc_start: memaddr_t := X"002"; 
    signal pc_stop: memaddr_t := X"006"; 
begin
    unit0: unit port map(clk=>clk, pc_stop=>pc_stop, pc_start=>pc_start);
    
    clkgen: process (clk) begin
        if clk='0' then
            clk <= '1' after 0.5 ns, '0' after 1 ns;
        end if;
    end process clkgen;

end architecture beh;

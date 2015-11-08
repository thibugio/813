--processor
library ieee;
use ieee.std_logic_1164.all, ieee.numeric_std.all;

package ps4p1_utils is
    constant ww: integer := 32; --word width of the data-path
    constant aw: integer := 12; --address width of the memory
    subtype code_t is std_logic_vector(3 downto 0);
    subtype memword_t is std_logic_vector(ww-1 downto 0);
    subtype memaddr_t is std_logic_vector(aw-1 downto 0);
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
    function decode_addr(addr: memaddr_t) return integer;
    function printv(v: std_logic_vector) return string;
    function printvs(v: std_logic_vector) return string;
    function printi(i: integer) return string;
end package ps4p1_utils;

package body ps4p1_utils is
    function decode_addr(addr: memaddr_t) return integer is
    begin
        return to_integer(unsigned(addr)); 
    end;
    function printvs(v: std_logic_vector) return string is
    begin
        return integer'image(to_integer(signed(v)));
    end;
    function printv(v: std_logic_vector) return string is
    begin
        return integer'image(to_integer(unsigned(v)));
    end;
    function printi(i: integer) return string is
    begin
        return integer'image(i);
    end;
end package body ps4p1_utils;

library ieee;
use ieee.std_logic_1164.all, work.ps4p1_utils.all, ieee.numeric_std.all;

entity unit is 
    port (clk: in bit;
          pc_start: in memaddr_t);
end unit;
architecture beh of unit is
    component memory is
        port (
              mem_rw, mem_en: in bit;
              addr: in memaddr_t; 
              dbus: inout memword_t;
              mem_ready: buffer bit := '0';
              pload: buffer bit := '0');
    end component;
    component processor is
        port (clk: in bit;
              pc_start: in memaddr_t;
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
    proc0: processor port map(clk=>clk, pc_start=>pc_start, mem_ready=>mem_ready,
                              pload=>pload, addr=>addr, dbus=>dbus, mem_rw=>mem_rw, mem_en=>mem_en);
end architecture beh;

library ieee;
use ieee.std_logic_1164.all, work.ps4p1_utils.all, ieee.numeric_std.all;

entity processor is
    port (clk: in bit;
          pc_start: in memaddr_t;
          mem_ready: in bit;
          pload: in bit;
          dbus: inout memword_t;
          addr: out memaddr_t;
          mem_rw, mem_en: buffer bit); 
end processor;
architecture beh of processor is
    --local processor signals
    type regfile_t is array (0 to 15) of memword_t;
    signal regfile: regfile_t;
    signal busdata: memword_t;
    signal ir: memword_t;
    signal pc: memaddr_t;
    signal psr: std_logic_vector(4 downto 0);
    alias op: code_t is ir(31 downto 28);
    alias cc: code_t is ir(27 downto 24);
    alias src_type: std_logic is ir(27);
    alias dst_type: std_logic is ir(26);
    alias src_addr: memaddr_t is ir(23 downto 12);
    alias shf_cnt: memaddr_t is ir(23 downto 12);
    alias dst_addr: memaddr_t is ir(11 downto 0);
    alias zer: std_logic is psr(4);
    alias neg: std_logic is psr(3);
    alias eve: std_logic is psr(2);
    alias par: std_logic is psr(1);
    alias car: std_logic is psr(0);
    ----convenience-operations----
    function increment(vec: std_logic_vector) return std_logic_vector is
    begin
        return std_logic_vector(unsigned(vec) + B"1"); 
    end;
    function imm2word (imm: memaddr_t) return memword_t is
        variable word: memword_t;
    begin
        word := (memword_t'high downto memaddr_t'high+1 =>'0') & imm;
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
        variable temp_psr: std_logic_vector(psr'range);
        variable tpar: std_logic := '0';
    begin
        temp_psr(0) := carry;   --carry
        for i in memword_t'range loop
            tpar := tpar xor res_word(i);
        end loop;
        temp_psr(1) := tpar; --parity
        temp_psr(2) := not res_word(memword_t'low);  --even
        temp_psr(3) := res_word(memword_t'high);  --negative
        if res_word=zero_word then --zero
            temp_psr(4) := '1';
        else 
            temp_psr(4) := '0';
        end if;
        return temp_psr;
    end;
begin

    busdriver: process begin
        if mem_en='1' and mem_rw='0' then --write to memory
            dbus <= busdata;
        else 
            dbus <= (others => 'Z');
        end if;
        wait on mem_en, mem_rw;
    end process busdriver;

    process
        variable pc_int, addr_int, shf_int: integer;
        variable res_word: memword_t;
        variable res_word_carry: std_logic_vector(memword_t'high + 1 downto memword_t'low);
        variable res_car: std_logic;
    begin
        mem_en <= '0';
        wait until clk'event and clk'last_value='0' and clk='1';
        
        if pload='0' or pc_start'active then
            --initialize the program counter
            report "initializing program counter";
            --wait until pc_start'delayed'stable(0.25 ns);
            --report "pc_Start stable";
            wait until pload='1';
            pc <= pc_start;
            psr <= (others => '0');
        else
            pc_int := to_integer(unsigned(pc));
            
            report "program counter: " & printi(pc_int);
            report "psr car-par-eve-neg-zer: " & std_logic'image(car) & std_logic'image(par)  & std_logic'image(eve) & std_logic'image(neg) & std_logic'image(zer);   
            --fetch the next instruction from memory
            addr <= pc;
            mem_rw <= '1'; --read
            mem_en <= '1';
            --wait until mem_ready ='1';
            while mem_ready='0' loop
                wait until clk'event and clk'last_value='0' and clk='1';
            end loop;
            ir <= dbus;
            wait until clk'event and clk'last_value='0' and clk='1';
            mem_en <= '0';
            wait until clk'event and clk'last_value='0' and clk='1';
            
            --execute the instruction
            if op=op_nop then
                pc <= increment(pc); 
                wait until clk'event and clk'last_value='0' and clk='1';
                report "nop";
            elsif op=op_ld then
                if src_type=srcmem then
                    addr <= src_addr;
                    mem_rw <= '1'; --read
                    mem_en <= '1';
                    wait until clk'event and clk'last_value='0' and clk='1';
                    --wait until mem_ready='1';
                    while mem_ready='0' loop
                        wait until clk'event and clk'last_value='0' and clk='1';
                    end loop;
                    res_word := dbus;
                    wait until clk'event and clk'last_value='0' and clk='1';
                    mem_en <= '0';
                else
                    res_word := imm2word(src_addr);
                end if;
                regfile(check_regaddr(dst_addr)) <= res_word;
                pc <= increment(pc);
                psr <= set_psr(res_word, '0');
                wait until clk'event and clk'last_value='0' and clk='1';
                report "ld: reg " & printv(dst_addr) & " = " & printvs(res_word); 
            elsif op=op_str then
                if src_type=srcreg then
                    busdata <= regfile(check_regaddr(src_addr));
                else
                    busdata <= imm2word(src_addr);
                end if;
                addr <= dst_addr;
                mem_rw <= '0'; --write
                mem_en <= '1';
                wait until clk'event and clk'last_value='0' and clk='1';
                --wait until mem_ready='1';
                while mem_ready='0' loop
                    wait until clk'event and clk'last_value='0' and clk='1';
                end loop;
                mem_en <= '0';
                pc <= increment(pc); 
                psr <= (others => '0');
                wait until clk'event and clk'last_value='0' and clk='1';
                report "str: mem " & printv(dst_addr) & " = " & printvs(busdata); 
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
                wait until clk'event and clk'last_value='0' and clk='1';
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
                wait until clk'event and clk'last_value='0' and clk='1';
                report "xor: reg " & printi(addr_int) & " = " & printvs(regfile(addr_int));
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
                wait until clk'event and clk'last_value='0' and clk='1';
                report "add: reg " & printi(addr_int) & " = " & printvs(regfile(addr_int));
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
                wait until clk'event and clk'last_value='0' and clk='1';
                report "rot: reg " & printi(addr_int) & " = " & printvs(regfile(addr_int));
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
                wait until clk'event and clk'last_value='0' and clk='1';
                report "shf: reg " & printi(addr_int) & " = " & printvs(regfile(addr_int));
            elsif op=op_hlt then
                report "program halted" severity failure;
                wait until pc_start'active; 
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
                wait until clk'event and clk'last_value='0' and clk='1';
                --wait until pc'active;
                --wait until pc'delayed'stable(0.25 ns);
                report "cmp: reg " & printv(dst_addr) & " = " & printvs(res_word);
            else 
                report "instruction not recognized" severity failure;
            end if;
        end if; --pload='0' or pc_start'active
    end process;

end architecture beh;

library ieee;
use ieee.std_logic_1164.all, work.ps4p1_utils.all, ieee.numeric_std.all;

entity memory is 
    port (
          mem_rw, mem_en: in bit;
          addr: in memaddr_t; 
          dbus: inout memword_t;
          mem_ready: buffer bit := '0';
          pload: buffer bit := '0');
    type mem_t is array (0 to 2**aw-1) of memword_t;
end memory;
architecture beh of memory is
    signal ram: mem_t := (
                          ---------------------------------------------------------
                          --program 1: compute the 2's complement of mem[0], store result to mem[1]
                          ---------------------------------------------------------
                          --0=>X"0000_0006", 
                          --1=>X"0000_0000",
                          --2=>op_ld & srcmem & dstreg & B"00" & X"000" & X"000",
                          --3=>op_cmp & srcreg & dstreg & B"00" & X"000" & X"000",
                          --4=>op_add & srcimm & dstreg & B"00" & X"001" & X"000",
                          --5=>op_str & srcreg & dstmem & B"00" & X"000" & X"001",
                          --6=>op_hlt & X"000_0000", others => X"0000_0000"
                          ---------------------------------------------------------
                          --program 2: count the 1's in mem[0], store result to mem[1]
                          ---------------------------------------------------------
                          0=>X"0101_0101", 
                          1=>X"0000_0000",
                          2=>op_ld & srcmem & dstreg & B"00" & X"000" & X"000",
                          3=>op_ld & srcimm & dstreg & B"00" & X"001" & X"001",--loop counter
                          4=>op_ld & srcimm & dstreg & B"00" & X"000" & X"002",--result
                          5=>op_shf & srcimm & dstreg & B"00" & X"001" & X"000",--shift the word L 1
                          6=>op_bra & cc_nc & X"000" & X"008", --jump forward 2
                          7=>op_add & srcimm & dstreg & B"00" & X"001" & X"002",--inc result
                          8=>op_shf & srcimm & dstreg & B"00" & X"001" & X"001",--shift the counter L 1
                          9=>op_bra & cc_nc & X"000" & X"005", --jump back 5 ('shift the word')
                          --9=>op_hlt & X"000_0000",
                          10=>op_str & srcreg & dstmem & B"00" & X"002" & X"001",
                          11=>op_hlt & X"000_0000", others => X"0000_0000"
                          ---------------------------------------------------------
                          --program 3: multiply 2 signed 4-b numbers: mem[0]*mem[1]->mem[2]
                          ---------------------------------------------------------
                          --0=>X"0000_000A", --multiplier
                          --1=>X"0000_000B", --multiplicand
                          --2=>X"0000_0000",
                          --3=>op_ld & srcmem & dstreg & B"00" & X"001" & X"001", --multiplicand
                          --4=>op_ld & srcmem & dstreg & B"00" & X"000" & X"000", --multiplier
                          --5=>op_bra & cc_po & X"000" & X"00A", --jump forward 5 ('psr->multiplicand')
                          --6=>op_cmp & srcreg & dstreg & B"00" & X"000" & X"000", --2sComp of multiplier
                          --7=>op_add & srcimm & dstreg & B"00" & X"001" & X"000",
                          --8=>op_cmp & srcreg & dstreg & B"00" & X"001" & X"001", --2sComp of multiplicand
                          --9=>op_add & srcimm & dstreg & B"00" & X"001" & X"001",
                          --10=>op_xor & srcimm $ dstreg & B"00" & X"000" & X"001", --psr->multiplicand
                          --11=>op_bra & cc_po & X"000" & X"00E", --jump forward 3 ('loop counter')
                          --12=>op_ld & srcimm & dstreg & B"00" & X"FF0" & X"003", --sign extend multiplicand
                          --13=>op_xor & srcreg & dstreg & B"00" & X"003" & X"001",
                          --14=>op_ld & srcimm & dstreg & B"00" & X"008" & X"002",--loop counter
                          --15=>op_ld & srcreg & dstreg & B"00" & X"000" & X"003",--term
                          --16=>op_ld & srcimm & dstreg & B"00" & X"000" & X"004",--partial product
                          --17=>op_shf & srcimm & dstreg & B"00" & X"001" & X"000", --shift multiplier L 1
                          --18=>op_shf & srcimm & dstreg & B"00" & X"FFF" & X"000", --shift multiplier R 1
                          --19=>op_bra & cc_e & X"000" & X"015", --jump forward 2 ('shift term L 1')
                          --20=>op_add & srcreg & dstreg & B"00" & X"003" & X"004", --add term to partial
                          --21=>op_shf & srcimm & dstreg & B"00" & X"001" & X"003", --shift term L 1
                          --22=>op_shf & srcimm & dstreg & B"00" & X"FFF" & X"002", --shift loop counter L 1
                          --23=>op_bra & cc_z & X"000" & X"012", --jump back 5 ('shift multiplier R 1')
                          --24=>op_str & srcreg & dstmem & B"00" & X"004" & X"002",
                          --25=>op_hlt & X"000_0000", others => X"0000_0000"
                          );
    signal busdata: memword_t;
    signal rready, wready: bit := '0';
begin
    control: process begin
        if pload='0' then
            wait for 1 ns;
            pload <= '1';
        end if; 
      
        --if mem_en='1' and mem_rw='1' then --read request
        if mem_en='1' and rready='1' then
            dbus <= busdata;
            --report "dbus has data: " & printvs(busdata);
        else
            dbus <= (others => 'Z');
            --report "dbus tristated.";
        end if;

        if mem_en='1' and (rready='1' or wready='1') then
            mem_ready <= '1';
            --report "set mem_ready = 1";
        else 
            mem_ready <= '0';
            --report "set mem_ready = 0";
        end if;

        wait on mem_en, mem_rw, rready, wready;
    end process control;

    read: process --(pload, mem_en, mem_rw)
        variable rwaddr: integer;
    begin
        if pload='1' and mem_en='1' and mem_rw='1' then
            rwaddr := decode_addr(addr);
            busdata <= ram(rwaddr);
            rready <= '1';
            report "fetched memory location " & integer'image(rwaddr);
        else
            busdata <= (others=>'0');
            rready <= '0';
        end if;
        wait on pload, mem_en, mem_rw;
    end process read;

    write: process --(pload, mem_en, mem_rw)
        variable rwaddr: integer;
    begin
        if pload='1' and mem_en='1' and mem_rw='0' then
            rwaddr := decode_addr(addr);
            ram(rwaddr) <= dbus;
            wready <= '1';
            report "stored word at memory location " & integer'image(rwaddr);
        else
            wready <= '0';
        end if;
        wait on pload, mem_en, mem_rw;
    end process write;
            
end architecture beh;


library ieee;
use ieee.std_logic_1164.all, ieee.numeric_std.all, work.ps4p1_utils.all;

entity testbench_ps4p1 is end testbench_ps4p1;
architecture beh of testbench_ps4p1 is
    component unit is 
        port (clk: in bit;
              pc_start: in memaddr_t);
    end component;    
    signal clk: bit := '0';
    signal pc_start: memaddr_t := X"002"; 
begin
    unit0: unit port map(clk=>clk, pc_start=>pc_start);
    
    clkgen: process (clk) begin
        if clk='0' then
            clk <= '1' after 1 ns, '0' after 2 ns;
        end if;
    end process clkgen;

end architecture beh;

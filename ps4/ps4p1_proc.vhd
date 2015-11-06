--processor
library ieee;
use ieee.std_logic_1164.all, ieee.numeric_std.all;

package ps4p1_utils is
    subtype code_t is std_logic_vector(3 downto 0);
    subtype memword_t is std_logic_vector(31 downto 0);
    subtype memaddr_t is std_logic_vector(11 downto 0);
    type program_t is array (integer range <>) of memword_t;
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
          program: in program_t;
          pc_start: in memaddr_t);
    
end unit;
architecture beh of unit is
begin
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
          mem_r, mem_w, mem_en: out bit := '0'
          );
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
    function is_initialized(vec: std_logic_vector) return boolean is
    begin
        for i in vec'range loop
            if vec(i)='X' or vec(i)='U' then
                return false;
            end if;
        end loop;
        return true;
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
        variable pc_int, pc_stop_int, addr_int, shf_int: integer;
        variable res_word: memword_t;
        variable res_word_carry: std_logic_vector(memword_t'high + 1 downto memword_t'low);
        variable res_car: std_logic;
    begin
        wait until clk'event and clk'last_value='0' and clk='1';
        
        if pload='0' or not is_initialized(pc) or pc_start'event then
            --initialize the program counter
            wait until pc_start'delayed'stable(1 ns);
            pc <= pc_start;
            pc_stop_int := to_integer(unsigned(pc_stop));
        else
            pc_int := to_integer(unsigned(pc)); 
            
            if pc_int <= pc_stop_int then
                --fetch the next instruction from memory
                --it would be nice to wrap mem r/ws in a procedure, but can't drive signal from procedure (?)
                mem_en <= '1';
                addr <= pc;
                mem_r <= '1';
                wait until mem_ready ='1';
                mem_r <= '0';
                mem_en <= '0';
                ir <= dbus;
                wait until clk'event and clk'last_value='0' and clk='1';
                --execute the instruction
                if op=op_nop then
                    pc <= increment(pc); 
                elsif op=op_ld then
                    mem_en <= '1';
                    addr <= src_addr;
                    mem_r <= '1';
                    wait until mem_ready='1';
                    mem_r <= '0';
                    mem_en <= '0';
                    res_word := dbus;
                    regfile(check_regaddr(dst_addr)) <= res_word;
                    pc <= increment(pc);
                    psr <= set_psr(res_word, '0');
                elsif op=op_str then
                    if src_type=srcreg then
                        dbus <= regfile(check_regaddr(src_addr));
                    else
                        dbus <= imm2word(src_addr);
                    end if;
                    mem_en <= '1';
                    addr <= dst_addr;
                    mem_w <= '1';
                    wait until mem_ready='1';
                    mem_w <= '0';
                    mem_en <= '0';
                    pc <= increment(pc); 
                    psr <= (others => '0');
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
                        report "condition code not recognized" severity failure;
                    end if;
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
                elsif op=op_rot then
                    addr_int := check_regaddr(dst_addr);
                    shf_int := to_integer(signed(shf_cnt));
                    if shf_int < 0 then
                        res_word := std_logic_vector(rotate_right(unsigned(regfile(addr_int)), natural(abs(shf_int))));
                        regfile(addr_int) <= res_word;
                        psr <= set_psr(res_word, '0');
                    else
                        res_word := std_logic_vector(rotate_left(unsigned(regfile(addr_int)), natural(shf_int)));
                        regfile(addr_int) <= res_word;
                        psr <= set_psr(res_word, '0');
                    end if;
                    pc <= increment(pc); 
                elsif op=op_shf then
                    addr_int := check_regaddr(dst_addr);
                    shf_int := to_integer(signed(shf_cnt));
                    if shf_int < 0 then
                        res_word := std_logic_vector(shift_right(unsigned(regfile(addr_int)), natural(abs(shf_int))));
                        regfile(addr_int) <= res_word;
                        psr <= set_psr(res_word, '0');
                    else
                        res_word_carry := std_logic_vector(shift_left('0' & unsigned(regfile(addr_int)), natural(shf_int)));
                        regfile(addr_int) <= res_word_carry(memword_t'range);
                        psr <= set_psr(res_word_carry(memword_t'range), res_word_carry(memword_t'high+1));
                    end if;
                    pc <= increment(pc); 
                elsif op=op_hlt then
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
    port (
          program: in program_t;
          pc_start: in memaddr_t;
          mem_r, mem_w, mem_en: in bit;
          addr: in memaddr_t; 
          dbus: inout memword_t;
          mem_ready: out bit := '0';
          pload: out bit := '0');
    type mem_t is array (0 to 255) of memword_t;
end memory;
architecture beh of memory is
    signal ram: mem_t; 
    signal pload_internal: bit := '0';
begin
    process 
        variable pc_start_int, plen, rwaddr: integer;
    begin
        --initialize the memory
        if pload_internal='0' then
            wait until program'event or pc_start'event; 
            wait until program'delayed'stable(1 ns) and pc_start'delayed'stable(1 ns);
           
            pc_start_int := to_integer(unsigned(pc_start));
            plen := program'high - program'low + 1;
            assert plen <= 256 report "program too long" severity failure;

            for i in 0 to plen-1 loop
                ram(i) <= program(i); 
            end loop;

            pload <= '1';
            pload_internal <= '1';
            mem_ready <= '0';
            dbus <= zbus;
            wait until pload_internal='1';
        end if;

        --handle cpu requests during program execution
        if pload_internal='1' then
            dbus <= zbus;
            wait until dbus=zbus;
        else
            if mem_en='1' then
                if mem_r'event and mem_r'last_value='0' and mem_r='1' then --read request
                    mem_ready <= '0';
                    wait until addr'active and addr'delayed'stable(1 ns);
                    rwaddr := decode_addr(addr);
                    assert pc_start_int <= rwaddr and rwaddr <= pc_start_int + plen 
                        report "attempted to read from memory outside of program bounds" 
                        severity warning;
                    dbus <= ram(rwaddr); 
                    mem_ready <= '1';
                elsif mem_w'event and mem_w'last_value='0' and mem_w='1' then --write request
                    mem_ready <= '0';
                    wait until addr'active and dbus'active;
                    wait until addr'delayed'stable(1 ns) and dbus'delayed'stable(1 ns);

                    rwaddr := decode_addr(addr);
                    assert pc_start_int <= rwaddr and rwaddr <= pc_start_int + plen 
                        report "attempted to read from memory outside of program bounds" 
                        severity warning;
                    ram(rwaddr) <= dbus;
                    mem_ready <= '1';
                end if;
                wait until mem_en='0';
            end if;
        end if;
        wait on mem_en, pc_start, program;
    end process;
end architecture beh;

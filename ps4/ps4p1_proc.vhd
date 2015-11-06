--processor
library ieee;
use ieee.std_logic_1164.all, ieee.numeric_std.all;

package ps4p1_utils is
    subtype memword_t is std_logic_vector(31 downto 0);
    subtype memaddr_t is std_logic_vector(11 downto 0);
    type program_t is array (integer range <>) of memword_t;
    function decode_addr(addr: memaddr_t) return integer;
    constant zbus: memword_t := (others => 'Z');
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
    alias op: std_logic_vector(3 downto 0) is ir(31 downto 28);
    alias cc: std_logic_vector(3 downto 0) is ir(27 downto 24);
    alias srctype: std_logic is ir(27);
    alias dsttype: std_logic is ir(26);
    alias src_addr: std_logic_vector(memaddr_t'range) is ir(23 downto 12);
    alias srcnt: std_logic_vector(memaddr_t'range) is ir(23 downto 12);
    alias dst_addr: std_logic_vector(memaddr_t'range) is ir(11 downto 0);
    alias car: std_logic is psr(4);
    alias par: std_logic is psr(3);
    alias eve: std_logic is psr(2);
    alias neg: std_logic is psr(1);
    alias zer: std_logic is psr(0);
    constant srcreg: std_logic := '0';
    constant srcmem: std_logic := '0';
    constant srcimm: std_logic := '1';
    constant dstreg: std_logic := '0';
    constant dstmem: std_logic := '1';
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
    --local signals
    signal mem_addr: memaddr_t;
    signal mem_word: memword_t;
    signal memr_req: bit := '0';
    signal memw_req: bit := '0';
    signal memrw_fin: bit := '0';
begin
    process
        variable pc_int, pc_stop_int: integer;
    begin
        wait until clk'event and clk'last_value='0' and clk='1';
        
        if pload='0' or not is_initialized(pc) then
            --initialize the program counter
            wait until pc_start'delayed'stable(1 ns);
            pc <= pc_start;
            pc_stop_int := to_integer(unsigned(pc_stop));
        else
            pc_int := to_integer(unsigned(pc)); 
            
            if pc_int <= pc_stop_int then
                --fetch the next instruction from memory
                mem_addr <= pc;
                memr_req <= '1';
                wait until memrw_fin ='1';
                ir <= mem_word;
                --execute the instruction
            end if;
        end if;
    end process;

    mem_rw: process
    begin
        wait until (memr_req ='1' and memw_req ='0') or (memr_req='1' and memw_req='0');
        memrw_fin <= '0';
        mem_en <= '1';
        addr <= mem_addr;
        if memr_req='1' then
            mem_r <= '1';
            mem_w <= '0';
        else
            mem_r <= '0';
            mem_w <= '1';
        end if;
        wait until mem_ready='1';
        if memr_req='1' then
            mem_word <= dbus;
        else 
            dbus <= mem_word;
        end if;
        mem_en <= '0';
        mem_r <= '0';
        mem_w <= '0';
        memrw_fin <= '1';
    end process mem_rw;

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

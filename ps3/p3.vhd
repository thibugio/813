-- problem 3: cache memory
library ieee;
use ieee.std_logic_1164.all;

package MemTypes is 
    function decode (vec:std_ulogic_vector) return integer; --range will be set when it is called
    constant mtagWidth: integer := 5; --bits of the memory address 'tag' field
    constant mindexWidth: integer := 3; --bits of the memory address 'index' field
    constant mbyteWidth: integer := 2; --bits of the memory address 'byte' field
    subtype mbyteRange is integer range 0 to (2**mbyteWdith)-1;
    type mbyteField is ("00", "01", "10", "11");
    subtype Maddress_t is std_ulogic_vector (9 downto 0);
    subtype mbyte_t is std_ulogic_vector (byteWidth-1 downto 0);
    subtype mindex_t is std_ulogic_vector (indexWidth-1 downto 0);
    subtype mtag_t is std_ulogic_vector (tagWidth-1 downto 0);
    function mbyte (address: Maddress_t) return mbyte_t;
    function mindex (address: Maddress_t) return mindex_t;
    function mtag (address: Maddress_t) return mtag_t;
--    type MemAddressRec_t is record
--        Address: std_ulogic_vector (byteWdith+indexWidth+tagWdidth-1 downto 0);
--        Byte: mbyte_t;
--        Index: mindex_t;
--        Tag: mtag_t;
--    end record MemAddressRec_t;
    subtype mbyte_t is std_ulogic_vector (7 downto 0);
    subtype mword_t is array (mbyteRange'low to mbyteRange'high) of mbyte_t;
    type MainMem_t is array (0 to 255) of mword_t;
    type Cache_t is array (mindex_t) of (mtag_t, mword_t); 
    function fetchWord (address: Maddress_t, cache: Cache_t, mem: MainMem_t) return mword_t;
    function fetchByte (address: Maddress_t, cache: Cache_t, mem: MainMem_t) return mbyte_t;
    function writeWord(Pdata: mword_t, address: Maddress_t, cache: Cache_t, mem: MainMem_t) return boolean; 
    function isHit (address: Maddress_t, cache: Cache_t) return boolean; 
    function fetchWordFromCache (address: Maddress_t, cache: Cache_t) return mword_t;
    function fetchWordFromMain (address: Maddress_t, mem: MainMem_t) return mword_t;
    function fetchByteFromMain (address: Maddress_t, mem: MainMem_t) return mbyte_t;
    function writeWordToCache (address: Maddress_t, data: mword_t, cache: Cache_t) return boolean;
    constant initialMem: MainMem_t := (117 <= ("01110101","01110100","01110011","01110010"),--75h
                                       101 <= ("01100101","01100100","01100011","01100010"),--65h
                                       89  <= ("01011001","01011000","01010111","01010110"),--59h
                                       others <= ("00000000","00000000","00000000","00000000"));
end package MemTypes;
package body MemTypes is
    function decode (vec:std_ulogic_vector) return integer is 
        variable int:integer;
    begin
        int := 0;
        for i in vec'low to vec'high loop
            int:=int + vec(i)*2**i;
        end loop;
        return int;
    end;
    function mbyte (address: Maddress_t) return mbyte_t is
        variable byte: mbyte_t;
    begin
        byte := address(mbyteWidth-1 downto 0);
        return byte;
    end;
    function mindex (address: Maddress_t) return mindex_t is
        variable index: mindex_t;
    begin
        index := address(mindexWidth+mbyteWidth-1 downto mbyteWidth);
        return index;
    end;
    function mtag (address: Maddress_t) return mtag_t is
        variable tag: mtag_t;
    begin
        tag := address(mtagWidth+mindexWidth+mbyteWidth-1 downto mindexWidth+mbyteWidth);
        return tag;
    end;
    function isHit (address: Maddress_t, cache: Cache_t) return boolean is 
    begin
        return mtag(address) = cache(mindex(address))(0);
    end;
    function fetchWordFromCache (address: Maddress_t, cache: Cache_t) return mword_t is 
        variable index: mindex_t;
    begin
        index:=mindex(address);
        return cache(index)(1);
    end;
    function fetchWordFromMain (address: Maddress_t, mem: MainMem_t, cache: Cache_t) return mword_t is 
        variable data: mword_t;
    begin
        data:=mem(decode(address(Maddress_t'high downto mbyteWidth)));
        cache(mindex(address)):=(mtag(address), data); --store for future use
        return data;
    end;
    function fetchWord (address: Maddress_t, cache: Cache_t, mem: MainMem_t) return mword_t is 
    begin
        if isHit(address, cache) then return fetchWordFromCache(address, cache);
        else return fetchWordFromMain(address, mem, cache);
        end if;
    end;
    function fetchByte (address: Maddress_t, cache: Cache_t, mem: MainMem_t) return mbyte_t is 
        variable data: mword_t;
        variable b: mbyteRange;
    begin
        data:=fetchWord(address, cache, mem);
        b:=decode(mbyte(address));
        return data(b);
    end;
    function fetchByteFromMain (address: Maddress_t, mem: MainMem_t) return mbyte_t is
        variable data: mword_t;
        variable b: mbyteRange;
    begin
        data:=mem(decode(address(Maddress_t'high downto mbyteWidth)));
        b:=decode(mbyte(address));
        return data(b);
    end;
    function writeWordToCache (address: Maddress_t, data: mword_t, cache: Cache_t) return boolean is
    begin
        cache(mindex(address)) := (mtag(address), data); 
    end;
    function writeWord(Pdata: mword_t, address: Maddress_t, cache: Cache_t, mem: MainMem_t) return boolean is
    begin
        --write word to cache and main memory in parallel
        mem(decode(memaddress(Maddress_t'high downto mbyteWidth))) := Pdata;
        cache(mindex(memaddress)) := (mtag(memaddress), Pdata); 
        return '1';
    end;
end package body MemTypes;

package InterfaceTypes is
    constant itagWidth: integer := 6; --bits of the interface address 'tag' field
    constant iindexWidth: integer := 3; --bits of the interface address 'index' field
    constant ibyteWidth: integer := 2; --bits of the interface address 'byte' field
    subtype Iaddress_t is std_ulogic_vector (15 downto 0);
    subtype ibyte_t is std_ulogic_vector (ibyteWidth-1 downto 0);
    subtype iindex_t is std_ulogic_vector (iindexWidth-1 downto 0);
    subtype itag_t is std_ulogic_vector (itagWidth-1 downto 0);
    function ibyte (address: Iaddress_t) return ibyte_t;
    function iindex (address: Iaddress_t) return iindex_t;
    function itag (address: Iaddress_t) return itag_t;
    function maddress(address: Iaddress_t) return Maddress_t;
    type Zword_t is array (integer range <>) of 'z'; 
    function getZword (nZs: integer) return Zword_t;
    constant RW: array("read", "write") of std_ulogic := ("read" <= '1', "write" <= '0');
end package InterfaceTypes;
package body InterfaceTypes is
    function ibyte (address: Iaddress_t) return ibyte_t is
        variable byte: ibyte_t;
    begin
        byte := address(ibyteWidth-1 downto 0);
        return byte;
    end;
    function iindex (address: Iaddress_t) return iindex_t is
        variable index: iindex_t;
    begin
        index := address(iindexWidth+ibyteWidth-1 downto ibyteWidth);
        return index;
    end;
    function itag (address: Iaddress_t) return itag_t is
        variable tag: itag_t;
    begin
        tag := address(itagWidth+iindexWidth+ibyteWidth-1 downto iindexWidth+ibyteWidth);
        return tag;
    end;
    function maddress(address: Iaddress_t) return Maddress_t is
        variable memaddress: Maddress_t;
    begin
        memaddress:=(address(14 downto 10) & address(4 downto 2) & address(1 downto 0));
        return memaddress;
    end;
    function getZword (nZs: integer) return Zword_t is 
    begin
        return array (0 to nZs-1) of 'z';
    end;
end package body InterfaceTypes;

library ieee;
use ieee.std_logic_1164.all;
use work.MemTypes.all, work.InterfaceTypes.all;


entity testBench is end testBench;
architecture archTestBench of testBench is
    type addresses_t is array (0 to 4) of std_ulogic_vector (7 downto 0);
    constant addresses: addresses_t := ("01110101",--75h
                                        "01100101",--65h
                                        "01110101",--75h
                                        "01011001",--59h
                                        "01110101");--75h
    function getIaddress (address: std_ulogic_vector (7 downto 0)) return Iaddress_t is
    begin
        return ('0' & address(7 downto 3) & "00000" & address(2 downto 0) & "00");
    end;
    constant clkHalfPeriod: time := 100 ns;
    signal Pstrobe, Prw, Pready, Sysstrobe, Sysrw, clk, ld: bit;
    signal Paddress_in, Paddress, Sysaddress: Iaddress_t;
    signal Pdata: mword_t;
    signal Sysdata: mbyte_t;
    component cache
        port (clk: in bit;
              Pstrobe, Prw: in bit; --processor
              Paddress: in Iaddress_t;  --processor
              Pdata: inout mword_t; --processor
              Sysdata: inout mbyte_t; --system bus
              Pready: out bit --processor
              Sysaddress: out Iaddress_t; --system bus
              Sysstrobe, Sysrw: out bit); --system bus
    end component;
    component processor
        port (clk, ld: in bit; --testbench
              Paddress_in: in Iaddress_t; --testbench
              Pready: in bit; 
              Pdata: inout mword_t; 
              Paddress: out Iaddress_t; 
              Pstrobe, Prw: out bit);
    end component;
    component systemBus
        port (clk: in bit;
              Sysstrobe, Sysrw: in bit;
              Sysaddress: in Iaddress_t;
              Sysdata: inout mbyte_t);
    end component;
begin
    cache1: cache port map(clk, Pstrobe, Prw, Paddress, Pdata, Sysdata, Pready, Sysaddress, Sysstrobe, Sysrw);
    processor1: processor port map(clk, ld, Paddress_in, Pready, Pdata, Paddress, Pstrobe, Prw);
    systemBus1: systemBus port map(clk, Sysstrobe, Sysrw, Sysaddress, Sysdata);
    clockGen: process (clk) begin
        if clk = '0' then
            clk <= '1' after clkHalfPeriod, '0' after 2*clkHalfPeriod;
        end if;
    end process;
    stimuli: process (clk) begin
        for i in addresses'low to addresses'high loop
            if clk'event and clk'last_value='0' and clk='1' then
                ld <= '1';
                Paddress_in <= getIaddress(addresses(i));
                wait until clk='1';
                ld <= '0';
                while not (Pready = '1') loop
                    wait until clk='1';
                end loop;
            end if; --rising edge clk
        end loop;
    end process;
end architecture archTestBench;


entity cache is --direct mapped cache= tag RAM + cache RAM + controller
    port (clk: in bit;
          Pstrobe, Prw: in bit; --processor
          Paddress: in Iaddress_t;  --processor
          Pdata: inout mword_t; --processor
          Sysdata: inout mbyte_t; --system bus
          Pready: out bit --processor
          Sysaddress: out Iaddress_t; --system bus
          Sysstrobe, Sysrw: out bit); --system bus
end cache;
architecture archCache of cache is
    variable cache: Cache_t;
    variable mem: MainMem_t;
begin
    process (clk) 
        variable tempWord: mword_t; 
    begin
        if clk'event and clk='1' and clk'last_value='0' then
            if Pstrobe'event and Pstrobe='1' then
                assert((Prw = RW("read") or Prw = RW("write")) and Paddress > '0'); --legal comparison?
                wait until clk = '1';
                assert(Pstrobe = '0');
                --begin handling bus transaction
                if Prw = RW("read") then --processor read request: write data to pdata bus
                    if isHit(maddress(Paddress), cache) then
                        Pready <= '1';
                        Pdata <= fetchWordFromCache(maddress(Paddress), cache);
                    else --read word from main memory
                        Sysaddress <= Paddress;
                        Sysstrobe <= '1';
                        Sysrw <= RW("read");
                        wait until clk='1';
                        Sysstrobe <= '0';
                        wait_cycles: for i in 1 to integer'high loop 
                            exit wait_cycles when i > 4;
                            tempWord(i) <= Sysdata;
                            wait until clk = '1';
                        end loop wait_cycles;
                        Pready <= '1';
                        Pdata <= tempWord;
                        writeWordToCache(maddress(Paddress), tempWord, cache);
                    end if; --isHit()
                    wait until clk='1';
                    Pready <= '0';
                else --processor write request: read Pdata bus and write to cache and main memory
                    writeWordToCache(maddress(Paddress), Pdata, cache);
                    Sysaddress <= Paddress;
                    Sysstrobe <= '1';
                    Sysrw <= RW("write");
                    wait until clk='1';
                    Sysstrobe <= '0';
                    wait_cycles: for i in 1 to integer'high loop 
                        exit wait_cycles when i > 4;
                        Sysdata <= Pdata(i);
                        wait until clk = '1';
                    end loop wait_cycles;
                    Pready <= '1';
                    wait until clk='1';
                    Pready <= '0';
                end if; --rw
                Pdata <= zword32b; --tristate the bus
            else
                Pready <= '0';
                Sysstrobe <= '0';
            end if; --rising edge Pstrobe
        end if; --rising edge clk
    end process;
end architecture archCache;

entity processor is 
    port (clk, ld: in bit; --testbench
          Paddress_in: in Iaddress_t; --testbench
          Pready: in bit; 
          Pdata: inout mword_t; 
          Paddress: out Iaddress_t; 
          Pstrobe, Prw: out bit);
end entity processor;
architecture archProcessor of processor is
    variable zword32b: Zword_t := getZword(32);
begin
    pbus_transaction: process (clk) begin
        if clk'event and clk = '1' and clk'last_value='0' then --rising edge of clk
            if ld'event and ld'last_value='0' and ld='1' then
                Pstrobe <= '1';
                Prw <= RW("read"); --testbench is always a read request
                Paddress <= Paddress_in;
                wait until clk = '1';
                Pstrobe <= '0';
                --begin bus transaction
                wait until Pready = '1';
                Pdata <= zword32b; --tristate the bus
            end if; --rising edge Pstrobe
        end if; --init_transaction
        end if; --rising edge clk
    end process;
end architecture archProcessor;

entity systemBus is
    port (clk: in bit;
          Sysstrobe, Sysrw: in bit;
          Sysaddress: in Iaddress_t;
          Sysdata: inout mbyte_t);
end entity systemBus;
architecture archSystemBus of systemBus is 
    variable mem: MainMem_t := initialMem;
    variable zword8b: Zword_t := getZword(8);
begin
    process (clk) begin
        if clk'event and clk = '1' and clk'last_value='0' then
            if (Sysstrobe'event and Sysstrobe='1') then
                assert Sysaddress > '0' report "invalid Sysaddress";
                wait until clk = '1';
                assert Sysstrobe = '0' report "sysstrobe was not pulled low";
                if Sysrw=RW("read") then --read request
                    wait_cycles: for i in 1 to integer'high loop -- wait cycles
                        exit wait_cycles when i > 4;
                        Sysdata <= mem(decode(maddress(Sysaddress)(Maddress_t'high downto mbyteWidth)))(i);
                        wait until clk = '1';
                    end loop wait_cycles;
                elsif (Sysrw = RW("write") then --write request
                    wait_cycles: for i in 1 to integer'high loop -- wait cycles
                        exit wait_cycles when i > 4;
                        mem(decode(maddress(Sysaddress)(Maddress_t'high downto mbyteWidth)))(i) <= Sysdata;
                        wait until clk = '1';
                    end loop wait_cycles;
                end if; --rw
                wait until clk = '1';
                Sysdata <= zword8b; --tristate the bus
            end if; --sysstrobe
        end if; --rising edge clk
    end process;
end architecture archSystemBus;


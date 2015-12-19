-- problem 3: cache memory
library ieee;
use ieee.std_logic_1164.all;

package MemTypes is 
    function decode (vec:std_logic_vector) return integer; --range will be set when it is called
    constant mtagWidth: integer := 5; --std_logics of the memory address 'tag' field
    constant mindexWidth: integer := 3; --std_logics of the memory address 'index' field
    constant mbyteWidth: integer := 2; --std_logics of the memory address 'byte' field
    subtype mbyteRange is integer range 0 to (2**mbyteWidth)-1;
    subtype Maddress_t is std_logic_vector (9 downto 0);
    subtype mbytefield_t is std_logic_vector (mbyteWidth-1 downto 0);
    subtype mindexfield_t is std_logic_vector (mindexWidth-1 downto 0);
    subtype mtagfield_t is std_logic_vector (mtagWidth-1 downto 0);
    function mbytefield (address: Maddress_t) return mbytefield_t;
    function mindexfield (address: Maddress_t) return mindexfield_t;
    function mtagfield (address: Maddress_t) return mtagfield_t;
    subtype mbyte_t is std_logic_vector (7 downto 0);
    type mword_t is array (mbyteRange'low to mbyteRange'high) of mbyte_t;
    type MainMem_t is array (0 to 255) of mword_t;
    type cacheMem_t is record
        Tag: mtagfield_t;
        Word: mword_t;
    end record;
    type Cache_t is array (mindexfield_t'low to mindexfield_t'high) of cacheMem_t;
    procedure fetchWord (address:in Maddress_t; signal cache:inout Cache_t; signal mem:in MainMem_t; data:out mword_t);
    procedure fetchByte (address:in Maddress_t; signal cache:inout Cache_t; signal mem:in MainMem_t; mbyte:out mbyte_t);
    procedure writeWord(Pdata:in mword_t; address:in Maddress_t; signal cache:inout Cache_t; signal mem:inout MainMem_t); 
    function isHit (address: Maddress_t; cache: Cache_t) return boolean; 
    function fetchWordFromCache (address: Maddress_t; cache: Cache_t) return mword_t;
    procedure fetchWordFromMain(address:in Maddress_t;signal mem:in MainMem_t;signal cache:inout Cache_t;data:out mword_t);
    function fetchByteFromMain (address: Maddress_t; mem: MainMem_t) return mbyte_t;
    procedure writeWordToCache (address:in Maddress_t; data:in mword_t; signal cache:inout Cache_t);
    constant zbyte: mbyte_t := (others => 'Z');
    constant zword32b: mword_t := (others => zbyte);
    constant initialMem: MainMem_t := (117 => ("01110101","01110100","01110011","01110010"),--75h
                                       101 => ("01100101","01100100","01100011","01100010"),--65h
                                       89  => ("01011001","01011000","01010111","01010110"),--59h
                                       others => ("00000000","00000000","00000000","00000000"));
end package MemTypes;
package body MemTypes is
    function decode (vec:std_logic_vector) return integer is 
        variable int:integer := 0;
    begin
        for i in vec'low to vec'high loop
            if vec(i)='1' or vec(i)='H' then
                int:=int + 2**i;
            end if;
        end loop;
        return int;
    end;
    function mbytefield(address: Maddress_t) return mbytefield_t is
        variable byte: mbytefield_t;
    begin
        byte := address(mbyteWidth-1 downto 0);
        return byte;
    end;
    function mindexfield(address: Maddress_t) return mindexfield_t is
        variable index: mindexfield_t;
    begin
        index := address(mindexWidth+mbyteWidth-1 downto mbyteWidth);
        return index;
    end;
    function mtagfield (address: Maddress_t) return mtagfield_t is
        variable tag: mtagfield_t;
    begin
        tag := address(mtagWidth+mindexWidth+mbyteWidth-1 downto mindexWidth+mbyteWidth);
        return tag;
    end;
    function isHit (address: Maddress_t; cache: Cache_t) return boolean is 
    begin
        return mtagfield(address) = cache(decode(mindexfield(address))).Tag;
    end;
    function fetchWordFromCache (address: Maddress_t; cache: Cache_t) return mword_t is 
        variable index: mindexfield_t;
    begin
        index:=mindexfield(address);
        return cache(decode(index)).Word;
    end;
    procedure fetchWordFromMain(address:in Maddress_t; signal mem:in MainMem_t; signal cache:inout Cache_t; data:out mword_t) 
    is 
        variable tempdata: mword_t; 
    begin
        tempdata:=mem(decode(address(Maddress_t'high downto mbyteWidth)));
        cache(decode(mindexfield(address))).Tag<=mtagfield(address); 
        cache(decode(mindexfield(address))).Word<=tempdata; --store for future use
        data:=tempdata;
    end procedure fetchwordfrommain;
    procedure fetchWord (address:in Maddress_t; signal cache:inout Cache_t; signal mem:in MainMem_t; data:out mword_t) is
    begin
        if isHit(address, cache) then data := fetchWordFromCache(address, cache);
        else fetchWordFromMain(address, mem, cache, data);
        end if;
    end procedure fetchword;
    procedure fetchByte (address:in Maddress_t; signal cache:inout Cache_t; signal mem:in MainMem_t; mbyte:out mbyte_t) is
        variable data: mword_t;
        variable b: mbyteRange;
    begin
        fetchWord(address, cache, mem, data);
        b:=decode(mbytefield(address));
        mbyte:=data(b);
    end procedure fetchbyte;
    function fetchByteFromMain (address: Maddress_t; mem: MainMem_t) return mbyte_t is
        variable data: mword_t;
        variable b: mbyteRange;
    begin
        data:=mem(decode(address(Maddress_t'high downto mbyteWidth)));
        b:=decode(mbytefield(address));
        return data(b);
    end;
    procedure writeWordToCache (address:in Maddress_t; data:in mword_t; signal cache:inout Cache_t) is
    begin
        cache(decode(mindexfield(address))).Tag<=mtagfield(address); 
        cache(decode(mindexfield(address))).Word<=data; --store for future use
    end procedure writewordtocache;
    procedure writeWord(Pdata:in mword_t; address:in Maddress_t; signal cache:inout Cache_t; signal mem:inout MainMem_t) is
    begin
        --write word to cache and main memory in parallel
        mem(decode(address(Maddress_t'high downto mbyteWidth))) <= Pdata;
        cache(decode(mindexfield(address))).Tag<=mtagfield(address); 
        cache(decode(mindexfield(address))).Word<=Pdata; --store for future use
    end procedure writeword;
end package body MemTypes;

library ieee;
use ieee.std_logic_1164.all;
use work.MemTypes.all;

package InterfaceTypes is
    constant itagWidth: integer := 6; --std_logics of the interface address 'tag' field
    constant iindexWidth: integer := 3; --std_logics of the interface address 'index' field
    constant ibyteWidth: integer := 2; --std_logics of the interface address 'byte' field
    subtype Iaddress_t is std_logic_vector (15 downto 0);
    subtype ibyte_t is std_logic_vector (ibyteWidth-1 downto 0);
    subtype iindex_t is std_logic_vector (iindexWidth-1 downto 0);
    subtype itag_t is std_logic_vector (itagWidth-1 downto 0);
    function ibyte (address: Iaddress_t) return ibyte_t;
    function iindex (address: Iaddress_t) return iindex_t;
    function itag (address: Iaddress_t) return itag_t;
    function maddress(address: Iaddress_t) return Maddress_t;
    function getZword (nZs: integer) return mword_t;
    constant read: std_logic := '1';
    constant write: std_logic := '0';
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
    function getZword (nZs: integer) return mword_t is
        variable zs: mword_t;
        variable tempzs: mbyte_t := (others => 'Z');
    begin
        for i in mword_t'low to mword_t'high loop
            zs(i):=tempzs;
        end loop;
        return zs;
    end;
end package body InterfaceTypes;

library ieee;
use ieee.std_logic_1164.all;
use work.MemTypes.all, work.InterfaceTypes.all;


entity testbench_p3 is end testbench_p3;
architecture archtestbench_p3 of testbench_p3 is
    type addresses_t is array (0 to 4) of std_logic_vector (7 downto 0);
    constant addresses: addresses_t := ("01110101",--75h
                                        "01100101",--65h
                                        "01110101",--75h
                                        "01011001",--59h
                                        "01110101");--75h
    function getIaddress (address: std_logic_vector (7 downto 0)) return Iaddress_t is
        variable iaddress: Iaddress_t := (others => '0');
    begin
        iaddress(14 downto 10) := address(7 downto 3);
        iaddress(4 downto 2) := address(2 downto 0);
        return iaddress;
    end;
    constant clkHalfPeriod: time := 100 ns;
    signal Pstrobe, Prw, Pready, Sysstrobe, Sysrw, clk, ld: std_logic;
    signal Paddress_in, Paddress, Sysaddress: Iaddress_t;
    signal Pdata: mword_t;
    signal Sysdata: mbyte_t;
    component cache
        port (clk: in std_logic;
              Pstrobe, Prw: in std_logic; --processor
              Paddress: in Iaddress_t;  --processor
              Pdata: inout mword_t; --processor
              Sysdata: inout mbyte_t; --system bus
              Pready: out std_logic; --processor
              Sysaddress: out Iaddress_t; --system bus
              Sysstrobe, Sysrw: out std_logic); --system bus
    end component;
    component processor
        port (clk, ld: in std_logic; --testbench_p3
              Paddress_in: in Iaddress_t; --testbench_p3
              Pready: in std_logic; 
              Pdata: inout mword_t; 
              Paddress: out Iaddress_t; 
              Pstrobe, Prw: out std_logic);
    end component;
    component systemBus
        port (clk: in std_logic;
              Sysstrobe, Sysrw: in std_logic;
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
    stimuli: process begin
        for i in addresses'low to addresses'high loop
            if clk'event and clk'last_value='0' and clk='1' then
                ld <= '1';
                Paddress_in <= getIaddress(addresses(i));
                wait until clk'event and clk'last_value='0' and clk='1';
                ld <= '0';
                while not (Pready = '1') loop
                    wait until clk'event and clk'last_value='0' and clk='1';
                end loop;
            end if; --rising edge clk
        end loop;
    end process;
end architecture archtestbench_p3;

library ieee;
use ieee.std_logic_1164.all;
use work.MemTypes.all, work.InterfaceTypes.all;

entity cache is --direct mapped cache= tag RAM + cache RAM + controller
    port (clk: in std_logic;
          Pstrobe, Prw: in std_logic; --processor
          Paddress: in Iaddress_t;  --processor
          Pdata: inout mword_t; --processor
          Sysdata: inout mbyte_t; --system bus
          Pready: out std_logic; --processor
          Sysaddress: out Iaddress_t; --system bus
          Sysstrobe, Sysrw: out std_logic); --system bus
end cache;
architecture archCache of cache is
    signal cache: Cache_t;
    signal mem: MainMem_t;
begin
    process 
        variable tempWord: mword_t; 
    begin
        if clk'event and clk='1' and clk'last_value='0' then
            if Pstrobe'event and Pstrobe='1' then
                --assert (Prw = read or Prw = write) and Paddress > '0' report "bad paddress" severity warning;
                wait until clk'event and clk'last_value='0' and clk = '1';
                assert Pstrobe = '0' report "pstrobe not unasserted" severity warning;
                --begin handling bus transaction
                if Prw = read then --processor read request: write data to pdata bus
                    if isHit(maddress(Paddress), cache) then
                        Pready <= '1';
                        Pdata <= fetchWordFromCache(maddress(Paddress), cache);
                    else --read word from main memory
                        Sysaddress <= Paddress;
                        Sysstrobe <= '1';
                        Sysrw <= read;
                        wait until clk'event and clk'last_value='0' and clk='1';
                        Sysstrobe <= '0';
                        wait_cycles: for i in 1 to integer'high loop 
                            exit wait_cycles when i > 4;
                            tempWord(i) := Sysdata;
                            wait until clk'event and clk'last_value='0' and clk = '1';
                        end loop wait_cycles;
                        Pready <= '1';
                        Pdata <= tempWord;
                        writeWordToCache(maddress(Paddress), tempWord, cache);
                    end if; --isHit()
                    wait until clk'event and clk'last_value='0' and clk='1';
                    Pready <= '0';
                else --processor write request: read Pdata bus and write to cache and main memory
                    writeWordToCache(maddress(Paddress), Pdata, cache);
                    Sysaddress <= Paddress;
                    Sysstrobe <= '1';
                    Sysrw <= write;
                    wait until clk'event and clk'last_value='0' and clk='1';
                    Sysstrobe <= '0';
                    wait_cycles2: for i in 1 to integer'high loop 
                        exit wait_cycles2 when i > 4;
                        Sysdata <= Pdata(i);
                        wait until clk'event and clk'last_value='0' and clk = '1';
                    end loop wait_cycles2;
                    Pready <= '1';
                    wait until clk'event and clk'last_value='0' and clk='1';
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

library ieee;
use ieee.std_logic_1164.all;
use work.MemTypes.all, work.InterfaceTypes.all;

entity processor is 
    port (clk, ld: in std_logic; --testbench_p3
          Paddress_in: in Iaddress_t; --testbench_p3
          Pready: in std_logic; 
          Pdata: inout mword_t; 
          Paddress: out Iaddress_t; 
          Pstrobe, Prw: out std_logic);
end entity processor;
architecture archProcessor of processor is
begin
    pbus_transaction: process begin
        if clk'event and clk = '1' and clk'last_value='0' then --rising edge of clk
            if ld'event and ld'last_value='0' and ld='1' then
                Pstrobe <= '1';
                Prw <= read; --testbench_p3 is always a read request
                Paddress <= Paddress_in;
                wait until clk'event and clk'last_value='0' and clk = '1';
                Pstrobe <= '0';
                --begin bus transaction
                wait until Pready'event and Pready'last_value='0' and Pready = '1';
                Pdata <= zword32b; --tristate the bus
            end if; --ld (init transaction)
        end if; --rising edge clk
    end process;
end architecture archProcessor;

library ieee;
use ieee.std_logic_1164.all;
use work.MemTypes.all, work.InterfaceTypes.all;

entity systemBus is
    port (clk: in std_logic;
          Sysstrobe, Sysrw: in std_logic;
          Sysaddress: in Iaddress_t;
          Sysdata: inout mbyte_t);
end entity systemBus;
architecture archSystemBus of systemBus is 
    signal mem: MainMem_t := initialMem;
begin
    process begin
        if clk'event and clk = '1' and clk'last_value='0' then
            if Sysstrobe'event and Sysstrobe'last_value='0' and Sysstrobe='1' then
                --assert Sysaddress > '0' report "invalid Sysaddress";
                wait until clk'event and clk'last_value='0' and clk = '1';
                assert Sysstrobe = '0' report "sysstrobe was not pulled low";
                if Sysrw=read then --read request
                    wait_cycles: for i in 1 to integer'high loop -- wait cycles
                        exit wait_cycles when i > 4;
                        Sysdata <= mem(decode(maddress(Sysaddress)(Maddress_t'high downto mbyteWidth)))(i);
                        wait until clk'event and clk'last_value='0' and clk = '1';
                    end loop wait_cycles;
                elsif Sysrw = write then --write request
                    wait_cycles2: for i in 1 to integer'high loop -- wait cycles
                        exit wait_cycles2 when i > 4;
                        mem(decode(maddress(Sysaddress)(Maddress_t'high downto mbyteWidth)))(i) <= Sysdata;
                        wait until clk'event and clk'last_value='0' and clk = '1';
                    end loop wait_cycles2;
                end if; --rw
                wait until clk'event and clk'last_value='0' and clk = '1';
                Sysdata <= zbyte; --tristate the bus
            end if; --sysstrobe
        end if; --rising edge clk
    end process;
end architecture archSystemBus;


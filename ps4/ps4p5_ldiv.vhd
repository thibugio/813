library ieee;
use ieee.std_logic_1164.all, ieee.numeric_std.all;

package ps4p1_utils is
    function signExtend(nbits: integer; vec: signed) return signed;
    function twosComp(a: signed) return signed;
    function vec2str(vec: signed) return string;
    function vec2strb(vec: signed) return string;
end package ps4p1_utils;
package body ps4p1_utils is
    function  signExtend(nbits: integer; vec: signed) return signed is
        variable res: signed(nbits-1 downto 0);
        variable len: integer := vec'high - vec'low + 1;
    begin
        res := (nbits-1 downto len => vec(vec'high)) & vec;
        return res;
    end;
    function twosComp(a: signed) return signed is
    begin
        return (not a) + 1;
    end;
    function vec2str(vec: signed) return string is
    begin
        return integer'image(to_integer(vec));
    end;
    function vec2strb(vec: signed) return string is
        variable sb: string(vec'range);
    begin
        for i in vec'range loop
            sb(i) := character'value(std_logic'image(vec(i)));
        end loop;
        return sb;
    end;
end package body ps4p1_utils;
------------------------------------------
------------------------------------------
library ieee;
use ieee.std_logic_1164.all, ieee.numeric_std.all, work.ps4p1_utils.all;

entity ldiv is 
    generic (nbits: integer := 4);
    port (divisor, dividend: in signed(nbits-1 downto 0);
          quotient, remainder: out signed(nbits-1 downto 0));
    subtype reg_t is signed(nbits-1 downto 0);
    constant zero_reg: reg_t := (others => '0');
end ldiv;
architecture beh of ldiv is
    --test if 2 signed vectors have the same sign
    function same_sign(a, b: signed) return boolean is
    begin
        return to_bit(a(a'high))=to_bit(b(b'high));
    end;
    --registers
    signal M, A, Q: reg_t;
    --internal signals
    signal save_dividend: reg_t;
    signal ld, fin: bit := '0';
    signal count: integer := nbits;
begin
    main: process 
        variable temp: signed(reg_t'high*2+1 downto reg_t'low);
        variable save_A: signed(A'range);
    begin
        wait until dividend'event or divisor'event;
        wait until dividend'delayed'stable(1 ns) and divisor'delayed'stable(1 ns);
        --check divide-by-zero
        assert to_integer(divisor)/=0 report "divide by zero" severity failure;
        
        --wait until ld='0' and fin='0';
        A <= (others => dividend(reg_t'high));
        Q <= dividend;
        M <= divisor;
        save_dividend <= dividend;
        ld <= '1';
        
        wait until ld='1';
        divide: while count > 0 loop
            report "count: " & integer'image(count) & "; A: " & vec2str(A) & "; Q: " & vec2str(Q);
            --shift            
            A <= shift_left(A, 1);
            A(reg_t'low) <= Q(reg_t'high);--A(reg_t'high-1 downto reg_t'low) & Q(reg_t'high);
            Q <= shift_left(Q, 1);
            wait on A, Q;
            --add if sign(A)=sign(M); else subtract 
            save_A := A;
            if same_sign(A, M) then
                A <= A - M;
            else    
                A <= A + M;
            end if;
            wait on A;
            --set-bit if sign(A)=sign(A') or A'=0; else restore
            if same_sign(A, save_A) or A=zero_reg then
                Q(reg_t'low) <= '1';
            else
                Q(reg_t'low) <= '0';
                A <= save_A;
            end if;
            count <= count - 1;
            wait on count;-- and count'delayed'stable(1 ns);
        end loop divide;
        fin <= '1';

        wait until fin='1';
        remainder <= A;
        if same_sign(save_dividend, M) then
            quotient <= Q;
        else
            quotient <= twosComp(Q);
        end if;
        fin <= '0';
        ld <= '0';
        count <= nbits;
        wait until fin='0' and ld='0' and count=nbits;
    end process main;
end architecture beh;

------------------------------------------
------------------------------------------
library ieee;
use ieee.std_logic_1164.all, ieee.numeric_std.all, work.ps4p1_utils.all;

entity testbench_ps4p1 is end testbench_ps4p1;
architecture beh of testbench_ps4p1 is
    --test if a signed vector is valid (i.e. {0,1,H,L})
    function is_valid_number(a: signed) return boolean is
        variable valid: boolean := true;
    begin
        l0: for i in a'range loop
            if a(i)='U' or a(i)='X' or a(i)='Z' then
                valid := false;
                exit l0;
            end if;
        end loop l0;
        return valid;
    end;
    constant nbits: integer := 4;
    component ldiv is
        generic (nbits: integer := 4);
        port (divisor, dividend: in signed(nbits-1 downto 0);
              quotient, remainder: out signed(nbits-1 downto 0));
    end component;
    signal divisor, dividend, quotient, remainder: signed(nbits-1 downto 0);
begin
    ldiv0: ldiv generic map (nbits => nbits) 
                port map (divisor=>divisor, dividend=>dividend, quotient=>quotient, remainder=>remainder);
    
    test: process begin
        report "testing divide: 7/-2";
        dividend <= to_signed(7, nbits);
        divisor <= to_signed(-2, nbits);
        
        wait until dividend'active and divisor'active;
        wait until dividend'delayed'stable(1 ns) and divisor'delayed'stable(1 ns);
        
        --check the divisor and dividend have been initialized and their values are known
        assert is_valid_number(divisor) report "divisor undefined or uninitialized" severity failure;
        assert is_valid_number(dividend) report "dividend undefined or uninitialized" severity failure;
       
        wait until quotient'active and remainder'active;
        wait until quotient'delayed'stable(1 ns) and remainder'delayed'stable(1 ns);
        
        assert (dividend=divisor*quotient + remainder) 
            report "division failed" severity warning;
        assert quotient=to_signed(-3, nbits) report "7/-2: quotient was "& vec2str(quotient)     
            severity warning;
        assert remainder=to_signed(1, nbits) report "7/-2: remainder was "& vec2str(remainder) 
            severity warning;
        
        wait for 1 ns;

        report "testing divide: 6/-2";
        dividend <= to_signed(6, nbits);
        divisor <= to_signed(-2, nbits);
        
        wait until dividend'active and divisor'active;
        wait until dividend'delayed'stable(1 ns) and divisor'delayed'stable(1 ns);
        
        --check the divisor and dividend have been initialized and their values are known
        assert is_valid_number(divisor) report "divisor undefined or uninitialized" severity failure;
        assert is_valid_number(dividend) report "dividend undefined or uninitialized" severity failure;
       
        wait until quotient'active and remainder'active;
        wait until quotient'delayed'stable(1 ns) and remainder'delayed'stable(1 ns);
        
        assert (dividend=divisor*quotient + remainder) 
            report "division failed" severity warning;
        assert quotient=to_signed(-3, nbits) report "6/-2: quotient was "& vec2str(quotient)     
            severity warning;
        assert remainder=to_signed(0, nbits) report "6/-2: remainder was "& vec2str(remainder) 
            severity warning;
        
        assert false report "finished." severity failure;
        wait for 1 ns;
    end process;
end architecture beh;

------------------------------------------
------------------------------------------
library ieee;
use ieee.std_logic_1164.all, ieee.numeric_std.all, work.ps4p1_utils.all;

entity unit_tests is end unit_tests;
architecture beh of unit_tests is
    constant nbits: integer := 4;
    type input_t is array (integer range<>) of signed(nbits-1 downto 0);
    signal inputs: input_t(0 to 15) := (X"0", X"1", X"2", X"3", X"4", X"5", X"6", X"7",
                                        X"8", X"9", X"A", X"B", X"C", X"D", X"E", X"F");
begin
    test: process begin
    for i in inputs'range loop
        report "vec2str of " & integer'image(i) & ": " & vec2str(inputs(i));
        --report "vec2strb of " & integer'image(i) & ": " & vec2strb(inputs(i)); --range error in vec2strb?
        report "signExtend of " & integer'image(i) & ": " & vec2str(signExtend(nbits*2, inputs(i)));
        report "twosComp of " & integer'image(i) & ": " & vec2str(twosComp(inputs(i)));
        wait for 1 ns;
        if i=inputs'high then 
            report "finished." severity failure; 
        end if;
    end loop;
    end process test;
end architecture beh;

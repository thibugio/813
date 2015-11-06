--problem set 4, problem 1: ADDER
--note: as usual, using Little Endian bit-order (MSB in highest mem address)
--TODO: sub-problem: determine all cases when signed overflow will occur

library ieee;
use ieee.std_logic_1164.all, ieee.numeric_std.all;

package utils_ps4_p1 is
    subtype bus_t is std_logic_vector (15 downto 0); --an input word to the adder
    subtype code_t is std_logic_vector (2 downto 0); --an input word to the adder
    type code_word_t is (add, addu, sub, subu, inc, dec);
    function decode (c: code_t) return code_word_t;
    function encode (c: code_word_t) return code_t;
end package utils_ps4_p1;
package body utils_ps4_p1 is
    function decode (c: code_t) return code_word_t is 
    begin
        if c(code_t'high) = '1' then
            if c(0) = '1' then return dec; else return inc; end if;
        elsif c(code_t'high - 1) = '1' then 
            if c(0) = '1' then return subu; else return sub; end if;
        else
            if c(code_t'low) = '1' then return addu; else return add; end if;
        end if;
    end;
    
    function encode (c: code_word_t) return code_t is 
    begin
        case c is
            when add => return "000";
            when addu => return "001";
            when sub => return "010";
            when subu => return "011";
            when inc => return "100";
            when dec => return "101";
        end case;
    end;
    
end package body utils_ps4_p1;

library ieee;
use ieee.std_logic_1164.all, ieee.numeric_std.all, work.utils_ps4_p1.all;

entity testbench_p1 is end testbench_p1;
architecture behaviour of testbench_p1 is
    constant ninputs: integer := 5; 
    type bus_array_t is array (0 to ninputs-1) of bus_t;
    type bit_array_t is array (0 to ninputs-1) of bit; --i.e., bit_vector
    type bit_d is ('0', '1', 'd'); --bit with 'don't care'
    type bit_d_array_t is array (0 to ninputs-1) of bit_d;
    function equals_d (b1: bit; b2: bit_d) return boolean is
    begin
        if b2='d' then return true; end if;
        if b1='1' and b2='1' then return true; end if;
        if b1='0' and b2='0' then return true; end if;
        return false;
    end;
    ---------------------inputs--------------------------
    constant A_inputs: bus_array_t := (X"0000", X"000F", X"7F00", X"FF00", X"8100");
    constant B_inputs: bus_array_t := (X"0001", X"000F", X"0300", X"0100", X"8000");
    constant ci_inputs_addX_incdec: bit_array_t := ('0', '1', '0', '1', '1');
    constant ci_inputs_subX: bit_array_t := ('1', '1', '1', '1', '1');
    constant coe_inputs: bit_array_t := ('0', '0', '0', '0', '1');
    --------------outputs_add-------------------------------- 
    constant C_outputs_add: bus_array_t := (X"0001", X"001F", X"8200", X"0001", X"0101");
    constant v_outputs_add: bit_array_t := ('0', '0', '1', '0', '1');
    constant co_outputs_add: bit_d_array_t := ('0', '0', '0', '1', 'd');
    -------------outputs_addu-------------------------------
    constant C_outputs_addu: bus_array_t := C_outputs_add;
    constant v_outputs_addu: bit_array_t := ('0', '0', '0', '0', '0');
    constant co_outputs_addu: bit_d_array_t := co_outputs_add;
    -------------outputs_sub-------------------------------
    constant C_outputs_sub: bus_array_t := (X"FFFF", X"0000", X"7C00", X"FE00", X"0100");
    constant v_outputs_sub: bit_array_t := v_outputs_addu;
    constant co_outputs_sub: bit_d_array_t := ('0', '1', '1', '1', 'd');
    -------------outputs_subu-------------------------------
    constant C_outputs_subu: bus_array_t := (X"FFFF", X"0220", X"7C00", X"FE00", X"0100");
    constant v_outputs_subu: bit_array_t := v_outputs_addu;
    constant co_outputs_subu: bit_d_array_t := co_outputs_sub;
    ------------outputs_inc---------------------------------
    constant C_outputs_inc: bus_array_t := (X"0001", X"0F01", X"8000", X"FF01", X"8101");
    constant v_outputs_inc: bit_array_t := ('0', '0', '1', '0', '0');
    constant co_outputs_inc: bit_d_array_t := ('0', '0', '0', '0', 'd');
    -----------outputs_dec----------------------------------
    constant C_outputs_dec: bus_array_t := (X"FFFF", X"000E", X"7EFF", X"FEFF", X"7FFF");
    constant v_outputs_dec: bit_array_t := ('0', '0', '0', '0', '1');
    constant co_outputs_dec: bit_d_array_t := ('0', '1', '1', '1', 'd');
    ----------entity_under_test-----------------------------
    component adder is
    port (A, B: in bus_t; 
          CODE: in code_t;
          cin: in bit;
          coe: in bit; --carry out enable (active low)
          C: inout bus_t;
          vout: inout bit; --signed overflow
          cout: inout bit);
    end component;
    ----------signals------------------------------------
    signal A_in, B_in, C_out: bus_t;
    signal code_in: code_t;
    signal cin_in, coe_in, v_out, co_out: bit;
    signal test_C_out: bus_t;
    signal test_v_out: bit;
    signal test_co_out: bit_d;
    signal counter: integer := 0;
    signal ready: bit:='0';
begin
    adder0: adder port map (A=>A_in, B=>B_in, CODE=>code_in, cin=>cin_in, coe=>coe_in, 
                            C=>C_out, vout=>v_out, cout=>co_out);
    process  
        variable cin_inputs: bit_array_t;
        variable C_outputs: bus_array_t;
        variable v_outputs: bit_array_t;
        variable co_outputs: bit_d_array_t;
    begin
    stim: for word in code_word_t'left to code_word_t'right loop
            code_in <= encode(word);
            case word is
                when add =>
                    cin_inputs := ci_inputs_addX_incdec;
                    C_outputs := C_outputs_add;
                    v_outputs := v_outputs_add;
                    co_outputs := co_outputs_add;
                when addu =>
                    cin_inputs := ci_inputs_addX_incdec;
                    C_outputs := C_outputs_addu;
                    v_outputs := v_outputs_addu;
                    co_outputs := co_outputs_addu;
                when sub =>
                    cin_inputs := ci_inputs_subX;
                    C_outputs := C_outputs_sub;
                    v_outputs := v_outputs_sub;
                    co_outputs := co_outputs_sub;
                when subu =>
                    cin_inputs := ci_inputs_subX;
                    C_outputs := C_outputs_subu;
                    v_outputs := v_outputs_subu;
                    co_outputs := co_outputs_subu;
                when inc =>
                    cin_inputs := ci_inputs_addX_incdec;
                    C_outputs := C_outputs_inc;
                    v_outputs := v_outputs_inc;
                    co_outputs := co_outputs_inc;
                when dec =>
                    cin_inputs := ci_inputs_addX_incdec;
                    C_outputs := C_outputs_dec;
                    v_outputs := v_outputs_dec;
                    co_outputs := co_outputs_dec;
            end case;
            for j in 0 to ninputs-1 loop
                A_in <= A_inputs(j);
                B_in <= B_inputs(j);
                cin_in <= cin_inputs(j);
                coe_in <= coe_inputs(j);
                test_C_out <= C_outputs(j);
                test_v_out <= v_outputs(j);
                test_co_out <= co_outputs(j);

                ready <= '1';
                wait until ready = '1';

                assert false report "trial " & integer'image(counter) severity note;
                assert C_out=test_C_out report "discrepancy in C" severity warning;
                assert v_out=test_v_out report "discrepancy in vout" severity warning;
                assert equals_d(co_out, test_co_out) report "discrepancy in cout" severity warning;
                assert false report "" severity note;

                ready <= '0';
                wait until ready = '0';

                counter <= counter + 1;
            end loop;
        end loop;
    end process;
end architecture behaviour;

library ieee;
use ieee.std_logic_1164.all, ieee.numeric_std.all, work.utils_ps4_p1.all;

entity adder is 
    port (A, B: in bus_t; 
          CODE: in code_t;
          cin: in bit;
          coe: in bit; --carry out enable (active low)
          C: inout bus_t;
          vout: inout bit; --signed overflow
          cout: inout bit);
end adder;
architecture behaviour of adder is
    function bit_to_vector (b: bit) return bit_vector is
        variable vec: bit_vector (0 to 0);
    begin
        vec(0) := b;
        return vec;
    end;
    
    function pow (base, exp: integer) return integer is
        variable res: integer := 1;
    begin
        for i in 0 to exp-1 loop
            res := res * base;
        end loop;
        return res;
    end;
    --signed addition with parameter list
    procedure p_add_p (in1, in2: in bus_t; ci, ce: in bit; out1: inout bus_t; vo, co: out bit) is
        variable in1_s: signed(bus_t'range) := signed(in1);
        variable in2_s: signed(bus_t'range) := signed (in2);
        variable in1_pos: boolean := in1_s(bus_t'high)='1'; --msb
        variable in2_pos: boolean := in2_s(bus_t'high)='1'; --msb
    begin
        out1 := std_logic_vector((in1_s + in2_s) + signed(to_stdlogicvector(bit_to_vector(ci))));
        
        if (in1_pos and in2_pos and out1(bus_t'high)='1') or 
            (not in1_pos and not in2_pos and out1(bus_t'high)='0') then
            vo := '1';
        else
            vo := '0';
        end if;
        
        co := '0';
        if ce='0' then
            --I think this is ok since it seemed like the point of this particular problem was
            --creating a good design organization and not making an adder, etc.
            if abs(in1_s) + abs(in2_s) > to_signed(pow(2, (in1_s'length-1)-1), in1_s'length) then
                co := '1';
            end if;
        end if;
    end procedure p_add_p;

    --signed addition
    procedure p_add (in1, in2: in bus_t; ci, ce: in bit; out1: inout bus_t; vo, co: out bit) is
    begin
        p_add_p (in1=>in1, in2=>in2, ci=>ci, ce=>ce, out1=>out1, vo=>vo, co=>co);
    end procedure p_add;

    --unsigned addition
    procedure p_addu (in1, in2: in bus_t; ci, ce: in bit; out1: inout bus_t; vo, co: out bit) is
    begin
        out1 := std_logic_vector(unsigned(in1) + unsigned(in2));
        if ce='0' then
            if unsigned(in1) + unsigned(in2) > to_unsigned(pow(2, in1'length)-1, in1'length) then
                co := '1';
            end if;
        end if;
    end procedure p_addu;

    --signed subtraction with parameter list
    procedure p_sub_p (in1, in2: in bus_t; ci, ce: in bit; out1: inout bus_t; vo, co: out bit) is
        variable in1_s: signed(bus_t'range) := signed(in1);
        variable in2_s: signed(bus_t'range) := signed (in2);
        variable in1_pos: boolean := in1_s(bus_t'high)='1'; --msb
        variable in2_pos: boolean := in2_s(bus_t'high)='1'; --msb
    begin
        out1 := std_logic_vector((in1_s - in2_s) - signed(to_stdlogicvector(bit_to_vector(ci))));

        if (in1_pos and in2_pos and out1(bus_t'high)='1') or
            (not in1_pos and not in2_pos and out1(bus_t'high)='0') then
            vo := '1';
        else 
            vo := '0';
        end if;

        co := '0';
        if ce='0' then
            if not in1_pos and not in2_pos and 
                (abs(in1_s) + abs(in2_s) > to_signed(pow(2, (in1_s'length-1)-1), in1_s'length)) then
                co := '1';
            end if;
        end if;
    end procedure p_sub_p;

    --signed subtraction
    procedure p_sub (in1, in2: in bus_t; ci, ce: in bit; out1: inout bus_t; vo, co: out bit) is
    begin
        p_sub_p (in1=>in1, in2=>in2, ci=>ci, ce=>ce, out1=>out1, vo=>vo, co=>co);
    end procedure p_sub;

    --unsigned subtraction
    procedure p_subu (in1, in2: in bus_t; ci, ce: in bit; out1: inout bus_t; vo, co: out bit) is
    begin
        out1 := std_logic_vector(unsigned(in1) - unsigned(in2));
        if ce='0' then
            if unsigned(in2) > unsigned(in1) then
                co := '1';
            end if;
        end if;
    end procedure p_subu;

    --signed increment
    procedure p_inc (in1, in2: in bus_t; ci, ce: in bit; out1: inout bus_t; vo, co: out bit) is
    begin
        p_add_p (in1=>in1, in2=>in2, ci=>ci, ce=>ce, out1=>out1, vo=>vo, co=>co);
    end procedure p_inc;

    --signed decrement
    procedure p_dec (in1, in2: in bus_t; ci, ce: in bit; out1: inout bus_t; vo, co: out bit) is
    begin
        p_sub_p (in1=>in1, in2=>in2, ci=>ci, ce=>ce, out1=>out1, vo=>vo, co=>co);
    end procedure p_dec;
begin
    process (A, B, CODE) 
        variable temp_c: bus_t := C;
        variable temp_vout: bit := vout;
        variable temp_cout: bit := cout;
    begin
        case decode(CODE) is
            when add => p_add (A, B, cin, coe, temp_c, temp_vout, temp_cout);
            when addu => p_addu (A, B, cin, coe, temp_c, temp_vout, temp_cout);
            when sub => p_sub (A, B, cin, coe, temp_c, temp_vout, temp_cout);
            when subu => p_subu (A, B, cin, coe, temp_c, temp_vout, temp_cout);
            when inc => p_inc (A, X"0001", cin, coe, temp_c, temp_vout, temp_cout);
            when dec => p_dec (A, X"0001", cin, coe, temp_c, temp_vout, temp_cout);
        end case;
        C <= temp_c;
        vout <= temp_vout;
        cout <= temp_cout;
    end process;
end architecture behaviour;

--problem 2: traffic light controller
  
package LightTypes is
    type LightColor_t is ('g', 'y', 'r');
end package LightTypes;

library ieee;
use ieee.std_logic_1164.all;
use work.LightTypes.all;
  

entity testbench_p2 is end entity testbench_p2;
architecture archtestbench_p2 of testbench_p2 is 
    signal clk: std_logic := '0';
    signal Asensor, Bsensor, ga, ya, ra, gb, yb, rb: std_logic;
    function "+" (b1: integer; b2: std_logic) return integer is
        variable sum:integer := 0;
    begin
        if b2='1' then sum:=sum+1; end if;
        sum:=sum+b1;
        return sum;
    end;
    function "+" (b1: std_logic; b2: integer) return integer is
        variable sum:integer := 0;
    begin
        if b1='1' then sum:=sum+1; end if;
        sum:=sum+b2;
        return sum;
    end;
    function "+" (b1, b2: std_logic) return integer is
        variable sum:integer := 0;
    begin
        if b1='1' then sum:=sum+1; end if;
        if b2='1' then sum:=sum+1; end if;
        return sum;
    end;
    component trafficController
        port (clk, Asensor, Bsensor: in std_logic;
              ga, ya, ra, gb, yb, rb: out std_logic);
    end component;
begin
    tc: trafficController port map (clk, Asensor, Bsensor, ga, ya, ra, gb, yb, rb);
    clockGen: process (clk) begin
        if clk='0' then
            clk <= '1' after 5000 ms, '0' after 10000 ms;
        end if; 
    end process; 
    test: process (clk) begin
        if clk'event and clk'last_value='0' and clk='1' then
            assert "+"(ra,"+"(ga,ya)) = 1 report "illegal state light A" severity error;
            assert (gb + yb + rb) = 1 report "illegal state light B" severity error;
            assert (ga + gb) <= 1 report "illegal state: A and B green" severity error;
            assert (ya + yb) <= 1 report "illegal state: A and B yellow" severity error;
            assert (ra + rb) <= 1 report "illegal state: A and B red" severity error;
            assert (ga'delayed'quiet(9999 ms) and ya'delayed'quiet(9999 ms) and ra'delayed'quiet(9999 ms) 
                    and gb'delayed'quiet(9999 ms) and yb'delayed'quiet(9999 ms) 
                    and rb'delayed'quiet(9999 ms))
                    report "state change during last clock cycle" severity error;
            if ga'event and ga'last_value='1' and ga='0' then
                assert ga'delayed'quiet(59999 ms) report "Light A was green for less than 60 s" severity error;
            end if; --falling edge ga
            if gb'event and gb'last_value='1' and gb='0' then
                assert gb'delayed'quiet(49999 ms) report "Light B was green for less than 50 s" severity error;
            end if; --failling edge gb
        end if; --rising edge clk
    end process;
    stimulusGen: process (clk) 
        type input_vec_t is array (0 to 16) of std_logic_vector (0 to 1);
        --the following should systematically cover every possible bit-valued transition:
        constant stimuli: input_vec_t := ("00", "00", "01", "00", "10", "00", "11", "01", "01",
                                          "10", "01", "11", "10", "10", "11", "11", "00");
        variable clk_counter: integer := 0;
        variable stim_counter: integer := 0;
    begin
        if clk'event and clk'last_value='0' and clk='1' then
             if clk_counter > 150 then --arbitrary number greater than 60+50
                assert false 
                    report "Asensor is "&std_logic'image(Asensor)&", Bsensor is "&std_logic'image(Bsensor) 
                    severity note;
                Asensor <= stimuli(stim_counter)(0);
                Bsensor <= stimuli(stim_counter)(1);
                if stim_counter < input_vec_t'length then
                    stim_counter:=stim_counter+1;
                else stim_counter:=0;
                end if;
                clk_counter:=0; 
            end if;
            clk_counter:=clk_counter+1;
        end if; --rising edge clk
    end process;
end architecture archtestbench_p2;

library ieee;
use ieee.std_logic_1164.all;
use work.LightTypes.all;
  
entity trafficController is
    port (clk, Asensor, Bsensor: in std_logic;
          ga, ya, ra, gb, yb, rb: out std_logic);
    constant nstates: integer := 13;
    subtype tcFSM_state_no is integer range 0 to nstates-1;
    type SensorInput_t is (car, clear);
    type tcFSM_input_t is array (0 to 1) of SensorInput_t;
    type tcFSM_state_t is array (0 to 1) of LightColor_t;
    type tcFSM_states_t is array (tcFSM_state_no) of tcFSM_state_t;
    constant tcFSM_states: tcFSM_states_t := (0 to 5 => ('g','r'), 6 => ('g','r'),
                                              7 to 11 => ('g','r'), 12 => ('g','r'));
    function red (light: LightColor_t) return std_logic is
    begin
        case light is
            when 'r' => return '1';
            when others   => return '0';
        end case;
    end;
    function green (light: LightColor_t) return std_logic is
    begin
        case light is
            when 'g' => return '1';
            when others   => return '0';
        end case;
    end;
    function yellow (light: LightColor_t) return std_logic is
    begin
        case light is
            when 'y' => return '1';
            when others   => return '0';
        end case;
    end;
end trafficController;
architecture archTC of trafficController is
    signal current_state_no: tcFSM_state_no := 0;
begin
    process (clk) 
        variable next_state_no: tcFSM_state_no;
    begin
    if clk'event and clk'last_value='0' and clk='1' then
        case current_state_no is
            when 0 to 4 | 6 to 10 => 
                next_state_no := current_state_no + 1;
            when 5 =>
                if Bsensor = '0' then
                    next_state_no := current_state_no;
                else
                    next_state_no := current_state_no + 1;
                end if; --sb'
            when 11 =>
                if Bsensor = '1' and Asensor = '0' then
                    next_state_no := current_state_no;
                else
                    next_state_no := current_state_no + 1;
                end if; --sa'sb
            when 12 =>
                next_state_no := 0;
        end case;
        --update current state and outputs
        current_state_no <= next_state_no;
        ga <= green(tcFSM_states(next_state_no)(0));
        ya <= yellow(tcFSM_states(next_state_no)(0));
        ra <= red(tcFSM_states(next_state_no)(0));
        gb <= green(tcFSM_states(next_state_no)(1));
        yb <= yellow(tcFSM_states(next_state_no)(1));
        rb <= red(tcFSM_states(next_state_no)(1));
    end if; --rising edge clk
    end process;
end architecture archTC;

--problem 2: traffic light controller
library ieee;
use ieee.std_logic_1164.all;
  
package LightTypes is
    type LightColor_t is ("g", "y", "r");
end package LightTypes;

library ieee;
use ieee.std_logic_1164.all;
use work.LightTypes.all;
  

entity testBench is end entity testBench;
architecture archTestBench of testBench is 
signal clk: std_logic := '0';
signal Asensor, Bsensor, ga, ya, ra, gb, yb, rb: std_logic;
component trafficController
    port (clk, Asensor, Bsensor: in std_logic;
          ga, ya, ra, gb, yb, rb: out std_logic);
end component;
    tc: trafficController port map (clk, Asensor, Bsensor, ga, ya, ra, gb, yb, rb);
begin
    clockGen: process (clk) begin
        if clk='0' then
            clk <= '1' after 5000 ms, '0' after 10000 ms;
        end if; 
    end process; 
    test: process (clk) begin
        if clk'event and clk'last_value='0' and clk='1' then
            assert (ga+ya+ra)=1 report "more than one or no signal asserted for light A" severity error;
            assert (gb+yb+rb)=1 report "more than one or no signal asserted for light B" severity error;
            assert (ga nand gb) report "illegal state" severity error;
            assert (ya nand yb) report "illegal state" severity error;
            assert (ra nand rb) report "illegal state" severity error;
            assert (ga'delayed'quiet(10000 ms) and ya'delayed'quiet(10000 ms) and ra'delayed'quiet(10000 ms) 
                    and gb'delayed'quiet(10000 ms) and yb'delayed'quiet(10000 ms) 
                    and rb'delayed'quiet(10000 ms))
                    report "state change during last clock cycle" severity error;
            if ga'event and ga'last_value='1' and ga='0' then
                assert ga'delayed'quiet(60000 ms) report "Light A was green for less than 60 s" severity error;
            end if; --falling edge ga
            if gb'event and gb'last_value='1' and gb='0' then
                assert gb'delayed'quiet(50000 ms) report "Light A was green for less than 50 s" severity error;
            end if; --failling edge gb
        end if; --rising edge clk
    end process;
    stimulusGen: process (clk) 
        variable clk_counter, stim_counter: integer := 0; 
        type input_vec_t is array (integer range <>) of std_logic_vector (0 to 1);
        --the following should systematically cover every possible bit-valued transition:
        constant stimuli: input_vec_t := ("00", "00", "01", "00", "10", "00", "11", "01", "01",
                                          "10", "01", "11", "10", "10", "11", "11", "00");
    begin
        if clk'event and clk'last_value='0' and clk='1' then
             clk_counter:=clk_counter+1;
             if clk_counter > 150 then --arbitrary number greater than 60+50
                clk_counter:=0; 
                Asensor <= stimuli(stim_counter)(0);
                Bsensor <= stimuli(stim_counter)(1);
                stim_counter:=stim_counter+1;
            end if;
        end if; --rising edge clk
    end process;
end architecture archTestBench;

entity trafficController is
    port (clk, Asensor, Bsensor: in std_logic;
          ga, ya, ra, gb, yb, rb: out std_logic);
    constant nstates: integer := 13;
    subtype tcFSM_state_no is integer range 0 to nstates-1;
    type SensorInput_t is ("car", "clear");
    type tcFSM_state_t is array (0 to 1) of LightColor_t;
    type tcFSM_input_t is array (0 to 1) of SensorInput_t;
    type tcFSM_states_t is array (tcFSM_state_no) of tcFSM_state_t;
    type tcFSM_t is array (tcFSM_input_t, tcFSM_state_no) of tcFSM_state_no;
    constant tcFSM_states: tcFSM_states_t := ((0 to 5) <= ("g","r"), 6 <= ("g","r"),
                                              (7 to 11) <= ("g","r"), 12 <= ("g","r"));
    constant tcFSM: tcFSM_t := ((0,("clear","clear"))<=1, (0,("clear","car"))<=1, 
                                (0,("car","clear"))<=1, (0,("car","car"))<=1, 
                                
                                (1,("clear","clear"))<=2, (1,("clear","car"))<=2, 
                                (1,("car","clear"))<=2, (1,("car","car"))<=2, 
                                
                                (2,("clear","clear"))<=3, (2,("clear","car"))<=3, 
                                (2,("car","clear"))<=3, (2,("car","car"))<=3, 
                                
                                (3,("clear","clear"))<=4, (3,("clear","car"))<=4, 
                                (3,("car","clear"))<=4, (3,("car","car"))<=4, 
                                
                                (4,("clear","clear"))<=5, (4,("clear","car"))<=5, 
                                (4,("car","clear"))<=5, (4,("car","car"))<=5, 
                                
                                (5,("clear","clear"))<=5, (5,("car","clear"))<=5, 
                                (5,("clear","car"))<=6, (5,("car","car"))<=6,  
                                
                                (6,("clear","clear"))<=7, (6,("clear","car"))<=7, 
                                (6,("car","clear"))<=7, (6,("car","car"))<=7, 
                                
                                (7,("clear","clear"))<=8, (7,("clear","car"))<=8, 
                                (7,("car","clear"))<=8, (7,("car","car"))<=8, 
                                
                                (8,("clear","clear"))<=9, (8,("clear","car"))<=9, 
                                (8,("car","clear"))<=9, (8,("car","car"))<=9, 
                                
                                (9,("clear","clear"))<=10, (9,("clear","car"))<=10, 
                                (9,("car","clear"))<=10, (9,("car","car"))<=10, 
                                
                                (10,("clear","clear"))<=11, (10,("clear","car"))<=11, 
                                (10,("car","clear"))<=11, (10,("car","car"))<=11, 
                                
                                (11,("clear","car"))<=11, (11,("car","clear"))<=12,
                                (11,("clear","clear"))<=12, (11,("car","car"))<=12,
                                
                                (12,("clear","clear"))<=0, (12,("clear","car"))<=0, 
                                (12,("car","clear"))<=0, (12,("car","car"))<=0, 
    function red (light: LightColor_t) return std_logic is
    begin
        case light is
            when "r" => return '1';
            when others   => return '0';
        end case;
    end;
    function green (light: LightColor_t) return std_logic is
    begin
        case light is
            when "g" => return '1';
            when others   => return '0';
        end case;
    end;
    function yellow (light: LightColor_t) return std_logic is
    begin
        case light is
            when "y" => return '1';
            when others   => return '0';
        end case;
    end;
end trafficController; 
architecture archTC of trafficController is
    variable input: tcFSM_input_t := ("clear","clear");
    variable next_state_no: tcFSM_state_no;
    signal current_state_no: tcFSM_state_no := 0;
begin
    if clk'event and clk'last_value='0' and clk='1' then
        case (Asensor,Bsensor) is
            when "00" => input:=("clear","clear");
            when "01" => input:=("clear","car");
            when "10" => input:=("car","clear");
            when others => input:=("car","car");
        end case;
        --update current state and outputs
        next_state_no := tcFSM (current_state_no, input);
        current_state_no <= next_state_no;
        ga <= green(tcFSM_states(next_state_no)(0));
        ya <= yellow(tcFSM_states(next_state_no)(0));
        ra <= red(tcFSM_states(next_state_no)(0));
        gb <= green(tcFSM_states(next_state_no)(1));
        yb <= yellow(tcFSM_states(next_state_no)(1));
        rb <= red(tcFSM_states(next_state_no)(1));
    end if; --rising edge clk
end archTc;

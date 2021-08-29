--------------------------------------------------------------------------------
-- model_video_out_clock.vhd                                                  --
-- Fast simulation model of video_out_clock.vhd                               --
--------------------------------------------------------------------------------
-- (C) Copyright 2021 Adam Barnes <ambarnes@gmail.com>                        --
-- This file is part of The Tyto Project. The Tyto Project is free software:  --
-- you can redistribute it and/or modify it under the terms of the GNU Lesser --
-- General Public License as published by the Free Software Foundation,       --
-- either version 3 of the License, or (at your option) any later version.    --
-- The Tyto Project is distributed in the hope that it will be useful, but    --
-- WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY --
-- or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public     --
-- License for more details. You should have received a copy of the GNU       --
-- Lesser General Public License along with The Tyto Project. If not, see     --
-- https://www.gnu.org/licenses/.                                             --
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity model_video_out_clock is
    port (

        rsti        : in    std_logic;                      -- reset
        clki        : in    std_logic;                      -- reference clock
        sys_rst     : in    std_logic;                      -- system clock synchronous reset
        sys_clk     : in    std_logic;                      -- system clock e.g. 100MHz

        sel         : in    std_logic_vector(1 downto 0);   -- output clock select: 00 = 25.2, 01 = 27.0, 10 = 74.25, 11 = 148.5
        rsto        : out   std_logic;                      -- output clock synchronous reset
        clko        : out   std_logic;                      -- pixel clock
        clko_x5     : out   std_logic                       -- serialiser clock (5x pixel clock)

    );
end entity model_video_out_clock;

architecture model of model_video_out_clock is

    signal t10  : time := 3968ps;
    signal rst  : std_logic;

begin

    clko <=
        '0' when rst = '1' else
        '1' after 5*t10 when clko = '0' else
        '0' after 5*t10 when clko = '1' else
        '0';

    clko_x5 <=
        '0' when rst = '1' else
        '1' after t10 when clko_x5 = '0' else
        '0' after t10 when clko_x5 = '1' else
        '0';

    process(sel)
    begin
        if sel'event then
            case sel is
                when "00" => t10 <= 3968ps;
                when "01" => t10 <= 3705ps;
                when "10" => t10 <= 1347ps;                
                when "11" => t10 <= 673ps;
                when others => t10 <= 3968ps;
            end case;
        end if;
    end process;

    process
    begin    
        wait until sel'event;
        rst <= '1';
        rsto <= '1';
        wait for 100ns;
        rst <= '0';
        wait for 100ns;
        for i in 0 to 9 loop
            wait until rising_edge(clko);
        end loop;
        rsto <= '0';
    end process;

end architecture model;
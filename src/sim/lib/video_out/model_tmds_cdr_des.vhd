--------------------------------------------------------------------------------
-- model_tmds_cdr_des.vhd                                                     --
-- CDR and 1 to 10 deserialiser, locks to TMDS control symbols.               --
--------------------------------------------------------------------------------
-- (C) Copyright 2020 Adam Barnes <ambarnes@gmail.com>                        --
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

entity model_tmds_cdr_des is
    port
    (
        serial      : in    std_logic;
        parallel    : out   std_logic_vector(9 downto 0);
        clk         : out   std_logic;
        locked      : out   std_logic
    );
end entity model_tmds_cdr_des;

architecture model of model_tmds_cdr_des is

    constant ts         : time := 250ps; -- sample time (after serial transition)
    signal  tui         : time := 0ps; -- shortest measured bit time
    signal  sample      : std_logic := '0'; -- DDR sample clock
    signal  count       : integer range 0 to 9 := 0;
    signal  shift_reg   : std_logic_vector(9 downto 0);

begin

    -- measure shortest bit time (unit interval)
    process(serial)
        variable prev : time := 0ps;
    begin
        if serial'event then
            if tui = 0ps or now - prev < tui then
                tui <= now - prev;
            end if;
            prev := now;
        end if;
    end process;

    -- clock recovery (sample event)
    process
    begin
        wait on serial until serial = '1';
        wait until serial'event;
        wait for ts;
        sample <= transport not sample after tui;
        loop
            wait on serial, sample;
            if serial'event then
                sample <= transport sample;
                sample <= transport not sample after ts;
            else
                sample <= transport not sample after tui;
            end if;
        end loop;
    end process;

    -- serial to parallel
    process(locked,sample)
    begin
        if sample'event then

            shift_reg <= serial & shift_reg(9 downto 1);

            if count = 9 then
                count <= 0;
            else
                count <= count+1;
            end if;

            if (shift_reg = "1101010100")
            or (shift_reg = "0010101011")
            or (shift_reg = "0101010100")
            or (shift_reg = "1010101011")
            then -- control symbol
                if locked = '0' then
                    locked <= '1';
                    count <= 0;
                elsif count /= 9 then
                    locked <= '0';
                    count <= 0;
                end if;
            end if;

            if locked = '1' then
                if count = 9 then
                    parallel <= shift_reg;
                    clk <= '0';
                elsif count = 4 then
                    clk <= '1';
                end if;
            else
                parallel <= (others => 'X');
                clk <= '0';
            end if;

        end if;
    end process;

end architecture model;
----------------------------------------------------------------------
-- end of file
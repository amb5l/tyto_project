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
        refclk      : in    std_logic;
        serial      : in    std_logic;
        parallel    : out   std_logic_vector(9 downto 0);
        clk         : out   std_logic;
        locked      : out   std_logic
    );
end entity model_tmds_cdr_des;

architecture model of model_tmds_cdr_des is

    signal  refclk_prev : time := 0ps;
    signal  tr          : time := 0ps;
    signal  refclk_d    : std_logic_vector(1 to 4);
    signal  sample      : std_logic := '0'; -- DDR sample clock
    signal  count       : integer range 0 to 9 := 0;
    signal  shift_reg   : std_logic_vector(9 downto 0);

begin

    -- lazy assumption: refclk edges align with serial edges
    process(refclk)
        variable t : time;
    begin
        if rising_edge(refclk) then
            t := now-refclk_prev;
            if t < 40ns and t > 6.7ns then -- between 25 and 148.5 MHz
                tr <= now-refclk_prev;
            else
                tr <= 0ps;
            end if;
            refclk_prev <= now;
        end if;
    end process;
    refclk_d(1) <= refclk after tr/10;
    refclk_d(2) <= refclk after (2*tr)/10;
    refclk_d(3) <= refclk after (3*tr)/10;
    refclk_d(4) <= refclk after (4*tr)/10;
    sample <= refclk xor refclk_d(1) xor refclk_d(2) xor refclk_d(3) xor refclk_d(4) after tr/20;

    -- serial to parallel
    process(locked,sample)
    begin
        if sample'event then
            shift_reg <= serial & shift_reg(9 downto 1);
            count <= count+1;
            if count = 9 then
                count <= 0;
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

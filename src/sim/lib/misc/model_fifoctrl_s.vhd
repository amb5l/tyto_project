--------------------------------------------------------------------------------
-- model_mig.vhd                                                              --
-- Behavioural model of a fifo controller (single clock).                     --
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

entity model_fifoctrl_s is
    generic (
        size    : integer
    );
    port (
        rst     : in    std_logic;
        clk     : in    std_logic;
        wen     : in    std_logic;
        ren     : in    std_logic;
        ef      : out   std_logic;
        ff      : out   std_logic;
        wptr    : out   integer range 0 to size-1;
        wcount  : out   integer range 0 to size;
        werr    : out   std_logic;
        rptr    : out   integer range 0 to size-1;
        rcount  : out   integer range 0 to size;
        rerr    : out   std_logic
    );
end entity model_fifoctrl_s;

architecture model of model_fifoctrl_s is
begin

    process(rst,clk)

        variable temp_wcount : integer;
        variable temp_rcount : integer;

    begin
        if rst = '1' then

            ef      <= '1';
            ff      <= '0';
            wptr    <= 0;
            wcount  <= size;
            werr    <= '0';
            rptr    <= 0;
            rcount  <= 0;
            rerr    <= '0';

        elsif rising_edge(clk) then

            temp_wcount := wcount;
            temp_rcount := rcount;

            if wen = '1' then
                temp_wcount := temp_wcount-1;
                temp_rcount := temp_rcount+1;
                wptr <= (wptr+1) mod size;
                ef <= '0';
                werr <= werr or ff;
            end if;

            if ren = '1' then
                temp_wcount := temp_wcount+1;
                temp_rcount := temp_rcount-1;
                rptr <= (rptr+1) mod size;
                rerr <= rerr or ef;
                ff <= '0';
                rerr <= rerr or ef;
            end if;

            if temp_wcount = 0 then
                ff <= '1';
            else
                ff <= '0';
            end if;
            if temp_rcount = 0 then
                ef <= '1';
            else
                ef <= '0';
            end if;

            wcount <= temp_wcount;
            rcount <= temp_rcount;

        end if;
    end process;

end architecture model;

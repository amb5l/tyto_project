--------------------------------------------------------------------------------
-- double_sync.vhd                                                            --
-- Double flip flop synchroniser.                                             --
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

library unisim;
use unisim.vcomponents.all;

entity double_sync is
    port (
        rst : in    std_logic;
        clk : in    std_logic;
        d   : in    std_logic;
        q   : out   std_logic
    );
end entity double_sync;

architecture synth of double_sync is

    signal i : std_logic;

    attribute async_reg : string;
    attribute async_reg of FF1 : label is "TRUE";
    attribute async_reg of FF2 : label is "TRUE";

begin

    FF1: fdre
        port map (
             c  => clk,
             ce => '1',
             r  => rst,
             d  => d,
             q  => i
        );

    FF2: fdre
        port map (
             c  => clk,
             ce => '1',
             r  => rst,
             d  => i,
             q  => q
        );

end architecture synth;

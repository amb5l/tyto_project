--------------------------------------------------------------------------------
-- np65_types_pkg.vhd                                                         --
-- Common types for np65 CPU design.                                          --
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

package np65_types_pkg is

    type slv_7_0_t is array(natural range <>) of std_logic_vector(7 downto 0);
    type slv_7_2_t is array(natural range <>) of std_logic_vector(7 downto 2);
    type slv_7_3_t is array(natural range <>) of std_logic_vector(7 downto 3);
    type slv_15_0_t is array(natural range <>) of std_logic_vector(15 downto 0);
    type slv_31_0_t is array(natural range <>) of std_logic_vector(31 downto 0);

end package np65_types_pkg;
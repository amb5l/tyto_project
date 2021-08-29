--------------------------------------------------------------------------------
-- global_pkg_nexys_video.vhd                                                 --
-- Board specific globals for the mb_fb design.                               --
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

package global_pkg is

    constant data_width_log2    : integer := 4;     -- 4 => 2^4 => 16 bytes
    constant addr_width_log2    : integer := 25;    -- 25 => 2^25 * 16 = 512MBytes
    
    type mig_addr_t is array(natural range <>) of std_logic_vector(addr_width_log2+data_width_log2-1 downto data_width_log2);
    type mig_data_t is array(natural range <>) of std_logic_vector(2**(data_width_log2+3)-1 downto 0);
    type mig_be_t is array (natural range <>) of std_logic_vector(2**data_width_log2-1 downto 0);

end package global_pkg;

--------------------------------------------------------------------------------
-- tb_np65_poc_qmtech_wukong.vhd                                              --
-- Simulation testbench for np65_poc_qmtech_wukong.vhd.                       --
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
use ieee.numeric_std.all;

library std;
use std.env.all;

entity tb_np65_poc_nexys_video is
end entity tb_np65_poc_nexys_video;

architecture sim of tb_np65_poc_nexys_video is

    signal clki_50m     : std_logic;
    signal key_n        : std_logic_vector(1 downto 0);
    signal led_n        : std_logic_vector(1 downto 0);

begin

    clki_50m <=
        '1' after 10ns when clki_50m = '0' else
        '0' after 10ns when clki_50m = '1' else
        '0';

    process
        variable mode : integer;
    begin
        key_n(0) <= '0';
        wait for 20ns;
        key_n(0) <= '1';
        wait;
    end process;

    UUT: entity work.top
        port map (
            clki_50m    => clki_50m,
            led_n       => led_n,
            key_n       => key_n,
            ser_tx      => open,
            hdmi_clk_p  => hdmi_clk_p,
            hdmi_clk_n  => hdmi_clk_n,
            hdmi_d_p    => hdmi_d_p,
            hdmi_d_n    => hdmi_d_n,
            hdmi_scl    => open,
            hdmi_sda    => open,
            eth_rst_n   => open,
            ddr3_rst_n  => open
        );

end architecture sim;

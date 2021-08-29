--------------------------------------------------------------------------------
-- tb_mb_display_sd_qmtech_wukong.vhd                                           --
-- Top level simulation testbench for the mb_display_sd design.               --
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

library std;
use std.env.all;

library xil_defaultlib;
use xil_defaultlib.types_pkg.all;

entity tb_mb_display_sd_qmtech_wukong is
end entity tb_mb_display_sd_qmtech_wukong;

architecture sim of tb_mb_display_sd_qmtech_wukong is

    signal clki_50m         : std_logic;
    signal key_n            : std_logic_vector(1 downto 0);
    signal led_n            : std_logic_vector(1 downto 0);

    signal hdmi_clk_p       : std_logic;
    signal hdmi_clk_n       : std_logic;
    signal hdmi_d_p         : std_logic_vector(0 to 2);
    signal hdmi_d_n         : std_logic_vector(0 to 2);

    signal vga_clk          : std_logic;
    signal vga_vs           : std_logic;
    signal vga_hs           : std_logic;
    signal vga_de           : std_logic;
    signal vga_r            : std_logic_vector(7 downto 0);
    signal vga_g            : std_logic_vector(7 downto 0);
    signal vga_b            : std_logic_vector(7 downto 0);

    signal cap_stb          : std_logic;

begin

    clki_50m <=
        '1' after 10ns when clki_50m = '0' else
        '0' after 10ns when clki_50m = '1' else
        '0';

    process
    begin
        key_n <= "10";
        wait for 20ns;
        key_n <= "11";
        wait until rising_edge(cap_stb);
        stop;
    end process;

    UUT: entity xil_defaultlib.top
        port map (
            clki_50m    => clki_50m,
            led_n       => led_n,
            key_n       => key_n,
            ser_tx      => open,
            ser_rx      => '1',
            hdmi_clk_p  => hdmi_clk_p,
            hdmi_clk_n  => hdmi_clk_n,
            hdmi_d_p    => hdmi_d_p,
            hdmi_d_n    => hdmi_d_n,
            hdmi_scl    => open,
            hdmi_sda    => open,
            eth_rst_n   => open,
            ddr3_rst_n  => open
        );

    DECODE: entity xil_defaultlib.model_dvi_decoder
        port map (
            dvi_clk     => hdmi_clk_p,
            dvi_d       => hdmi_d_p,
            vga_clk     => vga_clk,
            vga_vs      => vga_vs,
            vga_hs      => vga_hs,
            vga_de      => vga_de,
            vga_p(2)    => vga_r,
            vga_p(1)    => vga_g,
            vga_p(0)    => vga_b
        );

    CAPTURE: entity xil_defaultlib.model_vga_sink
        generic map (
            name        => "sim_mb_display_sd_nexys_video"
        )
        port map (
            rst         => '0',
            clk         => vga_clk,
            vs          => vga_vs,
            hs          => vga_hs,
            de          => vga_de,
            r           => vga_r,
            g           => vga_g,
            b           => vga_b,
            stb         => cap_stb
        );

end architecture sim;

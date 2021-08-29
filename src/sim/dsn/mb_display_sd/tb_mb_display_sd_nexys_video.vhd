--------------------------------------------------------------------------------
-- tb_mb_display_sd_nexys_video.vhd                                           --
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

entity tb_mb_display_sd_nexys_video is
end entity tb_mb_display_sd_nexys_video;

architecture sim of tb_mb_display_sd_nexys_video is

    constant mode           : std_logic_vector(3 downto 0) := "0000";
    constant dvi            : std_logic := '0';

    signal clki_100m        : std_logic;
    signal btn_rst_n        : std_logic;
    signal sw               : std_logic_vector(7 downto 0);
    signal led              : std_logic_vector(7 downto 0);

    signal hdmi_tx_clk_p    : std_logic;
    signal hdmi_tx_clk_n    : std_logic;
    signal hdmi_tx_d_p      : std_logic_vector(0 to 2);
    signal hdmi_tx_d_n      : std_logic_vector(0 to 2);

    signal vga_clk          : std_logic;
    signal vga_vs           : std_logic;
    signal vga_hs           : std_logic;
    signal vga_de           : std_logic;
    signal vga_r            : std_logic_vector(7 downto 0);
    signal vga_g            : std_logic_vector(7 downto 0);
    signal vga_b            : std_logic_vector(7 downto 0);

    signal cap_stb          : std_logic;

begin

    clki_100m <=
        '1' after 5ns when clki_100m = '0' else
        '0' after 5ns when clki_100m = '1' else
        '0';

    process
    begin
        sw <= "000" & dvi & mode;
        btn_rst_n <= '0';
        wait for 20ns;
        btn_rst_n <= '1';
        wait until rising_edge(cap_stb);
        stop;
    end process;

    UUT: entity xil_defaultlib.top
        port map (
            clki_100m       => clki_100m,
            led             => led,
            btn_rst_n       => btn_rst_n,
            oled_res_n      => open,
            oled_d_c        => open,
            oled_sclk       => open,
            oled_sdin       => open,
            hdmi_tx_clk_p   => hdmi_tx_clk_p,
            hdmi_tx_clk_n   => hdmi_tx_clk_n,
            hdmi_tx_d_p     => hdmi_tx_d_p,
            hdmi_tx_d_n     => hdmi_tx_d_n,
            ac_mclk         => open,
            ac_dac_sdata    => open,
            uart_rx_out     => open,
            uart_tx_in      => '1',
            eth_rst_n       => open,
            ftdi_rd_n       => open,
            ftdi_wr_n       => open,
            ftdi_siwu_n     => open,
            ftdi_oe_n       => open,
            ps2_clk         => open,
            ps2_data        => open,
            qspi_cs_n       => open
        );

    DECODE: entity xil_defaultlib.model_dvi_decoder
        port map (
            dvi_clk     => hdmi_tx_clk_p,
            dvi_d       => hdmi_tx_d_p,
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

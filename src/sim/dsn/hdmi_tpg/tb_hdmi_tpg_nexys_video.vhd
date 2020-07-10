--------------------------------------------------------------------------------
-- tb_hdmi_tpg_nexys_video.vhd                                                --
-- Simulation testbench for hdmi_tpg_nexys_video.vhd.                         --
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
use ieee.numeric_std.all;

library std;
use std.env.all;

library xil_defaultlib;
use xil_defaultlib.types_pkg.all;

entity tb_hdmi_tpg_nexys_video is
end entity tb_hdmi_tpg_nexys_video;

architecture sim of tb_hdmi_tpg_nexys_video is

    signal clki_100m        : std_logic;
    signal btn_rst_n        : std_logic;
    signal btn_c            : std_logic;
    signal sw               : std_logic_vector(7 downto 0);
    signal led              : std_logic_vector(7 downto 0);

    signal hdmi_tx_clk_p    : std_logic;
    signal hdmi_tx_clk_n    : std_logic;
    signal hdmi_tx_d_p      : std_logic_vector(0 to 2);
    signal hdmi_tx_d_n      : std_logic_vector(0 to 2);

    signal data_pstb        : std_logic;
    signal data_hb          : slv_7_0_t(0 to 3);
    signal data_hb_ok       : std_logic;
    signal data_sb          : slv_7_0_2d_t(0 to 3,0 to 7);
    signal data_sb_ok       : std_logic_vector(0 to 3);

    signal vga_rst          : std_logic;
    signal vga_clk          : std_logic;
    signal vga_vs           : std_logic;
    signal vga_hs           : std_logic;
    signal vga_de           : std_logic;
    signal vga_r            : std_logic_vector(7 downto 0);
    signal vga_g            : std_logic_vector(7 downto 0);
    signal vga_b            : std_logic_vector(7 downto 0);

    signal cap_rst          : std_logic;
    signal cap_stb          : std_logic;

begin

    clki_100m <=
        '1' after 5ns when clki_100m = '0' else
        '0' after 5ns when clki_100m = '1' else
        '0';

    sw <= (others => '0');

    process
        variable mode : integer;
    begin
        mode := 0;
        btn_rst_n <= '0';
        btn_c <= '0';
        cap_rst <= '1';
        wait for 20ns;
        btn_rst_n <= '1';
        cap_rst <= '0';
        loop
            wait until rising_edge(cap_stb);
            mode := mode + 1;
            if mode = 15 then
                exit;
            end if;
            btn_c <= '1';
            wait for 100ns;
            btn_c <= '0';
            wait for 100ns;
        end loop;
    end process;

    UUT: entity work.top
        port map (
            clki_100m       => clki_100m,
            led             => led,
            btn_rst_n       => btn_rst_n,
            btn_c           => btn_c,
            sw              => sw,
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
            eth_rst_n       => open,
            ftdi_rd_n       => open,
            ftdi_wr_n       => open,
            ftdi_siwu_n     => open,
            ftdi_oe_n       => open,
            ps2_clk         => open,
            ps2_data        => open,
            qspi_cs_n       => open
        );

    DECODE: entity work.model_hdmi_decoder
        port map (
            rst         => cap_rst,
            hdmi_clk    => hdmi_tx_clk_p,
            hdmi_d      => hdmi_tx_d_p,
            data_pstb   => data_pstb,
            data_hb     => data_hb,
            data_hb_ok  => data_hb_ok,
            data_sb     => data_sb,
            data_sb_ok  => data_sb_ok,
            vga_rst     => vga_rst,
            vga_clk     => vga_clk,
            vga_vs      => vga_vs,
            vga_hs      => vga_hs,
            vga_de      => vga_de,
            vga_p(2)    => vga_r,
            vga_p(1)    => vga_g,
            vga_p(0)    => vga_b
        );

    CAPTURE: entity work.model_vga_sink
        generic map (
            name        => "tb_hdmi_tpg_nexys_video"
        )
        port map (
            vga_rst => vga_rst,
            vga_clk => vga_clk,
            vga_vs  => vga_vs,
            vga_hs  => vga_hs,
            vga_de  => vga_de,
            vga_r   => vga_r,
            vga_g   => vga_g,
            vga_b   => vga_b,
            cap_rst => cap_rst,
            cap_stb => cap_stb
        );

end architecture sim;

--------------------------------------------------------------------------------
-- tb_mb_fb_qmtech_wukong.vhd                                                 --
-- Simulation testbench for mb_fb_qmtech_wukong.vhd.                          --
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

library work;
use work.global_pkg.all;

entity tb_mb_fb_qmtech_wukong is
end entity tb_mb_fb_qmtech_wukong;

architecture sim of tb_mb_fb_qmtech_wukong is

    signal clki_50m         : std_logic;
    signal key_n            : std_logic_vector(1 downto 0);
    signal led_n            : std_logic_vector(1 downto 0);

    signal hdmi_clk_p       : std_logic;
    signal hdmi_clk_n       : std_logic;
    signal hdmi_d_p         : std_logic_vector(0 to 2);
    signal hdmi_d_n         : std_logic_vector(0 to 2);

    signal ddr3_reset_n     : std_logic;
    signal ddr3_ck_p        : std_logic_vector(0 downto 0);
    signal ddr3_ck_n        : std_logic_vector(0 downto 0);
    signal ddr3_cke         : std_logic_vector(0 downto 0);
    signal ddr3_ras_n       : std_logic;
    signal ddr3_cas_n       : std_logic;
    signal ddr3_we_n        : std_logic;
    signal ddr3_odt         : std_logic_vector(0 downto 0);
    signal ddr3_addr        : std_logic_vector(14 downto 0);
    signal ddr3_ba          : std_logic_vector(2 downto 0);
    signal ddr3_dm          : std_logic_vector(1 downto 0);
    signal ddr3_dq          : std_logic_vector(15 downto 0);
    signal ddr3_dqs_p       : std_logic_vector(1 downto 0);
    signal ddr3_dqs_n       : std_logic_vector(1 downto 0);

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

    component top is
        port (
            clki_50m        : in    std_logic;
            led_n           : out   std_logic_vector(1 downto 0);
            key_n           : in    std_logic_vector(1 downto 0);
            ser_tx          : out   std_logic;
            ser_rx          : in    std_logic;
            hdmi_clk_p      : out   std_logic;
            hdmi_clk_n      : out   std_logic;
            hdmi_d_p        : out   std_logic_vector(0 to 2);
            hdmi_d_n        : out   std_logic_vector(0 to 2);
            hdmi_scl        : out   std_logic;
            hdmi_sda        : inout std_logic;
            eth_rst_n       : out   std_logic;
            ddr3_reset_n    : out   std_logic;
            ddr3_ck_p       : out   std_logic_vector(0 downto 0);
            ddr3_ck_n       : out   std_logic_vector(0 downto 0);
            ddr3_cke        : out   std_logic_vector(0 downto 0);
            ddr3_ras_n      : out   std_logic;
            ddr3_cas_n      : out   std_logic;
            ddr3_we_n       : out   std_logic;
            ddr3_odt        : out   std_logic_vector(0 downto 0);
            ddr3_addr       : out   std_logic_vector(14 downto 0);
            ddr3_ba         : out   std_logic_vector(2 downto 0);
            ddr3_dm         : out   std_logic_vector(1 downto 0);
            ddr3_dq         : inout std_logic_vector(15 downto 0);
            ddr3_dqs_p      : inout std_logic_vector(1 downto 0);
            ddr3_dqs_n      : inout std_logic_vector(1 downto 0)
        );
    end component top;

begin

    clki_50m <=
        '1' after 10ns when clki_50m = '0' else
        '0' after 10ns when clki_50m = '1' else
        '0';

    process
    begin
        key_n(0) <= '0';
        vga_rst <= '1';
        cap_rst <= '1';
        wait for 100ns;
        key_n(0) <= '1';
        vga_rst <= '0';
        cap_rst <= '0';
        wait;
    end process;

    UUT: component top
        port map (
            clki_50m        => clki_50m,
            led             => led,
            btn_rst_n       => key_n(0),
            ser_tx          => open,
            ser_rx          => '1',
            hdmi_clk_p      => hdmi_clk_p,
            hdmi_clk_n      => hdmi_clk_n,
            hdmi_d_p        => hdmi_d_p,
            hdmi_d_n        => hdmi_d_n,
            hdmi_scl        => open,
            hdmi_sda        => open,
            eth_rst_n       => open,
            ftdi_rd_n       => open,
            ddr3_reset_n    => ddr3_reset_n,
            ddr3_ck_p       => ddr3_ck_p,
            ddr3_ck_n       => ddr3_ck_n,
            ddr3_cke        => ddr3_cke,
            ddr3_ras_n      => ddr3_ras_n,
            ddr3_cas_n      => ddr3_cas_n,
            ddr3_we_n       => ddr3_we_n,
            ddr3_odt        => ddr3_odt,
            ddr3_addr       => ddr3_addr,
            ddr3_ba         => ddr3_ba,
            ddr3_dm         => ddr3_dm,
            ddr3_dq         => ddr3_dq,
            ddr3_dqs_p      => ddr3_dqs_p,
            ddr3_dqs_n      => ddr3_dqs_n
        );

    DDR3: entity work.ddr3_model
        port map (
            rst_n           => ddr3_reset_n,
            ck              => ddr3_ck_p,
            ck_n            => ddr3_ck_n,
            cke             => ddr3_cke,
            cs_n            => '0',
            ras_n           => ddr3_ras_n,
            cas_n           => ddr3_cas_n,
            we_n            => ddr3_we_n,
            odt             => ddr3_odt,
            addr            => ddr3_addr,
            ba              => ddr3_ba,
            dm_tdqs         => ddr3_dm,
            dq              => ddr3_dq,
            dqs             => ddr3_dqs_p,
            dqs_n           => ddr3_dqs_n,
            tdqs_n          => "11"
        );

    DECODE: entity work.model_dvi_decoder
        port map (
            dvi_clk         => hdmi_clk_p,
            dvi_d           => hdmi_d_p,
            vga_clk         => vga_clk,
            vga_vs          => vga_vs,
            vga_hs          => vga_hs,
            vga_de          => vga_de,
            vga_p(2)        => vga_r,
            vga_p(1)        => vga_g,
            vga_p(0)        => vga_b
        );

    CAPTURE: entity work.model_vga_sink
        generic map (
            name        => "tb_mb_fb_qmtech_wukong"
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

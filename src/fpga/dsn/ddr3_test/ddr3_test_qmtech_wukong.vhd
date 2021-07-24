--------------------------------------------------------------------------------
-- ddr3_test_nexys_video.vhd                                                  --
-- QMTECH Wukong board wrapper for the ddr3_test design.                      --
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

library xil_defaultlib;

entity top is
    port (

        -- clocks
        clki_50m        : in    std_logic;

        -- LEDs and keys
        led_n           : out   std_logic_vector(1 downto 0);
        key_n           : in    std_logic_vector(1 downto 0);

        -- serial (UART)
        ser_tx          : out   std_logic;
--      ser_rx          : in    std_logic;

        -- HDMI output
--      hdmi_clk_p      : out   std_logic;
--      hdmi_clk_n      : out   std_logic;
--      hdmi_d_p        : out   std_logic_vector(0 to 2);
--      hdmi_d_n        : out   std_logic_vector(0 to 2);
        hdmi_scl        : out   std_logic;
        hdmi_sda        : inout std_logic;
--      hdmi_cec        : out   std_logic;
--      hdmi_hpd        : in    std_logic;

        -- ethernet
        eth_rst_n       : out   std_logic;
--      eth_gtx_clk     : out   std_logic;
--      eth_txclk       : out   std_logic;
--      eth_txen        : out   std_logic;
--      eth_txer        : out   std_logic;
--      eth_txd         : out   std_logic_vector(7 downto 0);
--      eth_rxclk       : in    std_logic;
--      eth_rxdv        : in    std_logic;
--      eth_rxer        : in    std_logic;
--      eth_rxd         : in    std_logic_vector(7 downto 0);
--      eth_crs         : in    std_logic;
--      eth_col         : in    std_logic;
--      eth_mdc         : out   std_logic;
--      eth_mdio        : inout std_logic;

        -- DDR3
        ddr3_rst_n      : out   std_logic;
        ddr3_ck_p       : out   std_logic_vector(0 downto 0);
        ddr3_ck_n       : out   std_logic_vector(0 downto 0);
        ddr3_cke        : out   std_logic_vector(0 downto 0);
        ddr3_ras_n      : out   std_logic;
        ddr3_cas_n      : out   std_logic;
        ddr3_we_n       : out   std_logic;
        ddr3_odt        : out   std_logic_vector(0 downto 0);
        ddr3_addr       : out   std_logic_vector(13 downto 0);
        ddr3_ba         : out   std_logic_vector(2 downto 0);
        ddr3_dm         : out   std_logic_vector(1 downto 0);
        ddr3_dq         : inout std_logic_vector(15 downto 0);
        ddr3_dqs_p      : inout std_logic_vector(1 downto 0);
        ddr3_dqs_n      : inout std_logic_vector(1 downto 0);

        -- I/O connectors
        j10             : out std_logic_vector(7 downto 0)
--      j11             : inout std_logic_vector(7 downto 0);
--      jp2             : inout std_logic_vector(15 downto 0);
--      j12             : inout std_logic_vector(33 downto 0);

        -- MGTs
--      mgt_clk_p       : in    std_logic_vector(0 to 1);
--      mgt_clk_n       : in    std_logic_vector(0 to 1);
--      mgt_tx_p        : out   std_logic_vector(3 downto 0);
--      mgt_tx_n        : out   std_logic_vector(3 downto 0);
--      mgt_rx_p        : out   std_logic_vector(3 downto 0);
--      mgt_rx_n        : out   std_logic_vector(3 downto 0);

    );
end entity top;

architecture synth of top is

    signal rst_100m     : std_logic;
    signal clk_100m     : std_logic;
    signal clk_50m      : std_logic;
    signal ui_cc        : std_logic;
    signal ui_rdy       : std_logic;
    signal ui_en        : std_logic;
    signal ui_r_w       : std_logic;
    signal ui_a         : std_logic_vector(28 downto 4);
    signal ui_wrdy      : std_logic;
    signal ui_we        : std_logic;
    signal ui_wbe       : std_logic_vector(15 downto 0);
    signal ui_wd        : std_logic_vector(127 downto 0);
    signal ui_rd        : std_logic_vector(127 downto 0);
    signal ui_rstb      : std_logic;

    signal ctrl_size    : std_logic_vector(4 downto 0);
    signal stat_run     : std_logic;
    signal stat_passes  : std_logic_vector(31 downto 0);
    signal stat_errors  : std_logic_vector(31 downto 0);

begin

    ctrl_size <= "11100" when key_n(1) = '1' else "01000";

    TEST: entity xil_defaultlib.ddr3_test
        port map (
            clk_100m    => clk_100m,
            rst_100m    => rst_100m,
            ctrl_run    => '1',
            ctrl_slow   => '0',
            ctrl_size   => ctrl_size,
            stat_run    => stat_run,
            stat_passes => stat_passes,
            stat_errors => stat_errors,
            ui_cc       => ui_cc,
            ui_rdy      => ui_rdy,
            ui_en       => ui_en,
            ui_r_w      => ui_r_w,
            ui_a        => ui_a,
            ui_wrdy     => ui_wrdy,
            ui_we       => ui_we,
            ui_wbe      => ui_wbe,
            ui_wd       => ui_wd,
            ui_rd       => ui_rd,
            ui_rstb     => ui_rstb
        );

    MC: entity xil_defaultlib.ddr3_wrapper_qmtech_wukong
        port map (
            xrst        => not key_n(0),
            xclk        => clki_50m,
            rst_100m    => rst_100m,
            clk_100m    => clk_100m,
            clk_50m     => clk_50m,
            ui_cc       => ui_cc,
            ui_rdy      => ui_rdy,
            ui_en       => ui_en,
            ui_r_w      => ui_r_w,
            ui_a        => ui_a(27 downto 4),
            ui_wrdy     => ui_wrdy,
            ui_we       => ui_we,
            ui_wbe      => ui_wbe,
            ui_wd       => ui_wd,
            ui_rd       => ui_rd,
            ui_rstb     => ui_rstb,
            ddr3_rst_n  => ddr3_rst_n,
            ddr3_ck_p   => ddr3_ck_p,
            ddr3_ck_n   => ddr3_ck_n,
            ddr3_cke    => ddr3_cke,
            ddr3_ras_n  => ddr3_ras_n,
            ddr3_cas_n  => ddr3_cas_n,
            ddr3_we_n   => ddr3_we_n,
            ddr3_odt    => ddr3_odt,
            ddr3_addr   => ddr3_addr,
            ddr3_ba     => ddr3_ba,
            ddr3_dm     => ddr3_dm,
            ddr3_dq     => ddr3_dq,
            ddr3_dqs_p  => ddr3_dqs_p,
            ddr3_dqs_n  => ddr3_dqs_n
        );

    -- I/O

    j10(0) <= clk_50m;
    j10(7 downto 1) <= (others => '0');
    led_n(0) <= not stat_run;
    led_n(1) <= '0' when stat_errors /= x"00000000" else '1';

    -- unused I/O

    ser_tx      <= '1';
    hdmi_scl    <= 'Z';
    hdmi_sda    <= 'Z';
    eth_rst_n   <= '0';

end architecture synth;

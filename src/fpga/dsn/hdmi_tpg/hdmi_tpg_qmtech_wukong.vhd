--------------------------------------------------------------------------------
-- hdmi_tpg_qmtech_wukong.vhd                                                 --
-- Board specific top level wrapper for the hdmi_tpg design.                  --
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
        hdmi_clk_p      : out   std_logic;
        hdmi_clk_n      : out   std_logic;
        hdmi_d_p        : out   std_logic_vector(0 to 2);
        hdmi_d_n        : out   std_logic_vector(0 to 2);
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
        ddr3_rst_n      : out   std_logic
--      ddr3_ck_p       : out   std_logic_vector(0 downto 0);
--      ddr3_ck_n       : out   std_logic_vector(0 downto 0);
--      ddr3_cke        : out   std_logic_vector(0 downto 0);
--      ddr3_ras_n      : out   std_logic;
--      ddr3_cas_n      : out   std_logic;
--      ddr3_we_n       : out   std_logic;
--      ddr3_odt        : out   std_logic_vector(0 downto 0);
--      ddr3_addr       : out   std_logic_vector(14 downto 0);
--      ddr3_ba         : out   std_logic_vector(2 downto 0);
--      ddr3_dm         : out   std_logic_vector(1 downto 0);
--      ddr3_dq         : inout std_logic_vector(15 downto 0);
--      ddr3_dqs_p      : inout std_logic_vector(1 downto 0);
--      ddr3_dqs_n      : inout std_logic_vector(1 downto 0)

        -- I/O connectors
--      j10             : inout std_logic_vector(7 downto 0);
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

    signal ext_rst      : std_logic;
    signal ref_rst      : std_logic;
    signal ref_clk      : std_logic;
    signal mode_step    : std_logic;
    signal mode         : std_logic_vector(3 downto 0);
    signal dvi          : std_logic;
    signal heartbeat    : std_logic_vector(3 downto 0);
    signal status       : std_logic_vector(2 downto 0);

begin

    -- user interface:
    -- button SW2 = reset
    -- button SW3 = press to increment video mode (0..14 then wrap)
    -- led D5 = heartbeat
    -- led D6 = all MMCMs locked

    ext_rst <= not key_n(0);
    -- note MMCM cascading; better to have 100MHz input clock
    REF_CLOCK: entity xil_defaultlib.clock_100m
        generic map (
            fref    => 50.0 -- 50MHz
        )
        port map (
            rsti    => ext_rst,
            clki    => clki_50m,
            rsto    => ref_rst,
            clko    => ref_clk
        );
    mode_step <= not key_n(1);
    dvi <= '0';
    led_n(0) <=
        heartbeat(2) when status = "111" else   -- full lock = 1Hz
        heartbeat(1) when status /= "000" else  -- partial lock = 2Hz
        heartbeat(0);                           -- no lock = 4Hz
    led_n(1) <= not mode(0);

    MAIN: entity xil_defaultlib.hdmi_tpg
        generic map (
            fref        => 100.0 -- 100MHz
        )
        port map (
            ext_rst     => ref_rst,
            ref_clk     => ref_clk,
            mode_step   => mode_step,
            mode        => mode,
            dvi         => dvi,
            heartbeat   => heartbeat,
            status      => status,
            hdmi_clk_p  => hdmi_clk_p,
            hdmi_clk_n  => hdmi_clk_n,
            hdmi_d_p    => hdmi_d_p,
            hdmi_d_n    => hdmi_d_n
        );

    -- unused I/Os

    ser_tx      <= '1';
    hdmi_scl    <= 'Z';
    hdmi_sda    <= 'Z';
    eth_rst_n   <= '0';
    ddr3_rst_n  <= '0';

end architecture synth;

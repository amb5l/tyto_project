--------------------------------------------------------------------------------
-- mb_fb_qmtech_wukong.vhd                                                    --
-- Board specific top level wrapper for the mb_fb design.                     --
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
use work.mb_fb_pkg.all;

entity top is
    port (

        -- clocks
        clki_50m        : in    std_logic;

        -- LEDs and keys
        led_n           : out   std_logic_vector(1 downto 0);
        key_n           : in    std_logic_vector(1 downto 0);

        -- serial (UART)
        ser_tx          : out   std_logic;
        ser_rx          : in    std_logic;

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
        ddr3_reset_n    : out   std_logic;
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
        ddr3_dqs_n      : inout std_logic_vector(1 downto 0)

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

    signal clk          : std_logic;
    signal rst          : std_logic;

    signal led          : std_logic_vector(1 downto 0);

    signal mig_cc       : std_logic;
    signal mig_avalid   : std_logic;
    signal mig_r_w      : std_logic;
    signal mig_addr     : std_logic_vector(addr_width_log2+data_width_log2-1 downto data_width_log2);
    signal mig_aready   : std_logic;
    signal mig_wvalid   : std_logic;
    signal mig_wdata    : std_logic_vector(2**(data_width_log2+3)-1 downto 0);
    signal mig_wbe      : std_logic_vector(2**data_width_log2-1 downto 0);
    signal mig_wready   : std_logic;
    signal mig_rdata    : std_logic_vector(2**(data_width_log2+3)-1 downto 0);
    signal mig_rvalid   : std_logic;

    -- MIG (DDR3 controller IP core)
    component ddr3 is
        port (
            sys_rst               : in    std_logic;
            sys_clk_i             : in    std_logic;
            clk_ref_i             : in    std_logic;
            ui_clk_sync_rst       : out   std_logic;
            ui_clk                : out   std_logic;
            device_temp           : out   std_logic_vector(11 downto 0);
            init_calib_complete   : out   std_logic;
            app_addr              : in    std_logic_vector(27 downto 0);
            app_cmd               : in    std_logic_vector(2 downto 0);
            app_en                : in    std_logic;
            app_rdy               : out   std_logic;
            app_wdf_data          : in    std_logic_vector(127 downto 0);
            app_wdf_end           : in    std_logic;
            app_wdf_mask          : in    std_logic_vector(15 downto 0);
            app_wdf_wren          : in    std_logic;
            app_rd_data           : out   std_logic_vector(127 downto 0);
            app_rd_data_end       : out   std_logic;
            app_rd_data_valid     : out   std_logic;
            app_wdf_rdy           : out   std_logic;
            app_sr_req            : in    std_logic;
            app_sr_active         : out   std_logic;
            app_ref_req           : in    std_logic;
            app_ref_ack           : out   std_logic;
            app_zq_req            : in    std_logic;
            app_zq_ack            : out   std_logic;
            ddr3_reset_n          : out   std_logic;
            ddr3_ck_p             : out   std_logic_vector(0 downto 0);
            ddr3_ck_n             : out   std_logic_vector(0 downto 0);
            ddr3_cke              : out   std_logic_vector(0 downto 0);
            ddr3_ras_n            : out   std_logic;
            ddr3_cas_n            : out   std_logic;
            ddr3_we_n             : out   std_logic;
            ddr3_odt              : out   std_logic_vector(0 downto 0);
            ddr3_addr             : out   std_logic_vector(13 downto 0);
            ddr3_ba               : out   std_logic_vector(2 downto 0);
            ddr3_dm               : out   std_logic_vector(1 downto 0);
            ddr3_dq               : inout std_logic_vector(15 downto 0);
            ddr3_dqs_p            : inout std_logic_vector(1 downto 0);
            ddr3_dqs_n            : inout std_logic_vector(1 downto 0)
        );
    end component ddr3;

begin

    led_n <= not led;

    -- main design

    MAIN: component mb_fb
        generic map (
            fref            => 100.0 -- 100MHz
        )
        port map (

            xclk            => clki_50m,
            xrst            => not key_n(0),

            sclk            => clk,
            srst            => rst,

            uart_txd        => ser_tx,
            uart_rxd        => ser_rx,

            mig_cc          => mig_cc,
            mig_avalid      => mig_avalid,
            mig_r_w         => mig_r_w,
            mig_addr        => mig_addr,
            mig_aready      => mig_aready,
            mig_wvalid      => mig_wvalid,
            mig_wdata       => mig_wdata,
            mig_wbe         => mig_wbe,
            mig_wready      => mig_wready,
            mig_rdata       => mig_rdata,
            mig_rvalid      => mig_rvalid,

            dvi_clk_p       => hdmi_clk_p,
            dvi_clk_n       => hdmi_clk_n,
            dvi_d_p         => hdmi_d_p,
            dvi_d_n         => hdmi_d_n,

            debug           => led(1 downto 0)
        );

    -- board specific DDR3 controller IP core

    MIG: component ddr3
        port map (

            sys_rst             => not key_n(0),
            sys_clk_i           => clki_50m,
            clk_ref_i           => '0',         -- IODELAYCTRL ref clk generated by DDR3 MMCM

            ui_clk_sync_rst     => rst,
            ui_clk              => clk,
            device_temp         => open,
            init_calib_complete => mig_cc,

            app_addr            => '0' & mig_addr & "000",
            app_cmd             => "00" & mig_r_w,
            app_en              => mig_avalid,
            app_rdy             => mig_aready,
            app_wdf_data        => mig_wdata,
            app_wdf_end         => mig_wvalid,
            app_wdf_mask        => not mig_wbe,
            app_wdf_wren        => mig_wvalid,
            app_rd_data         => mig_rdata,
            app_rd_data_end     => open,
            app_rd_data_valid   => mig_rvalid,
            app_wdf_rdy         => mig_wready,

            app_sr_req          => '0',
            app_sr_active       => open,
            app_ref_req         => '0',
            app_ref_ack         => open,
            app_zq_req          => '0',
            app_zq_ack          => open,

            ddr3_reset_n        => ddr3_reset_n,
            ddr3_ck_p           => ddr3_ck_p,
            ddr3_ck_n           => ddr3_ck_n,
            ddr3_cke            => ddr3_cke,
            ddr3_ras_n          => ddr3_ras_n,
            ddr3_cas_n          => ddr3_cas_n,
            ddr3_we_n           => ddr3_we_n,
            ddr3_odt            => ddr3_odt,
            ddr3_addr           => ddr3_addr,
            ddr3_ba             => ddr3_ba,
            ddr3_dm             => ddr3_dm,
            ddr3_dq             => ddr3_dq,
            ddr3_dqs_p          => ddr3_dqs_p,
            ddr3_dqs_n          => ddr3_dqs_n

        );

    -- unused I/Os

    hdmi_scl    <= 'Z';
    hdmi_sda    <= 'Z';
    eth_rst_n   <= '0';

end architecture synth;

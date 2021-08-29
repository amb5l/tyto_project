--------------------------------------------------------------------------------
-- mb_fb_nexys_video.vhd                                                      --
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
        clki_100m       : in    std_logic;
--      gtp_clk_p       : in    std_logic;
--      gtp_clk_n       : in    std_logic;
--      fmc_mgt_clk_p   : in    std_logic;
--      fmc_mgt_clk_n   : in    std_logic;

        -- LEDs, buttons and switches
        led             : out   std_logic_vector(7 downto 0);
--      btn_c           : in    std_logic;
--      btn_d           : in    std_logic;
--      btn_l           : in    std_logic;
--      btn_r           : in    std_logic;
--      btn_u           : in    std_logic;
        btn_rst_n       : in    std_logic;
--      sw              : in    std_logic_vector(7 downto 0);

        -- OLED
        oled_res_n      : out   std_logic;
        oled_d_c        : out   std_logic;
        oled_sclk       : out   std_logic;
        oled_sdin       : out   std_logic;
--      oled_vbat_dis   : out   std_logic;
--      oled_vdd_dis    : out   std_logic;

        -- HDMI RX
--      hdmi_rx_clk_p   : in    std_logic;
--      hdmi_rx_clk_n   : in    std_logic;
--      hdmi_rx_d_p     : in    std_logic_vector(0 to 2);
--      hdmi_rx_d_n     : in    std_logic_vector(0 to 2);
--      hdmi_rx_sda     : inout std_logic;
--      hdmi_rx_cec     : in    std_logic;
--      hdmi_rx_hpd     : out   std_logic;
--      hdmi_rx_txen    : out   std_logic;
--      hdmi_rx_scl     : in    std_logic;

        -- HDMI TX
        hdmi_tx_clk_p   : out   std_logic;
        hdmi_tx_clk_n   : out   std_logic;
        hdmi_tx_d_p     : out   std_logic_vector(0 to 2);
        hdmi_tx_d_n     : out   std_logic_vector(0 to 2);
--      hdmi_tx_scl     : out   std_logic;
--      hdmi_tx_sda     : inout std_logic;
--      hdmi_tx_cec     : out   std_logic;
--      hdmi_tx_hpd     : in    std_logic;

        -- DisplayPort
--      dp_tx_p         : out   std_logic_vector(0 to 1);
--      dp_tx_n         : out   std_logic_vector(0 to 1);
--      dp_tx_aux_p     : inout std_logic;
--      dp_tx_aux_n     : inout std_logic;
--      dp_tx_aux2_p    : inout std_logic;
--      dp_tx_aux2_n    : inout std_logic;
--      dp_tx_hpd       : in    std_logic;

        -- audio codec
        ac_mclk         : out   std_logic;
--      ac_lrclk        : out   std_logic;
--      ac_bclk         : out   std_logic;
        ac_dac_sdata    : out   std_logic;
--      ac_adc_sdata    : in    std_logic;

        -- PMODs
--      ja              : inout std_logic_vector(7 downto 0);
--      jb              : inout std_logic_vector(7 downto 0);
--      jc              : inout std_logic_vector(7 downto 0);
--      xa_p            : inout std_logic_vector(3 downto 0);
--      xa_n            : inout std_logic_vector(3 downto 0);

        -- UART
        uart_rx_out     : out   std_logic;
        uart_tx_in      : in    std_logic;

        -- ethernet
        eth_rst_n       : out   std_logic;
--      eth_txck        : out   std_logic;
--      eth_txctl       : out   std_logic;
--      eth_txd         : out   std_logic_vector(3 downto 0);
--      eth_rxck        : in    std_logic;
--      eth_rxctl       : in    std_logic;
--      eth_rxd         : in    std_logic_vector(3 downto 0);
--      eth_mdc         : out   std_logic;
--      eth_mdio        : inout std_logic;
--      eth_int_n       : in    std_logic;
--      eth_pme_n       : in    std_logic;

        -- fan
--      fan_pwm         : out   std_logic;

        -- FTDI
--      ftdi_clko       : in    std_logic;
--      ftdi_rxf_n      : in    std_logic;
--      ftdi_txe_n      : in    std_logic;
        ftdi_rd_n       : out   std_logic;
        ftdi_wr_n       : out   std_logic;
        ftdi_siwu_n     : out   std_logic;
        ftdi_oe_n       : out   std_logic;
--      ftdi_d          : inout std_logic_vector(7 downto 0);
--      ftdi_spien      : out   std_logic;

        -- PS/2
        ps2_clk         : inout std_logic;
        ps2_data        : inout std_logic;

        -- QSPI
        qspi_cs_n       : out   std_logic;
--      qspi_dq         : inout std_logic_vector(3 downto 0);

        -- SD
--      sd_reset        : out   std_logic;
--      sd_cclk         : out   std_logic;
--      sd_cmd          : out   std_logic;
--      sd_d            : inout std_logic_vector(3 downto 0);
--      sd_cd           : in    std_logic;

        -- I2C
--      i2c_scl         : inout std_logic;
--      i2c_sda         : inout std_logic;

        -- VADJ
--      set_vadj        : out   std_logic_vector(1 downto 0);
--      vadj_en         : out   std_logic;

        -- FMC
--      fmc_clk0_m2c_p  : in    std_logic;
--      fmc_clk0_m2c_n  : in    std_logic;
--      fmc_clk1_m2c_p  : in    std_logic;
--      fmc_clk1_m2c_n  : in    std_logic;
--      fmc_la_p        : inout std_logic_vector(33 downto 0);
--      fmc_la_n        : inout std_logic_vector(33 downto 0);

        -- DDR3
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
end entity top;

architecture synth of top is

    signal clk          : std_logic;
    signal rst          : std_logic;

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
            app_addr              : in    std_logic_vector(28 downto 0);
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
            ddr3_addr             : out   std_logic_vector(14 downto 0);
            ddr3_ba               : out   std_logic_vector(2 downto 0);
            ddr3_dm               : out   std_logic_vector(1 downto 0);
            ddr3_dq               : inout std_logic_vector(15 downto 0);
            ddr3_dqs_p            : inout std_logic_vector(1 downto 0);
            ddr3_dqs_n            : inout std_logic_vector(1 downto 0)
        );
    end component ddr3;

begin

    led(7 downto 2) <= (others => '0');

    -- main design

    MAIN: component mb_fb
        generic map (
            fref            => 100.0 -- 100MHz
        )
        port map (

            xclk            => clki_100m,
            xrst            => not btn_rst_n,

            sclk            => clk,
            srst            => rst,

            uart_txd        => uart_rx_out,
            uart_rxd        => uart_tx_in,

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

            dvi_clk_p       => hdmi_tx_clk_p,
            dvi_clk_n       => hdmi_tx_clk_n,
            dvi_d_p         => hdmi_tx_d_p,
            dvi_d_n         => hdmi_tx_d_n,

            debug           => led(1 downto 0)
        );

    -- board specific DDR3 controller IP core

    MIG: component ddr3
        port map (

            sys_rst             => not btn_rst_n,
            sys_clk_i           => clki_100m,
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

    oled_res_n      <= '0';
    oled_d_c        <= '0';
    oled_sclk       <= '0';
    oled_sdin       <= '0';
    ac_mclk         <= '0';
    ac_dac_sdata    <= '0';
    eth_rst_n       <= '0';
    ftdi_rd_n       <= '1';
    ftdi_wr_n       <= '1';
    ftdi_siwu_n     <= '1';
    ftdi_oe_n       <= '1';
    ps2_clk         <= 'Z';
    ps2_data        <= 'Z';
    qspi_cs_n       <= '1';

end architecture synth;

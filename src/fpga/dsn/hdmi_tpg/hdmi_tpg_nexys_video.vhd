--------------------------------------------------------------------------------
-- hdmi_tpg_nexys_video.vhd                                                   --
-- Board specific top level wrapper for the mb_display_sd design.             --
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
        clki_100m       : in    std_logic;
        gtp_clk_p       : in    std_logic;
        gtp_clk_n       : in    std_logic;
        fmc_mgt_clk_p   : in    std_logic;
        fmc_mgt_clk_n   : in    std_logic;

        -- LEDs, buttons and switches
        led             : out   std_logic_vector(7 downto 0);
        btn_c_n         : in    std_logic;
        btn_d_n         : in    std_logic;
        btn_l_n         : in    std_logic;
        btn_r_n         : in    std_logic;
        btn_u_n         : in    std_logic;
        btn_rst_n       : in    std_logic;
        sw              : in    std_logic_vector(7 downto 0);

        -- OLED
        oled_res_n      : out   std_logic;
        oled_d_c        : out   std_logic;
        oled_sclk       : out   std_logic;
        oled_sdin       : out   std_logic;
        oled_vbat_dis   : out   std_logic;
        oled_vdd_dis    : out   std_logic;

        -- HDMI RX
--      hdmi_rx_clk_p   : in    std_logic;
--      hdmi_rx_clk_n   : in    std_logic;
--      hdmi_rx_ch_p    : in    std_logic_vector(0 to 2);
--      hdmi_rx_ch_n    : in    std_logic_vector(0 to 2);
        hdmi_rx_scl     : in    std_logic;
        hdmi_rx_sda     : inout std_logic;
        hdmi_rx_cec     : in    std_logic;
        hdmi_rx_hpd     : out   std_logic;
        hdmi_rx_txen    : out   std_logic;

        -- HDMI TX
        hdmi_tx_clk_p   : out   std_logic;
        hdmi_tx_clk_n   : out   std_logic;
        hdmi_tx_ch_p    : out   std_logic_vector(0 to 2);
        hdmi_tx_ch_n    : out   std_logic_vector(0 to 2);
        hdmi_tx_scl     : out   std_logic;
        hdmi_tx_sda     : inout std_logic;
        hdmi_tx_cec     : out   std_logic;
        hdmi_tx_hpd     : in    std_logic;

        -- DisplayPort
--      dp_tx_p         : out   std_logic_vector(0 to 1);
--      dp_tx_n         : out   std_logic_vector(0 to 1);
--      dp_tx_aux_p     : inout std_logic;
--      dp_tx_aux_n     : inout std_logic;
--      dp_tx_aux2_p    : inout std_logic;
--      dp_tx_aux2_n    : inout std_logic;
        dp_tx_hpd       : in    std_logic;

        -- audio codec
        ac_mclk         : out   std_logic;
        ac_lrclk        : out   std_logic;
        ac_bclk         : out   std_logic;
        ac_dac_sdata    : out   std_logic;
        ac_adc_sdata    : in    std_logic;

        -- PMODs
        ja              : inout std_logic_vector(7 downto 0);
        jb              : inout std_logic_vector(7 downto 0);
        jc              : inout std_logic_vector(7 downto 0);
        xa_p            : inout std_logic_vector(3 downto 0);
        xa_n            : inout std_logic_vector(3 downto 0);

        -- UART
        uart_rx_out     : out   std_logic;
        uart_tx_in      : in    std_logic;

        -- ethernet
        eth_rst_n       : out   std_logic;
        eth_txck        : out   std_logic;
        eth_txctl       : out   std_logic;
        eth_txd         : out   std_logic_vector(3 downto 0);
        eth_rxck        : in    std_logic;
        eth_rxctl       : in    std_logic;
        eth_rxd         : in    std_logic_vector(3 downto 0);
        eth_mdc         : out   std_logic;
        eth_mdio        : inout std_logic;
        eth_int_n       : in    std_logic;
        eth_pme_n       : in    std_logic;

        -- fan
        fan_pwm         : out   std_logic;

        -- FTDI
        ftdi_clko       : in    std_logic;
        ftdi_rxf_n      : in    std_logic;
        ftdi_txe_n      : in    std_logic;
        ftdi_rd_n       : out   std_logic;
        ftdi_wr_n       : out   std_logic;
        ftdi_siwu_n     : out   std_logic;
        ftdi_oe_n       : out   std_logic;
        ftdi_d          : inout std_logic_vector(7 downto 0);
        ftdi_spien      : out   std_logic;

        -- PS/2
        ps2_clk         : inout std_logic;
        ps2_data        : inout std_logic;

        -- QSPI
        qspi_cs_n       : out   std_logic;
        qspi_dq         : inout std_logic_vector(3 downto 0);

        -- SD
        sd_reset        : out   std_logic;
        sd_cclk         : out   std_logic;
        sd_cmd          : out   std_logic;
        sd_d            : inout std_logic_vector(3 downto 0);
        sd_cd           : in    std_logic;

        -- I2C
        i2c_scl         : inout std_logic;
        i2c_sda         : inout std_logic;

        -- VADJ
        set_vadj        : out   std_logic_vector(1 downto 0);
        vadj_en         : out   std_logic;

        -- FMC
        fmc_clk0_m2c_p  : in    std_logic;
        fmc_clk0_m2c_n  : in    std_logic;
        fmc_clk1_m2c_p  : in    std_logic;
        fmc_clk1_m2c_n  : in    std_logic;
        fmc_la_p        : inout std_logic_vector(33 downto 0);
        fmc_la_n        : inout std_logic_vector(33 downto 0)

    );
end entity top;

architecture synth of top is
begin

    MAIN: entity xil_defaultlib.hdmi_tpg
        port map (
            ext_rst     => not btn_rst_n,
            ref_clk     => clki_100m,
            mode        => sw(3 downto 0),
            dvi         => sw(4),
            led         => led,
            hdmi_clk_p  => hdmi_tx_clk_p,
            hdmi_clk_n  => hdmi_tx_clk_n,
            hdmi_ch_p   => hdmi_tx_ch_p,
            hdmi_ch_n   => hdmi_tx_ch_n
        );

    --------------------------------------------------------------------------------

    -- OLED
    oled_res_n      <= '0';
    oled_d_c        <= '0';
    oled_sclk       <= '0';
    oled_sdin       <= '0';
    oled_vbat_dis   <= '1';
    oled_vdd_dis    <= '1';

    -- HDMI RX
    hdmi_rx_sda     <= 'Z';
    hdmi_rx_hpd     <= '0';
    hdmi_rx_txen    <= '0';

    -- HDMI TX
--  hdmi_tx_clk_p   <= '0';
--  hdmi_tx_clk_n   <= '1';
--  hdmi_tx_p       <= (others => '0');
--  hdmi_tx_n       <= (others => '1');
    hdmi_tx_scl     <= 'Z';
    hdmi_tx_sda     <= 'Z';
    hdmi_tx_cec     <= 'Z';

    -- DisplayPort
--  dp_tx_p         <= (others => 'Z');
--  dp_tx_n         <= (others => 'Z');
--  dp_tx_aux_p     <= 'Z';
--  dp_tx_aux_n     <= 'Z';
--  dp_tx_aux2_p    <= 'Z';
--  dp_tx_aux2_n    <= 'Z';

    -- audio codec
    ac_mclk         <= '0';
    ac_bclk         <= 'Z';
    ac_lrclk        <= 'Z';
    ac_dac_sdata    <= '0';

    -- PMODs
    ja              <= (others => 'Z');
    jb              <= (others => 'Z');
    jc              <= (others => 'Z');
    xa_p            <= (others => 'Z');
    xa_n            <= (others => 'Z');

    -- UART
    uart_rx_out     <= '1';

    -- ethernet
    eth_rst_n       <= '0';
    eth_txck        <= '0';
    eth_txctl       <= '0';
    eth_txd         <= (others => '0');
    eth_mdc         <= '0';
    eth_mdio        <= 'Z';

    -- fan
    fan_pwm         <= '0';

    -- FTDI
    ftdi_rd_n       <= '1';
    ftdi_wr_n       <= '1';
    ftdi_siwu_n     <= '1';
    ftdi_oe_n       <= '1';
    ftdi_d          <= (others => 'Z');
    ftdi_spien      <= 'Z';

    -- PS/2
    ps2_clk         <= 'Z';
    ps2_data        <= 'Z';

    -- QSPI
    qspi_cs_n       <= '1';
    qspi_dq         <= (others => 'Z');

    -- SD
    sd_reset        <= 'Z';
    sd_cclk         <= 'Z';
    sd_cmd          <= 'Z';
    sd_d            <= (others => 'Z');

    -- I2C
    i2c_scl         <= 'Z';
    i2c_sda         <= 'Z';

    -- VADJ
    set_vadj        <= (others => 'Z');
    vadj_en         <= 'Z';

    -- FMC
    fmc_la_p        <= (others => 'Z');
    fmc_la_n        <= (others => 'Z');

end architecture synth;

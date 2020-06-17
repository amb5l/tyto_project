--------------------------------------------------------------------------------
-- tb_mb_audio_io_nexys_video.vhd                                             --
-- Interactive simulation of demo_audio_io design.                            --
--------------------------------------------------------------------------------
-- (C) Copyright 2020 Adam Barnes <ambarnes@gmail.com>                        --
--                                                                            --
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

entity tb_mb_audio_io_nexys_video is
end entity tb_mb_audio_io_nexys_video;

architecture sim of tb_mb_audio_io_nexys_video is

    signal clki_100m        : std_logic;
    signal btn_rst_n        : std_logic;
    signal sw               : std_logic_vector(7 downto 0);
    signal led              : std_logic_vector(7 downto 0);

    signal ac_mclk         : std_logic;
    signal ac_lrclk        : std_logic;
    signal ac_bclk         : std_logic;
    signal ac_dac_sdata    : std_logic;
    signal ac_adc_sdata    : std_logic;

begin

    clki_100m <=
        '1' after 5ns when clki_100m = '0' else
        '0' after 5ns when clki_100m = '1' else
        '0';

    process
    begin
        sw <= (others => '0');
        btn_rst_n <= '0';
        wait for 100ns;
        btn_rst_n <= '1';
        wait;
    end process;

    ac_adc_sdata <= ac_dac_sdata; -- loopback

    UUT: entity xil_defaultlib.top
        port map (

            -- clocks
            clki_100m       => clki_100m,
            gtp_clk_p       => '0',
            gtp_clk_n       => '1',
            fmc_mgt_clk_p   => '0',
            fmc_mgt_clk_n   => '1',

            -- LEDs, buttons and switches
            led             => led,
            btn_c_n         => '1',
            btn_d_n         => '1',
            btn_l_n         => '1',
            btn_r_n         => '1',
            btn_u_n         => '1',
            btn_rst_n       => btn_rst_n,
            sw              => sw,

            -- OLED
            oled_res_n      => open,
            oled_d_c        => open,
            oled_sclk       => open,
            oled_sdin       => open,
            oled_vbat_dis   => open,
            oled_vdd_dis    => open,

            -- HDMI RX
--          hdmi_rx_clk_p   => '0',
--          hdmi_rx_clk_n   => '1',
--          hdmi_rx_ch_p    => "000",
--          hdmi_rx_ch_n    => "111",
            hdmi_rx_scl     => '1',
            hdmi_rx_sda     => open,
            hdmi_rx_cec     => '0',
            hdmi_rx_hpd     => open,
            hdmi_rx_txen    => open,

            -- HDMI TX
--          hdmi_tx_clk_p   => open,
--          hdmi_tx_clk_n   => open,
--          hdmi_tx_ch_p    => open,
--          hdmi_tx_ch_n    => open,
            hdmi_tx_scl     => open,
            hdmi_tx_sda     => open,
            hdmi_tx_cec     => open,
            hdmi_tx_hpd     => '0',

            -- DisplayPort
--          dp_tx_p         => open,
--          dp_tx_n         => open,
--          dp_tx_aux_p     => open,
--          dp_tx_aux_n     => open,
--          dp_tx_aux2_p    => open,
--          dp_tx_aux2_n    => open,
            dp_tx_hpd       => '0',

            -- audio codec
            ac_mclk         => ac_mclk,
            ac_lrclk        => ac_lrclk,
            ac_bclk         => ac_bclk,
            ac_dac_sdata    => ac_dac_sdata,
            ac_adc_sdata    => ac_adc_sdata,

            -- PMODs
            ja              => open,
            jb              => open,
            jc              => open,
            xa_p            => open,
            xa_n            => open,

            -- UART
            uart_rx_out     => open,
            uart_tx_in      => '1',

            -- ethernet
            eth_rst_n       => open,
            eth_txck        => open,
            eth_txctl       => open,
            eth_txd         => open,
            eth_rxck        => '0',
            eth_rxctl       => '0',
            eth_rxd         => "0000",
            eth_mdc         => open,
            eth_mdio        => open,
            eth_int_n       => '1',
            eth_pme_n       => '1',

            -- fan
            fan_pwm         => open,

            -- FTDI
            ftdi_clko       => '0',
            ftdi_rxf_n      => '1',
            ftdi_txe_n      => '1',
            ftdi_rd_n       => open,
            ftdi_wr_n       => open,
            ftdi_siwu_n     => open,
            ftdi_oe_n       => open,
            ftdi_d          => open,
            ftdi_spien      => open,

            -- PS/2
            ps2_clk         => open,
            ps2_data        => open,

            -- QSPI
            qspi_cs_n       => open,
            qspi_dq         => open,

            -- SD
            sd_reset        => open,
            sd_cclk         => open,
            sd_cmd          => open,
            sd_d            => open,
            sd_cd           => '0',

            -- I2C
            i2c_scl         => open,
            i2c_sda         => open,

            -- VADJ
            set_vadj        => open,
            vadj_en         => open,

            -- FMC
            fmc_clk0_m2c_p  => '0',
            fmc_clk0_m2c_n  => '1',
            fmc_clk1_m2c_p  => '0',
            fmc_clk1_m2c_n  => '1',
            fmc_la_p        => open,
            fmc_la_n        => open

        );

end architecture sim;

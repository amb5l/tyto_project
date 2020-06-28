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
    signal sw               : std_logic_vector(7 downto 0);
    signal led              : std_logic_vector(7 downto 0);

    signal hdmi_tx_clk_p    : std_logic;
    signal hdmi_tx_clk_n    : std_logic;
    signal hdmi_tx_ch_p     : std_logic_vector(0 to 2);
    signal hdmi_tx_ch_n     : std_logic_vector(0 to 2);

    signal clk_p            : std_logic;
    signal rst_p            : std_logic;

    signal data_pstb        : std_logic;
    signal data_hb          : slv_7_0_t(0 to 3);
    signal data_hb_ok       : std_logic;
    signal data_sb          : slv_7_0_2d_t(0 to 3,0 to 7);
    signal data_sb_ok       : std_logic_vector(0 to 3);

    signal vga_vs           : std_logic;
    signal vga_hs           : std_logic;
    signal vga_de           : std_logic;
    signal vga_r            : std_logic_vector(7 downto 0);
    signal vga_g            : std_logic_vector(7 downto 0);
    signal vga_b            : std_logic_vector(7 downto 0);

    signal mode             : std_logic_vector(3 downto 0);
    signal dvi              : std_logic;
    signal cap_stb          : std_logic;

begin

    clki_100m <=
        '1' after 5ns when clki_100m = '0' else
        '0' after 5ns when clki_100m = '1' else
        '0';

    sw <= "000" & dvi & mode;

    process
    begin
        dvi <= '0';
        mode <= x"0";
        loop
            btn_rst_n <= '0';
            rst_p <= '1';
            wait for 20ns;
            btn_rst_n <= '1';
            wait until rising_edge(clk_p);
            wait until rising_edge(clk_p);
            rst_p <= '0';
            wait until rising_edge(cap_stb);
            if mode = x"E" then
                exit;
            else
                mode <= std_logic_vector(unsigned(mode)+1);
            end if;
        end loop;
    end process;

    UUT: entity work.top
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
            hdmi_tx_clk_p   => hdmi_tx_clk_p,
            hdmi_tx_clk_n   => hdmi_tx_clk_n,
            hdmi_tx_ch_p    => hdmi_tx_ch_p,
            hdmi_tx_ch_n    => hdmi_tx_ch_n,
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
            ac_mclk         => open,
            ac_lrclk        => open,
            ac_bclk         => open,
            ac_dac_sdata    => open,
            ac_adc_sdata    => '0',

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

    DECODE: entity work.model_hdmi_decoder
        port map (
            rst     => rst_p,
            ch      => hdmi_tx_ch_p,
            clk     => clk_p,
            pstb    => data_pstb,
            hb      => data_hb,
            hb_ok   => data_hb_ok,
            sb      => data_sb,
            sb_ok   => data_sb_ok,
            vs      => vga_vs,
            hs      => vga_hs,
            de      => vga_de,
            p(2)    => vga_r,
            p(1)    => vga_g,
            p(0)    => vga_b
        );

    CAPTURE: entity work.model_vga_sink
        generic map (
            name        => "sim"
        )
        port map (
            rst         => '0',
            clk         => clk_p,
            vs          => vga_vs,
            hs          => vga_hs,
            de          => vga_de,
            r           => vga_r,
            g           => vga_g,
            b           => vga_b,
            stb         => cap_stb
        );

end architecture sim;

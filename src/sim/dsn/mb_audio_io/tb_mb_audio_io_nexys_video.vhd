--------------------------------------------------------------------------------
-- tb_mb_audio_io_nexys_video.vhd                                             --
-- Interactive simulation of mb_audio_io design.                              --
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
            led             => led,
            btn_rst_n       => btn_rst_n,
            oled_res_n      => open,
            oled_d_c        => open,
            oled_sclk       => open,
            oled_sdin       => open,
            ac_mclk         => ac_mclk,
            ac_lrclk        => ac_lrclk,
            ac_bclk         => ac_bclk,
            ac_dac_sdata    => ac_dac_sdata,
            ac_adc_sdata    => ac_adc_sdata,                
            uart_rx_out     => open,
            uart_tx_in      => '1',
            eth_rst_n       => open,
            ftdi_rd_n       => open,
            ftdi_wr_n       => open,
            ftdi_siwu_n     => open,
            ftdi_oe_n       => open,
            ps2_clk         => open,
            ps2_data        => open,
            qspi_cs_n       => open,
            i2c_scl         => open,
            i2c_sda         => open,
            ddr3_reset_n    => open
        );

end architecture sim;

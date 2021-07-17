--------------------------------------------------------------------------------
-- tb_np65_poc_nexys_video.vhd                                                --
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

entity tb_np65_poc_nexys_video is
end entity tb_np65_poc_nexys_video;

architecture sim of tb_np65_poc_nexys_video is

    signal clki_100m        : std_logic;
    signal btn_rst_n        : std_logic;
    signal led              : std_logic_vector(7 downto 0);

begin

    clki_100m <=
        '1' after 5ns when clki_100m = '0' else
        '0' after 5ns when clki_100m = '1' else
        '0';

    process
        variable mode : integer;
    begin
        btn_rst_n <= '0';
        wait for 20ns;
        btn_rst_n <= '1';
        wait;
    end process;

    UUT: entity work.top
        port map (
            clki_100m       => clki_100m,
            led             => led,
            btn_rst_n       => btn_rst_n,
            ja              => x"00",
            jb              => x"00",
            jc              => open,
            oled_res_n      => open,
            oled_d_c        => open,
            oled_sclk       => open,
            oled_sdin       => open,
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

end architecture sim;

--------------------------------------------------------------------------------
-- tb_ddr3_test_qmtech_wukong.vhd                                             --
-- Simulation testbench for ddr3_test_qmtech_wukong.vhd.                      --
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

entity tb_ddr3_test_qmtech_wukong is
end entity tb_ddr3_test_qmtech_wukong;

architecture sim of tb_ddr3_test_qmtech_wukong is

    signal clki_50m     : std_logic;
    signal key_n        : std_logic_vector(1 downto 0);
    signal led_n        : std_logic_vector(1 downto 0);

    signal ddr3_rst_n   : std_logic;
    signal ddr3_ck_p    : std_logic_vector(0 downto 0);
    signal ddr3_ck_n    : std_logic_vector(0 downto 0);
    signal ddr3_cke     : std_logic_vector(0 downto 0);
    signal ddr3_ras_n   : std_logic;
    signal ddr3_cas_n   : std_logic;
    signal ddr3_we_n    : std_logic;
    signal ddr3_odt     : std_logic_vector(0 downto 0);
    signal ddr3_addr    : std_logic_vector(13 downto 0);
    signal ddr3_ba      : std_logic_vector(2 downto 0);
    signal ddr3_dm      : std_logic_vector(1 downto 0);
    signal ddr3_dq      : std_logic_vector(15 downto 0);
    signal ddr3_dqs_p   : std_logic_vector(1 downto 0);
    signal ddr3_dqs_n   : std_logic_vector(1 downto 0);

begin

    clki_50m <=
        '1' after 10ns when clki_50m = '0' else
        '0' after 10ns when clki_50m = '1' else
        '0';

    key_n(1) <= '0'; -- test size = 256 bytes

    process
    begin
        key_n(0) <= '0';
        wait for 100ns;
        key_n(0) <= '1';
        wait;
    end process;

    UUT: entity xil_defaultlib.top
        port map (
            clki_50m        => clki_50m,
            key_n           => key_n,
            led_n           => led_n,
            ser_tx          => open,
            hdmi_scl        => open,
            hdmi_sda        => open,
            eth_rst_n       => open,
            ddr3_rst_n      => ddr3_rst_n,
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
            ddr3_dqs_n      => ddr3_dqs_n,
            j10             => open
        );

    DDR3: entity xil_defaultlib.ddr3_model
        port map (
            rst_n           => ddr3_rst_n,
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

end architecture sim;

--------------------------------------------------------------------------------
-- ddr3_wrapper_qmtech_wukong.vhd                                             --
-- Simple wrapper for DDR3 memory controller IP for QMTECH Wukong.            --
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

entity ddr3_wrapper_qmtech_wukong is
    port (

        -- clock and reset

        xrst        : in    std_logic;
        xclk        : in    std_logic;

        rst_100m    : out   std_logic;
        clk_100m    : out   std_logic;
        clk_50m     : out   std_logic;

        -- user interface (clk_100m synchronous)

        ui_cc       : out   std_logic;
        
        ui_rdy      : out   std_logic;
        ui_en       : in    std_logic;
        ui_r_w      : in    std_logic;
        ui_a        : in    std_logic_vector(27 downto 4);
        
        ui_wrdy     : out   std_logic;
        ui_we       : in    std_logic;
        ui_wbe      : in    std_logic_vector(15 downto 0);
        ui_wd       : in    std_logic_vector(127 downto 0);
        
        ui_rd       : out   std_logic_vector(127 downto 0);
        ui_rstb     : out   std_logic;

        -- DDR3 interface (single device, 128Mx16)

        ddr3_rst_n  : out   std_logic;
        ddr3_ck_p   : out   std_logic_vector(0 downto 0);
        ddr3_ck_n   : out   std_logic_vector(0 downto 0);
        ddr3_cke    : out   std_logic_vector(0 downto 0);
        ddr3_ras_n  : out   std_logic;
        ddr3_cas_n  : out   std_logic;
        ddr3_we_n   : out   std_logic;
        ddr3_odt    : out   std_logic_vector(0 downto 0);
        ddr3_addr   : out   std_logic_vector(13 downto 0);
        ddr3_ba     : out   std_logic_vector(2 downto 0);
        ddr3_dm     : out   std_logic_vector(1 downto 0);
        ddr3_dq     : inout std_logic_vector(15 downto 0);
        ddr3_dqs_p  : inout std_logic_vector(1 downto 0);
        ddr3_dqs_n  : inout std_logic_vector(1 downto 0)

    );
end entity ddr3_wrapper_qmtech_wukong;

architecture synth of ddr3_wrapper_qmtech_wukong is

begin

    DDR3_IP: entity xil_defaultlib.ddr3
        port map (

            sys_rst             => xrst,
            sys_clk_i           => xclk,
            clk_ref_i           => '0',         -- IODELAYCTRL ref clk generated by DDR3 MMCM

            ui_clk_sync_rst     => rst_100m,
            ui_clk              => clk_100m,
            ui_addn_clk_1       => clk_50m,
            device_temp         => open,
            init_calib_complete => ui_cc,

            app_addr            => '0' & ui_a & "000",
            app_cmd             => "00" & ui_r_w,
            app_en              => ui_en,
            app_rdy             => ui_rdy,
            app_wdf_data        => ui_wd,
            app_wdf_end         => ui_we,
            app_wdf_mask        => not ui_wbe,
            app_wdf_wren        => ui_we,
            app_rd_data         => ui_rd,
            app_rd_data_end     => open,
            app_rd_data_valid   => ui_rstb,
            app_wdf_rdy         => ui_wrdy,
            app_sr_req          => '0',
            app_sr_active       => open,
            app_ref_req         => '0',
            app_ref_ack         => open,
            app_zq_req          => '0',
            app_zq_ack          => open,

            ddr3_reset_n        => ddr3_rst_n,
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

end architecture synth;
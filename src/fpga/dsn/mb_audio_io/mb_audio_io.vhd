--------------------------------------------------------------------------------
-- demo_audio_io.vhd                                                          --
-- A simple I2S audio I/O demonstration, powered by a Microblaze CPU.         --
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

entity demo_audio_io is
    generic (

        fref        : real                                  -- reference clock frequency (MHz)

    );
    port (

        ext_rst     : in    std_logic;                      -- external reset (asynchronous)
        ref_clk     : in    std_logic;                      -- reference clock (for MMCMs)
        sys_rst     : out   std_logic;                      -- system reset (synchronous to system clock)
        sys_clk     : out   std_logic;                      -- system clock (100MHz)

        led         : out   std_logic_vector(7 downto 0);

        uart_tx     : out   std_logic;
        uart_rx     : in    std_logic;

        i2c_scl     : inout std_logic;
        i2c_sda     : inout std_logic;

        i2s_mclk    : out   std_logic;                      -- main codec clock (256Fs)
        i2s_bclk    : out   std_logic;                      -- bit clock (64Fs)
        i2s_lrclk   : out   std_logic;                      -- left/right clock (Fs) (48kHz)
        i2s_sdo     : out   std_logic;                      -- serial data out
        i2s_sdi     : in    std_logic                       -- serial data in

    );
end entity demo_audio_io;

architecture synth of demo_audio_io is

    signal cpu_rst          : std_logic;
    signal pcm_rst          : std_logic;
    signal pcm_clk          : std_logic;
    signal pcm_clken        : std_logic;

    signal gpo              : std_logic_vector(7 downto 0);

    signal fifo_tx_data     : std_logic_vector(31 downto 0);
    signal fifo_tx_valid    : std_logic;
    signal fifo_tx_last     : std_logic;
    signal fifo_tx_ready    : std_logic;

    signal fifo_rx_data     : std_logic_vector(31 downto 0);
    signal fifo_rx_valid    : std_logic;
    signal fifo_rx_last     : std_logic;
    signal fifo_rx_ready    : std_logic;

    signal pcm_out_l        : std_logic_vector(15 downto 0);
    signal pcm_out_r        : std_logic_vector(15 downto 0);
    signal pcm_in_l         : std_logic_vector(15 downto 0);
    signal pcm_in_r         : std_logic_vector(15 downto 0);

begin

    led(4 downto 0) <= gpo(4 downto 0);
    led(5) <= not pcm_rst;
    led(6) <= not cpu_rst;
    led(7) <= not sys_rst;

    CLOCK_100M: entity xil_defaultlib.clock_100m
        generic map (
            fref    => 100.0
        )
        port map (
            rsti    => ext_rst,
            clki    => ref_clk,
            rsto    => sys_rst,
            clko    => sys_clk
        );

    AUDIO_CLOCK: entity xil_defaultlib.audio_clock
        generic map (
            fref    => 100.0,   -- reference clock frequency (MHz)
            fs      => 48.0,    -- sample frequency (kHz)
            ratio   => 256      -- clk : clken frequency ration
        )
        port map (
            rsti    => ext_rst,
            clki    => ref_clk,
            rsto    => pcm_rst,
            clk     => pcm_clk,
            clken   => pcm_clken
        );

    i2s_mclk <= pcm_clk;

    CPU: entity xil_defaultlib.microblaze_wrapper
        port map (
            clk             => sys_clk,
            rsti_n          => '1',
            lock            => not sys_rst,
            rsto(0)         => cpu_rst,
            uart_txd        => uart_tx,
            uart_rxd        => uart_rx,
            gpo             => gpo,
            i2c_scl_io      => i2c_scl,
            i2c_sda_io      => i2c_sda,
            fifo_rx_data    => fifo_rx_data,
            fifo_rx_valid   => fifo_rx_valid,
            fifo_rx_last    => fifo_rx_last,
            fifo_rx_ready   => fifo_rx_ready,
            fifo_tx_data    => fifo_tx_data,
            fifo_tx_valid   => fifo_tx_valid,
            fifo_tx_last    => fifo_tx_last,
            fifo_tx_ready   => fifo_tx_ready
        );

    AUDIO_AXIS: entity xil_defaultlib.audio_axis
        port map (
            axis_rst        => sys_rst,
            axis_clk        => sys_clk,
            axis_out_data   => fifo_tx_data,
            axis_out_valid  => fifo_tx_valid,
            axis_out_last   => fifo_tx_last,
            axis_out_ready  => fifo_tx_ready,
            axis_in_data    => fifo_rx_data,
            axis_in_valid   => fifo_rx_valid,
            axis_in_last    => fifo_rx_last,
            axis_in_ready   => fifo_rx_ready,
            pcm_rst         => pcm_rst,
            pcm_clk         => pcm_clk,
            pcm_clken       => pcm_clken,
            pcm_out_l       => pcm_out_l,
            pcm_out_r       => pcm_out_r,
            pcm_in_l        => pcm_in_l,
            pcm_in_r        => pcm_in_r
        );

    AUDIO_I2S: entity xil_defaultlib.audio_i2s
        generic map (
            ratio       => 256, -- pcm_clk = 256Fs
            w           => 16   -- 16 bit samples
        )
        port map (
            pcm_rst     => pcm_rst,
            pcm_clk     => pcm_clk,
            pcm_clken   => pcm_clken,
            pcm_out_l   => pcm_out_l,
            pcm_out_r   => pcm_out_r,
            pcm_in_l    => pcm_in_l,
            pcm_in_r    => pcm_in_r,
            i2s_bclk    => i2s_bclk,
            i2s_lrclk   => i2s_lrclk,
            i2s_sdo     => i2s_sdo,
            i2s_sdi     => i2s_sdi
        );

end architecture synth;

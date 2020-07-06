--------------------------------------------------------------------------------
-- audio_axis.vhd                                                             --
-- Simple AXI-Streaming to parallel PCM bridge.                               --
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

library xpm;
use xpm.vcomponents.all;

library xil_defaultlib;

entity audio_axis is
    port (

        axis_rst        : in    std_logic;
        axis_clk        : in    std_logic;
        axis_out_data   : in    std_logic_vector(31 downto 0);
        axis_out_valid  : in    std_logic;
        axis_out_last   : in    std_logic;
        axis_out_ready  : out   std_logic;
        axis_in_data    : out   std_logic_vector(31 downto 0);
        axis_in_valid   : out   std_logic;
        axis_in_last    : out   std_logic;
        axis_in_ready   : in    std_logic;

        pcm_rst         : in    std_logic;
        pcm_clk         : in    std_logic;
        pcm_clken       : in    std_logic;
        pcm_out_l       : out   std_logic_vector(15 downto 0);
        pcm_out_r       : out   std_logic_vector(15 downto 0);
        pcm_in_l        : in    std_logic_vector(15 downto 0);
        pcm_in_r        : in    std_logic_vector(15 downto 0)

    );
end entity audio_axis;

architecture synth of audio_axis is

    signal axis_out_send  : std_logic;
    signal axis_out_rcv   : std_logic;
    signal axis_out_rcv_1 : std_logic;
    signal pcm_out_req    : std_logic;
    signal pcm_out_ack    : std_logic;

    signal pcm_rst_a      : std_logic_vector(0 to 3);
    signal pcm_in_send    : std_logic;
    signal pcm_in_rcv     : std_logic;

begin

    axis_in_last <= '1';

    process(pcm_rst,pcm_clk)
    begin
        if pcm_rst = '1' then
            pcm_out_ack <= '0';
            pcm_in_send <= '0';
        elsif rising_edge(pcm_clk) then
            if pcm_out_ack = '0' and pcm_out_req = '1' and pcm_clken = '1' then
                pcm_out_ack <= '1';
            end if;
            if pcm_out_ack = '1' and pcm_out_req = '0' then
                pcm_out_ack <= '0';
            end if;
            if pcm_in_send = '0' and pcm_in_rcv = '0' and pcm_clken = '1' then
                pcm_in_send <= '1';
            end if;
            if pcm_in_send = '1' and pcm_in_rcv = '1' then
                pcm_in_send <= '0';
            end if;
        end if;
    end process;

    process(axis_rst,axis_clk)
    begin
        if axis_rst = '1' then
            pcm_rst_a <= (others => '1');
            axis_out_send <= '0';
            axis_out_rcv_1 <= '0';
            axis_out_ready <= '0';
        elsif rising_edge(axis_clk) then
            pcm_rst_a <= pcm_rst & pcm_rst_a(0 to 2);
            if pcm_rst_a(3) = '0' and axis_out_send = '0' and axis_out_rcv = '0' and axis_out_valid = '1' then
                axis_out_send <= '1';
            end if;
            if axis_out_send = '1' and axis_out_rcv = '1' then
                axis_out_send <= '0';
            end if;
            axis_out_rcv_1 <= axis_out_rcv;
            axis_out_ready <= axis_out_rcv_1 and not axis_out_rcv; -- trailing edge of rcv
        end if;
    end process;

    DATA_A2P: xpm_cdc_handshake
        generic map (
            DEST_EXT_HSK           => 1,
            DEST_SYNC_FF           => 4,
            INIT_SYNC_FF           => 0,
            SIM_ASSERT_CHK         => 1,
            SRC_SYNC_FF            => 4,
            WIDTH                  => 32
        )
        port map (
            src_clk                => axis_clk,
            src_in                 => axis_out_data,
            src_send               => axis_out_send,
            src_rcv                => axis_out_rcv,
            dest_clk               => pcm_clk,
            dest_req               => pcm_out_req,
            dest_ack               => pcm_out_ack,
            dest_out(15 downto 0)  => pcm_out_l,
            dest_out(31 downto 16) => pcm_out_r
    );

    DATA_P2A: xpm_cdc_handshake
        generic map (
            DEST_EXT_HSK   => 0,
            DEST_SYNC_FF   => 4,
            INIT_SYNC_FF   => 0,
            SIM_ASSERT_CHK => 1,
            SRC_SYNC_FF    => 4,
            WIDTH          => 32
        )
        port map (
            src_clk        => pcm_clk,
            src_in         => pcm_in_r & pcm_in_l,
            src_send       => pcm_in_send,
            src_rcv        => pcm_in_rcv,
            dest_clk       => axis_clk,
            dest_req       => axis_in_valid,
            dest_ack       => '0', -- unused
            dest_out       => axis_in_data
    );

end architecture synth;

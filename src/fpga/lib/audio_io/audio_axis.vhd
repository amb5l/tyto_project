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

    signal axis_out_valid_s : std_logic;                -- sync'd to pcm_clk
    signal axis_out_ready_a : std_logic;                -- synchronous to pcm_clk
    signal axis_out_ready_s : std_logic_vector(0 to 1); -- sync'd to axis_clk

    signal axis_in_ready_s  : std_logic;
    signal axis_in_valid_a  : std_logic;                -- synchronous to pcm_clk
    signal axis_in_valid_s  : std_logic_vector(0 to 1); -- sync'd to axis_clk

begin

    axis_in_last <= '1';

    process(pcm_clk)
    begin
        if rising_edge(pcm_clk) then
            axis_out_ready_a <= '0';
            axis_in_valid_a <= '0';
            if pcm_rst  = '1' then
                pcm_out_l <= (others => '0');
                pcm_out_r <= (others => '0');
            else
                if pcm_clken = '1' then
                    if axis_out_valid_s = '1' then
                        pcm_out_l <= axis_out_data(15 downto 0);
                        pcm_out_r <= axis_out_data(31 downto 16);
                        axis_out_ready_a <= '1';
                    else
                        pcm_out_l <= (others => '0');
                        pcm_out_r <= (others => '0');
                    end if;
                    axis_in_data(15 downto 0) <= pcm_in_l;
                    axis_in_data(31 downto 16) <= pcm_in_r;
                    axis_in_valid_a <= axis_in_ready_s;
                end if;
            end if;
        end if;
    end process;

    process(axis_clk)
    begin
        if rising_edge(axis_clk) then
            axis_out_ready <= '0';
            axis_in_valid <= '0';
            if axis_rst = '1' then
                axis_out_ready_s(1)  <= '0';
                axis_in_valid_s(1)   <= '0';
            else
                axis_out_ready_s(1) <= axis_out_ready_s(0);
                if axis_out_ready_s(0) = '1' and axis_out_ready_s(1) = '0' then
                    axis_out_ready <= '1';
                end if;
                axis_in_valid_s(1) <= axis_in_valid_s(0);
                if axis_in_valid_s(0) = '1' and axis_in_valid_s(1) = '0' then
                    axis_in_valid <= '1';
                end if;
            end if;
        end if;
    end process;

    SYNC1: entity xil_defaultlib.double_sync
        port map (
            rst => pcm_rst,
            clk => pcm_clk,
            d   => axis_out_valid,
            q   => axis_out_valid_s
        );

    SYNC2: entity xil_defaultlib.double_sync
        port map (
            rst => axis_rst,
            clk => axis_clk,
            d   => axis_out_ready_a,
            q   => axis_out_ready_s(0)
        );

    SYNC3: entity xil_defaultlib.double_sync
        port map (
            rst => pcm_rst,
            clk => pcm_clk,
            d   => axis_in_ready,
            q   => axis_in_ready_s
        );

    SYNC4: entity xil_defaultlib.double_sync
        port map (
            rst => axis_rst,
            clk => axis_clk,
            d   => axis_in_valid_a,
            q   => axis_in_valid_s(0)
        );

end architecture synth;

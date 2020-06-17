--------------------------------------------------------------------------------
-- audio_i2s.vhd                                                              --
-- I2S serial <-> parallel PCM samples.                                       --
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

entity audio_i2s is
    generic (
        ratio       : integer;                              -- ratio of pcm_clk to Fs/pcm_clken, >=128
        w           : integer                               -- sample width (16/18/20//24)
    );
    port (

        pcm_rst     : in    std_logic;
        pcm_clk     : in    std_logic;                      -- Fs x ratio e.g. 12.288MHz
        pcm_clken   : in    std_logic;                      -- Fs e.g. 48kHz

        pcm_out_l   : in    std_logic_vector(15 downto 0);  -- } parallel PCM I/O
        pcm_out_r   : in    std_logic_vector(15 downto 0);  -- } synchronous to pcm_clk
        pcm_in_l    : out   std_logic_vector(15 downto 0);  -- } valid on pcm_clken
        pcm_in_r    : out   std_logic_vector(15 downto 0);  -- }

        i2s_bclk    : out   std_logic;                      -- 64Fs (32 bits L, 32 bits R)
        i2s_lrclk   : out   std_logic;                      -- Fs
        i2s_sdo     : out   std_logic;
        i2s_sdi     : in    std_logic

    );
end entity audio_i2s;

architecture synth of audio_i2s is

    signal count_bclk   : integer range 0 to (ratio/64)-1;
    signal count_lrclk  : integer range 0 to 63;
    signal shift_reg    : std_logic_vector(63 downto 0);

begin

    process(pcm_clk)
    begin
        if rising_edge(pcm_clk) then
            if pcm_rst = '1' then
                count_bclk <= 0;
                count_lrclk <= 0;
                i2s_bclk <= '0';
                i2s_lrclk <= '0';
                i2s_sdo <= '0';
            else
                count_bclk <= count_bclk + 1;
                if count_bclk = (ratio/128)-1 then
                    i2s_bclk <= '1';
                    if count_lrclk = 0 then
                        shift_reg(63 downto 64-w) <= pcm_out_l;
                        shift_reg(63-w downto 32) <= (others => '0');
                        shift_reg(31 downto 32-w) <= pcm_out_r;
                        shift_reg(31-w downto 0) <= (others => '0');
                        pcm_in_l <= shift_reg(62 downto 63-w);
                        pcm_in_r <= shift_reg(30 downto 31-w);
                    else
                        shift_reg(63 downto 0) <= shift_reg(62 downto 0) & i2s_sdi;
                    end if;
                elsif count_bclk = (ratio/64)-1 then
                    count_bclk <= 0;
                    i2s_bclk <= '0';
                    i2s_sdo <= shift_reg(63);
                    count_lrclk <= count_lrclk + 1;
                    if count_lrclk = 31 then
                        i2s_lrclk <= '1';
                    elsif count_lrclk = 63 then
                        count_lrclk <= 0;
                        i2s_lrclk <= '0';
                    end if;
                end if;
                if pcm_clken = '1' then -- alignment
                    count_bclk <= 0;
                    count_lrclk <= 0;
                    i2s_bclk <= '0';
                    i2s_lrclk <= '0';
                end if;
            end if;
        end if;
    end process;

end architecture synth;

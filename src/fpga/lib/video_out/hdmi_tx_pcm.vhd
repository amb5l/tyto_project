--------------------------------------------------------------------------------
-- hdmi_tx_pcm.vhd                                                            --
-- Adds IEC60958 channel status to PCM stream.                                --
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

library xil_defaultlib;

entity hdmi_tx_pcm is
    generic (
        fs  : real;         -- sample frequency, kHz
        w   : integer := 16 -- sample width, bits
    );
    port (

        rst             : in    std_logic;                      -- reset
        clk             : in    std_logic;                      -- audio clock (sample rate xN)
        clken           : in    std_logic;                      -- audio clock enable (sample rate)

        in_l            : in    std_logic_vector(w-1 downto 0); -- left sample
        in_r            : in    std_logic_vector(w-1 downto 0); -- right sample

        out_req         : out   std_logic;                      -- output req
        out_ack         : in    std_logic;                      -- output ack
        out_sync        : out   std_logic;                      -- b preamble (sync)
        out_l           : out   std_logic_vector(23 downto 0);  -- left channel sample
        out_lv          : out   std_logic;                      -- left channel status
        out_lu          : out   std_logic;                      -- left user data
        out_lc          : out   std_logic;                      -- left channel status
        out_lp          : out   std_logic;                      -- left channel status
        out_r           : out   std_logic_vector(23 downto 0);  -- right channel sample
        out_rv          : out   std_logic;                      -- right channel status
        out_ru          : out   std_logic;                      -- right user data
        out_rc          : out   std_logic;                      -- right channel status
        out_rp          : out   std_logic                       -- right channel status

    );
end entity hdmi_tx_pcm;

architecture synth of hdmi_tx_pcm is

    signal frame_count  : integer range 0 to 255;
    signal clken_1      : std_logic;
    signal sync         : std_logic;
    signal cs_v         : std_logic_vector(0 to 39);
    signal cs           : std_logic;

    function xor_v(
        v : std_logic_vector
    ) return std_logic is
        variable i : integer;
        variable r : std_logic;
    begin
        r := '0';
        for i in 0 to v'length-1 loop
            r := r xor v(i);
        end loop;
        return r;
    end function xor_v;

begin

    -- IEC60958 channel status

    cs_v(0) <= '0';                 -- consumer use
    cs_v(1) <= '0';                 -- PCM samples
    cs_v(2) <= '1';                 -- no copyright
    cs_v(3 to 5) <= "000";          -- 2 channels without pre-emphasis
    cs_v(6 to 7) <= "00";           -- channel status mode 0
    cs_v(8 to 15) <= "01000000";    -- category code
    cs_v(16 to 19) <= "0000";       -- source - do not take into account
    cs_v(20 to 23) <= "0000";       -- channel number - do not take into account
    cs_v(24 to 27) <=               -- sample frequency
        "0010" when fs = 22.05 else
        "0000" when fs = 44.1 else
        "0001" when fs = 88.2 else
        "0011" when fs = 176.4 else
        "0110" when fs = 24.0 else
        "0100" when fs = 48.0 else
        "0101" when fs = 96.0 else
        "0111" when fs = 192.0 else
        "1001" when fs = 768.0 else
        "1100" when fs = 32.0 else
        "1000";
    cs_v(28 to 29) <= "00";         -- clock accuracy level 2
    cs_v(30) <= '0';                -- reserved
    cs_v(31) <= '0';                -- reserved
    cs_v(32) <= '1';                -- max sample word length is 24 bits
    cs_v(33 to 35) <= "000";        -- word length not indicated
    cs_v(36 to 39) <= "0000";       -- original sample frequency not indicated

    process(frame_count)
    begin
        cs <= '0';
        sync <= '0';
        if frame_count = 0 then
            sync <= '1';
        end if;
        if frame_count < 40 then
            cs <= cs_v(frame_count);
        end if;
    end process;

    -- audio formatting

    process(rst,clk)
    begin
        if rst = '1' then

            frame_count <= 0;
            out_req     <= '0';
            out_sync    <= '0';
            out_l       <= (others => '0');
            out_lv      <= '0';
            out_lu      <= '0';
            out_lc      <= '0';
            out_lp      <= '0';
            out_r       <= (others => '0');
            out_rv      <= '0';
            out_ru      <= '0';
            out_rc      <= '0';
            out_rp      <= '0';

        elsif rising_edge(clk) then

            if clken = '1' then
                frame_count <= (frame_count + 1) mod 192;
                out_sync    <= sync;
                out_l       <= (others => '0');
                out_l(23 downto 24-w) <= in_l;
                out_lv      <= '0';
                out_lu      <= '0';
                out_lc      <= cs;
                out_lp      <= xor_v(in_l & cs & sync);
                out_r       <= (others => '0');
                out_r(23 downto 24-w) <= in_r;
                out_rv      <= '0';
                out_ru      <= '0';
                out_rc      <= cs;
                out_rp      <= xor_v(in_r & cs & sync);
            end if;

           clken_1 <= clken;
            if clken_1 = '1' then
                out_req <= '1';
            end if;
            if out_ack = '1' then
                out_req <= '0';
            end if;

        end if;

    end process;

end architecture synth;

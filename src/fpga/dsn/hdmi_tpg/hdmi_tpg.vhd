--------------------------------------------------------------------------------
-- hdmi_tpg.vhd                                                               --
-- HDMI video test pattern generator with audio test tone.                    --
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

entity hdmi_tpg is
    generic (
        fref        : real                                  -- reference clock frequency (MHz)
    );
    port (

        ext_rst     : in    std_logic;                      -- hard reset
        ref_clk     : in    std_logic;                      -- reference clock (100MHz)

        mode_step   : in    std_logic;                      -- video mode step (e.g. button)
        mode        : out   std_logic_vector(3 downto 0);   -- current video mode
        dvi         : in    std_logic;                      -- 1 = DVI, 0 = HDMI

        heartbeat   : out   std_logic_vector(3 downto 0);   -- 4 bit count @ 8Hz (heartbeat for LEDs)
        status      : out   std_logic_vector(2 downto 0);   -- MMCM lock status

        hdmi_clk_p  : out   std_logic;                      -- HDMI (TMDS) clock output (+ve)
        hdmi_clk_n  : out   std_logic;                      -- HDMI (TMDS) clock output (-ve)
        hdmi_d_p    : out   std_logic_vector(0 to 2);       -- HDMI (TMDS) data output channels 0..2 (+ve)
        hdmi_d_n    : out   std_logic_vector(0 to 2)        -- HDMI (TMDS) data output channels 0..2 (-ve)

    );
end entity hdmi_tpg;

architecture synth of hdmi_tpg is

    signal sys_rst          : std_logic;                        -- system clock domain reset
    signal sys_clk          : std_logic;                        -- system clock (100MHz)
    signal sys_clken_1khz   : std_logic;                        -- system clock enable @ 1kHz

    signal pix_rst          : std_logic;                        -- pixel clock domain reset
    signal pix_clk          : std_logic;                        -- pixel clock (25.2/27/74.25/148.5 MHz)
    signal pix_clk_x5       : std_logic;                        -- serial clock = pixel clock x5

    signal mode_step_s      : std_logic_vector(0 to 1);         -- mode step input synchroniser
    signal mode_step_f      : std_logic;                        -- mode step input, filtered (debounced)
    signal mode_step_d      : std_logic;                        -- mode step input, filtered, delayed

    signal mode_clk_sel     : std_logic_vector(1 downto 0);     -- pixel frequency select
    signal mode_dmt         : std_logic;                        -- 1 = DMT, 0 = CEA
    signal mode_id          : std_logic_vector(7 downto 0);     -- DMT ID or CEA/CTA VIC
    signal mode_pix_rep     : std_logic;                        -- 1 = pixel doubling/repetition
    signal mode_aspect      : std_logic_vector(1 downto 0);     -- 0x = normal, 10 = force 16:9, 11 = force 4:3
    signal mode_interlace   : std_logic;                        -- interlaced/progressive scan
    signal mode_v_tot       : std_logic_vector(10 downto 0);    -- vertical total lines (must be odd if interlaced)
    signal mode_v_act       : std_logic_vector(10 downto 0);    -- vertical total lines (must be odd if interlaced)
    signal mode_v_sync      : std_logic_vector(2 downto 0);     -- vertical sync width
    signal mode_v_bp        : std_logic_vector(5 downto 0);     -- vertical back porch
    signal mode_h_tot       : std_logic_vector(11 downto 0);    -- horizontal total
    signal mode_h_act       : std_logic_vector(10 downto 0);    -- vertical total lines (must be odd if interlaced)
    signal mode_h_sync      : std_logic_vector(6 downto 0);     -- horizontal sync width
    signal mode_h_bp        : std_logic_vector(7 downto 0);     -- horizontal back porch
    signal mode_vs_pol      : std_logic;                        -- vertical sync polarity (1 = high)
    signal mode_hs_pol      : std_logic;                        -- horizontal sync polarity (1 = high)

    signal raw_f            : std_logic;                        -- field ID
    signal raw_vs           : std_logic;                        -- vertical sync
    signal raw_hs           : std_logic;                        -- horizontal sync
    signal raw_vblank       : std_logic;                        -- vertical blank
    signal raw_hblank       : std_logic;                        -- horizontal blank
    signal raw_ax           : std_logic_vector(11 downto 0);    -- active area X (signed)
    signal raw_ay           : std_logic_vector(11 downto 0);    -- active area Y (signed)

    signal vga_vs           : std_logic;                        -- vertical sync
    signal vga_hs           : std_logic;                        -- horizontal sync
    signal vga_vblank       : std_logic;                        -- vertical blank
    signal vga_hblank       : std_logic;                        -- horizontal blank
    signal vga_r            : std_logic_vector(7 downto 0);     -- red
    signal vga_g            : std_logic_vector(7 downto 0);     -- green
    signal vga_b            : std_logic_vector(7 downto 0);     -- blue

    signal pcm_rst          : std_logic;                        -- audio clock domain reset
    signal pcm_clk          : std_logic;                        -- audio clock (12.288MHz)
    signal pcm_clken        : std_logic;                        -- audio clock enable @ 48kHz
    signal pcm_l            : std_logic_vector(15 downto 0);    -- left channel  } audio sample,
    signal pcm_r            : std_logic_vector(15 downto 0);    -- right channel } signed 16 bit
    signal pcm_acr          : std_logic;                        -- HDMI Audio Clock Regeneration packet strobe
    signal pcm_n            : std_logic_vector(19 downto 0);    -- HDMI Audio Clock Regeneration packet N value
    signal pcm_cts          : std_logic_vector(19 downto 0);    -- HDMI Audio Clock Regeneration packet CTS value

begin

    status(0) <= not sys_rst;   -- system clock MMCM locked
    status(1) <= not pix_rst;   -- pixel clock MMCM locked
    status(2) <= not pcm_rst;   -- audio clock MMCM locked

    DO_1KHZ: process(sys_rst,sys_clk)
        variable counter : integer range 0 to 99999;
    begin
        if sys_rst = '1' then
            counter := 0;
            sys_clken_1khz <= '0';
        elsif rising_edge(sys_clk) then
            if counter = 99999 then
                counter := 0;
                sys_clken_1khz <= '1';
            else
                counter := counter + 1;
                sys_clken_1khz <= '0';
            end if;
        end if;
    end process DO_1KHZ;

    -- 4 bit counter @ 1Hz => 0.5Hz, 1Hz, 2Hz and 4Hz heartbeat pulses for LEDs
    DO_HEARTBEAT: process(sys_rst,sys_clk,sys_clken_1khz)
        variable counter : integer range 0 to 124;
    begin
        if sys_rst = '1' then
            counter := 0;
            heartbeat <= (others => '0');
        elsif rising_edge(sys_clk) and sys_clken_1khz = '1' then
            if counter = 124 then
                counter := 0;
                heartbeat <= std_logic_vector(unsigned(heartbeat)+1);
            else
                counter := counter + 1;
            end if;
        end if;
    end process DO_HEARTBEAT;

    -- increment mode on button press
    DO_MODE_STEP: process(sys_rst,sys_clk,sys_clken_1khz)
        variable counter : integer range 0 to 10; -- 10ms debounce
    begin
        if sys_rst = '1' then
            counter := 0;
            mode_step_s <= (others => '0');
            mode_step_f <= '0';
            mode_step_d <= '0';
            mode <= x"0";
        elsif rising_edge(sys_clk) then
            mode_step_s <= mode_step & mode_step_s(0);
            if counter /= 0 then
                if sys_clken_1khz = '1' then
                    if counter = 5 then
                        counter := 0;
                    else
                        counter := counter + 1;
                    end if;
                end if;
            else
                if mode_step_s(1) /= mode_step_f then
                    mode_step_f <= mode_step_s(1);
                    counter := 1;
                end if;
            end if;
            mode_step_d <= mode_step_f;
            if mode_step_d = '0' and mode_step_f = '1' then -- leading edge of button press
                if mode = x"E" then
                    mode <= x"0";
                else
                    mode <= std_logic_vector(unsigned(mode)+1);
                end if;
            end if;
        end if;
    end process DO_MODE_STEP;

    -- 100MHz clock
    SYSTEM_CLOCK: entity xil_defaultlib.clock_100m
        generic map (
            fref => fref
        )
        port map (
            rsti => ext_rst,
            clki => ref_clk,
            rsto => sys_rst,
            clko => sys_clk
        );

    -- reconfigurable MMCM: 25.2MHz, 27MHz, 74,25MHz or 148.5MHz
    VIDEO_CLOCK: entity xil_defaultlib.video_out_clock
        port map (
            rsti    => ext_rst,
            clki    => ref_clk,
            sys_rst => sys_rst,
            sys_clk => sys_clk,
            sel     => mode_clk_sel,
            rsto    => pix_rst,
            clko    => pix_clk,
            clko_x5 => pix_clk_x5
        );

    -- lookup table: expand mode number to detailed timings for that mode
    VIDEO_MODE: entity xil_defaultlib.video_mode
        port map (
            mode      => mode,
            clk_sel   => mode_clk_sel,
            dmt       => mode_dmt,
            id        => mode_id,
            pix_rep   => mode_pix_rep,
            aspect    => mode_aspect,
            interlace => mode_interlace,
            v_tot     => mode_v_tot,
            v_act     => mode_v_act,
            v_sync    => mode_v_sync,
            v_bp      => mode_v_bp,
            h_tot     => mode_h_tot,
            h_act     => mode_h_act,
            h_sync    => mode_h_sync,
            h_bp      => mode_h_bp,
            vs_pol    => mode_vs_pol,
            hs_pol    => mode_hs_pol
        );

    -- basic video timing generation
    VIDEO_TIMING: entity xil_defaultlib.video_out_timing
        port map (
            rst       => pix_rst,
            clk       => pix_clk,
            pix_rep   => mode_pix_rep,
            interlace => mode_interlace,
            v_tot     => mode_v_tot,
            v_act     => mode_v_act,
            v_sync    => mode_v_sync,
            v_bp      => mode_v_bp,
            h_tot     => mode_h_tot,
            h_act     => mode_h_act,
            h_sync    => mode_h_sync,
            h_bp      => mode_h_bp,
            align     => (others => '0'),
            f         => raw_f,
            vs        => raw_vs,
            hs        => raw_hs,
            vblank    => raw_vblank,
            hblank    => raw_hblank,
            ax        => raw_ax,
            ay        => raw_ay
        );

    -- test pattern generator
    TEST_PATTERN: entity xil_defaultlib.video_out_test_pattern
        port map (
            rst        => pix_rst,
            clk        => pix_clk,
            pix_rep    => mode_pix_rep,
            v_act      => mode_v_act,
            h_act      => mode_h_act,
            raw_vs     => raw_vs,
            raw_hs     => raw_hs,
            raw_vblank => raw_vblank,
            raw_hblank => raw_hblank,
            raw_ax     => raw_ax,
            raw_ay     => raw_ay,
            vga_vs     => vga_vs,
            vga_hs     => vga_hs,
            vga_vblank => vga_vblank,
            vga_hblank => vga_hblank,
            vga_r      => vga_r,
            vga_g      => vga_g,
            vga_b      => vga_b,
            vga_ax     => open,
            vga_ay     => open
        );

    -- simple audio test tone
    AUDIO_TONE: entity xil_defaultlib.audio_out_test_tone
        generic map (
            fref        => 100.0
        )
        port map (
            ref_rst   => ext_rst,
            ref_clk   => ref_clk,
            pcm_rst   => pcm_rst,
            pcm_clk   => pcm_clk,
            pcm_clken => pcm_clken,
            pcm_l     => pcm_l,
            pcm_r     => pcm_r
        );

    -- N and CTS values for HDMI Audio Clock Regeneration; depends on pixel clock
    -- these values correspond to 48kHz audio sample rate
    pcm_n <= std_logic_vector(to_unsigned(6144,pcm_n'length));
    with mode_clk_sel select pcm_cts <=
        std_logic_vector(to_unsigned(148500,pcm_cts'length)) when "11",
        std_logic_vector(to_unsigned(74250,pcm_cts'length)) when "10",
        std_logic_vector(to_unsigned(27000,pcm_cts'length)) when "01",
        std_logic_vector(to_unsigned(25200,pcm_cts'length)) when others;

    -- ACR packet rate should be 128fs/N = 1kHz
    process(pcm_rst,pcm_clk,pcm_clken)
        variable count : integer range 0 to 47;
    begin
        if pcm_rst = '1' then
            count := 0;
            pcm_acr <= '0';
        elsif rising_edge(pcm_clk) and pcm_clken = '1' then
            pcm_acr <= '0';
            if count = 47 then
                count := 0;
                pcm_acr <= '1';
            else
                count := count+1;                
            end if;
       end if;
   end process;

    -- new improved VGA to HDMI converter
    HDMI_CONVERTER: entity xil_defaultlib.vga_to_hdmi
        generic map (
            pcm_fs      => 48.0
        )
        port map (
            dvi        => dvi,
            vic        => mode_id,
            pix_rep    => mode_pix_rep,
            aspect     => mode_aspect,
            vs_pol     => mode_vs_pol,
            hs_pol     => mode_hs_pol,
            vga_rst    => pix_rst,
            vga_clk    => pix_clk,
            vga_clk_x5 => pix_clk_x5,
            vga_vs     => vga_vs,
            vga_hs     => vga_hs,
            vga_de     => vga_vblank nor vga_hblank,
            vga_r      => vga_r,
            vga_g      => vga_g,
            vga_b      => vga_b,
            pcm_rst    => pcm_rst,
            pcm_clk    => pcm_clk,
            pcm_clken  => pcm_clken,
            pcm_l      => pcm_l,
            pcm_r      => pcm_r,
            pcm_acr    => pcm_acr,
            pcm_n      => pcm_n,
            pcm_cts    => pcm_cts,
            hdmi_clk_p => hdmi_clk_p,
            hdmi_clk_n => hdmi_clk_n,
            hdmi_d_p   => hdmi_d_p,
            hdmi_d_n   => hdmi_d_n
        );

end architecture synth;

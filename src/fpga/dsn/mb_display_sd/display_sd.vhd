--------------------------------------------------------------------------------
-- display_sd.vhd                                                             --
-- Display subsystem for mb_display_sd design.                                --
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

entity display_sd is
    port (

        ref_rst     : in    std_logic;                      -- MMCM reset
        ref_clk     : in    std_logic;                      -- reference clock for MMCM

        sys_rst     : in    std_logic;                      -- system reset
        sys_clk     : in    std_logic;                      -- system clock

        bram_en     : in    std_logic;                      -- character buffer enable
        bram_we     : in    std_logic_vector(3 downto 0);
        bram_addr   : in    std_logic_vector(15 downto 0);
        bram_din    : in    std_logic_vector(31 downto 0);
        bram_dout   : out   std_logic_vector(31 downto 0);

        pal_ntsc    : in    std_logic;
        border      : in    std_logic_vector(3 downto 0);

        dvi_clk_p   : out   std_logic;                      -- DVI TMDS clock (differential, P)
        dvi_clk_n   : out   std_logic;                      -- DVI TMDS clock (differential, N)
        dvi_ch_p    : out   std_logic_vector(0 to 2);       -- DVI TMDS channels 0..2 (differential, P)
        dvi_ch_n    : out   std_logic_vector(0 to 2)        -- DVI TMDS channels 0..2 (differential, N)

    );
end entity display_sd;

architecture synth of display_sd is

    signal pix_rst          : std_logic;
    signal pix_clk          : std_logic;
    signal pix_clk_x5       : std_logic;

    signal char_buf_addr    : std_logic_vector(12 downto 1);    -- 4k x 16
    signal char_buf_data    : std_logic_vector(15 downto 0);    -- attribute + character code

    signal char_rom_row     : std_logic_vector(3 downto 0);
    signal char_rom_data    : std_logic_vector(7 downto 0);

    signal char_sr          : std_logic_vector(7 downto 0);
    signal char_attr        : std_logic_vector(7 downto 0);
    signal in_v_vis         : std_logic;
    signal in_h_vis         : std_logic;

    signal mode_v_tot       : std_logic_vector(10 downto 0);  -- vertical total lines (must be odd if interlaced)
    signal mode_v_act       : std_logic_vector(10 downto 0);  -- vertical active lines
    signal mode_v_sync      : std_logic_vector(2 downto 0);   -- vertical sync width
    signal mode_v_bp        : std_logic_vector(5 downto 0);   -- vertical back porch
    signal mode_h_tot       : std_logic_vector(11 downto 0);  -- horizontal total
    signal mode_h_act       : std_logic_vector(10 downto 0);  -- horizontal active
    signal mode_h_sync      : std_logic_vector(6 downto 0);   -- horizontal sync width
    signal mode_h_bp        : std_logic_vector(7 downto 0);   -- horizontal back porch

    signal raw_ce           : std_logic;                      -- active area enable in
    signal raw_f            : std_logic;                      -- field ID in
    signal raw_vs           : std_logic;                      -- vertical sync in
    signal raw_hs           : std_logic;                      -- horizontal sync in
    signal raw_vblank       : std_logic;                      -- vertical blanking in
    signal raw_hblank       : std_logic;                      -- horizontal blanking in
    signal raw_ax           : std_logic_vector(11 downto 0);  -- active area x position in
    signal raw_ay           : std_logic_vector(11 downto 0);  -- active area y position in

    signal raw_v_vis        : std_logic;
    signal raw_h_vis        : std_logic;

    signal vga_vs           : std_logic;                      -- vertical sync out
    signal vga_hs           : std_logic;                      -- horizontal sync out
    signal vga_vblank       : std_logic;                      -- vertical blanking out
    signal vga_hblank       : std_logic;                      -- horizontal blanking out
    signal vga_r            : std_logic_vector(7 downto 0);   -- red output
    signal vga_g            : std_logic_vector(7 downto 0);   -- green output
    signal vga_b            : std_logic_vector(7 downto 0);   -- blue output
    signal vga_ax           : std_logic_vector(11 downto 0);  -- active area x position out
    signal vga_ay           : std_logic_vector(11 downto 0);  -- active area y position out

    alias char_buf_code     : std_logic_vector(7 downto 0) is char_buf_data(7 downto 0);
    alias char_buf_attr     : std_logic_vector(7 downto 0) is char_buf_data(15 downto 8);

begin

    process(pal_ntsc)
    begin
        if pal_ntsc = '1' then -- 720 x 576 @ 50Hz interlaced
            mode_v_tot  <= std_logic_vector(to_unsigned(625,mode_v_tot'length));
            mode_v_sync <= std_logic_vector(to_unsigned(3,mode_v_sync'length));
            mode_v_bp   <= std_logic_vector(to_unsigned(19,mode_v_bp'length));
            mode_v_act  <= std_logic_vector(to_unsigned(576,mode_v_act'length));
            mode_h_tot  <= std_logic_vector(to_unsigned(864,mode_h_tot'length));
            mode_h_sync <= std_logic_vector(to_unsigned(63,mode_h_sync'length));
            mode_h_bp   <= std_logic_vector(to_unsigned(69,mode_h_bp'length));
            mode_h_act  <= std_logic_vector(to_unsigned(720,mode_h_act'length));
        else -- 720 x 480 @ 59.94Hz interlaced
            mode_v_tot  <= std_logic_vector(to_unsigned(525,mode_v_tot'length));
            mode_v_sync <= std_logic_vector(to_unsigned(3,mode_v_sync'length));
            mode_v_bp   <= std_logic_vector(to_unsigned(15,mode_v_bp'length));
            mode_v_act  <= std_logic_vector(to_unsigned(480,mode_v_act'length));
            mode_h_tot  <= std_logic_vector(to_unsigned(858,mode_h_tot'length));
            mode_h_sync <= std_logic_vector(to_unsigned(62,mode_h_sync'length));
            mode_h_bp   <= std_logic_vector(to_unsigned(57,mode_h_bp'length));
            mode_h_act  <= std_logic_vector(to_unsigned(720,mode_h_act'length));
        end if;
    end process;

    -- video clock is fixed for these SD modes
    VIDEO_CLOCK: entity xil_defaultlib.video_clock_out_27m
        generic map (
            fref    => 100.0
        )
        port map (
            rsti    => ref_rst,
            clki    => ref_clk,
            rsto    => pix_rst,
            clko    => pix_clk,
            clko_x5 => pix_clk_x5
        );

    process(pix_clk)

        -- CGA palette
        function cga(c : std_logic_vector(3 downto 0)) return std_logic_vector is
            variable rgb : std_logic_vector(23 downto 0);
        begin
            case c is
                when x"0" => rgb := std_logic_vector'(x"000000");
                when x"1" => rgb := std_logic_vector'(x"0000AA");
                when x"2" => rgb := std_logic_vector'(x"00AA00");
                when x"3" => rgb := std_logic_vector'(x"00AAAA");
                when x"4" => rgb := std_logic_vector'(x"AA0000");
                when x"5" => rgb := std_logic_vector'(x"AA00AA");
                when x"6" => rgb := std_logic_vector'(x"AA5500");
                when x"7" => rgb := std_logic_vector'(x"AAAAAA");
                when x"8" => rgb := std_logic_vector'(x"555555");
                when x"9" => rgb := std_logic_vector'(x"5555FF");
                when x"A" => rgb := std_logic_vector'(x"55FF55");
                when x"B" => rgb := std_logic_vector'(x"55FFFF");
                when x"C" => rgb := std_logic_vector'(x"FF5555");
                when x"D" => rgb := std_logic_vector'(x"FF55FF");
                when x"E" => rgb := std_logic_vector'(x"FFFF55");
                when x"F" => rgb := std_logic_vector'(x"FFFFFF");
            end case;
            return rgb;
        end function cga;

        variable cx : unsigned(6 downto 0);  -- 80 columns
        variable cy : unsigned(4 downto 0);  -- 25 or 32 rows
        variable a  : unsigned(11 downto 0); -- 4k x 16

    begin
        if rising_edge(pix_clk) then
            if pix_rst = '1' then

                char_buf_addr       <= (others => '0');
                char_rom_row        <= (others => '0');
                char_sr             <= (others => '0');
                char_attr           <= (others => '0');
                raw_v_vis           <= '0';
                raw_h_vis           <= '0';
                vga_vs              <= '0';
                vga_hs              <= '0';
                vga_vblank          <= '0';
                vga_hblank          <= '0';
                vga_ax              <= (others => '0');
                vga_ay              <= (others => '0');
                (vga_r,vga_g,vga_b) <= std_logic_vector'(x"000000");

            elsif raw_ce = '1' then

                -- character buffer address
                cx := shift_right(unsigned(raw_ax)-(40-4),3)(6 downto 0);    -- adjust for start pos, 4 clocks ahead, divide by char width (8)
                if pal_ntsc = '1' then
                    cy := shift_right(unsigned(raw_ay) - 32,4)(4 downto 0);  -- adjust for start pos, divide by char height (16) (80x32, 576i)
                else
                    cy := shift_right(unsigned(raw_ay) - 40,4)(4 downto 0);  -- adjust for start pos, divide by char height (16) (80x25, 480i)
                end if;
                a := shift_left(resize(cy,a'length),6)
                    + shift_left(resize(cy,a'length),4)
                    + resize(cx,a'length); -- a = (y*80) + x
                char_buf_addr <= std_logic_vector(a);

                -- character row
                char_rom_row <= raw_ay(3 downto 0) xor (not pal_ntsc) & "000";

                -- shift/load
                char_sr <= char_sr(6 downto 0) & '0';
                if raw_ax(2 downto 0) = "111" then
                    char_sr <= char_rom_data;
                    char_attr <= char_buf_attr;
                end if;

                -- visible region
                if raw_vs = '1' then
                    raw_v_vis <= '0';
                    raw_h_vis <= '0';
                end if;
                if pal_ntsc = '1' then
                    if to_integer(unsigned(raw_ay)) = 32
                    or to_integer(unsigned(raw_ay)) = 33
                    then
                        raw_v_vis <= '1';
                    elsif to_integer(unsigned(raw_ay)) = 544
                    or to_integer(unsigned(raw_ay)) = 545 then
                        raw_v_vis <= '0';
                    end if;
                else
                    if to_integer(unsigned(raw_ay)) = 40
                    or to_integer(unsigned(raw_ay)) = 41
                    then
                        raw_v_vis <= '1';
                    elsif to_integer(unsigned(raw_ay)) = 440
                    or to_integer(unsigned(raw_ay)) = 441 then
                        raw_v_vis <= '0';
                    end if;
                end if;
                if to_integer(unsigned(raw_ax)) = 39 then
                    raw_h_vis <= '1';
                elsif to_integer(unsigned(raw_ax)) = 679 then
                    raw_h_vis <= '0';
                end if;

                -- outputs
                vga_vs      <= raw_vs;
                vga_hs      <= raw_hs;
                vga_vblank  <= raw_vblank;
                vga_hblank  <= raw_hblank;
                vga_ax      <= raw_ax;
                vga_ay      <= raw_ay;
                (vga_r,vga_g,vga_b) <= std_logic_vector'(x"000000");
                if raw_vblank = '0' and raw_hblank = '0' then
                    if raw_v_vis = '1' and raw_h_vis = '1' then
                        if char_sr(7) = '1' then
                            (vga_r,vga_g,vga_b) <= cga(char_attr(3 downto 0));  -- character foreground colour
                        else
                            (vga_r,vga_g,vga_b) <= cga(char_attr(7 downto 4));  -- character background colour
                        end if;
                    else
                        (vga_r,vga_g,vga_b) <= cga(border);                     -- border colour
                    end if;
                end if;

            end if;
        end if;
    end process;

    -- 8kByte character buffer; 4k x 16 on A (display) port, 2k x 32 on B (CPU) port

    CHAR_BUF: entity xil_defaultlib.ram_4kx16_2kx32
        port map(
            clk_a   => sys_clk,
            clr_a   => '0',
            en_a    => bram_en,
            we_a    => bram_we,
            addr_a  => bram_addr(12 downto 2),
            din_a   => bram_din,
            dout_a  => bram_dout,
            clk_b   => pix_clk,
            clr_b   => '0',
            en_b    => '1',
            we_b    => (others => '0'),
            addr_b  => char_buf_addr,
            din_b   => (others => '0'),
            dout_b  => char_buf_data
        );

    -- character ROM (256 patterns x 8 pixels wide x 16 rows high)

    CHAR_ROM: entity xil_defaultlib.char_rom_437_8x16
        port map (
            clk     => pix_clk,
            r       => char_rom_row,    -- character row (scan line) (0..15)
            a       => char_buf_code,   -- character code (0..255)
            d       => char_rom_data    -- character row data (8 pixels)
        );

    -- DVI output block

    DVI_OUT: entity xil_defaultlib.dvi_out
        port map (
            rst         => pix_rst,
            clk         => pix_clk,
            clk_x5      => pix_clk_x5,
            mode_pixrep => '1',
            mode_ilace  => '1',
            mode_v_tot  => mode_v_tot,
            mode_v_act  => mode_v_act,
            mode_v_sync => mode_v_sync,
            mode_v_bp   => mode_v_bp,
            mode_h_tot  => mode_h_tot,
            mode_h_act  => mode_h_act,
            mode_h_sync => mode_h_sync,
            mode_h_bp   => mode_h_bp,
            mode_vs_pol => '0',
            mode_hs_pol => '0',
            raw_ce      => raw_ce,
            raw_f       => raw_f,
            raw_vs      => raw_vs,
            raw_hs      => raw_hs,
            raw_vblank  => raw_vblank,
            raw_hblank  => raw_hblank,
            raw_ax      => raw_ax,
            raw_ay      => raw_ay,
            raw_align   => (others => '0'),
            vga_vs      => vga_vs,
            vga_hs      => vga_hs,
            vga_vblank  => vga_vblank,
            vga_hblank  => vga_hblank,
            vga_r       => vga_r,
            vga_g       => vga_g,
            vga_b       => vga_b,
            vga_ax      => vga_ax,
            vga_ay      => vga_ay,
            dvi_clk_p   => dvi_clk_p,
            dvi_clk_n   => dvi_clk_n,
            dvi_ch_p    => dvi_ch_p,
            dvi_ch_n    => dvi_ch_n
        );

end architecture synth;

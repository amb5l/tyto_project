--------------------------------------------------------------------------------
-- model_hdmi_decoder.vhd                                                     --
-- Simple simulation model of HDMI decoder; extracts video and data.          --
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
use xil_defaultlib.types_pkg.all;

entity model_hdmi_decoder is
    port
    (
        rst         : in    std_logic;

        hdmi_clk    : in    std_logic;        
        hdmi_d      : in    std_logic_vector(0 to 2);       -- 3x TMDS channels

        data_pstb   : out   std_logic;                      -- data packet strobe
        data_hb     : out   slv_7_0_t(0 to 3);              -- data header bytes
        data_hb_ok  : out   std_logic;                      -- data header bytes ECC OK
        data_sb     : out   slv_7_0_2d_t(0 to 3,0 to 7);    -- data subpacket bytes (4 subpackets)
        data_sb_ok  : out   std_logic_vector(0 to 3);       -- data subpacket bytes ECC OK

        vga_rst     : out   std_logic;                      -- VGA reset
        vga_clk     : out   std_logic;                      -- VGA pixel clock
        vga_vs      : out   std_logic;                      -- VGA vertical sync
        vga_hs      : out   std_logic;                      -- VGA horizontal sync
        vga_de      : out   std_logic;                      -- VGA pixel data enable
        vga_p       : out   slv_7_0_t(0 to 2)               -- VGA pixel components

    );
end entity model_hdmi_decoder;

architecture model of model_hdmi_decoder is

    signal hdmi_clk_lock    : std_logic := '0';
    signal hdmi_clk_prev    : time := 0ps;      -- time of last event (since hdmi_clk'last_event always returns 0ps)
    signal hdmi_clk_hp      : time := 0ps;      -- half clock period
    signal hdmi_clk_count   : integer := 0;

    type period_t is (
            UNKNOWN,
            CONTROL,
            VIDEO_PRE,
            VIDEO_GB,
            VIDEO,
            DATA_PRE,
            DATA_GB_LEADING,
            DATA_ISLAND,
            DATA_GB_TRAILING
        );

    signal tmds_data        : slv_9_0_t(0 to 2);
    signal tmds_clk         : std_logic_vector(0 to 2);
    signal tmds_locked      : std_logic_vector(0 to 2);
    type tmds_type_t is (CTRL, TERC4, VIDEO);
    type tmds_type_array_t is array(0 to 2) of tmds_type_t;
    signal tmds_type        : tmds_type_array_t;

    signal c                : slv_1_0_t(0 to 2);         -- decoded control
    signal d                : slv_7_0_t(0 to 2);         -- decoded data
    signal xd               : slv_3_0_t(0 to 2);         -- decoded auxilliary data

    signal data             : slv_3_0_2d_t(0 to 2,0 to 31); -- extracted raw data

    signal debug_period     : period_t;
    signal debug_pcount     : integer;
    signal debug_hb_byte    : integer range 0 to 3;
    signal debug_hb_bit     : integer range 0 to 7;
    signal debug_sb_byte    : integer range 0 to 7;
    signal debug_sb_2bit    : integer range 0 to 3;
    signal debug_ecc        : slv_7_0_t(0 to 4);

begin

    -- clock monitor

    process(rst,hdmi_clk)
    begin
        if rst = '1' then
            hdmi_clk_lock <= '0';
            hdmi_clk_hp <= 0ps;
            hdmi_clk_count <= 0;
        elsif hdmi_clk'event then
            if hdmi_clk_lock = '1' then
                if hdmi_clk /= '0' and hdmi_clk /= '1' then
                    hdmi_clk_lock <= '0';
                    hdmi_clk_hp <= 0ps;
                    hdmi_clk_count <= 0;
                else
                    if abs(hdmi_clk_hp-(now-hdmi_clk_prev)) > 5ps then -- reject >5ps jitter
                        hdmi_clk_lock <= '0';
                        hdmi_clk_hp <= 0ps;
                        hdmi_clk_count <= 0;                        
                    end if;
                end if;
            else
                if hdmi_clk_hp = 0ps then
                    hdmi_clk_hp <= now-hdmi_clk_prev;
                else
                    if abs(hdmi_clk_hp-(now-hdmi_clk_prev)) > 5ps then -- reject >5ps jitter
                        hdmi_clk_lock <= '0';
                        hdmi_clk_hp <= 0ps;
                        hdmi_clk_count <= 0;  
                    else
                        if hdmi_clk_count = 4 then
                            hdmi_clk_lock <= '1';
                        else
                            hdmi_clk_count <= hdmi_clk_count+1;
                        end if;
                    end if;
                end if;
            end if;
        hdmi_clk_prev <= now;
        end if;
    end process;

    -- CDR, deserialise

    GEN_TMDS_CDR_DES: for i in 0 to 2 generate
        TMDS_CDR_DES: entity work.model_tmds_cdr_des
            port map (
                refclk      => hdmi_clk,
                serial      => hdmi_d(i),
                parallel    => tmds_data(i),
                clk         => tmds_clk(i),
                locked      => tmds_locked(i)
            );
    end generate GEN_TMDS_CDR_DES;

    vga_clk <= tmds_clk(0); -- assumption: channel to channel skew is small (less than half a pixel clock)

    -- decode (per channel)

    process(tmds_data)
        variable s : std_logic_vector(9 downto 0);
    begin
        for i in 0 to 2 loop
            s := tmds_data(i);
            xd(i) <= (others => 'X');
            d(i)(0) <= s(0) xor s(9);
            for j in 1 to 7 loop
                d(i)(j) <= (s(j) xor s(9)) xor ((s(j-1) xor s(9)) xnor s(8));
            end loop;
            tmds_type(i) <= VIDEO;
            case s is
                when "1010011100" => xd(i) <= "0000"; tmds_type(i) <= TERC4;
                when "1001100011" => xd(i) <= "0001"; tmds_type(i) <= TERC4;
                when "1011100100" => xd(i) <= "0010"; tmds_type(i) <= TERC4;
                when "1011100010" => xd(i) <= "0011"; tmds_type(i) <= TERC4;
                when "0101110001" => xd(i) <= "0100"; tmds_type(i) <= TERC4;
                when "0100011110" => xd(i) <= "0101"; tmds_type(i) <= TERC4;
                when "0110001110" => xd(i) <= "0110"; tmds_type(i) <= TERC4;
                when "0100111100" => xd(i) <= "0111"; tmds_type(i) <= TERC4;
                when "1011001100" => xd(i) <= "1000"; tmds_type(i) <= TERC4;
                when "0100111001" => xd(i) <= "1001"; tmds_type(i) <= TERC4;
                when "0110011100" => xd(i) <= "1010"; tmds_type(i) <= TERC4;
                when "1011000110" => xd(i) <= "1011"; tmds_type(i) <= TERC4;
                when "1010001110" => xd(i) <= "1100"; tmds_type(i) <= TERC4;
                when "1001110001" => xd(i) <= "1101"; tmds_type(i) <= TERC4;
                when "0101100011" => xd(i) <= "1110"; tmds_type(i) <= TERC4;
                when "1011000011" => xd(i) <= "1111"; tmds_type(i) <= TERC4;
                when "1101010100" => c(i) <= "00"; tmds_type(i) <= CTRL;
                when "0010101011" => c(i) <= "01"; tmds_type(i) <= CTRL;
                when "0101010100" => c(i) <= "10"; tmds_type(i) <= CTRL;
                when "1010101011" => c(i) <= "11"; tmds_type(i) <= CTRL;
                when others => null;
            end case;
        end loop;
    end process;

    -- decode (overall) and extract video timing + data

    process(rst,tmds_locked,vga_clk)
        variable period     : period_t;
        variable pcount     : integer;
        variable hb_byte    : integer range 0 to 3;
        variable hb_bit     : integer range 0 to 7;
        variable sb_byte    : integer range 0 to 7;
        variable sb_2bit    : integer range 0 to 3;
    begin
        if rst = '1' or hdmi_clk_lock = '0' or tmds_locked /= "111" then

            vga_rst     <= '1';
            vga_vs      <= 'X';
            vga_hs      <= 'X';
            vga_de      <= '0';
            vga_p       <= (others => (others => '0'));

            data        <= (others => (others => (others => '0')));
            data_pstb   <= '0';

            period  := UNKNOWN;

        elsif rising_edge(vga_clk) then

            -- period transitions

            case period is

                when UNKNOWN =>
                    if tmds_type = (tmds_type'range => CTRL) and c(1) = "00" and c(2) = "00" then
                        period := CONTROL; pcount := 0; vga_rst <= '0';
                    end if;

                when CONTROL =>
                    pcount := pcount + 1;
                    if tmds_type = (tmds_type'range => VIDEO) then
                        period := VIDEO;
                    else
                        if tmds_type(0) = CTRL then
                            if c(1) = "00" and c(2) = "00" then
                                null;
                            elsif c(1) = "01" and c(2)(1) = '0' then
                                if pcount < 11 then
                                    report "control period too short" severity warning;
                                    period := UNKNOWN; pcount := 0; vga_rst <= '1';
                                else
                                    if c(2)(0) = '0' then
                                        period := VIDEO_PRE; pcount := 0;
                                    elsif c(2)(0) = '1' then
                                        period := DATA_PRE; pcount := 0;
                                    end if;
                                end if;
                            end if;
                        end if;
                    end if;
                    if period = CONTROL and tmds_type(0) = CTRL and c(1) /= "00" and c(2) /= "00" then
                        report "unrecognised control/preamble period" severity warning;
                        period := UNKNOWN; pcount := 0; vga_rst <= '1';
                    end if;

                when VIDEO_PRE =>
                    pcount := pcount + 1;
                    if pcount < 8 then
                        if not (tmds_type(0) = CTRL and c(1) = "01" and c(2) = "00") then
                            report "video preamble ended too soon" severity warning;
                            period := UNKNOWN; pcount := 0; vga_rst <= '1';
                        end if;
                    else
                        if tmds_data(0) = "1011001100"
                        and tmds_data(1) = "0100110011"
                        and tmds_data(2) = "1011001100"
                        then
                            period := VIDEO_GB; pcount := 0;
                        else
                            report "expected video guard band" severity warning;
                            period := UNKNOWN; pcount := 0; vga_rst <= '1';
                        end if;
                    end if;

                when VIDEO_GB =>
                    pcount := pcount + 1;
                    if pcount = 1 then
                        if tmds_data(0) /= "1011001100"
                        or tmds_data(1) /= "0100110011"
                        or tmds_data(2) /= "1011001100"
                        then
                            report "expected video guard band" severity warning;
                            period := UNKNOWN; pcount := 0; vga_rst <= '1';
                        end if;
                    else
                        if tmds_type = (tmds_type'range => VIDEO) then
                            period := VIDEO; pcount := 0;
                        else
                            report "expected video" severity warning;
                            period := UNKNOWN; pcount := 0; vga_rst <= '1';
                        end if;
                    end if;

                when VIDEO =>
                    pcount := pcount + 1;
                    if tmds_type(0) = CTRL then
                        if c(1) = "00" and c(2) = "00" then
                            period := CONTROL; pcount := 0;
                        elsif c(1) = "01" and c(2)(1) = '0' then
                            if c(2)(0) = '0' then
                                period := VIDEO_PRE; pcount := 0;
                            elsif c(2)(0) = '1' then
                                period := DATA_PRE; pcount := 0;
                            end if;
                        else
                            report "unrecognised control/preamble period" severity warning;
                            period := UNKNOWN; pcount := 0; vga_rst <= '1';
                        end if;
                    end if;

                when DATA_PRE =>
                    pcount := pcount + 1;
                    if pcount < 8 then
                        if not (tmds_type(0) = CTRL and c(1) = "01" and c(2) = "01") then
                            report "data preamble ended too soon" severity warning;
                            period := UNKNOWN; pcount := 0; vga_rst <= '1';
                        end if;
                    else
                        if tmds_data(1) = "0100110011"
                        and tmds_data(2) = "0100110011"
                        and (
                            tmds_data(0) = "1010001110" or
                            tmds_data(0) = "1001110001" or
                            tmds_data(0) = "0101100011" or
                            tmds_data(0) = "1011000011"
                        )
                        then
                            period := DATA_GB_LEADING; pcount := 0;
                        else
                            report "expected data island leading guard band" severity warning;
                            period := UNKNOWN; pcount := 0; vga_rst <= '1';
                        end if;
                    end if;

                when DATA_GB_LEADING =>
                    pcount := pcount + 1;
                    if pcount = 1 then
                        if tmds_data(1) /= "0100110011"
                        or tmds_data(2) /= "0100110011"
                        or not (
                            tmds_data(0) = "1010001110" or
                            tmds_data(0) = "1001110001" or
                            tmds_data(0) = "0101100011" or
                            tmds_data(0) = "1011000011"
                        )
                        then
                            report "expected data island leading guard band" severity warning;
                            period := UNKNOWN; pcount := 0; vga_rst <= '1';
                        end if;
                    else
                        if tmds_type = (tmds_type'range => TERC4) then
                            period := DATA_ISLAND; pcount := 0;
                        else
                            report "expected data" severity warning;
                            period := UNKNOWN; pcount := 0; vga_rst <= '1';
                        end if;
                    end if;

                when DATA_ISLAND =>
                    pcount := pcount + 1;
                    if tmds_type(0) = CTRL or tmds_type(1) = CTRL or tmds_type(2) = CTRL then
                        report "unexpected control period" severity warning;
                        period := UNKNOWN; pcount := 0; vga_rst <= '1';
                    end if;
                    if (pcount mod 32) = 0 then
                        if tmds_data(1) = "0100110011"
                        and tmds_data(2) = "0100110011"
                        and (
                            tmds_data(0) = "1010001110" or
                            tmds_data(0) = "1001110001" or
                            tmds_data(0) = "0101100011" or
                            tmds_data(0) = "1011000011"
                        )
                        then
                            period := DATA_GB_TRAILING; pcount := 0;
                        end if;
                    end if;
                    if period = DATA_ISLAND then
                        if tmds_type(0) /= TERC4 or tmds_type(1) /= TERC4 or tmds_type(2) /= TERC4 then
                            report "bad data period" severity warning;
                            period := UNKNOWN; pcount := 0; vga_rst <= '1';
                        end if;
                    end if;

                when DATA_GB_TRAILING =>
                    pcount := pcount + 1;
                    if pcount = 1 then
                        if tmds_data(1) /= "0100110011"
                        or tmds_data(2) /= "0100110011"
                        or not (
                            tmds_data(0) = "1010001110" or
                            tmds_data(0) = "1001110001" or
                            tmds_data(0) = "0101100011" or
                            tmds_data(0) = "1011000011"
                        )
                        then
                            report "expected data island trailing guard band" severity warning;
                            period := UNKNOWN; pcount := 0; vga_rst <= '1';
                        end if;
                    else
                        if tmds_type(0) = CTRL then
                            if c(1) = "00" and c(2) = "00" then
                                period := CONTROL; pcount := 0;
                            elsif c(1) = "01" and c(2)(1) = '0' then
                                if c(2)(0) = '0' then
                                    period := VIDEO_PRE; pcount := 0;
                                elsif c(2)(0) = '1' then
                                    period := DATA_PRE; pcount := 0;
                                end if;
                            end if;
                        end if;
                        if period /= CONTROL and period /= VIDEO_PRE and period /= DATA_PRE then
                            report "expected control or preamble period" severity warning;
                            period := UNKNOWN; pcount := 0; vga_rst <= '1';
                        end if;
                    end if;

            end case;

            -- extract video timing

            vga_de <= '0';
            vga_p <= (others => (others => '0'));

            case period is

                when UNKNOWN =>
                    vga_vs <= 'X';
                    vga_hs <= 'X';
                    vga_de <= 'X';
                    vga_p <= (others => (others => 'X'));

                when CONTROL | VIDEO_PRE | DATA_PRE =>
                    vga_vs <= c(0)(1);
                    vga_hs <= c(0)(0);

                when VIDEO_GB =>
                    null;

                when VIDEO =>
                    vga_de <= '1';
                    vga_p <= d;

                when DATA_GB_LEADING | DATA_ISLAND | DATA_GB_TRAILING =>
                    vga_vs <= xd(0)(1);
                    vga_hs <= xd(0)(0);

            end case;

            -- extract data

            data_pstb <= '0';
            if period = DATA_ISLAND then
                for i in 0 to 2 loop
                    data(i,pcount mod 32) <= xd(i);
                end loop;
                if pcount mod 32 = 31 then
                    data_pstb <= '1';
                end if;
            end if;

            if data_pstb = '1' then
                for i in 0 to 31 loop
                    hb_byte := i/8;
                    hb_bit := i mod 8;
                    sb_byte := i/4;
                    sb_2bit := i mod 4;
                    data_hb(hb_byte)(hb_bit) <= data(0,i)(2);
                    for j in 0 to 3 loop
                        data_sb(j,sb_byte)(0+(2*sb_2bit)) <= data(1,i)(j);
                        data_sb(j,sb_byte)(1+(2*sb_2bit)) <= data(2,i)(j);
                    end loop;
                end loop;
            end if;

            -- to allow variables to be observed on simulation waveform (Vivado)

            debug_period  <= period;
            debug_pcount  <= pcount;
            debug_hb_byte <= hb_byte;
            debug_hb_bit  <= hb_bit;
            debug_sb_byte <= sb_byte;
            debug_sb_2bit <= sb_2bit;

        end if;
    end process;

    -- check data ECC

    process(data_pstb)

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

        function hdmi_bch_ecc8( -- see hdmi_bch_ecc.py
            q : std_logic_vector(7 downto 0);
            d : std_logic_vector(7 downto 0)
        ) return std_logic_vector is
            variable r : std_logic_vector(7 downto 0);
        begin
            r(0) := xor_v(d(0) & d(1) & d(2) & d(4) & d(5) & d(7) & q(0) & q(1) & q(2) & q(4) & q(5) & q(7));
            r(1) := xor_v(d(3) & d(4) & d(6) & d(7) & q(3) & q(4) & q(6) & q(7));
            r(2) := xor_v(d(1) & d(2) & q(1) & q(2));
            r(3) := xor_v(d(0) & d(2) & d(3) & q(0) & q(2) & q(3));
            r(4) := xor_v(d(0) & d(1) & d(3) & d(4) & q(0) & q(1) & q(3) & q(4));
            r(5) := xor_v(d(1) & d(2) & d(4) & d(5) & q(1) & q(2) & q(4) & q(5));
            r(6) := xor_v(d(0) & d(2) & d(3) & d(5) & d(6) & q(0) & q(2) & q(3) & q(5) & q(6));
            r(7) := xor_v(d(0) & d(1) & d(3) & d(4) & d(6) & d(7) & q(0) & q(1) & q(3) & q(4) & q(6) & q(7));
            return r;
        end function hdmi_bch_ecc8;

        variable ecc : std_logic_vector(7 downto 0);

    begin

        if falling_edge(data_pstb) then

            ecc := x"00";
            for i in 0 to 2 loop
                ecc := hdmi_bch_ecc8(ecc, data_hb(i));
            end loop;
            debug_ecc(4) <= ecc;
            if ecc = data_hb(3) then
                data_hb_ok <= '1';
            else
                data_hb_ok <= '0';
            end if;

            for i in 0 to 3 loop
                ecc := x"00";
                for j in 0 to 6 loop
                    ecc := hdmi_bch_ecc8(ecc, data_sb(i,j));
                end loop;
                debug_ecc(i) <= ecc;
                if ecc = data_sb(i,7) then
                    data_sb_ok(i) <= '1';
                else
                    data_sb_ok(i) <= '0';
                end if;
            end loop;

        end if;

    end process;

end architecture model;

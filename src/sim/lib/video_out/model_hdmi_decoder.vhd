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
        rst     : in    std_logic;

        ch      : in    std_logic_vector(0 to 2);       -- 3x TMDS channels

        clk     : out   std_logic;

        pstb    : out   std_logic;                      -- packet strobe
        hb      : out   slv_7_0_t(0 to 3);              -- header bytes
        hb_ok   : out   std_logic;                      -- header bytes ECC OK
        sb      : out   slv_7_0_2d_t(0 to 3,0 to 7);    -- subpacket bytes (4 subpackets)
        sb_ok   : out   std_logic_vector(0 to 3);       -- subpacket bytes ECC OK

        vs      : out   std_logic;                      -- vertical sync
        hs      : out   std_logic;                      -- horizontal sync
        de      : out   std_logic;                      -- pixel data enable
        p       : out   slv_7_0_t(0 to 2)               -- pixel components

    );
end entity model_hdmi_decoder;

architecture model of model_hdmi_decoder is

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

    -------------------------------------------------------------------------------
    -- CDR, deserialise

    GEN_TMDS_CDR_DES: for i in 0 to 2 generate
        TMDS_CDR_DES: entity work.model_tmds_cdr_des
            port map (
                serial      => ch(i),
                parallel    => tmds_data(i),
                clk         => tmds_clk(i),
                locked      => tmds_locked(i)
            );
    end generate GEN_TMDS_CDR_DES;

    -- assumption: channel to channel skew is small (less than half a pixel clock)
    clk <= tmds_clk(0);

    -------------------------------------------------------------------------------
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

    -------------------------------------------------------------------------------
    -- decode (overall) and extract video timing + data

    process(rst,tmds_locked,clk)
        variable period     : period_t;
        variable pcount     : integer;
        variable hb_byte    : integer range 0 to 3;
        variable hb_bit     : integer range 0 to 7;
        variable sb_byte    : integer range 0 to 7;
        variable sb_2bit    : integer range 0 to 3;
    begin
        if rst = '1' or tmds_locked /= "111" then

            vs      <= 'X';
            hs      <= 'X';
            de      <= '0';
            p       <= (others => (others => '0'));
            data    <= (others => (others => (others => '0')));
            pstb    <= '0';

            period  := UNKNOWN;

        elsif rising_edge(clk) then

            -------------------------------------------------------------------------------
            -- period transitions

            case period is

                when UNKNOWN =>
                    if tmds_type = (tmds_type'range => CTRL) and c = (c'range => "00") then
                        period := CONTROL; pcount := 0;
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
                                    period := UNKNOWN; pcount := 0;
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
                        period := UNKNOWN; pcount := 0;
                    end if;

                when VIDEO_PRE =>
                    pcount := pcount + 1;
                    if pcount < 8 then
                        if not (tmds_type(0) = CTRL and c(1) = "01" and c(2) = "00") then
                            report "video preamble ended too soon" severity warning;
                            period := UNKNOWN; pcount := 0;
                        end if;
                    else
                        if tmds_data(0) = "1011001100"
                        and tmds_data(1) = "0100110011"
                        and tmds_data(2) = "1011001100"
                        then
                            period := VIDEO_GB; pcount := 0;
                        else
                            report "expected video guard band" severity warning;
                            period := UNKNOWN; pcount := 0;
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
                            period := UNKNOWN; pcount := 0;
                        end if;
                    else
                        if tmds_type = (tmds_type'range => VIDEO) then
                            period := VIDEO; pcount := 0;
                        else
                            report "expected video" severity warning;
                            period := UNKNOWN; pcount := 0;
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
                            period := UNKNOWN; pcount := 0;
                        end if;
                    end if;

                when DATA_PRE =>
                    pcount := pcount + 1;
                    if pcount < 8 then
                        if not (tmds_type(0) = CTRL and c(1) = "01" and c(2) = "01") then
                            report "data preamble ended too soon" severity warning;
                            period := UNKNOWN; pcount := 0;
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
                            period := UNKNOWN; pcount := 0;
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
                            period := UNKNOWN; pcount := 0;
                        end if;
                    else
                        if tmds_type = (tmds_type'range => TERC4) then
                            period := DATA_ISLAND; pcount := 0;
                        else
                            report "expected data" severity warning;
                            period := UNKNOWN; pcount := 0;
                        end if;
                    end if;

                when DATA_ISLAND =>
                    pcount := pcount + 1;
                    if tmds_type(0) = CTRL or tmds_type(1) = CTRL or tmds_type(2) = CTRL then
                        report "unexpected control period" severity warning;
                        period := UNKNOWN; pcount := 0;
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
                            period := UNKNOWN; pcount := 0;
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
                            period := UNKNOWN; pcount := 0;
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
                            period := UNKNOWN; pcount := 0;
                        end if;
                    end if;

            end case;

            -------------------------------------------------------------------------------
            -- extract video timing

            de <= '0';
            p <= (others => (others => '0'));

            case period is

                when UNKNOWN =>
                    vs <= 'X';
                    hs <= 'X';
                    de <= 'X';
                    p <= (others => (others => 'X'));

                when CONTROL | VIDEO_PRE | DATA_PRE =>
                    vs <= c(0)(1);
                    hs <= c(0)(0);

                when VIDEO_GB =>
                    null;

                when VIDEO =>
                    de <= '1';
                    p <= d;

                when DATA_GB_LEADING | DATA_ISLAND | DATA_GB_TRAILING =>
                    vs <= xd(0)(1);
                    hs <= xd(0)(0);

            end case;

            -------------------------------------------------------------------------------
            -- extract data

            pstb <= '0';
            if period = DATA_ISLAND then
                for i in 0 to 2 loop
                    data(i,pcount mod 32) <= xd(i);
                end loop;
                if pcount mod 32 = 31 then
                    pstb <= '1';
                end if;
            end if;

            if pstb = '1' then
                for i in 0 to 31 loop
                    hb_byte := i/8;
                    hb_bit := i mod 8;
                    sb_byte := i/4;
                    sb_2bit := i mod 4;
                    hb(hb_byte)(hb_bit) <= data(0,i)(2);
                    for j in 0 to 3 loop
                        sb(j,sb_byte)(0+(2*sb_2bit)) <= data(1,i)(j);
                        sb(j,sb_byte)(1+(2*sb_2bit)) <= data(2,i)(j);
                    end loop;
                end loop;
            end if;

            -------------------------------------------------------------------------------
            -- to allow variables to be observed on simulation waveform (Vivado)

            debug_period  <= period;
            debug_pcount  <= pcount;
            debug_hb_byte <= hb_byte;
            debug_hb_bit  <= hb_bit;
            debug_sb_byte <= sb_byte;
            debug_sb_2bit <= sb_2bit;

            -------------------------------------------------------------------------------


        end if;
    end process;

    -------------------------------------------------------------------------------
    -- check data ECC

    process(pstb)

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

        if falling_edge(pstb) then

            ecc := x"00";
            for i in 0 to 2 loop
                ecc := hdmi_bch_ecc8(ecc, hb(i));
            end loop;
            debug_ecc(4) <= ecc;
            if ecc = hb(3) then
                hb_ok <= '1';
            else
                hb_ok <= '0';
            end if;

            for i in 0 to 3 loop
                ecc := x"00";
                for j in 0 to 6 loop
                    ecc := hdmi_bch_ecc8(ecc, sb(i,j));
                end loop;
                debug_ecc(i) <= ecc;
                if ecc = sb(i,7) then
                    sb_ok(i) <= '1';
                else
                    sb_ok(i) <= '0';
                end if;
            end loop;

        end if;

    end process;

     -------------------------------------------------------------------------------

end architecture model;

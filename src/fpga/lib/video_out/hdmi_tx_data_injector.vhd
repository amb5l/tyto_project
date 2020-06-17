--------------------------------------------------------------------------------
-- hdmi_tx_data_injector.vhd                                                  --
-- Drives HDMI encoder block to inject data islands into output video.        --
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
use xil_defaultlib.hdmi_tx_encoder_pkg.all;

entity hdmi_tx_data_injector is
    generic (
        pcm_clk_ratio   : integer                           -- PCM clock to clock enable frequency ratio e.g. 256
    );
    port (

        rst         : in    std_logic;                      -- reset (synchronous to pixel clock)
        clk         : in    std_logic;                      -- pixel clock

        dvi         : in    std_logic;                      -- DVI mode disables data injection
        vic         : in    std_logic_vector(7 downto 0);
        aspect      : in    std_logic_vector(1 downto 0);
        pix_rep     : in    std_logic;

        pcm_rst     : in    std_logic;
        pcm_clk     : in    std_logic;
        pcm_req     : in    std_logic;                      -- request (sample valid)
        pcm_ack     : out   std_logic;                      -- acknowledge
        pcm_sync    : in    std_logic;                      -- b preamble (sync)
        pcm_l       : in    std_logic_vector(23 downto 0);  -- left channel sample
        pcm_lv      : in    std_logic;                      -- left channel status
        pcm_lu      : in    std_logic;                      -- left user data
        pcm_lc      : in    std_logic;                      -- left channel status
        pcm_lp      : in    std_logic;                      -- left channel status
        pcm_r       : in    std_logic_vector(23 downto 0);  -- right channel sample
        pcm_rv      : in    std_logic;                      -- right channel status
        pcm_ru      : in    std_logic;                      -- right user data
        pcm_rc      : in    std_logic;                      -- right channel status
        pcm_rp      : in    std_logic;                      -- right channel status
        pcm_n       : in    std_logic_vector(19 downto 0);  -- ACR N value
        pcm_cts     : in    std_logic_vector(19 downto 0);  -- ACR CTS value

        in_vs       : in    std_logic;
        in_hs       : in    std_logic;
        in_vblank   : in    std_logic;
        in_hblank   : in    std_logic;
        in_p        : in    slv_7_0_t(0 to 2);
        in_ax       : in    std_logic_vector(11 downto 0);
        in_ay       : in    std_logic_vector(11 downto 0);

        out_vs      : out   std_logic;
        out_hs      : out   std_logic;
        out_de      : out   std_logic;
        out_p       : out   slv_7_0_t(0 to 2);
        out_enc     : out   std_logic_vector(1 downto 0);
        out_ctl     : out   std_logic_vector(3 downto 0);
        out_d       : out   slv_3_0_t(0 to 2)

    );
end entity hdmi_tx_data_injector;

architecture synth of hdmi_tx_data_injector is

    constant SUBPACKETS     : integer := 4; -- per packet
    constant ISLAND_TYPES   : integer := 4; -- types of island supported here

    constant CTL_NULL       : std_logic_vector(3 downto 0) := "0000";
    constant CTL_PRE_VIDEO  : std_logic_vector(3 downto 0) := "0001"; -- video period preamble
    constant CTL_PRE_DATA   : std_logic_vector(3 downto 0) := "0101"; -- data period preamble

    constant XPOS_DATA      : integer := -100; -- with respect to active region of line

    type u8 is array(natural range <>) of unsigned(7 downto 0);
    type hb_array_t is array(0 to ISLAND_TYPES-1) of u8(0 to 2);
    type pb_array_t is array(0 to ISLAND_TYPES-1) of u8(0 to 27);
    type sb_array_t is array(0 to 3) of u8(0 to 6);
    type period_t is (
            CONTROL,
            VIDEO_PRE,
            VIDEO_GB,
            VIDEO,
            DATA_PRE,
            DATA_GB_LEADING,
            DATA_ISLAND,
            DATA_GB_TRAILING
        );

    signal pcm_req_p    : std_logic;                        -- pixel clock synchronous audio sample request
    signal pcm_ack_p    : std_logic;                        -- pixel clock synchronous acknowledge of pcm_req_p
    signal pcm_count    : integer range 0 to SUBPACKETS-1;
    signal pcm_req_4    : std_logic;
    signal pcm_ack_4    : std_logic;

    signal acr_req      : std_logic;                        -- request ACR packet at 128Fs/N = 256Fs/2N
    signal acr_req_p    : std_logic;                        -- pixel clock synchronous version of above
    signal acr_ack_p    : std_logic;                        -- pixel clock synchronous acknowledge of acr_req_p
    signal acr_ack      : std_logic;                        -- pcm clock synchronouse version of above
    signal acr_count    : unsigned(pcm_n'length downto 0);

    signal hb_a         : u8(0 to 2);
    signal pb_a         : u8(0 to 27);
    signal hb           : hb_array_t;
    signal pb           : pb_array_t;

    signal s3_data      : std_logic;
    signal s3_char      : unsigned(4 downto 0);             -- data island character #
    signal s3_hb        : u8(0 to 2);                       -- current header
    signal s3_sb        : sb_array_t;                       -- current set of 4 subpackets
    signal s2_data      : std_logic;
    signal s2_char      : unsigned(s3_char'range);          -- data island character #
    signal s2_bch4      : std_logic;                        -- BCH block 4 bit
    signal s2_bch_e     : std_logic_vector(3 downto 0);     -- BCH blocks 0-3 even bit
    signal s2_bch_o     : std_logic_vector(3 downto 0);     -- BCH blocks 0-3 odd bit
    signal s1_data      : std_logic;
    signal s1_char      : unsigned(s3_char'range);          -- data island character #
    signal s1_bch4      : std_logic;                        -- BCH block 4 bit
    signal s1_bch_e     : std_logic_vector(s2_bch_e'range); -- BCH blocks 0-3 even bit
    signal s1_bch_o     : std_logic_vector(s2_bch_o'range); -- BCH blocks 0-3 odd bit
    signal s1_bch_ecc   : slv_7_0_t(0 to SUBPACKETS);

    signal period       : period_t;
    signal pcount       : unsigned(6 downto 0);

    ----------------------------------------------------------------------
    -- constant packet content

    -- packet type 0: audio clock sample packet

    constant hb_0 : u8(0 to 2) := (
            x"02",
            x"0F",
            x"00"
        );

    -- packet type 1: audio clock regeneration packet

    constant hb_1 : u8(0 to 2) := (
            x"01",
            x"00",
            x"00"
        );

    -- packet type 2: audio infoframe packet

    constant hb_2 : u8(0 to 2) := (
            x"84",
            x"01",
            x"0A"
        );

    constant pb_2 : u8(0 to 27) := (
            0 => x"70",     -- checksum 84+01+0A+01+CKS = 00
            1 => x"01",     -- CT(3:0),RSVD,CC(2:0)
            others => x"00" -- zero
        );

    -- type 3: AVI infoframe packet

    constant hb_3 : u8(0 to 2) := (
            x"82",
            x"02",
            x"0D"
        );

    constant pb_3 : u8(0 to 27) := (
            0 => x"00",     -- *NOT CONSTANT* checksum
            1 => x"12",     -- RSVD,Y(1:0),A0,B(1:0),S(1:0)
            2 => x"00",     -- *PART CONSTANT* C(1:0),M(1:0),R(3:0)
            3 => x"88",     -- ITC,EC(2:0),Q(1:0),SC(1:0)
            4 => x"00",     -- *NOT CONSTANT* VIC
            5 => x"B0",     -- *PART CONSTANT* YQ(1:0),CN(1:0),PR(3:0)
            others => x"00" -- zero
        );

    function sum( data : u8 ) return unsigned is
        variable r : unsigned(7 downto 0);
    begin
        r := x"00";
        for i in 0 to data'length-1 loop
            r := r + data(i);
        end loop;
        return r;
    end function sum;

    constant sum_3 : unsigned(7 downto 0) := sum( hb_3 & pb_3 );

    ----------------------------------------------------------------------

begin

    -- main data injection process
    process(rst,clk) is

        variable s3_hb_byte : integer range 0 to 3;
        variable s3_hb_bit  : integer range 0 to 7;
        variable s3_sb_byte : integer range 0 to 7;
        variable s3_sb_2bit : integer range 0 to 3;

        -- BCH ECC functions (see hdmi_bch_ecc.py)
        function bch_ecc_1( -- 1 bit per clock
            q : std_logic_vector(7 downto 0);
            d : std_logic
        ) return std_logic_vector is
            variable r : std_logic_vector(7 downto 0);
        begin
            r(0) := d xor q(0) xor q(1);
            r(1) := d xor q(0) xor q(2);
            r(2) := q(3);
            r(3) := q(4);
            r(4) := q(5);
            r(5) := q(6);
            r(6) := q(7);
            r(7) := d xor q(0);
            return r;
        end function bch_ecc_1;
        function bch_ecc_2( -- 2 bits per clock
            q : std_logic_vector(7 downto 0);
            d : std_logic_vector(1 downto 0)
        ) return std_logic_vector is
            variable r : std_logic_vector(7 downto 0);
        begin
            r(0) := d(1) xor q(1) xor q(2);
            r(1) := d(0) xor d(1) xor q(0) xor q(1) xor q(3);
            r(2) := q(4);
            r(3) := q(5);
            r(4) := q(6);
            r(5) := q(7);
            r(6) := d(0) xor q(0);
            r(7) := d(0) xor d(1) xor q(0) xor q(1);
            return r;
        end function bch_ecc_2;

    begin

        if rst = '1' then

            pcm_ack_p       <= '0';
            pcm_count       <= 0;
            pcm_req_4       <= '0';
            pcm_ack_4       <= '0';
            acr_ack_p       <= '0';
            hb_a            <= (others => (others => '0'));
            pb_a            <= (others => (others => '0'));
            hb              <= (others => (others => (others => '0')));
            pb              <= (others => (others => (others => '0')));

            s3_char         <= (others => '0');
            s3_hb           <= (others => (others => '0'));
            s3_sb           <= (others => (others => (others => '0')));
            s2_char         <= (others => '0');
            s2_bch4         <= '0';
            s2_bch_e        <= (others => '0');
            s2_bch_o        <= (others => '0');
            s1_char         <= (others => '0');
            s1_bch4         <= '0';
            s1_bch_e        <= (others => '0');
            s1_bch_o        <= (others => '0');
            s1_bch_ecc      <= (others => (others => '0'));

            period          <= CONTROL;
            pcount          <= (others => '0');

            out_vs          <= '0';
            out_hs          <= '0';
            out_de          <= '0';
            out_p           <= (others => (others => '0'));
            out_enc         <= ENC_DVI;
            out_ctl         <= CTL_NULL;
            out_d           <= (others => (others => '0'));

        elsif rising_edge(clk) then

            ----------------------------------------------------------------------
            -- packet contents and handshaking

            hb_a(0 to 1) <= hb_0(0 to 1);
            hb_a(2)(3 downto 0) <= hb_0(2)(3 downto 0);
            if pcm_req_p = '1' and pcm_ack_p = '0' then -- leading edge of request
                pcm_ack_p <= '1';
                hb_a(2)(pcm_count+4) <= pcm_sync;
                pb_a((pcm_count*7)+0) <= unsigned(pcm_l(7 downto 0));
                pb_a((pcm_count*7)+1) <= unsigned(pcm_l(15 downto 8));
                pb_a((pcm_count*7)+2) <= unsigned(pcm_l(23 downto 16));
                pb_a((pcm_count*7)+3) <= unsigned(pcm_r(7 downto 0));
                pb_a((pcm_count*7)+4) <= unsigned(pcm_r(15 downto 8));
                pb_a((pcm_count*7)+5) <= unsigned(pcm_r(23 downto 16));
                pb_a((pcm_count*7)+6) <=
                    pcm_rp & pcm_rc & pcm_ru & pcm_rv &
                    pcm_lp & pcm_lc & pcm_lu & pcm_lv;
                pcm_count <= (pcm_count + 1) mod 4;
                if pcm_count = 0 then
                    pcm_req_4 <= '1';
                    hb(0) <= hb_a;
                    pb(0) <= pb_a;
                end if;
            end if;

            hb(1) <= hb_1;
            pb(1) <= (others => x"00");
            for i in 0 to 3 loop
                pb(1)((i*7)+1) <= x"0" & unsigned(pcm_cts(19 downto 16));
                pb(1)((i*7)+2) <= unsigned(pcm_cts(15 downto 8));
                pb(1)((i*7)+3) <= unsigned(pcm_cts(7 downto 0));
                pb(1)((i*7)+4) <= x"0" & unsigned(pcm_n(19 downto 16));
                pb(1)((i*7)+5) <= unsigned(pcm_n(15 downto 8));
                pb(1)((i*7)+6) <= unsigned(pcm_n(7 downto 0));
            end loop;
            hb(2) <= hb_2;
            pb(2) <= pb_2;
            hb(3) <= hb_3;
            pb(3)(0 to 5) <= pb_3(0 to 5);
            pb(3)(0) <= -- checksum
                1 + not (
                    sum_3 +
                    pb(3)(2) +
                    pb(3)(4) +
                    pb(3)(5)(3 downto 0)
                );
            pb(3)(2)(5 downto 4) <= unsigned(aspect);
            pb(3)(2)(3) <= '1';
            pb(3)(2)(1 downto 0) <= unsigned(aspect);
            pb(3)(4) <= unsigned(vic);
            pb(3)(5)(0) <= pix_rep;
            pb(3)(6 to 27) <= pb_3(6 to 27);

            if pcm_req_p = '0' then
                pcm_ack_p <= '0';
            end if;
            if pcm_ack_4 = '1' then
                pcm_req_4 <= '0';
            end if;
            if pcm_req_4 = '0' then
                pcm_ack_4 <= '0';
            end if;
            if acr_req_p = '0' then
                acr_ack_p <= '0';
            end if;

           ----------------------------------------------------------------------
            -- data island pipeline

            -- stage minus 3

            s3_hb_byte  := to_integer(unsigned(s3_char(4 downto 3)));
            s3_hb_bit   := to_integer(unsigned(s3_char(2 downto 0)));
            s3_sb_byte  := to_integer(unsigned(s3_char(4 downto 2)));
            s3_sb_2bit  := to_integer(unsigned(s3_char(1 downto 0)));

            s3_char <= s3_char + 1;
            if to_integer(signed(in_ax)) = XPOS_DATA+10-3 then
                s3_char <= (others => '0');
            end if;

            if to_integer(signed(in_ax)) = XPOS_DATA+10-3 then
                s3_data <= '1';
                s3_hb <= (others => (others => '0'));
                s3_sb <= (others => (others => (others => '0')));
                if pcm_req_4 = '1' then
                    pcm_ack_4 <= '1';
                    s3_hb <= hb(0);
                    s3_sb(0) <= pb(0)(0 to 6);
                    s3_sb(1) <= pb(0)(7 to 13);
                    s3_sb(2) <= pb(0)(14 to 20);
                    s3_sb(3) <= pb(0)(21 to 27);
                end if;
            elsif to_integer(signed(in_ax)) = XPOS_DATA+10+32-3 then
                if acr_req_p = '1' then
                    acr_ack_p <= '1';
                    s3_hb <= hb(1);
                    s3_sb(0) <= pb(1)(0 to 6);
                    s3_sb(1) <= pb(1)(7 to 13);
                    s3_sb(2) <= pb(1)(14 to 20);
                    s3_sb(3) <= pb(1)(21 to 27);
                end if;
            elsif to_integer(signed(in_ax)) = XPOS_DATA+10+64-3 then
                if to_integer(signed(in_ay)) /= -1 then
                    s3_data <= '0';
                end if;
                s3_hb <= hb(2);
                s3_sb(0) <= pb(2)(0 to 6);
                s3_sb(1) <= pb(2)(7 to 13);
                s3_sb(2) <= pb(2)(14 to 20);
                s3_sb(3) <= pb(2)(21 to 27);
            elsif to_integer(signed(in_ax)) = XPOS_DATA+10+96-3 then
                s3_hb <= hb(3);
                s3_sb(0) <= pb(3)(0 to 6);
                s3_sb(1) <= pb(3)(7 to 13);
                s3_sb(2) <= pb(3)(14 to 20);
                s3_sb(3) <= pb(3)(21 to 27);
            elsif to_integer(signed(in_ax)) = XPOS_DATA+10+128-3 then
                s3_data <= '0';
            end if;

            -- stage minus 2

            s2_data <= s3_data;
            s2_char <= s3_char;
            s2_bch4 <= '0';
            if s3_hb_byte < s3_hb'length then
                s2_bch4 <= s3_hb(s3_hb_byte)(s3_hb_bit);
            end if;
            for i in 0 to 3 loop
                s2_bch_e(i) <= '0';
                s2_bch_o(i) <= '0';
                if s3_sb_byte < s3_sb(i)'length then
                    s2_bch_e(i) <= s3_sb(i)(s3_sb_byte)(0+(2*s3_sb_2bit));
                    s2_bch_o(i) <= s3_sb(i)(s3_sb_byte)(1+(2*s3_sb_2bit));
                end if;
            end loop;

            -- stage minus 1

            s1_data <= s2_data;
            s1_char <= s2_char;
            s1_bch4 <= s2_bch4;
            s1_bch_e <= s2_bch_e;
            s1_bch_o <= s2_bch_o;
            if unsigned(s2_char(4 downto 0)) = 0 then
                s1_bch_ecc(4) <= bch_ecc_1(x"00",s2_bch4);
            elsif unsigned(s2_char(4 downto 0)) < 24 then
                s1_bch_ecc(4) <= bch_ecc_1(s1_bch_ecc(4),s2_bch4);
            end if;
            for i in 0 to 3 loop
                if unsigned(s2_char(4 downto 0)) = 0 then
                    s1_bch_ecc(i) <= bch_ecc_2(x"00",s2_bch_o(i) & s2_bch_e(i));
                elsif unsigned(s2_char(4 downto 0)) < 28 then
                    s1_bch_ecc(i) <= bch_ecc_2(s1_bch_ecc(i),s2_bch_o(i) & s2_bch_e(i));
                end if;
            end loop;

            -- stage 0 / output

            out_d <= (others => (others => '0'));
            if s1_data = '1' then
                out_d(0)(0) <= in_hs;
                out_d(0)(1) <= in_vs;
                if unsigned(s1_char(4 downto 0)) < 24 then
                    out_d(0)(2) <= s1_bch4;
                else
                    out_d(0)(2) <= s1_bch_ecc(4)(to_integer(unsigned(s1_char(2 downto 0))));
                end if;
                if unsigned(s1_char) = 0 then
                    out_d(0)(3) <= '0';
                else
                    out_d(0)(3) <= '1';
                end if;
                if unsigned(s1_char(4 downto 0)) < 28 then
                    out_d(1) <= s1_bch_e;
                    out_d(2) <= s1_bch_o;
                else
                    for i in 0 to 3 loop
                        out_d(1)(i) <= s1_bch_ecc(i)(0+(2*to_integer(unsigned(s1_char(1 downto 0)))));
                        out_d(2)(i) <= s1_bch_ecc(i)(1+(2*to_integer(unsigned(s1_char(1 downto 0)))));
                    end loop;
                end if;
            end if;

            ----------------------------------------------------------------------
            -- other outputs

            out_vs  <= in_vs;
            out_hs  <= in_hs;
            out_de  <= in_vblank nor in_hblank;
            out_p   <= in_p;

            pcount <= pcount + 1;

            case period is

                when CONTROL =>
                    if in_vblank = '0' and to_integer(signed(in_ax)) = -10 then
                        period <= VIDEO_PRE;
                        pcount <= (others => '0');
                        out_ctl <= CTL_PRE_VIDEO;
                    elsif to_integer(signed(in_ax)) = XPOS_DATA then
                        period <= DATA_PRE;
                        pcount <= (others => '0');
                        out_ctl <= CTL_PRE_DATA;
                    end if;

                when VIDEO_PRE =>
                    if pcount(2 downto 0) = "111" then
                        period <= VIDEO_GB;
                        pcount <= (others => '0');
                        out_ctl <= CTL_NULL;
                        out_enc <= ENC_GB_VIDEO;
                    end if;

                when VIDEO_GB =>
                    if pcount(0) = '1' then
                        period <= VIDEO;
                        pcount <= (others => '0');
                        out_enc <= ENC_DVI;
                    end if;

                when VIDEO =>
                    if in_hblank = '1' then
                        period <= CONTROL;
                        pcount <= (others => '0');
                    end if;

                when DATA_PRE =>
                    if pcount(2 downto 0) = "111" then
                        period <= DATA_GB_LEADING;
                        pcount <= (others => '0');
                        out_ctl <= CTL_NULL;
                        out_enc <= ENC_GB_DATA;
                    end if;

                when DATA_GB_LEADING =>
                    if pcount(0) = '1' then
                        period <= DATA_ISLAND;
                        pcount <= (others => '0');
                        out_enc <= ENC_DATA;
                    end if;

                when DATA_ISLAND =>
                    if (to_integer(signed(in_ay)) = -1 and pcount(6 downto 0) = "1111111") -- 4 packets on line above active area
                    or (to_integer(signed(in_ay)) /= -1 and pcount(5 downto 0) = "111111") -- 2 packets elsewhere
                    then
                        period <= DATA_GB_TRAILING;
                        pcount <= (others => '0');
                        out_enc <= ENC_GB_DATA;
                    end if;

                when DATA_GB_TRAILING =>
                    if pcount(0) = '1' then
                        period <= CONTROL;
                        pcount <= (others => '0');
                        out_enc <= ENC_DVI;
                    end if;

            end case;

            if dvi = '1' then
                out_enc <= ENC_DVI;
                out_ctl <= (others => '0');
                out_d <= (others => (others => '0'));
            end if;

            ----------------------------------------------------------------------

        end if;

    end process;

    -- periodic ACR packet request
    process(pcm_rst,pcm_clk)
        variable acr_count_max : unsigned(pcm_n'length downto 0);
    begin
        if pcm_rst = '1' then
            acr_count <= (0 => '1', others => '0');
            acr_req <= '0';
        elsif rising_edge(pcm_clk) then
            if pcm_clk_ratio = 256 then
                acr_count_max := shift_left('0' & unsigned(pcm_n),1);
            elsif pcm_clk_ratio = 128 then
                acr_count_max := '0' & unsigned(pcm_n);
            else
                report "unsupported audio clock frequency" severity FAILURE;
            end if;
            if acr_count = acr_count_max then
                acr_count <= (0 => '1', others => '0');
                acr_req <= '1';
            else
                acr_count <= acr_count + 1;
            end if;
            if acr_ack = '1' then
                acr_req <= '0';
            end if;
        end if;
    end process;

    SYNC1: entity work.double_sync
        port map (
            rst => '0',
            clk => clk,
            d   => acr_req,
            q   => acr_req_p
        );

    SYNC2: entity work.double_sync
        port map (
            rst => '0',
            clk => pcm_clk,
            d   => acr_ack_p,
            q   => acr_ack
        );

    SYNC3: entity xil_defaultlib.double_sync
        port map (
            rst => rst,
            clk => clk,
            d   => pcm_req,
            q   => pcm_req_p
        );

    SYNC4: entity xil_defaultlib.double_sync
        port map (
            rst => '0',
            clk => pcm_clk,
            d   => pcm_ack_p,
            q   => pcm_ack
        );

end architecture synth;

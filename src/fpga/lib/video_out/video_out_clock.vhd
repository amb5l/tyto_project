--------------------------------------------------------------------------------
-- video_out_clock.vhd                                                        --
-- Pixel and serialiser clock synthesiser (dynamically configured MMCM).      --
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

package video_out_clock_pkg is

    component video_out_clock is
        port (

            rsti        : in    std_logic;                      -- reset
            clki        : in    std_logic;                      -- reference clock
            sys_rst     : in    std_logic;                      -- system clock synchronous reset
            sys_clk     : in    std_logic;                      -- system clock e.g. 100MHz

            sel         : in    std_logic_vector(1 downto 0);   -- output clock select: 00 = 25.2, 01 = 27.0, 10 = 74.25, 11 = 148.5
            rsto        : out   std_logic;                      -- output clock synchronous reset
            clko        : out   std_logic;                      -- pixel clock
            clko_x5     : out   std_logic                       -- serialiser clock (5x pixel clock)

        );
    end component video_out_clock;

end package video_out_clock_pkg;

----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library xpm;
use xpm.vcomponents.all;

library unisim;
use unisim.vcomponents.all;

entity video_out_clock is
    port (

        rsti        : in    std_logic;                      -- reset
        clki        : in    std_logic;                      -- reference clock
        sys_rst     : in    std_logic;                      -- system clock synchronous reset
        sys_clk     : in    std_logic;                      -- system clock e.g. 100MHz

        sel         : in    std_logic_vector(1 downto 0);   -- output clock select: 00 = 25.2, 01 = 27.0, 10 = 74.25, 11 = 148.5
        rsto        : out   std_logic;                      -- output clock synchronous reset
        clko        : out   std_logic;                      -- pixel clock
        clko_x5     : out   std_logic                       -- serialiser clock (5x pixel clock)

    );
end entity video_out_clock;

architecture synth of video_out_clock is

    signal sel_s        : std_logic_vector(1 downto 0);     -- sel, synchronised to sys_clk

    signal rsto_req     : std_logic;                        -- rsto request, synchronous to sys_clk

    signal mmcm_rst      : std_logic;                       -- MMCM reset
    signal locked       : std_logic;                        -- MMCM locked output
    signal locked_s     : std_logic;                        -- above, synchronised to sys_clk

    signal sel_prev     : std_logic_vector(1 downto 0);     -- to detect changes
    signal clk_fb       : std_logic;                        -- feedback clock
    signal clku_fb      : std_logic;                        -- unbuffered feedback clock
    signal clko_u       : std_logic;                        -- unbuffered pixel clock
    signal clko_u_x5    : std_logic;                        -- unbuffered serializer clock

    signal cfg_tbl_addr : std_logic_vector(6 downto 0);     -- 4 x 32 entries
    signal cfg_tbl_data : std_logic_vector(39 downto 0);    -- 8 bit address + 16 bit write data + 16 bit read mask

    signal cfg_rst      : std_logic;                        -- DRP reset
    signal cfg_daddr    : std_logic_vector(6 downto 0);     -- DRP register address
    signal cfg_den      : std_logic;                        -- DRP enable (pulse)
    signal cfg_dwe      : std_logic;                        -- DRP write enable
    signal cfg_di       : std_logic_vector(15 downto 0);    -- DRP write data
    signal cfg_do       : std_logic_vector(15 downto 0);    -- DRP read data
    signal cfg_drdy     : std_logic;                        -- DRP access complete

    type cfg_state_t is ( -- state machine states
        IDLE,       -- waiting for fsel change
        RESET,      -- put MMCM into reset
        TBL,        -- get first/next table value
        RD,         -- start read
        RD_WAIT,    -- wait for read to complete
        WR,         -- start write
        WR_WAIT,    -- wait for write to complete
        LOCK_WAIT   -- wait for reconfig to complete
        );
    signal cfg_state    : cfg_state_t;

begin

    process(sys_clk)

        -- contents of synchronous ROM table
        function cfg_tbl (addr : std_logic_vector) return std_logic_vector is
            -- bits 39..32 = cfg_daddr (MSB = 1 for last entry)
            -- bits 31..16 = cfg write data
            -- bits 15..0 = cfg read mask
            variable data : std_logic_vector(39 downto 0);
        begin
            -- values below pasted in from video_out_clk.xls
            case '0' & addr is
                when x"00" => data := x"06" & x"1145" & x"1000";
                when x"01" => data := x"07" & x"0000" & x"8000";
                when x"02" => data := x"08" & x"1083" & x"1000";
                when x"03" => data := x"09" & x"0080" & x"8000";
                when x"04" => data := x"0A" & x"130d" & x"1000";
                when x"05" => data := x"0B" & x"0080" & x"8000";
                when x"06" => data := x"0C" & x"1145" & x"1000";
                when x"07" => data := x"0D" & x"0000" & x"8000";
                when x"08" => data := x"0E" & x"1145" & x"1000";
                when x"09" => data := x"0F" & x"0000" & x"8000";
                when x"0A" => data := x"10" & x"1145" & x"1000";
                when x"0B" => data := x"11" & x"0000" & x"8000";
                when x"0C" => data := x"12" & x"1145" & x"1000";
                when x"0D" => data := x"13" & x"3000" & x"8000";
                when x"0E" => data := x"14" & x"13CF" & x"1000";
                when x"0F" => data := x"15" & x"4800" & x"8000";
                when x"10" => data := x"16" & x"0083" & x"C000";
                when x"11" => data := x"18" & x"002C" & x"FC00";
                when x"12" => data := x"19" & x"7C01" & x"8000";
                when x"13" => data := x"1A" & x"7DE9" & x"8000";
                when x"14" => data := x"28" & x"FFFF" & x"0000";
                when x"15" => data := x"4E" & x"0900" & x"66FF";
                when x"16" => data := x"CF" & x"1000" & x"666F";
                when x"20" => data := x"06" & x"1145" & x"1000";
                when x"21" => data := x"07" & x"0000" & x"8000";
                when x"22" => data := x"08" & x"10C4" & x"1000";
                when x"23" => data := x"09" & x"0080" & x"8000";
                when x"24" => data := x"0A" & x"1452" & x"1000";
                when x"25" => data := x"0B" & x"0080" & x"8000";
                when x"26" => data := x"0C" & x"1145" & x"1000";
                when x"27" => data := x"0D" & x"0000" & x"8000";
                when x"28" => data := x"0E" & x"1145" & x"1000";
                when x"29" => data := x"0F" & x"0000" & x"8000";
                when x"2A" => data := x"10" & x"1145" & x"1000";
                when x"2B" => data := x"11" & x"0000" & x"8000";
                when x"2C" => data := x"12" & x"1145" & x"1000";
                when x"2D" => data := x"13" & x"2800" & x"8000";
                when x"2E" => data := x"14" & x"15D7" & x"1000";
                when x"2F" => data := x"15" & x"2800" & x"8000";
                when x"30" => data := x"16" & x"0083" & x"C000";
                when x"31" => data := x"18" & x"00FA" & x"FC00";
                when x"32" => data := x"19" & x"7C01" & x"8000";
                when x"33" => data := x"1A" & x"7DE9" & x"8000";
                when x"34" => data := x"28" & x"FFFF" & x"0000";
                when x"35" => data := x"4E" & x"1900" & x"66FF";
                when x"36" => data := x"CF" & x"0100" & x"666F";
                when x"40" => data := x"06" & x"1145" & x"1000";
                when x"41" => data := x"07" & x"0000" & x"8000";
                when x"42" => data := x"08" & x"1041" & x"1000";
                when x"43" => data := x"09" & x"0000" & x"8000";
                when x"44" => data := x"0A" & x"1145" & x"1000";
                when x"45" => data := x"0B" & x"0000" & x"8000";
                when x"46" => data := x"0C" & x"1145" & x"1000";
                when x"47" => data := x"0D" & x"0000" & x"8000";
                when x"48" => data := x"0E" & x"1145" & x"1000";
                when x"49" => data := x"0F" & x"0000" & x"8000";
                when x"4A" => data := x"10" & x"1145" & x"1000";
                when x"4B" => data := x"11" & x"0000" & x"8000";
                when x"4C" => data := x"12" & x"1145" & x"1000";
                when x"4D" => data := x"13" & x"2400" & x"8000";
                when x"4E" => data := x"14" & x"1491" & x"1000";
                when x"4F" => data := x"15" & x"1800" & x"8000";
                when x"50" => data := x"16" & x"0083" & x"C000";
                when x"51" => data := x"18" & x"00FA" & x"FC00";
                when x"52" => data := x"19" & x"7C01" & x"8000";
                when x"53" => data := x"1A" & x"7DE9" & x"8000";
                when x"54" => data := x"28" & x"FFFF" & x"0000";
                when x"55" => data := x"4E" & x"0900" & x"66FF";
                when x"56" => data := x"CF" & x"1000" & x"666F";
                when x"60" => data := x"06" & x"1145" & x"1000";
                when x"61" => data := x"07" & x"0000" & x"8000";
                when x"62" => data := x"08" & x"1041" & x"1000";
                when x"63" => data := x"09" & x"00C0" & x"8000";
                when x"64" => data := x"0A" & x"1083" & x"1000";
                when x"65" => data := x"0B" & x"0080" & x"8000";
                when x"66" => data := x"0C" & x"1145" & x"1000";
                when x"67" => data := x"0D" & x"0000" & x"8000";
                when x"68" => data := x"0E" & x"1145" & x"1000";
                when x"69" => data := x"0F" & x"0000" & x"8000";
                when x"6A" => data := x"10" & x"1145" & x"1000";
                when x"6B" => data := x"11" & x"0000" & x"8000";
                when x"6C" => data := x"12" & x"1145" & x"1000";
                when x"6D" => data := x"13" & x"2400" & x"8000";
                when x"6E" => data := x"14" & x"1491" & x"1000";
                when x"6F" => data := x"15" & x"1800" & x"8000";
                when x"70" => data := x"16" & x"0083" & x"C000";
                when x"71" => data := x"18" & x"00FA" & x"FC00";
                when x"72" => data := x"19" & x"7C01" & x"8000";
                when x"73" => data := x"1A" & x"7DE9" & x"8000";
                when x"74" => data := x"28" & x"FFFF" & x"0000";
                when x"75" => data := x"4E" & x"0900" & x"66FF";
                when x"76" => data := x"CF" & x"1000" & x"666F";
                when others => data := (others => '0');
            end case;
            return data;
        end function cfg_tbl;

    begin
        if rising_edge(sys_clk) then

            cfg_tbl_data <= cfg_tbl(cfg_tbl_addr); -- synchronous ROM

            -- defaults
            cfg_den <= '0';
            cfg_dwe <= '0';

            -- state machine
            case cfg_state is
                when IDLE =>
                    if sel /= sel_prev  -- frequency selection has changed
                    or locked_s = '0'       -- lock lost
                    then
                        rsto_req <= '1';
                        cfg_rst <= '1';
                        cfg_state <= RESET;
                    end if;
                when RESET => -- put MMCM into reset
                    sel_prev <= sel;
                    cfg_tbl_addr <= sel & "00000";
                    cfg_state <= TBL;
                when TBL => -- get table entry from sychronous ROM
                    cfg_state <= RD;
                when RD => -- read specified register
                    cfg_daddr <= cfg_tbl_data(38 downto 32);
                    cfg_den <= '1';
                    cfg_state <= RD_WAIT;
                when RD_WAIT => -- wait for read to complete
                    if cfg_drdy = '1' then
                        cfg_di <= (cfg_do and cfg_tbl_data(15 downto 0))
                            or (cfg_tbl_data(31 downto 16) and not cfg_tbl_data(15 downto 0));
                        cfg_den <= '1';
                        cfg_dwe <= '1';
                        cfg_state <= WR;
                    end if;
                when WR => -- write modified contents back to same register
                    cfg_state <= WR_WAIT;
                when WR_WAIT => -- wait for write to complete
                    if cfg_drdy = '1' then
                        if cfg_tbl_data(39) = '1' then -- last entry in table
                            cfg_tbl_addr <= (others => '0');
                            cfg_state <= LOCK_WAIT;
                        else -- do next entry in table
                            cfg_tbl_addr(4 downto 0) <= std_logic_vector(unsigned(cfg_tbl_addr(4 downto 0)) + 1);
                            cfg_state <= TBL;
                        end if;
                    end if;
                when LOCK_WAIT => -- wait for MMCM to lock
                    cfg_rst <= '0';
                    if locked_s = '1' then -- all done
                        cfg_state <= IDLE;
                        rsto_req <= '0';
                    end if;
            end case;

            if sys_rst = '1' then -- full reset

                sel_prev    <= (others => '0');
                cfg_rst     <= '1';
                cfg_daddr   <= (others => '0');
                cfg_den     <= '0';
                cfg_dwe     <= '0';
                cfg_di      <= (others => '0');
                cfg_state   <= RESET;

                rsto_req   <= '1';

            end if;

        end if;
    end process;

    -- clock domain crossing

    SYNC1 : xpm_cdc_array_single
        generic map (
            DEST_SYNC_FF    => 2,
            INIT_SYNC_FF    => 1,
            SIM_ASSERT_CHK  => 1,
            SRC_INPUT_REG   => 0,
            WIDTH           => 3
        )
        port map (
            src_clk     => '0',
            src_in(0)   => locked,
            src_in(1)   => sel(0),
            src_in(2)   => sel(1),
            dest_clk    => sys_clk,
            dest_out(0) => locked_s,
            dest_out(1) => sel_s(0),
            dest_out(2) => sel_s(1)
        );

    SYNC2 : xpm_cdc_array_single
        generic map (
            DEST_SYNC_FF    => 2,
            INIT_SYNC_FF    => 1,
            SIM_ASSERT_CHK  => 1,
            SRC_INPUT_REG   => 0,
            WIDTH           => 1
        )
        port map (
            src_clk     => '0',
            src_in(0)   => rsto_req or not locked or cfg_rst or rsti,
            dest_clk    => clko,
            dest_out(0) => rsto
        );

    mmcm_rst <= cfg_rst or rsti;

    -- defaults: clk_s = 371.25MHz, clko = 74.25MHz (for clki = 100MHz)
    MMCM: mmcme2_adv
    generic map(
        bandwidth               => "OPTIMIZED",
        clkfbout_mult_f         => 37.125,
        clkfbout_phase          => 0.0,
        clkfbout_use_fine_ps    => false,
        clkin1_period           => 10.0,
        clkin2_period           => 0.0,
        clkout0_divide_f        => 2.0,
        clkout0_duty_cycle      => 0.5,
        clkout0_phase           => 0.0,
        clkout0_use_fine_ps     => false,
        clkout1_divide          => 10,
        clkout1_duty_cycle      => 0.5,
        clkout1_phase           => 0.0,
        clkout1_use_fine_ps     => false,
        clkout2_divide          => 1,
        clkout2_duty_cycle      => 0.5,
        clkout2_phase           => 0.0,
        clkout2_use_fine_ps     => false,
        clkout3_divide          => 1,
        clkout3_duty_cycle      => 0.5,
        clkout3_phase           => 0.0,
        clkout3_use_fine_ps     => false,
        clkout4_cascade         => false,
        clkout4_divide          => 1,
        clkout4_duty_cycle      => 0.5,
        clkout4_phase           => 0.0,
        clkout4_use_fine_ps     => false,
        clkout5_divide          => 1,
        clkout5_duty_cycle      => 0.5,
        clkout5_phase           => 0.0,
        clkout5_use_fine_ps     => false,
        clkout6_divide          => 1,
        clkout6_duty_cycle      => 0.5,
        clkout6_phase           => 0.0,
        clkout6_use_fine_ps     => false,
        compensation            => "ZHOLD",
        divclk_divide           => 5,
        is_clkinsel_inverted    => '0',
        is_psen_inverted        => '0',
        is_psincdec_inverted    => '0',
        is_pwrdwn_inverted      => '0',
        is_rst_inverted         => '0',
        ref_jitter1             => 0.01,
        ref_jitter2             => 0.01,
        ss_en                   => "FALSE",
        ss_mode                 => "CENTER_HIGH",
        ss_mod_period           => 10000,
        startup_wait            => false
    )
    port map (
        pwrdwn          => '0',
        rst             => mmcm_rst,
        locked          => locked,
        clkin1          => clki,
        clkin2          => '0',
        clkinsel        => '1',
        clkinstopped    => open,
        clkfbin         => clk_fb,
        clkfbout        => clku_fb,
        clkfboutb       => open,
        clkfbstopped    => open,
        clkout0         => clko_u_x5,
        clkout0b        => open,
        clkout1         => clko_u,
        clkout1b        => open,
        clkout2         => open,
        clkout2b        => open,
        clkout3         => open,
        clkout3b        => open,
        clkout4         => open,
        clkout5         => open,
        clkout6         => open,
        dclk            => sys_clk,
        daddr           => cfg_daddr,
        den             => cfg_den,
        dwe             => cfg_dwe,
        di              => cfg_di,
        do              => cfg_do,
        drdy            => cfg_drdy,
        psclk           => '0',
        psdone          => open,
        psen            => '0',
        psincdec        => '0'
    );

    U_BUFG_0: unisim.vcomponents.bufg
        port map (
            I   => clko_u_x5,
            O   => clko_x5
        );

    U_BUFG_1: unisim.vcomponents.bufg
        port map (
            I   => clko_u,
            O   => clko
        );

    U_BUFG_F: unisim.vcomponents.bufg
        port map (
            I   => clku_fb,
            O   => clk_fb
        );

end architecture synth;

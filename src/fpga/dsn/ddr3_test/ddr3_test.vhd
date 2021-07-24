--------------------------------------------------------------------------------
-- ddr3_test.vhd                                                              --
-- DDR3 test based on  Joris van Rantwijk's Pseudo Random Number Generator.   --
-- See https://github.com/jorisvr/vhdl_prng                                   --
--------------------------------------------------------------------------------
-- (C) Copyright 2021 Adam Barnes <ambarnes@gmail.com>                        --
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

entity ddr3_test is
    port (

        clk_100m    : in   std_logic;
        rst_100m    : in   std_logic;

        ctrl_run    : in    std_logic;                      -- 1 = run, 0 = halt
        ctrl_slow   : in    std_logic;                      -- 1 = run once per second, 0 = run as fast as possible
        ctrl_size   : in    std_logic_vector(4 downto 0);   -- 00100 (4) = 16 Bytes, 00101 = 32 Bytes... 11101 (29) = 512MBytes
        stat_run    : out   std_logic;                      -- toggles once per test
        stat_passes : out   std_logic_vector(31 downto 0);  -- pass count
        stat_errors : out   std_logic_vector(31 downto 0);  -- error count

        ui_cc       : in    std_logic;
        ui_rdy      : in    std_logic;
        ui_en       : out   std_logic;
        ui_r_w      : out   std_logic;
        ui_a        : out   std_logic_vector(28 downto 4);
        ui_wrdy     : in    std_logic;
        ui_we       : out   std_logic;
        ui_wbe      : out   std_logic_vector(15 downto 0);
        ui_wd       : out   std_logic_vector(127 downto 0);
        ui_rd       : in    std_logic_vector(127 downto 0);
        ui_rstb     : in    std_logic

    );
end entity ddr3_test;

architecture synth of ddr3_test is

    type slv_127_0_t is array(natural range <>) of std_logic_vector(127 downto 0);

    constant INIT_SEED : slv_127_0_t := (
            x"0123456789ABCDEF0123456789ABCDEF",
            x"123456789ABCDEF0123456789ABCDEF0",
            x"23456789ABCDEF0123456789ABCDEF01",
            x"3456789ABCDEF0123456789ABCDEF012"
        );
    
    signal test_size    : std_logic_vector(31 downto 0);
    signal test_end     : std_logic_vector(31 downto 0);
    signal pulse_second : std_logic;
    signal count_second : integer range 0 to 99999999;
    signal prng_reseed  : std_logic;
    signal prng_seed    : slv_127_0_t(0 to 3);
    signal prng_ok      : std_logic_vector(0 to 3);
    signal prng_en      : std_logic;
    signal prng_d       : std_logic_vector(127 downto 0);
    signal ui_rstb_1    : std_logic;
    signal compare      : std_logic_vector(127 downto 0);
    signal errors_found : boolean;
    signal count_data   : std_logic_vector(28 downto 4);

    type state_t is (
        INIT,
        WRITE,
        WRITE_PAUSE,
        WRITE_AFTER,
        READ,
        READ_AFTER,
        FINALE
    );
    signal state : state_t;

begin

    test_size <= std_logic_vector(shift_left(to_unsigned(1,32),to_integer(unsigned(ctrl_size))));
    test_end <= std_logic_vector(unsigned(test_size)-1);
    ui_wbe <= (others => '1');

    process(clk_100m)
    begin
        if rising_edge(clk_100m) then

            pulse_second <= '0';
            count_second <= count_second + 1;
            if count_second = 99999999 then
                count_second <= 0;
                pulse_second <= '1';
            end if;

            prng_reseed <= '0'; -- default

            case state is

                when INIT =>
                    if ui_cc = '1' and prng_ok = "1111" and ctrl_run = '1' and (ctrl_slow = '0' or pulse_second = '1') then
                        state <= WRITE;
                        ui_en <= '1';
                        ui_r_w <= '0';
                        ui_a <= (others => '0');
                        ui_we <= '1';
                        errors_found <= false;
                    end if;

                when WRITE =>
                    if ui_rdy = '0' or ui_wrdy = '0' then
                        state <= WRITE_PAUSE;
                        ui_en <= not ui_rdy;
                        ui_we <= not ui_wrdy;
                    else
                        ui_a <= std_logic_vector(unsigned(ui_a)+1);
                        if ui_a = test_end(28 downto 4) then
                            state <= WRITE_AFTER;
                            ui_en <= '0';
                            ui_a <= (others => '0');
                            ui_we <= '0';
                            prng_reseed <= '1';
                        end if;
                    end if;

                when WRITE_PAUSE =>
                    if (ui_en = '0' and ui_wrdy = '1') or (ui_we = '0' and ui_rdy = '1') or (ui_rdy = '1' and ui_wrdy = '1') then
                        state <= WRITE;
                        ui_en <= '1';
                        ui_we <= '1';
                        ui_a <= std_logic_vector(unsigned(ui_a)+1);
                        if ui_a = test_end(28 downto 4) then
                            state <= WRITE_AFTER;
                            ui_en <= '0';
                            ui_a <= (others => '0');
                            ui_we <= '0';
                            prng_reseed <= '1';
                        end if;
                    end if;

                when WRITE_AFTER =>
                    if prng_ok = "1111" then
                        state <= READ;
                        ui_en <= '1';
                        ui_r_w <= '1';
                        ui_a <= (others => '0');
                        count_data <= (others => '0');
                    end if;

                when READ =>
                    if ui_rdy = '1' then
                        ui_a <= std_logic_vector(unsigned(ui_a)+1);
                        if ui_a = test_end(28 downto 4) then
                            state <= READ_AFTER;
                            ui_en <= '0';
                            ui_r_w <= '0';
                            ui_a <= (others => '0');
                        end if;
                    end if;
                    if ui_rstb = '1' then
                        count_data <= std_logic_vector(unsigned(count_data)+1);
                    end if;

                when READ_AFTER =>
                    if ui_rstb = '1' then
                        count_data <= std_logic_vector(unsigned(count_data)+1);
                        if count_data = test_end(28 downto 4) then
                            state <= FINALE;
                            prng_reseed <= '1';
                            prng_seed(0) <= prng_d;
                            prng_seed(1) <= prng_d(123 downto 0) & prng_d(127 downto 124);
                            prng_seed(2) <= prng_d(119 downto 0) & prng_d(127 downto 120);
                            prng_seed(3) <= prng_d(115 downto 0) & prng_d(127 downto 116);
                        end if;
                    end if;

                when FINALE =>
                    if ui_rstb_1 = '0' and prng_ok = "1111" and ctrl_run = '1' and (ctrl_slow = '0' or pulse_second = '1') then
                        if not errors_found then
                            stat_passes <= std_logic_vector(unsigned(stat_passes)+1);
                        end if;  
                        state <= WRITE;
                        ui_en <= '1';
                        ui_r_w <= '0';
                        ui_a <= (others => '0');
                        ui_we <= '1';
                        count_data <= (others => '0');
                        errors_found <= false;
                        stat_run <= not stat_run;
                    end if;
        
            end case;

            if ui_rstb = '1' then
                compare <= ui_rd xor prng_d;
            end if;
            ui_rstb_1 <= ui_rstb;
            if ui_rstb_1 = '1' then
                if compare /= x"00000000000000000000000000000000" then
                    stat_errors <= std_logic_vector(unsigned(stat_errors)+1);
                    errors_found <= true;
                end if;
            end if;

            if rst_100m = '1' then
                pulse_second <= '0';
                count_second <= 0;
                ui_en <= '0';
                ui_r_w <= '0';
                ui_a <= (others => '0');
                ui_we <= '0';
                prng_reseed <= '1';
                prng_seed <= INIT_SEED;
                ui_rstb_1 <= '0';
                compare <= (others => '0');
                errors_found <= false;
                count_data <= (others => '0');
                stat_run <= '1';
                stat_errors <= (others => '0');
                stat_passes <= (others => '0');
                state <= INIT;
            end if;

        end if;
    end process;

    ui_wd <= prng_d when state = WRITE or state = WRITE_PAUSE else (others => '0');

    prng_en <= '1' when
        (state = WRITE and ui_rdy = '1' and ui_wrdy = '1') or
        (state = WRITE_PAUSE and ((ui_en = '0' and ui_wrdy = '1') or (ui_we = '0' and ui_rdy = '1') or (ui_rdy = '1' and ui_wrdy = '1'))) or
        (ui_rstb = '1')
        else '0';

    GEN_PRNG: for i in 0 to 3 generate
        PRNG: entity xil_defaultlib.rng_xoshiro128plusplus
            generic map (
                init_seed   => INIT_SEED(i),
                pipeline    => true
            )
            port map (
                clk         => clk_100m,
                rst         => rst_100m,
                reseed      => prng_reseed,
                newseed     => prng_seed(i),
                out_ready   => prng_en,
                out_valid   => prng_ok(i),
                out_data    => prng_d(31+(i*32) downto i*32)
            );
    end generate;

end architecture synth;

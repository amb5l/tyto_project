--------------------------------------------------------------------------------
-- mig_bridge_crtc.vhd                                                        --
-- Drives MIG UI to fetch pixels for CRTC.                                    --
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

library work;
use work.global_pkg.all;

package mig_bridge_crtc_pkg is

    component mig_bridge_crtc is
        generic (
            base_addr       : integer;
            size_log2       : integer
        );
        port (

            crtc_clk        : in    std_logic;
            crtc_rst        : in    std_logic;
            crtc_llen       : in    std_logic_vector(10 downto 6); -- line length (multiple of 64 pixels)
            crtc_vs         : in    std_logic;
            crtc_hs         : in    std_logic;
            crtc_vblank     : in    std_logic;
            crtc_hblank     : in    std_logic;
            crtc_r          : out   std_logic_vector(7 downto 0);
            crtc_g          : out   std_logic_vector(7 downto 0);
            crtc_b          : out   std_logic_vector(7 downto 0);

            mig_clk         : in    std_logic;
            mig_rst         : in    std_logic;
            mig_awvalid     : out   std_logic;
            mig_awready     : in    std_logic;
            mig_r_w         : out   std_logic;
            mig_addr        : out   std_logic_vector(addr_width_log2+data_width_log2-1 downto data_width_log2);
            mig_wdata       : out   std_logic_vector(2**(data_width_log2+3)-1 downto 0);
            mig_wbe         : out   std_logic_vector(2**data_width_log2-1 downto 0);
            mig_rdata       : in    std_logic_vector(2**(data_width_log2+3)-1 downto 0);
            mig_rvalid      : in    std_logic;
            mig_rready      : out   std_logic;

            fifo_underflow  : out   std_logic;
            fifo_overflow   : out   std_logic

        );
    end component mig_bridge_crtc;

end package mig_bridge_crtc_pkg;

----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

library xpm;
use xpm.vcomponents.all;

library work;
use work.global_pkg.all;

entity mig_bridge_crtc is
    generic (
        base_addr       : integer;
        size_log2       : integer
    );
    port (

        crtc_clk        : in    std_logic;
        crtc_rst        : in    std_logic;
        crtc_llen       : in    std_logic_vector(4 downto 0); -- line length (multiple of 64 pixels)
        crtc_vs         : in    std_logic;
        crtc_hs         : in    std_logic;
        crtc_vblank     : in    std_logic;
        crtc_hblank     : in    std_logic;
        crtc_r          : out   std_logic_vector(7 downto 0);
        crtc_g          : out   std_logic_vector(7 downto 0);
        crtc_b          : out   std_logic_vector(7 downto 0);

        mig_clk         : in    std_logic;
        mig_rst         : in    std_logic;
        mig_awvalid     : out   std_logic;
        mig_awready     : in    std_logic;
        mig_r_w         : out   std_logic;
        mig_addr        : out   std_logic_vector(addr_width_log2+data_width_log2-1 downto data_width_log2);
        mig_wdata       : out   std_logic_vector(2**(data_width_log2+3)-1 downto 0);
        mig_wbe         : out   std_logic_vector(2**data_width_log2-1 downto 0);
        mig_rdata       : in    std_logic_vector(2**(data_width_log2+3)-1 downto 0);
        mig_rvalid      : in    std_logic;
        mig_rready      : out   std_logic;

        fifo_underflow  : out   std_logic;
        fifo_overflow   : out   std_logic

    );
end entity mig_bridge_crtc;

architecture synth of mig_bridge_crtc is

    constant base_addr_v : std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(base_addr,32));
    constant ratio : integer := 2**(data_width_log2-2); -- ratio of MIG UI data width (e.g. 128 bits) to pixel width (32 bits)

    signal crtc_lreq        : std_logic;
    signal crtc_lreq_s      : std_logic_vector(0 to 1);
    signal crtc_vs_s        : std_logic_vector(0 to 1);

    signal fifo_ef          : std_logic;
    signal fifo_aff         : std_logic;
    signal fifo_wdata       : std_logic_vector(ratio*24-1 downto 0);
    signal fifo_wcount      : std_logic_vector(13-data_width_log2 downto 0);
    signal fifo_rcount      : std_logic_vector(11 downto 0);

    type state_cmd_t is (IDLE, BUSY);
    signal state_cmd        : state_cmd_t;
    signal count            : std_logic_vector(crtc_llen'range);

begin

    mig_r_w <= '1';
    mig_wdata <= (others => '0');
    mig_wbe <= (others => '0');

    crtc_lreq <= crtc_hs and not crtc_vblank; -- request a line of pixels

    SYNC : xpm_cdc_array_single
        generic map (
            dest_sync_ff    => 2,
            init_sync_ff    => 1,
            sim_assert_chk  => 1,
            src_input_reg   => 0,
            width           => 2
        )
        port map (
            src_clk                => crtc_clk,
            src_in(1)              => crtc_vs,
            src_in(0)              => crtc_lreq,
            dest_clk               => mig_clk,
            dest_out(1)            => crtc_vs_s(0),
            dest_out(0)            => crtc_lreq_s(0)
        );

    process(mig_clk)
    begin
        if rising_edge(mig_clk) then

            crtc_lreq_s(1) <= crtc_lreq_s(0);
            crtc_vs_s(1) <= crtc_vs_s(0);

            case state_cmd is

                when IDLE =>
                    if crtc_lreq_s(0) = '1' and crtc_lreq_s(1) = '0' then
                        state_cmd <= BUSY;
                        count <= (others => '0');
                        mig_awvalid <= '1';
                    end if;

                when BUSY =>
                    if mig_awready = '1' then
                        mig_addr(size_log2-1 downto data_width_log2) <= std_logic_vector(unsigned(mig_addr(size_log2-1 downto data_width_log2))+1);
                        if to_integer(signed(mig_addr(7 downto data_width_log2))) = -1 then -- completed 64 pixel chunk
                            count <= std_logic_vector(unsigned(count)+1);                            
                            if count = std_logic_vector(unsigned(crtc_llen)-1) then -- completed line
                                state_cmd <= IDLE;
                                count <= (others => '0');
                                mig_awvalid <= '0';
                            end if;
                        end if;
                    end if;

            end case;

            if crtc_vs_s(0) = '1' and crtc_vs_s(1) = '0' then
                mig_addr <= base_addr_v(mig_addr'range);
            end if;

            if mig_rst = '1' or crtc_vs_s(0) = '1' then
                state_cmd <= IDLE;
                count <= (others => '0');
                mig_awvalid <= '0';
            end if;

        end if;
    end process;

    GEN_FIFO_WDATA: for i in 0 to ratio-1 generate
        fifo_wdata(23+(i*24) downto i*24) <= mig_rdata(23+(i*32) downto i*32);
    end generate GEN_FIFO_WDATA;

    FIFO: xpm_fifo_async
        generic map (
            CDC_SYNC_STAGES     => 2,
            DOUT_RESET_VALUE    => "0",
            ECC_MODE            => "no_ecc",
            FIFO_MEMORY_TYPE    => "auto",
            FIFO_READ_LATENCY   => 0,
            FIFO_WRITE_DEPTH    => 2048/ratio,          -- enough for 2k pixels,
            FULL_RESET_VALUE    => 0,
            PROG_EMPTY_THRESH   => 16,
            PROG_FULL_THRESH    => 16,
            RD_DATA_COUNT_WIDTH => 12,                  -- 2k pixels
            READ_DATA_WIDTH     => 24,
            READ_MODE           => "fwft",
            RELATED_CLOCKS      => 0,
            SIM_ASSERT_CHK      => 0,
            USE_ADV_FEATURES    => "0101",              -- underflow, overflow
            WAKEUP_TIME         => 0,
            WRITE_DATA_WIDTH    => fifo_wdata'length,
            WR_DATA_COUNT_WIDTH => 14-data_width_log2   -- e.g. 10 c.w. 512 bursts of 4 pixels
        )
        port map (

            rst                 => mig_rst or crtc_vs_s(0),

            sbiterr             => open,
            dbiterr             => open,
            injectdbiterr       => '0',
            injectsbiterr       => '0',
            sleep               => '0',

            wr_clk              => mig_clk,
            wr_rst_busy         => open,
            wr_data_count       => fifo_wcount,
            wr_en               => mig_rvalid,
            wr_ack              => open,
            din                 => fifo_wdata,

            rd_clk              => crtc_clk,
            rd_rst_busy         => open,
            rd_data_count       => fifo_rcount,
            data_valid          => open,
            rd_en               => crtc_vblank nor crtc_hblank,
            dout(7 downto 0)    => crtc_r,
            dout(15 downto 8)   => crtc_g,
            dout(23 downto 16)  => crtc_b,

            empty               => fifo_ef,
            almost_empty        => open,
            prog_empty          => open,
            prog_full           => open,
            almost_full         => open,
            full                => open,

            underflow           => fifo_underflow,
            overflow            => fifo_overflow

        );

end architecture synth;

--------------------------------------------------------------------------------
-- model_mig.vhd                                                              --
-- Simple model of MIG IP core user interface.                                --
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

library work;

entity model_mig is
    generic (
        clk_period      : time := 10ns;
        data_width_log2 : integer;      -- 4 => 2^4 => 16 bytes
        addr_width_log2 : integer;      -- 25 => 2^25 * 16 = 512MBytes
        sim_mem_log2    : integer       -- 19 => 2^19 * 16 = 8MBytes
    );
    port (
        xrst            : in    std_logic;
        clk             : out   std_logic;
        rst             : out   std_logic;
        mig_cc          : out   std_logic;
        mig_avalid      : in    std_logic;
        mig_r_w         : in    std_logic;
        mig_addr        : in    std_logic_vector(addr_width_log2+data_width_log2-1 downto data_width_log2);
        mig_aready      : out   std_logic;
        mig_wvalid      : in    std_logic;
        mig_wdata       : in    std_logic_vector(2**(data_width_log2+3)-1 downto 0);
        mig_wbe         : in    std_logic_vector(2**data_width_log2-1 downto 0);
        mig_wready      : out   std_logic;
        mig_rdata       : out   std_logic_vector(2**(data_width_log2+3)-1 downto 0);
        mig_raddr       : out   std_logic_vector(addr_width_log2+data_width_log2-1 downto data_width_log2);
        mig_rvalid      : out   std_logic
    );
end entity model_mig;

-- assumption: user interface width matches burst size
-- latency is incurred except for back to back cycles to adjacent addresses

architecture model of model_mig is

    constant fifo_size_cmd   : integer  := 64;
    constant fifo_size_write : integer  := 64;
    constant latency_write   : integer  := 20;
    constant latency_read    : integer  := 10;

    subtype addr_t is integer range 0 to 2**addr_width_log2-1;
    subtype byte_t is integer range 0 to 255;
    type burst_t is array(2**data_width_log2-1 downto 0) of byte_t;
    type mem_t is array(0 to 2**sim_mem_log2-1) of burst_t;
    type cmd_t is record
        addr    : addr_t;
        r_w     : bit;
        latency : integer;
    end record cmd_t;
    type fifo_cmd_t is array(0 to fifo_size_cmd-1) of cmd_t;
    type write_t is record
        data    : burst_t;
        be      : bit_vector(2**data_width_log2-1 downto 0);
    end record write_t;
    type fifo_write_t is array(0 to fifo_size_write-1) of write_t;

    signal fifo_cmd             : fifo_cmd_t;
    signal fifo_cmd_wen         : std_logic;
    signal fifo_cmd_ren         : std_logic;
    signal fifo_cmd_ef          : std_logic;
    signal fifo_cmd_ff          : std_logic;
    signal fifo_cmd_wptr        : integer range 0 to fifo_size_cmd-1;
    signal fifo_cmd_wcount      : integer range 0 to fifo_size_cmd;
    signal fifo_cmd_werr        : std_logic;
    signal fifo_cmd_rptr        : integer range 0 to fifo_size_cmd-1;
    signal fifo_cmd_rcount      : integer range 0 to fifo_size_cmd;
    signal fifo_cmd_rerr        : std_logic;

    signal fifo_write           : fifo_write_t;
    signal fifo_write_wen       : std_logic;
    signal fifo_write_ren       : std_logic;
    signal fifo_write_ef        : std_logic;
    signal fifo_write_ff        : std_logic;
    signal fifo_write_wptr      : integer range 0 to fifo_size_write-1;
    signal fifo_write_wcount    : integer range 0 to fifo_size_write;
    signal fifo_write_werr      : std_logic;
    signal fifo_write_rptr      : integer range 0 to fifo_size_write-1;
    signal fifo_write_rcount    : integer range 0 to fifo_size_write;
    signal fifo_write_rerr      : std_logic;

    signal mem                  : mem_t;
    signal count                : integer;

begin

    clk <=
        '0' when xrst = '1' else
        '1' after clk_period/2 when clk = '0' else
        '0' after clk_period/2 when clk = '1' else
        '0';

    FIFOCTRL_CMD: entity work.model_fifoctrl_s
        generic map (
            size => fifo_size_cmd
        )
        port map (
            rst     => rst,
            clk     => clk,
            wen     => fifo_cmd_wen,
            ren     => fifo_cmd_ren,
            ef      => fifo_cmd_ef,
            ff      => fifo_cmd_ff,
            wptr    => fifo_cmd_wptr,
            wcount  => fifo_cmd_wcount,
            werr    => fifo_cmd_werr,
            rptr    => fifo_cmd_rptr,
            rcount  => fifo_cmd_rcount,
            rerr    => fifo_cmd_rerr
        );

    fifo_cmd_wen <= mig_avalid and mig_aready;
    mig_aready <= not fifo_cmd_ff;
    fifo_cmd_ren <= '1' when
        fifo_cmd_ef = '0' and
        ((fifo_cmd(fifo_cmd_rptr).r_w = '0' and fifo_write_ef = '0') or fifo_cmd(fifo_cmd_rptr).r_w = '1') and
        count >= fifo_cmd(fifo_cmd_rptr).latency
        else '0';

    FIFOCTRL_WRITE: entity work.model_fifoctrl_s
        generic map (
            size => fifo_size_write
        )
        port map (
            rst     => rst,
            clk     => clk,
            wen     => fifo_write_wen,
            ren     => fifo_write_ren,
            ef      => fifo_write_ef,
            ff      => fifo_write_ff,
            wptr    => fifo_write_wptr,
            wcount  => fifo_write_wcount,
            werr    => fifo_write_werr,
            rptr    => fifo_write_rptr,
            rcount  => fifo_write_rcount,
            rerr    => fifo_write_rerr
        );

    fifo_write_wen <= mig_wvalid and mig_wready;
    mig_wready <= not fifo_write_ff;
    fifo_write_ren <= '1' when
        fifo_cmd_ef = '0' and
        (fifo_cmd(fifo_cmd_rptr).r_w = '0' and fifo_write_ef = '0') and
        count >= fifo_cmd(fifo_cmd_rptr).latency
        else '0';

    process(xrst,clk)
    begin
        if xrst ='1' then
            rst <= '1';
            mig_cc <= '0';
        elsif rising_edge(clk) then
            rst <= '0';
            mig_cc <= not rst;
        end if;
    end process;

    process(clk)

        variable addr       : integer;
        variable r_w        : bit;
        variable wbe        : bit_vector(2**data_width_log2-1 downto 0);
        variable wdata      : burst_t;
        variable latency    : integer;

    begin
        if rising_edge(clk) then
            if rst = '1' then

                fifo_cmd    <= (others => (addr => 0, r_w => '0', latency => 0));
                fifo_write  <= (others => (data => (others => 0), be => (others => '0')));
                mem         <= (others => (others => 0));
                count       <= 0;    

                    mig_rvalid <= '0';
                mig_rdata <= (others => 'X');
                mig_raddr <= (others => 'X');

                addr := -1;
                r_w := '0';

            else

                if to_integer(unsigned(mig_addr)) = addr+1 and to_bit(mig_r_w) = r_w then -- consecutive cycle
                    latency := 0;
                elsif r_w = '1' then
                    latency := latency_read-1;
                else
                    latency := latency_write-1;
                end if;

                addr := to_integer(unsigned(mig_addr));
                r_w := to_bit(mig_r_w);
                for i in 0 to 2**data_width_log2-1 loop
                    wdata(i) := to_integer(unsigned(mig_wdata(7+(i*8) downto i*8)));
                end loop;
                wbe := to_bitvector(mig_wbe);

                if fifo_cmd_wen = '1' then
                    fifo_cmd(fifo_cmd_wptr) <= (addr => addr, r_w => r_w, latency => latency);
                end if;

                if fifo_write_wen = '1' then
                    fifo_write(fifo_write_wptr) <= (data => wdata, be => wbe);
                end if;

                mig_rvalid <= '0';
                mig_rdata <= (others => 'X');
                mig_raddr <= (others => 'X');
                if fifo_cmd_ef = '0' and fifo_cmd(fifo_cmd_rptr).r_w = '1' and count >= fifo_cmd(fifo_cmd_rptr).latency then
                    mig_rvalid <= '1';
                    for i in burst_t'range loop
                        mig_rdata(7+(i*8) downto i*8) <= std_logic_vector(to_unsigned(mem(fifo_cmd(fifo_cmd_rptr).addr)(i),8));
                    end loop;
                    mig_raddr <= std_logic_vector(to_unsigned(fifo_cmd(fifo_cmd_rptr).addr,addr_width_log2));                
                end if;

                if fifo_cmd_ren = '1' then
                    count <= 0;
                elsif fifo_cmd_ef = '0' then
                    count <= count+1;
                end if;

                if fifo_write_ren = '1' then
                    for i in burst_t'range loop
                        if fifo_write(fifo_write_rptr).be(i) = '1' then
                            mem(fifo_cmd(fifo_cmd_rptr).addr mod 2**sim_mem_log2)(i) <= fifo_write(fifo_write_rptr).data(i);
                        end if;
                    end loop;
                end if;

            end if;
        end if;
    end process;

end architecture model;

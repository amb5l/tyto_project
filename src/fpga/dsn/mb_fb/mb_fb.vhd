--------------------------------------------------------------------------------
-- mb_fb.vhd                                                                  --
-- MicroBlaze CPU with SDRAM frame buffer.                                    --
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

package mb_fb_pkg is

    component mb_fb  is
        generic (
            fref        : real
        );
        port (

            xclk        : in    std_logic;                  -- external (reference) clock
            xrst        : in    std_logic;                  -- external reset (asynchronous)

            sclk        : in    std_logic;                  -- system (CPU/MIG) clock
            srst        : in    std_logic;                  -- system reset (synchronous)

            uart_txd    : out   std_logic;
            uart_rxd    : in    std_logic;

            mig_cc      : in    std_logic;
            mig_avalid  : out   std_logic;
            mig_r_w     : out   std_logic;
            mig_addr    : out   std_logic_vector(addr_width_log2+data_width_log2-1 downto data_width_log2);
            mig_aready  : in    std_logic;
            mig_wvalid  : out   std_logic;
            mig_wdata   : out   std_logic_vector(2**(data_width_log2+3)-1 downto 0);
            mig_wbe     : out   std_logic_vector(2**data_width_log2-1 downto 0);
            mig_wready  : in    std_logic;
            mig_rdata   : in    std_logic_vector(2**(data_width_log2+3)-1 downto 0);
            mig_rvalid  : in    std_logic;

            dvi_clk_p   : out   std_logic;                  -- DVI TMDS clock (differential, P)
            dvi_clk_n   : out   std_logic;                  -- DVI TMDS clock (differential, N)
            dvi_d_p     : out   std_logic_vector(0 to 2);   -- DVI TMDS data channels 0..2 (differential, P)
            dvi_d_n     : out   std_logic_vector(0 to 2);   -- DVI TMDS data channels 0..2 (differential, N)

            debug       : out   std_logic_vector(1 downto 0)

        );
    end component mb_fb;

end package mb_fb_pkg;

--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library work;
use work.global_pkg.all;
use work.crtc_pkg.all;
use work.dvi_tx_pkg.all;
use work.mig_hub_pkg.all;
use work.mig_bridge_axi_pkg.all;
use work.mig_bridge_crtc_pkg.all;

entity mb_fb  is
    generic (
        fref            : real
    );
    port (

        xclk        : in    std_logic;                  -- external (reference) clock
        xrst        : in    std_logic;                  -- external reset (asynchronous)

        sclk        : in    std_logic;                  -- system (CPU/MIG) clock
        srst        : in    std_logic;                  -- system reset (synchronous)
        
        uart_txd    : out   std_logic;
        uart_rxd    : in    std_logic;

        mig_cc      : in    std_logic;
        mig_avalid  : out   std_logic;
        mig_r_w     : out   std_logic;
        mig_addr    : out   std_logic_vector(addr_width_log2+data_width_log2-1 downto data_width_log2);
        mig_aready  : in    std_logic;
        mig_wvalid  : out   std_logic;
        mig_wdata   : out   std_logic_vector(2**(data_width_log2+3)-1 downto 0);
        mig_wbe     : out   std_logic_vector(2**data_width_log2-1 downto 0);
        mig_wready  : in    std_logic;
        mig_rdata   : in    std_logic_vector(2**(data_width_log2+3)-1 downto 0);
        mig_rvalid  : in    std_logic;

        dvi_clk_p   : out   std_logic;                  -- DVI TMDS clock (differential, P)
        dvi_clk_n   : out   std_logic;                  -- DVI TMDS clock (differential, N)
        dvi_d_p     : out   std_logic_vector(0 to 2);   -- DVI TMDS data channels 0..2 (differential, P)
        dvi_d_n     : out   std_logic_vector(0 to 2);   -- DVI TMDS data channels 0..2 (differential, N)

        debug       : out   std_logic_vector(1 downto 0)

    );
end entity mb_fb;

architecture synth of mb_fb is

    constant mig_hub_ports : integer := 2;

    signal gpi          : std_logic_vector(31 downto 0);
    signal gpo          : std_logic_vector(31 downto 0);
    signal gpt          : std_logic_vector(31 downto 0);

    signal axi_awaddr   : std_logic_vector(31 downto 0);
    signal axi_awprot   : std_logic_vector(2 downto 0);
    signal axi_awvalid  : std_logic_vector(0 to 0);
    signal axi_awready  : std_logic_vector(0 to 0);
    signal axi_wdata    : std_logic_vector(31 downto 0);
    signal axi_wstrb    : std_logic_vector(3 downto 0);
    signal axi_wvalid   : std_logic_vector(0 to 0);
    signal axi_wready   : std_logic_vector(0 to 0);
    signal axi_bresp    : std_logic_vector(1 downto 0);
    signal axi_bvalid   : std_logic_vector(0 to 0);
    signal axi_bready   : std_logic_vector(0 to 0);
    signal axi_araddr   : std_logic_vector(31 downto 0);
    signal axi_arprot   : std_logic_vector(2 downto 0);
    signal axi_arvalid  : std_logic_vector(0 to 0);
    signal axi_arready  : std_logic_vector(0 to 0);
    signal axi_rdata    : std_logic_vector(31 downto 0);
    signal axi_rresp    : std_logic_vector(1 downto 0);
    signal axi_rvalid   : std_logic_vector(0 to 0);
    signal axi_rready   : std_logic_vector(0 to 0);

    -- CRTC
    signal mode         : std_logic_vector(3 downto 0);
    signal pclk         : std_logic;
    signal pclk_x5      : std_logic;
    signal prst         : std_logic;
    signal crtc_llen    : std_logic_vector(10 downto 6);
    signal crtc_vs      : std_logic;
    signal crtc_hs      : std_logic;
    signal crtc_vblank  : std_logic;
    signal crtc_hblank  : std_logic;
    signal crtc_r       : std_logic_vector(7 downto 0);
    signal crtc_g       : std_logic_vector(7 downto 0);
    signal crtc_b       : std_logic_vector(7 downto 0);

    -- MIG hub
    signal hub_awvalid  : std_logic_vector(0 to mig_hub_ports-1);
    signal hub_awready  : std_logic_vector(0 to mig_hub_ports-1);
    signal hub_r_w      : std_logic_vector(0 to mig_hub_ports-1);
    signal hub_addr     : mig_addr_t(0 to mig_hub_ports-1);
    signal hub_wdata    : mig_data_t(0 to mig_hub_ports-1);
    signal hub_wbe      : mig_be_t(0 to mig_hub_ports-1);
    signal hub_rdata    : std_logic_vector(2**(data_width_log2+3)-1 downto 0);
    signal hub_rvalid   : std_logic_vector(0 to mig_hub_ports-1);

    component microblaze is
        port (
        clk             : in    std_logic;
        rsti_n          : in    std_logic;
        rsto            : out   std_logic_vector(0 to 0);
        uart_txd        : out   std_logic;
        uart_rxd        : in    std_logic;
        gpio_tri_i      : in    std_logic_vector(31 downto 0);
        gpio_tri_o      : out   std_logic_vector(31 downto 0);
        gpio_tri_t      : out   std_logic_vector(31 downto 0);
        axi_awaddr      : out   std_logic_vector(31 downto 0);
        axi_awprot      : out   std_logic_vector(2 downto 0);
        axi_awvalid     : out   std_logic_vector(0 to 0);
        axi_awready     : in    std_logic_vector(0 to 0);
        axi_wdata       : out   std_logic_vector(31 downto 0);
        axi_wstrb       : out   std_logic_vector(3 downto 0);
        axi_wvalid      : out   std_logic_vector(0 to 0);
        axi_wready      : in    std_logic_vector(0 to 0);
        axi_bresp       : in    std_logic_vector(1 downto 0);
        axi_bvalid      : in    std_logic_vector(0 to 0);
        axi_bready      : out   std_logic_vector(0 to 0);
        axi_araddr      : out   std_logic_vector(31 downto 0);
        axi_arprot      : out   std_logic_vector(2 downto 0);
        axi_arvalid     : out   std_logic_vector(0 to 0);
        axi_arready     : in    std_logic_vector(0 to 0);
        axi_rdata       : in    std_logic_vector(31 downto 0);
        axi_rresp       : in    std_logic_vector(1 downto 0);
        axi_rvalid      : in    std_logic_vector(0 to 0);
        axi_rready      : out   std_logic_vector(0 to 0)
        );
    end component microblaze;

begin

    mode <= gpo(3 downto 0);
    gpi <= (0 => mig_cc, others => '0');

    U_CPU: entity work.microblaze
        port map (
            clk         => sclk,
            rsti_n      => not (srst or not mig_cc),
            rsto        => open,
            uart_txd    => uart_txd,
            uart_rxd    => uart_rxd,
            gpio_tri_i  => gpi,
            gpio_tri_o  => gpo,
            gpio_tri_t  => gpt,
            axi_awaddr   => axi_awaddr,
            axi_awprot   => axi_awprot,
            axi_awvalid  => axi_awvalid,
            axi_awready  => axi_awready,
            axi_wdata    => axi_wdata,
            axi_wstrb    => axi_wstrb,
            axi_wvalid   => axi_wvalid,
            axi_wready   => axi_wready,
            axi_bresp    => axi_bresp,
            axi_bvalid   => axi_bvalid,
            axi_bready   => axi_bready,
            axi_araddr   => axi_araddr,
            axi_arprot   => axi_arprot,
            axi_arvalid  => axi_arvalid,
            axi_arready  => axi_arready,
            axi_rdata    => axi_rdata,
            axi_rresp    => axi_rresp,
            axi_rvalid   => axi_rvalid,
            axi_rready   => axi_rready
        );

    U_BRIDGE_CPU: component mig_bridge_axi
        port map (
            clk         => sclk,
            rst         => srst,
            axi_awaddr  => axi_awaddr,
            axi_awprot  => axi_awprot,
            axi_awvalid => axi_awvalid,
            axi_awready => axi_awready,
            axi_wdata   => axi_wdata,
            axi_wstrb   => axi_wstrb,
            axi_wvalid  => axi_wvalid,
            axi_wready  => axi_wready,
            axi_bresp   => axi_bresp,
            axi_bvalid  => axi_bvalid,
            axi_bready  => axi_bready,
            axi_araddr  => axi_araddr,
            axi_arprot  => axi_arprot,
            axi_arvalid => axi_arvalid,
            axi_arready => axi_arready,
            axi_rdata   => axi_rdata,
            axi_rresp   => axi_rresp,
            axi_rvalid  => axi_rvalid,
            axi_rready  => axi_rready,
            mig_awvalid => hub_awvalid(1),
            mig_awready => hub_awready(1),
            mig_r_w     => hub_r_w(1),
            mig_addr    => hub_addr(1),
            mig_wdata   => hub_wdata(1),
            mig_wbe     => hub_wbe(1),
            mig_rdata   => hub_rdata,
            mig_rvalid  => hub_rvalid(1)
        );

    U_CRTC: component crtc
        generic map (
            fref        => 100.0
        )
        port map (
            xclk        => xclk,
            xrst        => xrst,
            sclk        => sclk,
            srst        => srst,
            pclk        => pclk,
            pclk_x5     => pclk_x5,
            prst        => prst,
            mode        => mode,
            fb_llen     => crtc_llen,
            fb_vs       => crtc_vs,
            fb_hs       => crtc_hs,
            fb_vblank   => crtc_vblank,
            fb_hblank   => crtc_hblank
        );

    U_BRIDGE_CRTC: component mig_bridge_crtc
        generic map (
            base_addr       => 0,
            size_log2       => 23   -- 2^23 = 8MBytes (enough for 1920 x 1080 x 32 bpp)
        )
        port map (
            crtc_clk        => pclk,
            crtc_rst        => prst,
            crtc_llen       => crtc_llen,
            crtc_vs         => crtc_vs,
            crtc_hs         => crtc_hs,
            crtc_vblank     => crtc_vblank,
            crtc_hblank     => crtc_hblank,
            crtc_r          => crtc_r,
            crtc_g          => crtc_g,
            crtc_b          => crtc_b,
            mig_clk         => sclk,
            mig_rst         => srst,
            mig_awvalid     => hub_awvalid(0),
            mig_awready     => hub_awready(0),
            mig_r_w         => hub_r_w(0),
            mig_addr        => hub_addr(0),
            mig_wdata       => hub_wdata(0),
            mig_wbe         => hub_wbe(0),
            mig_rdata       => hub_rdata,
            mig_rvalid      => hub_rvalid(0),
            fifo_underflow  => debug(0),
            fifo_overflow   => debug(1)
        );

    U_DVI_OUT: component dvi_tx
        port map (
            vga_clk     => pclk,
            vga_clk_x5  => pclk_x5,
            vga_rst     => prst,
            vga_vs      => crtc_vs,
            vga_hs      => crtc_hs,
            vga_vblank  => crtc_vblank,
            vga_hblank  => crtc_hblank,
            vga_r       => crtc_r,
            vga_g       => crtc_g,
            vga_b       => crtc_b,
            dvi_clk_p   => dvi_clk_p,
            dvi_clk_n   => dvi_clk_n,
            dvi_d_p     => dvi_d_p,
            dvi_d_n     => dvi_d_n
        );

    U_HUB: component mig_hub
        generic map (
            ports => 2
        )
        port map (
            clk             => sclk,
            rst             => srst,
            hub_awvalid     => hub_awvalid,
            hub_awready     => hub_awready,
            hub_r_w         => hub_r_w,
            hub_addr        => hub_addr,
            hub_wdata       => hub_wdata,
            hub_wbe         => hub_wbe,
            hub_rdata       => hub_rdata,
            hub_rvalid      => hub_rvalid,
            mig_avalid      => mig_avalid,
            mig_r_w         => mig_r_w,
            mig_addr        => mig_addr,
            mig_aready      => mig_aready,
            mig_wvalid      => mig_wvalid,
            mig_wdata       => mig_wdata,
            mig_wbe         => mig_wbe,
            mig_wready      => mig_wready,
            mig_rdata       => mig_rdata,
            mig_rvalid      => mig_rvalid
        );

end architecture synth;

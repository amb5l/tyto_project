if {$xbuild_design != "mb_display_sd"} {
    error "bad design name"
}
if {$xbuild_board == "nexys_video"} {
    set fpga_part xc7a200tsbg484-1
} else {
    error "unsupported board"
}
set vhdl_files [list \
    "dsn/${xbuild_design}/${xbuild_design}_${xbuild_board}.vhd" \
    "dsn/${xbuild_design}/${xbuild_design}.vhd" \
    "lib/misc/types_pkg.vhd" \
    "lib/misc/clock_100m.vhd" \
    "dsn/${xbuild_design}/display_sd.vhd" \
    "lib/video_out/video_out_clock_27m.vhd" \
    "lib/misc/ram_4kx16_2kx32.vhd" \
    "lib/video_out/char_rom_437_8x16.vhd" \
    "lib/video_out/dvi_out.vhd" \
    "lib/video_out/video_out_timing.vhd" \
    "lib/video_out/dvi_tx_encoder.vhd" \
    "lib/misc/serialiser_10to1_selectio.vhd" \
]
set bd_tcl_files [list \
    "dsn/${xbuild_design}/microblaze.tcl"
]
set constr_files [list \
    "dsn/${xbuild_design}/${xbuild_design}_${xbuild_board}.xdc" \
    "dsn/${xbuild_design}/${xbuild_design}.xdc" \
]
set sim_files [list \
    "dsn/${xbuild_design}/tb_${xbuild_design}_${xbuild_board}.vhd" \
    "lib/video_out/model_dvi_decoder.vhd" \
    "lib/video_out/model_tmds_cdr_des.vhd" \
    "lib/video_out/model_vga_sink.vhd" \
    "lib/video_out/sim_video_out_pkg.vhd" \
]
set mb_files [list \
    "dsn/${xbuild_design}/main.c" \
    "lib/peekpoke.h" \
    "lib/axi_gpio_p.h" \
    "lib/axi_gpio.h" \
    "lib/axi_gpio.c" \
    "lib/vdu.h" \
    "lib/vdu.c" \
    "lib/printf.h" \
    "lib/printf.c" \
]

if {$xbuild_design != "mb_fb"} {
    error "bad design name"
}
if {$xbuild_board == "nexys_video"} {
    set fpga_part xc7a200tsbg484-1
} elseif {$xbuild_board == "qmtech_wukong"} {
    set fpga_part xc7a100tfgg676-1
} else {
    error "unsupported board"
}
set ip_tcl_files [list \
    "xip/ddr3_${xbuild_board}/mig.tcl" \
]
set vhdl_files [list \
    "dsn/${xbuild_design}/${xbuild_design}_${xbuild_board}.vhd" \
    "dsn/${xbuild_design}/${xbuild_design}.vhd" \
    "dsn/${xbuild_design}/global_pkg_${xbuild_board}.vhd" \
    "lib/misc/types_pkg.vhd" \
    "dsn/${xbuild_design}/mig_bridge_axi.vhd" \
    "dsn/${xbuild_design}/mig_bridge_crtc.vhd" \
    "dsn/${xbuild_design}/mig_hub.vhd" \
    "dsn/${xbuild_design}/crtc.vhd" \
    "dsn/${xbuild_design}/dvi_tx.vhd" \
    "lib/video_out/video_mode.vhd" \
    "lib/video_out/video_out_clock.vhd" \
    "lib/video_out/video_out_timing.vhd" \
    "lib/video_out/dvi_tx_encoder.vhd" \
    "lib/misc/serialiser_10to1_selectio.vhd" \
]
set bd_tcl_files [list \
    "dsn/${xbuild_design}/microblaze.tcl"
]
set constr_files [list \
    "dsn/${xbuild_design}/${xbuild_design}_${xbuild_board}.xdc" \
]
set sim_files [list \
    "dsn/${xbuild_design}/tb_${xbuild_design}_${xbuild_board}.vhd" \
    "dsn/${xbuild_design}/tb_${xbuild_design}.vhd" \
    "dsn/${xbuild_design}/tb_crtc_etc.vhd" \
    "lib/mig/model_mig.vhd" \
    "lib/misc/model_fifoctrl_s.vhd" \
    "lib/video_out/model_dvi_decoder.vhd" \
    "lib/video_out/model_tmds_cdr_des.vhd" \
    "lib/video_out/model_vga_sink.vhd" \
    "lib/video_out/model_video_out_clock.vhd" \
    "lib/video_out/sim_video_out_pkg.vhd" \
]
set ip_sim_files [list \
    "ddr3/ddr3/example_design/sim/ddr3_model.sv" \
    "ddr3/ddr3/example_design/sim/ddr3_model_parameters.vh" \
]
set mb_files [list \
    "dsn/${xbuild_design}/main.c" \
    "dsn/${xbuild_design}/hagl_hal.c" \
    "dsn/${xbuild_design}/hagl_hal.h" \
    "lib/peekpoke.h" \
    "lib/axi_gpio_p.h" \
    "lib/axi_gpio.h" \
    "lib/axi_gpio.c" \
    "lib/fb.h" \
    "lib/fb.c" \
]
set mb_submodule_files [list \
    "hagl/src/bitmap.c" \
    "hagl/src/clip.c" \
    "hagl/src/fontx.c" \
    "hagl/src/hagl.c" \
    "hagl/src/hsl.c" \
    "hagl/src/rgb888.c" \
    "hagl/src/rgb565.c" \
    "hagl/src/tjpgd.c" \
    "hagl/include/aps.h" \
    "hagl/include/bitmap.h" \
    "hagl/include/clip.h" \
    "hagl/include/font5x7.h" \
    "hagl/include/font5x8.h" \
    "hagl/include/font6x9.h" \
    "hagl/include/fontx.h" \
    "hagl/include/fps.h" \
    "hagl/include/hagl.h" \
    "hagl/include/hsl.h" \
    "hagl/include/rgb332.h" \
    "hagl/include/rgb565.h" \
    "hagl/include/rgb888.h" \
    "hagl/include/tjpgd.h" \
    "hagl/include/window.h" \
]
set mb_include_paths [list \
    "dsn/${xbuild_design}" \
]
set mb_submodule_include_paths [list \
    "hagl/include"
]
set mb_symbols [list \
    "NO_MENUCONFIG"
]
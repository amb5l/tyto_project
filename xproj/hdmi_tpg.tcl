if {$xbuild_design != "hdmi_tpg"} {
    error "bad design name"
}
if {$xbuild_board == "nexys_video"} {
    set fpga_part xc7a200tsbg484-1
} elseif {$xbuild_board == "qmtech_wukong"} {
    set fpga_part xc7a100tfgg676-1
} else {
    error "unsupported board"
}
set vhdl_files [list \
    "dsn/${xbuild_design}/${xbuild_design}_${xbuild_board}.vhd" \
    "dsn/${xbuild_design}/${xbuild_design}.vhd" \
    "lib/misc/types_pkg.vhd" \
    "lib/misc/clock_100m.vhd" \
    "lib/video_out/video_out_clock.vhd" \
    "lib/video_out/video_mode.vhd" \
    "lib/video_out/video_out_timing.vhd" \
    "lib/video_out/video_out_test_pattern.vhd" \
    "lib/audio_io/audio_out_test_tone.vhd" \
    "lib/audio_io/audio_clock.vhd" \
    "lib/video_out/vga_to_hdmi.vhd" \
    "lib/video_out/hdmi_tx_encoder.vhd" \
    "lib/misc/serialiser_10to1_selectio.vhd" \
]
set constr_files [list \
    "dsn/${xbuild_design}/${xbuild_design}_${xbuild_board}.xdc" \
    "dsn/${xbuild_design}/${xbuild_design}.xdc" \
]
set sim_files [list \
    "dsn/${xbuild_design}/tb_${xbuild_design}_${xbuild_board}.vhd" \
    "lib/video_out/model_hdmi_decoder.vhd" \
    "lib/video_out/model_tmds_cdr_des.vhd" \
    "lib/video_out/model_vga_sink.vhd" \
    "lib/video_out/sim_video_out_pkg.vhd" \
]


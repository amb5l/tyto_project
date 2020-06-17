if {$xbuild_design != "mb_audio_io"} {
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
    "lib/misc/double_sync.vhd" \
    "lib/audio_io/audio_clock.vhd" \
    "lib/audio_io/audio_axis.vhd" \
    "lib/audio_io/audio_i2s.vhd" \
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
]
set mb_files [list \
    "dsn/${xbuild_design}/main.c" \
    "dsn/${xbuild_design}/global.h" \
    "dsn/${xbuild_design}/dalek.c" \
    "dsn/${xbuild_design}/dalek.h" \
    "dsn/${xbuild_design}/dalek_p.h" \
    "lib/peekpoke.h" \
    "lib/axi_iic.c" \
    "lib/axi_iic.h" \
    "lib/axi_iic_p.h" \
    "lib/adau1761.c" \
    "lib/adau1761.h" \
    "lib/adau1761_p.h" \
    "lib/axi_fifo_mm.c" \
    "lib/axi_fifo_mm.h" \
    "lib/axi_fifo_mm_p.h" \
]

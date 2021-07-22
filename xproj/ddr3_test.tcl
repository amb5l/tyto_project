if {$xbuild_design != "ddr3_test"} {
    error "bad design name"
}
if {$xbuild_board == "nexys_video"} {
    set fpga_part "xc7a200tsbg484-1"
} else {
    error "unsupported board"
}
set ip_tcl_files [list \
    "xip/ddr3_${xbuild_board}/mig_50.tcl" \
]
set vhdl_files [list \
    "dsn/${xbuild_design}/${xbuild_design}_${xbuild_board}.vhd" \
    "dsn/${xbuild_design}/${xbuild_design}.vhd" \
    "dsn/${xbuild_design}/ddr3_wrapper_${xbuild_board}.vhd" \
    "dsn/${xbuild_design}/rng_xoshiro128plusplus.vhd" \
]
set constr_files [list \
    "dsn/${xbuild_design}/${xbuild_design}_${xbuild_board}.xdc" \
]
set sim_files [list \
    "dsn/${xbuild_design}/tb_${xbuild_design}_${xbuild_board}.vhd" \
]
set ip_sim_files [list \
    "ddr3/ddr3/example_design/sim/ddr3_model.sv" \
    "ddr3/ddr3/example_design/sim/ddr3_model_parameters.vh" \
]

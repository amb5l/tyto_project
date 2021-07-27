if {$ram_size == "64"} {
    set ram_bank_size "16"
} elseif {$ram_size == "128"} {
    set ram_bank_size "32"
} elseif {$ram_size == "256"} {
    set ram_bank_size "64"
} else {
    error "bad ram size"
}
if {$xbuild_design != "np65_poc_${ram_size}k"} {
    error "bad design name"
}
if {$xbuild_board == "nexys_video"} {
    set fpga_part "xc7a200tsbg484-1"
} elseif {$xbuild_board == "qmtech_wukong"} {
    set fpga_part xc7a100tfgg676-1
} else {
    error "unsupported board"
}

# generate np65_ram_128k_pkg.vhd
exec ca65 ${src_path_65xx}/np65_poc/functest.a65 \
    -o ${src_path_fpga}/dsn/np65_poc/functest.o \
    -l ${src_path_fpga}/dsn/np65_poc/functest.lst
exec ld65 ${src_path_fpga}/dsn/np65_poc/functest.o \
    -o ${src_path_fpga}/dsn/np65_poc/functest.bin \
    -m ${src_path_fpga}/dsn/np65_poc/functest.map \
    -C ${src_path_65xx}/np65_poc/functest.cfg
exec python ${src_path_fpga}/lib/np65/np65_ram_pkg.py ${ram_size} 0 ${src_path_fpga}/dsn/np65_poc/functest.bin ${src_path_fpga}/dsn/np65_poc/

# generate np65_decoder.vhd
exec python ${src_path_fpga}/lib/np65/np65_decoder.py ${src_path_fpga}/lib/np65/np65_decoder.csv ${src_path_fpga}/lib/np65/

set vhdl_files [list \
    "dsn/np65_poc/np65_poc_${xbuild_board}.vhd" \
    "dsn/np65_poc/np65_poc.vhd" \
    "dsn/np65_poc/np65_poc_clock.vhd" \
    "dsn/np65_poc/np65_ram_${ram_size}k_pkg.vhd" \
    "lib/np65/np65_pkg.vhd" \
    "lib/np65/np65.vhd" \
    "lib/np65/np65_types_pkg.vhd" \
    "lib/np65/np65_ram.vhd" \
    "lib/np65/np65_ram_bank_${ram_bank_size}k.vhd" \
    "lib/np65/np65_cache.vhd" \
    "lib/np65/np65_decoder.vhd" \
    "lib/misc/double_sync.vhd" \
]
set constr_files [list \
    "dsn/np65_poc/np65_poc_${xbuild_board}.xdc" \
    "dsn/np65_poc/np65_poc_${xbuild_board}_${ram_size}k.xdc" \
    "dsn/np65_poc/np65_poc.xdc" \
]
set sim_files [list \
    "dsn/np65_poc/tb_np65_poc_${xbuild_board}.vhd" \
]
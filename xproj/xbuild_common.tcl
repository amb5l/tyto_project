set top_name "top"
set vivado_proj_name "fpga"
set vitis_proj_name "microblaze"
set vivado_proj_dir "vivado"
set vitis_proj_dir "vitis"
set fpga_src_path "src/fpga/"
set sim_src_path "src/sim/"
set mb_src_path "src/mb/"

proc lmap {_var list body} {
    upvar 1 $_var var
    set res {}
    foreach var $list {lappend res [uplevel 1 $body]}
    set res
}
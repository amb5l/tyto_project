set top_name "top"
set vivado_proj_name "fpga"
set vitis_proj_name "microblaze"
set vivado_proj_dir "vivado"
set vitis_proj_dir "vitis"
set src_path_fpga "src/fpga/"
set src_path_sim "src/sim/"
set src_path_mb "src/mb/"
set src_path_65xx "src/65xx/"

proc lmap {_var list body} {
    upvar 1 $_var var
    set res {}
    foreach var $list {lappend res [uplevel 1 $body]}
    set res
}
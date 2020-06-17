# three stage build
# stage 3 of 3: open Vivado project, associate ELF files, synthesize, implement, write bitstream

source "xproj/xbuild_common.tcl"
set xbuild_design [lindex $argv 0]
set xbuild_board [lindex $argv 1]
set jobs [lindex $argv 2]

# open project
cd xproj/vivado/${xbuild_design}_${xbuild_board}
open_project "${vivado_proj_name}.xpr"

# add ELF file for implementation
set f "../../${vitis_proj_dir}/${xbuild_design}_${xbuild_board}/${vitis_proj_name}/Release/${vitis_proj_name}.elf"
add_files -norecurse -fileset [get_filesets sources_1] $f
set_property SCOPED_TO_REF microblaze [get_files -all -of_objects [get_fileset sources_1] $f]
set_property SCOPED_TO_CELLS { cpu } [get_files -all -of_objects [get_fileset sources_1] $f]

# add ELF file for simulation
set f "../../${vitis_proj_dir}/${xbuild_design}_${xbuild_board}/${vitis_proj_name}/Debug/${vitis_proj_name}.elf"
add_files -norecurse -fileset [get_filesets sim_1] $f
set_property SCOPED_TO_REF microblaze [get_files -all -of_objects [get_fileset sim_1] $f]
set_property SCOPED_TO_CELLS { cpu } [get_files -all -of_objects [get_fileset sim_1] $f]

# synthesise, implement and write bitstream
launch_runs impl_1 -jobs $jobs
wait_on_run impl_1
open_run impl_1
write_bitstream "${xbuild_design}_${xbuild_board}.bit"

exit
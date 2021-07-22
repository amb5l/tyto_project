# single stage build
# create Vivado project, synthesize, implement, write bitstream

source "xproj/xbuild_common.tcl"
set xbuild_design [lindex $argv 0]
set xbuild_board [lindex $argv 1]
set jobs [lindex $argv 2]

# design/board specific settings
source "xproj/${xbuild_design}.tcl"

# create Vivado project
create_project ${vivado_proj_name} "xproj/vivado/${xbuild_design}_${xbuild_board}" -part $fpga_part -force
set_property -name "target_language" -value "VHDL" -objects [current_project]
set_property -name "enable_vhdl_2008" -value "1" -objects [current_project]
cd xproj/vivado/${xbuild_design}_${xbuild_board}

# add path prefix to file lists
if {[info exists ip_tcl_files]} {
    set ip_tcl_files [lmap f $ip_tcl_files {join [list "../../../" ${src_path_fpga} $f] ""}]
} else {
    set ip_tcl_files [list]
}
set vhdl_files [lmap f $vhdl_files {join [list "../../../" ${src_path_fpga} $f] ""}]
if {[info exists bd_tcl_files]} {
    set bd_tcl_files [lmap f $bd_tcl_files {join [list "../../../" ${src_path_fpga} $f] ""}]
} else {
    set bd_tcl_files [list]
}
set constr_files [lmap f $constr_files {join [list "../../../" ${src_path_fpga} $f] ""}]
if {[info exists sim_files]} {
    set sim_files [lmap f $sim_files {join [list "../../../" ${src_path_sim} $f] ""}]
} else {
    set sim_files [list]
}
if {[info exists ip_sim_files]} {
    set ip_sim_files [lmap f $ip_sim_files {join [list "fpga.gen/sources_1/ip/" $f] ""}]
} else {
    set ip_sim_files [list]
}

# run IP scripts
if { [llength $ip_tcl_files] > 0 } {
    foreach file $ip_tcl_files {
        source "${file}"        
    }
}

# add VHDL files
add_files -norecurse -fileset [get_filesets sources_1] $vhdl_files
foreach file $vhdl_files {
    set f [get_files -of_objects [get_filesets sources_1] "$file"]
    set_property -name "file_type" -value "VHDL 2008" -objects $f
}

# add constraints
add_files -norecurse -fileset [get_filesets constrs_1] $constr_files
foreach file $constr_files {
    set f [get_files -of_objects [get_filesets constrs_1] "$file"]
    set_property used_in_synthesis false [get_files  $f]
}

# build block diagrams
if { [llength $bd_tcl_files] > 0 } {
    foreach file $bd_tcl_files {
        set r [file rootname [file tail $file]]; # root of TCL file name
        set origin_dir_loc "./fpga.srcs/sources_1/bd/$r"
        source "${file}"        
        make_wrapper -top -import [get_files "$r.bd"]
        generate_target all [get_files "$r.bd"]
    }
}

# add simulation sources
if { [llength $sim_files] > 0 } {
    add_files -norecurse -fileset [get_filesets sim_1] $sim_files
    foreach file $sim_files {
        set f [get_files -of_objects [get_filesets sim_1] "$file"]
        set_property -name "file_type" -value "VHDL 2008" -objects $f
        set_property used_in_synthesis false [get_files  $f]
    }
}

# add IP simulation sources
if { [llength $ip_sim_files] > 0 } {
    add_files -norecurse -fileset [get_filesets sim_1] $ip_sim_files
    foreach file $ip_sim_files {
        set f [get_files -of_objects [get_filesets sim_1] "$file"]
        set_property used_in_synthesis false [get_files  $f]
    }
}

# set top
set_property -name "top" -value "top" -objects [get_filesets sources_1]

# add IP files
if { [info exists ip_filesets] } {
    set ip_files_local [list]
    exec mkdir fpga.srcs
    cd fpga.srcs
    exec mkdir sources_1
    cd sources_1
    exec mkdir ip
    cd ip
    foreach ip_fileset $ip_filesets {
        set ip_name [lindex $ip_fileset 0]
        exec mkdir $ip_name
        cd $ip_name
        set ip_files [lindex $ip_fileset 1]
        foreach ip_file $ip_files {
            puts "ip_file = ${ip_file}"
            exec cp "../../../../../../../${vivado_src_path}/${ip_file}" .
            set ip_filename [file tail $ip_file]
            lappend ip_files_local "fpga.srcs/sources_1/ip/$ip_name/$ip_filename"
        }
    }
    cd ../../../..
    add_files -norecurse -fileset [get_filesets sources_1] $ip_files_local
}

# synthesise, implement and write bitstream
launch_runs impl_1 -jobs $jobs
wait_on_run impl_1
open_run impl_1
write_bitstream "${xbuild_design}_${xbuild_board}.bit"

exit
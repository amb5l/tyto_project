# three stage build
# stage 2 of 3: create Vitis project, build ELF files

source "xproj/xbuild_common.tcl"
set xbuild_design [lindex $argv 0]
set xbuild_board [lindex $argv 1]

# design specific settings
source "xproj/${xbuild_design}.tcl"

# create project
cd xproj/vitis
setws ./${xbuild_design}_${xbuild_board}
cd ./${xbuild_design}_${xbuild_board}
set xsa_file "../../${vivado_proj_dir}/${xbuild_design}_${xbuild_board}/${vivado_proj_name}.xsa"
app create -name ${vitis_proj_name} -hw ${xsa_file} -os standalone -proc cpu -template {Empty Application}

# importsources does not handle remote sources, so hack linked resources
# into .project as follows:
set sources_uri_prefix "PARENT-4-PROJECT_LOC/"
set mb_files [lmap f $mb_files {join [list ${src_path_mb} $f] ""}]
set mb_submodule_files [lmap f $mb_submodule_files {join [list ${submodule_path} $f] ""}]
set mb_files [list {*}$mb_files {*}$mb_submodule_files]
set x [list "	<linkedResources>"]
foreach f $mb_files {
    set n [file tail $f]
    set s [list "		<link>"]
    lappend s "			<name>src/$n</name>"
    lappend s "			<type>1</type>"
    lappend s "			<locationURI>$sources_uri_prefix$f</locationURI>"
    lappend s "		</link>"
    set x [concat $x $s]
}
lappend x "	</linkedResources>"
set f [open "./${vitis_proj_name}/.project" "r"]
set lines [split [read $f] "\n"]
close $f
set i [lsearch $lines "	</natures>"]
if {$i < 0} {
    error "did not find insertion point"
}
set lines [linsert $lines 1+$i {*}$x]
set f [open "./${vitis_proj_name}/.project" "w"]
puts $f [join $lines "\n"]
close $f

#build release and debug ELF files
app config -name $vitis_proj_name build-config release
if {[info exists mb_symbols]} {
    foreach mb_symbol $mb_symbols {
        app config -name $vitis_proj_name define-compiler-symbols $mb_symbol
    }
}
app config -name $vitis_proj_name include-path "../../../../../${src_path_mb}/lib"
if {[info exists mb_include_paths]} {
    foreach mb_include_path $mb_include_paths {
        app config -name $vitis_proj_name include-path "../../../../../${src_path_mb}/${mb_include_path}"
    }
}
if {[info exists mb_submodule_include_paths]} {
    foreach mb_submodule_include_path $mb_submodule_include_paths {
        app config -name $vitis_proj_name include-path "../../../../../${submodule_path}/${mb_submodule_include_paths}"
    }
}
app build -name $vitis_proj_name
app config -name $vitis_proj_name build-config debug
if {[info exists mb_symbols]} {
    foreach mb_symbol $mb_symbols {
        app config -name $vitis_proj_name define-compiler-symbols $mb_symbol
    }
}
app config -name $vitis_proj_name include-path "../../../../../${src_path_mb}/lib"
if {[info exists mb_include_paths]} {
    foreach mb_include_path $mb_include_paths {
        app config -name $vitis_proj_name include-path "../../../../../${src_path_mb}/${mb_include_path}"
    }
}
if {[info exists mb_submodule_include_paths]} {
    foreach mb_submodule_include_path $mb_submodule_include_paths {
        app config -name $vitis_proj_name include-path "../../../../../${submodule_path}/${mb_submodule_include_paths}"
    }
}
app config -name $vitis_proj_name define-compiler-symbols BUILD_CONFIG_DEBUG
app build -name $vitis_proj_name

#exit
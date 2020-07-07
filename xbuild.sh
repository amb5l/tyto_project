if [ ! -f xproj/xbuild_common.tcl ]; then
  printf "cannot find xilinx build scripts\n"
  exit 1
fi
if [ $# -lt 2 -o $# -gt 3 ]; then
  printf "usage:\n"
  printf "  xbuild.bat design_name board_name <jobs>\n"
  exit 1
fi
if [ -z "$3" ]; then
  jobs=1
else
  jobs=$3
fi
printf "%s\n" "-------------------------------------------------------------------------------"
printf "design name = "
printf "%s  " "$1"
printf "board name = "
printf "%s  " "$2"
printf "parallel jobs = "
printf "%s\n" "$jobs"
printf "%s\n" "-------------------------------------------------------------------------------"
if [ ! -d xproj/vivado ]; then
  mkdir xproj/vivado
fi
if [ -d xproj/vivado/$1_$2 ]; then
  printf "deleting old Vivado files and directories...\n"
  rm -r xproj/vivado/$1_$2
fi
if ! [ -x "$(command -v vivado)" ]; then
  printf "vivado executable not found - have you run settings64.sh?\n"
  exit 1
fi
if [ ! -d src/mb/dsn/$1 ]; then
  vivado -mode tcl -nolog -nojournal -source xproj/xbuild.tcl -tclargs $1 $2 $jobs
  exit 0
else
  if [ ! -d xproj/vitis ]; then
    mkdir xproj/vitis
  fi
  if ! [ -x "$(command -v xsct)" ]; then
    printf "xsct executable not found - have you run settings64.sh?\n"
    exit 1
  fi
  if [ -d xproj/vitis/$1_$2 ]; then
    printf "deleting old Vitis files and directories...\n"
    rm -r xproj/vitis/$1_$2
  fi
  vivado -mode tcl -nolog -nojournal -source xproj/xbuild1.tcl -tclargs $1 $2 $jobs
  xsct xproj/xbuild2.tcl $1 $2
  vivado -mode tcl -nolog -nojournal -source xproj/xbuild3.tcl -tclargs $1 $2 $jobs
  exit 0
fi


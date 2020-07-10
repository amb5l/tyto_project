@echo off
@echo.
if not exist xproj\xbuild_common.tcl goto error_xscripts
if "%~1" == "" goto error_arguments
if "%~2" == "" goto error_arguments
set jobs=1
if NOT "%~3" == "" set jobs=%~3
@echo -------------------------------------------------------------------------------
@echo design name = %~1  board name = %~2  parallel jobs = %jobs%
@echo -------------------------------------------------------------------------------
if not exist xproj\vivado mkdir xproj\vivado
if not exist xproj\vivado\%~1_%~2 goto l1
@echo deleting old Vivado files...
del /f /q /s xproj\vivado\%~1_%~2 >nul
@echo removing old Vivado directories...
rmdir /q /s xproj\vivado\%~1_%~2
:l1
where vivado.bat >nul 2>nul
if %errorlevel% neq 0 (
    echo vivado.bat not found - have you run settings64.bat?
    exit /B -1
)
if exist src\mb\dsn\%~1 goto l2
call vivado -mode tcl -nolog -nojournal -source xproj/xbuild.tcl -tclargs %~1 %~2 %jobs%
exit /B 0
:l2
if not exist xproj\vitis mkdir xproj\vitis
where xsct.bat >nul 2>nul
if %errorlevel% neq 0 (
    echo xsct.bat not found - have you run settings64.bat?
    exit /B -1
)
if not exist xproj\vitis\%~1_%~2 goto l3
@echo deleting old Vitis files...
del /f /q /s xproj\vitis\%~1_%~2 >nul
@echo removing old Vitis directories...
rmdir /q /s xproj\vitis\%~1_%~2
:l3
call vivado -mode tcl -nolog -nojournal -source xproj/xbuild1.tcl -tclargs %~1 %~2 %jobs%
call xsct xproj/xbuild2.tcl %1 %2
call vivado -mode tcl -nolog -nojournal -source xproj/xbuild3.tcl -tclargs %~1 %~2 %jobs%
exit /B 0
:error_arguments
echo "usage:"
echo "  xbuild.bat design_name board_name <jobs>"
exit /B -1
:error_xscripts
echo "cannot find xilinx build scripts"
exit /B -1
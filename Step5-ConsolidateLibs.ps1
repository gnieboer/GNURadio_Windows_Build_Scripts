#
# GNURadio Windows Build System
# Step5_ConsolidateLibs.ps1
#
# Geof Nieboer
#
# NOTES:
# Each module is designed to be run independently, so sometimes variables
# are set redundantly.  This is to enable easier debugging if one package needs to be re-run
#

# script setup
$ErrorActionPreference = "Stop"

# setup helper functions
if ($script:MyInvocation.MyCommand.Path -eq $null) {
    $mypath = "."
} else {
    $mypath =  Split-Path $script:MyInvocation.MyCommand.Path
}
if (Test-Path $mypath\Setup.ps1) {
	. $mypath\Setup.ps1 -Force
} else {
	. $root\scripts\Setup.ps1 -Force
}

$mm = GetMajorMinor($gnuradio_version)
Write-Host "Consolidating for version $mm"

pushd $root

SetLog "Consolidate Libraries"
$configuration = "Release"

Write-Host ""
Write-Host "Starting Consolidation for $configuration"

# move qwtplot3d
Write-Host -NoNewline "Consolidating QwtPlot3D..."
New-Item -ItemType Directory -Force -Path $root/src-stage1-dependencies/vcpkg/installed/x64-windows/include/qwt3d *>> $log
cp -Recurse -Force $root/src-stage1-dependencies/Qwtplot3d/build/$configuration/qwtplot3d.lib $root/src-stage1-dependencies/vcpkg/installed/x64-windows/lib/ *>> $log
cp -Recurse -Force $root/src-stage1-dependencies/Qwtplot3d/build/$configuration/qwtplot3d.dll $root/src-stage1-dependencies/vcpkg/installed/x64-windows/bin/ *>> $log
cp -Recurse -Force $root/src-stage1-dependencies/Qwtplot3d/include/* $root/src-stage1-dependencies/vcpkg/installed/x64-windows/include/qwt3d *>> $log
"complete"

# move qt5
Write-Host -NoNewline "Consolidating Qt5..."
cp -Recurse -Force  $root/src-stage1-dependencies/vcpkg/installed/x64-windows/tools/python3/lib/site-packages/PyQt5/Qt/bin/*.* $root/src-stage1-dependencies/vcpkg/installed/x64-windows/bin/ *>> $log
cp -Recurse -Force  $root/src-stage1-dependencies/vcpkg/installed/x64-windows/tools/python3/lib/site-packages/PyQt5/Qt/plugins $root/src-stage1-dependencies/vcpkg/installed/x64-windows/bin/ *>> $log
"complete"

# uhd
Write-Host -NoNewline "Consolidating UHD..."
cp -Recurse -Force $root\src-stage1-dependencies\uhd/dist/$configuration/bin/uhd.dll $root/src-stage1-dependencies/vcpkg/installed/x64-windows/bin/ *>> $log
cp -Recurse -Force $root\src-stage1-dependencies\uhd/dist/$configuration/lib/uhd.lib $root/src-stage1-dependencies/vcpkg/installed/x64-windows/lib/ *>> $log
cp -Recurse -Force $root\src-stage1-dependencies\uhd/dist/$configuration/include/* $root/src-stage1-dependencies/vcpkg/installed/x64-windows/include/ *>> $log
robocopy "$root/src-stage1-dependencies/uhd/dist/$configuration" "$root/src-stage1-dependencies/vcpkg/installed/x64-windows" /e *>> $log
"complete"
	
# MPIR
#
# GNURadio will want to link statically
#
Write-Host -NoNewline "Consolidating MPIR..."
cp -Recurse -Force $root\src-stage1-dependencies\vcpkg\installed/x64-windows-static-md/lib/mpirxx.lib $root/src-stage1-dependencies/vcpkg/installed/x64-windows/lib/ *>> $log
cp -Recurse -Force $root\src-stage1-dependencies\vcpkg\installed/x64-windows-static-md/include/mpirxx.h $root/src-stage1-dependencies/vcpkg/installed/x64-windows/include/ *>> $log
cp -Recurse -Force $root\src-stage1-dependencies\vcpkg\installed/x64-windows-static-md/include/gmpxx.h $root/src-stage1-dependencies/vcpkg/installed/x64-windows/include/ *>> $log
"complete"

popd

""
"COMPLETED STEP 5: Libraries have been consolidated for easy CMake referencing to build GNURadio and OOT modules"
""

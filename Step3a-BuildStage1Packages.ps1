# GNURadio Windows Build System
#
# Geof Nieboer
#
# NOTES:
# Each module is designed to be run independently, so sometimes variables
# are set redundantly.  This is to enable easier debugging if one package needs to be re-run
#

# script setup
$ErrorActionPreference = "Stop"

# setup helper functions and variables
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
$env:_CL_ = ""
$env:_LINK_ = ""

# Build packages needed for Stage 1
cd src-stage1-dependencies

# Start with packages that can be installed using vcpkg
cd vcpkg

# build vcpkg itself
#SetLog "VCPkg"
#Write-Host -NoNewLine "Building VCPkg..."
#git pull *>> $Log
#./bootstrap-vcpkg.bat -disableMetrics -win64 *>> $Log
#Write-Host -NoNewLine "updating package lists..."
#./vcpkg update *>> $Log
#Write-Host -NoNewLine "upgrading existing packages..."
#./vcpkg upgrade --no-dry-run  *>> $Log
#Write-Host "complete"

# So while in theory every below vcpkg compatible package could be installed in a single command
# history teaches something will fail, so the more granular we handle the installations
# the easier it will be to quickly find root causes

# ____________________________________________________________________________________________________________
# zlib
VCPkgInstall zlib

# ____________________________________________________________________________________________________________
# bzip2
VCPkgInstall bzip2

# ____________________________________________________________________________________________________________
# libpng 
# uses zlib but incorporates the source directly so doesn't need to be built after zlib
VCPkgInstall libpng

# ____________________________________________________________________________________________________________
# pthreads
#
VCPkgInstall pthreads

# ____________________________________________________________________________________________________________
# freetype
#
VCPkgInstall freetype

# __________________________________________________________________
# libiconv
#
VCPkgInstall libiconv

# __________________________________________________________________
# get-text 
#
VCPkgInstall gettext

# ____________________________________________________________________________________________________________
# fontconfig
#
VCPkgInstall fontconfig
# There (was) a bug in this package where the .lib file instructs linkage to libfontconfig-1.dll file but the package actually creates fontconfig-1.dll
#If (Test-Path $root/src-stage1-dependencies/vcpkg/installed/x64-windows/bin/fontconfig-1.dll) {
#	Move-File $root/src-stage1-dependencies/vcpkg/installed/x64-windows/bin/fontconfig-1.dll $root/src-stage1-dependencies/vcpkg/installed/x64-windows/bin/libfontconfig-1.dll
#}
# ____________________________________________________________________________________________________________
# glib
#
VCPkgInstall glib

# ____________________________________________________________________________________________________________
# pixman
#
VCPkgInstall pixman

# ____________________________________________________________________________________________________________
# cairo
#
VCPkgInstall cairo

# ____________________________________________________________________________________________________________
# harfbuzz
#
VCPkgInstall harfbuzz

# ____________________________________________________________________________________________________________
# atk
#
#VCPkgInstall atk

# ____________________________________________________________________________________________________________
# gdk-pixbuf
#
#VCPkgInstall gdk-pixbuf

# ____________________________________________________________________________________________________________
# libepoxy
#
#VCPkgInstall libepoxy

# ____________________________________________________________________________________________________________
# pango
#
#VCPkgInstall pango

# ____________________________________________________________________________________________________________
# GTK
#
#VCPkgInstall gtk

# ____________________________________________________________________________________________________________
# libusb
#
VCPkgInstall libusb

# __________________________________________________________________
# libxml2
# must be after libiconv
#
VCPkgInstall libxml2

# ____________________________________________________________________________________________________________
# libxslt 1.1.29
#
# uses libxml, zlib, and iconv
VCPkgInstall libxslt

# ____________________________________________________________________________________________________________
# SDL
VCPkgInstall sdl1

# ____________________________________________________________________________________________________________
# portaudio
VCPkgInstall portaudio

# ____________________________________________________________________________________________________________
# cppunit
VCPkgInstall cppunit

# ____________________________________________________________________________________________________________
# fftw3
VCPkgInstall fftw3

# ____________________________________________________________________________________________________________
# openssl 
#
# required by Qt5 currently (this may be re-configurable)
#
VCPkgInstall openssl

# ____________________________________________________________________________________________________________
# boost
VCPkgInstall boost

# ____________________________________________________________________________________________________________
# libsodium
# 
VCPkgInstall libsodium

# ____________________________________________________________________________________________________________
# zeromq
#
VCPkgInstall zeromq
VCPkgInstall cppzmq

# ____________________________________________________________________________________________________________
# gsl
#
VCPkgInstall gsl

# ____________________________________________________________________________________________________________
# openblas
#
VCPkgInstall openblas

# ____________________________________________________________________________________________________________
# lapack
#
# This is no longer required for scipy/numpy, it is only required for gr-specest which also requires a fortran compiler
#
VCPkgInstall lapack

# ____________________________________________________________________________________________________________
# mbedtls (polarssl)
#
VCPkgInstall mbedtls
	
# ____________________________________________________________________________________________________________
# log4cpp
# 
VCPkgInstall log4cpp

# ____________________________________________________________________________________________________________
# MPIR
#
VCPkgInstall mpir
VCPkgInstall mpir -static 

# ____________________________________________________________________________________________________________
# jasper
#
VCPkgInstall jasper

# ____________________________________________________________________________________________________________
# Qt5
#
VCPkgInstall qt5-base
VCPkgInstall qt5-svg
VCPkgInstall qt5-imageformats
VCPkgInstall qt5-declarative

# ____________________________________________________________________________________________________________
# QWT 6
#
VCPkgInstall qwt


# ____________________________________________________________________________________________________________
# python3 (currently 3.9)
# 
# Python 3.8 has a new DLL search methodology 
# so we need to add a custom gnuradio.pth file to site-package to tell it to look in /bin 
#
# Note that we also install the VCPkg python as dependencies for other package, but it defaults to 3.9 and so may not work
#
VCPkgInstall python3

# Need to move to tools:
# libs/python39.lib  (some packages tries to link here instead of the other)
cp $root/src-stage1-dependencies/vcpkg/downloads/tools/python/python-3.9.0-x64/libs/python39.lib $root/src-stage1-dependencies/vcpkg/installed/x64-windows/tools/python3/libs -Force >> $Log
# python3.dll 	(PyQt5 links to this)
cp $root/src-stage1-dependencies/vcpkg/downloads/tools/python/python-3.9.0-x64/python3.dll $root/src-stage1-dependencies/vcpkg/installed/x64-windows/tools/python3 -Force >> $Log
# Include 
cp -recurse $root/src-stage1-dependencies/vcpkg/packages/python3_x64-windows/include/python3.9/* $root/src-stage1-dependencies/vcpkg/installed/x64-windows/tools/python3/include -Force >> $Log
# gnuradio.pth 
mv $root/src-stage1-dependencies/gnuradio.pth $root/src-stage1-dependencies/vcpkg/installed/x64-windows/tools/python3/lib/site-packages -Force >> $Log

SetLog "VCPkgIntegration"
# Integrate packages with MSBuild and CMake
./vcpkg integrate install  *>> $Log 
# Now install remaining packages...

# ____________________________________________________________________________________________________________
# QwtPlot3D
#
# 
SetLog "QwtPlot3d"
cd $root\src-stage1-dependencies\qwtplot3d
Write-Host -NoNewline "building QwtPlot3d Release..."
if ((TryValidate "build/Release/qwtplot3d.dll" "build/Release/qwtplot3d.lib") -eq $false) {
	New-Item -Force -ItemType Directory build/Release  *>> $Log  
	$ErrorActionPreference = "Continue"
	$env:PATH = "$root\src-stage1-dependencies\vcpkg\installed\x64-windows\tools\qt5\bin;$root\src-stage1-dependencies\vcpkg\installed\x64-windows\bin;" + $oldPath 
	$env:_CL_ = " /DQ_WS_WIN " #This is an obsolete macro that Qwt is looking for that Qt5 no longer puts out.  It should be Q_OS_WIN now.  Without it no symbols will be exported
	& qmake.exe qwtplot3d.pro "CONFIG += zlib"  *>> $Log  
	# this invocation of qmake seems to get confused about what version of msvc to build for so we need to manually upgrade
	devenv qwtplot3d.vcxproj /Upgrade *>> $Log  
	msbuild .\qwtplot3d.vcxproj /m /p:"configuration=Release;platform=x64" *>> $Log  
	Move-Item -Force lib/qwtplot3d.lib build/Release
	Move-Item -Force lib/qwtplot3d.dll build/Release
	Move-Item -Force lib/qwtplot3d.exp build/Release
	Remove-Item Backup -Recurse  
	Remove-Item UpgradeLog.htm 
	Validate "build/Release/qwtplot3d.dll" "build/Release/qwtplot3d.lib"
	$env:Path = $oldPath
} else {
	Write-Host "already built"
}

#__________________________________________________________________________________________
# wheel
#
PipInstall wheel "$pythonroot/lib/site-packages/wheel/__init__.py"

# ____________________________________________________________________________________________________________
# Mako
# Mako is a python-only package can be installed automatically
# used by UHD drivers
#
PipInstall "mako" "$pythonroot/lib/site-packages/mako/__init__.py"

# ____________________________________________________________________________________________________________
# Requests
# Requests is a python-only package can be installed automatically
# used by UHD helper script that downloads the UHD firmware images in step 8
#
PipInstall "Requests" "$pythonroot/lib/site-packages/Requests/__init__.py"

#__________________________________________________________________________________________
# numpy
#
# Right now 1.19.4 is completely broken on windows.  This forces 1.19.3, but later packages request the latest as dependencies so 
# for the moment a manual reinstall is required prior to Step7.  This will likely only last until January 2021-ish
#
PipInstall "numpy" "$pythonroot/lib/site-packages/numpy/__init__.py"

# ____________________________________________________________________________________________________________
# UHD 
#
SetLog "UHD"
Write-Host -NoNewline "building uhd..."
$ErrorActionPreference = "Continue"
cd $root\src-stage1-dependencies\uhd\host
New-Item -ItemType Directory -Force -Path .\build  *>> $Log
cd build 
if ((TryValidate "..\..\dist\Release\bin\uhd.dll" "..\..\dist\Release\lib\uhd.lib" "..\..\dist\Release\include\uhd.h") -eq $false) {
	Write-Host -NoNewline "configuring ..."
	$env:Path = "$pythonroot;$pythonroot/Dlls;"+ $oldPath
	$env:PYTHONPATH="$pythonroot;$pythonroot/DLLs;$pythonroot/Lib/site-packages"
    $env:PYTHONHOME="$pythonroot"
	$env:_LINK_= " boost_chrono-vc140-mt.lib boost_thread-vc140-mt.lib boost_filesystem-vc140-mt.lib boost_program_options-vc140-mt.lib boost_date_time-vc140-mt.lib boost_regex-vc140-mt.lib boost_system-vc140-mt.lib boost_serialization-vc140-mt.lib boost_unit_test_framework-vc140-mt.lib "
	& cmake .. `
		-G $cmakeGenerator -A x64 `
		-DCMAKE_TOOLCHAIN_FILE="$root/src-stage1-dependencies/vcpkg/scripts/buildsystems/vcpkg.cmake" `
		-DENABLE_PYTHON_API=ON `
		-DPYTHON_EXECUTABLE="$pythonroot\$pythonexe" `
		-DCMAKE_CXX_FLAGS=" /DBOOST_FORCE_SYMMETRIC_OPERATORS /DBOOST_BIND_NO_PLACEHOLDERS /EHsc "  *>> $Log 
	Write-Host -NoNewline "building..."
	msbuild .\UHD.sln /m /p:"configuration=RelWithDebInfo;platform=x64" *>> $Log 
	Write-Host -NoNewline "installing..."
	& cmake -DCMAKE_INSTALL_PREFIX="$root/src-stage1-dependencies/uhd\dist\Release" -DBUILD_TYPE="RelWithDebInfo" -P cmake_install.cmake *>> $Log
	New-Item -ItemType Directory -Path $root/src-stage1-dependencies/uhd\dist\Release\share\uhd\examples\ -Force *>> $Log
	cp -Recurse -Force $root/src-stage1-dependencies/uhd/host/build/examples/RelWithDebInfo/* $root/src-stage1-dependencies/uhd\dist\Release\share\uhd\examples\
	$env:_LINK_= ""
	Validate "..\..\dist\Release\bin\uhd.dll" "..\..\dist\Release\lib\uhd.lib" "..\..\dist\Release\include\uhd.h"
} else {
	Write-Host "already built"
}
	
cd $root/scripts

""
"COMPLETED STEP 3: Core Win32 dependencies have been built"
""
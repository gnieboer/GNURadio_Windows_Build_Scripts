# GNURadio Windows Build System
# Geof Nieboer

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

# Retrieve packages needed for Stage 1
cd $root/src-stage1-dependencies
SetLog "GetPackages"

#vcpkg
getPackage https://github.com/Microsoft/vcpkg.git 

# python
GetPackage https://www.python.org/ftp/python/$python_version/python-$python_version-embed-amd64.zip python-$python_version -AddFolderName
GetPackage https://www.python.org/ftp/python/$python_version/python-$python_version-amd64.exe 

# UHD
GetPackage https://github.com/EttusResearch/uhd.git -branch v$UHD_Version 

# QwtPlot3D
GetPackage http://www.gcndevelopment.com/gnuradio/downloads/sources/qwtplot3d.7z

# pkgconfig
GetPackage https://pypi.python.org/packages/source/p/pkgconfig/pkgconfig-$pkgconfig_version.tar.gz
GetPackage http://downloads.sourceforge.net/project/pkgconfiglite/0.28-1/pkg-config-lite-0.28-1_bin-win32.zip

# pygobject
GetPackage https://gitlab.gnome.org/GNOME/pygobject/-/archive/$pygobject3_version/pygobject-$pygobject3_version.zip

# GTK 3 (needed for introspection library only)
GetPackage http://www.gcndevelopment.com/gnuradio/downloads/sources/gtk3-x64.7z

# cleanup
""
"COMPLETED STEP 2: Source code needed to build core win32 dependencies and python dependencies have been downloaded"
""
# return to original directory
cd $root/scripts
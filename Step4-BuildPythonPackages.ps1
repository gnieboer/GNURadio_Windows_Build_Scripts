#
# GNURadio Windows Build System
# Step4_BuildPythonPackages.ps1
#
# Geof Nieboer
#
# NOTES:
# Each module is designed to be run independently, so sometimes variables
# are set redundantly.  This is to enable easier debugging if one package needs to be re-run
#
# This module builds the various python packages above the essentials included
# in the build originally.  We are building three versions, one for AVX2 only
# and one for release and one for debug

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

$env:Path = "$pythonroot;$pythonroot/Dlls;$root/src-stage1-dependencies/vcpkg/installed/x64-windows/bin"+ ";$oldPath"
$env:PKG_CONFIG_PATH = "$root/src-stage1-dependencies/vcpkg/installed/x64-windows/lib/pkgconfig" 
$env:PYTHONPATH = ""
$env:PYTHONHOME = "$pythonroot"
$mm = GetMajorMinor($gnuradio_version)

$ErrorActionPreference = "Stop"

$configuration = "ReleaseDLL"
""
"installing python packages for $configuration"

if ($configuration -match "Debug") { 
	$d = "d" 
	$debugext = "_d"
	$debug = "--debug"
} else {
	$d = ""
	$debugext = ""
	$debug = ""
}

#__________________________________________________________________________________________
# sip
#
PipInstall sip "$pythonroot/lib/site-packages/bin/sip-wheel.exe"

#__________________________________________________________________________________________
# PyQt5
#
PipInstall PyQt5 "$pythonroot/lib/site-packages/PyQt5/__init__.py"
	
#__________________________________________________________________________________________
# Cython
#
PipInstall Cython "$pythonroot/lib/site-packages/Cython/__init__.py"

#__________________________________________________________________________________________
# PyTest
# used for testing numpy/scipy etc only (after numpy 1.15), not in gnuradio directly
#
PipInstall pytest "$pythonroot/lib/site-packages/pytest/__init__.py"

#__________________________________________________________________________________________
# scipy
#
PipInstall scipy "$pythonroot/lib/site-packages/scipy/__init__.py"

#__________________________________________________________________________________________
# PyOpenGL
#
PipInstall PyOpenGL "$pythonroot/lib/site-packages/OpenGL/version.py"

#__________________________________________________________________________________________
# PyOpenGL-accelerate
#
PipInstall PyOpenGL_accelerate "$pythonroot/lib/site-packages/OpenGL_accelerate/wrapper.cp$pyver-win_amd64.pyd"

#__________________________________________________________________________________________
# PyYAML
#
PipInstall PyYAML "$pythonroot/lib/site-packages/yaml/__init__.py"	

#__________________________________________________________________________________________
# cheetah
#
# will download and install Markdown automatically
PipInstall Cheetah3 "$pythonroot/lib/site-packages/Cheetah/__init__.py"

#__________________________________________________________________________________________
# sphinx
#
# will also download/install a large number of dependencies
# pytz, babel, colorama, snowballstemmer, sphinx-rtd-theme, six, Pygments, docutils, Jinja2, alabaster, sphinx
PipInstall sphinx "$pythonroot/lib/site-packages/bin/sphinx-build.exe"

#__________________________________________________________________________________________
# pygi
#
PipInstall pygi "$pythonroot/lib/site-packages/pygi.py"
	
#__________________________________________________________________________________________
# click
#
PipInstall click "$pythonroot/lib/site-packages/click/__init__.py"
PipInstall click-plugins "$pythonroot/lib/site-packages/click_plugins/__init__.py"
	
#__________________________________________________________________________________________
# lxml
#
PipInstall lxml "$pythonroot/lib/site-packages/lxml/__init__.py"

#__________________________________________________________________________________________
# pyzmq
#
PipInstall pyzmq "$pythonroot/lib/site-packages/zmq/__init__.py"
	
# ____________________________________________________________________________________________________________
# tensorflow
#
# requires numpy
#
#PipInstall tensorflow "$pythonroot/lib/site-packages/tensorflow/__init__.py"
	
# ____________________________________________________________________________________________________________
# matplotlib
#
# required by gr-radar
# also installs Pillow, required by gr-paint
#
PipInstall matplotlib "$pythonroot/lib/site-packages/matplotlib/__init__.py"

# ____________________________________________________________________________________________________________
# bitarray
#
# required by gr-burst
#
PipInstall bitarray "$pythonroot/lib/site-packages/bitarray/__init__.py"

#__________________________________________________________________________________________
# pkg-config
# both the binary (using pkg-config-lite to avoid dependency issues) and the python wrapper
#
SetLog "$configuration pkg-config"
pushd $root\src-stage1-dependencies\pkgconfig-$pkgconfig_version
if ((TryValidate "$root\bin\pkg-config.exe" "dist/pkgconfig-$pkgconfig_version-py3-none-any.whl" "$pythonroot/lib/site-packages/pkgconfig/pkgconfig.py") -eq $false) {
	Write-Host -NoNewline "building pkg-config..."
	$ErrorActionPreference = "Continue"
	& $pythonroot/$pythonexe setup.py build  $debug *>> $log
	Write-Host -NoNewline "installing..."
	& $pythonroot/$pythonexe setup.py install --single-version-externally-managed --root=/ *>> $log
	Write-Host -NoNewline "crafting wheel..."
	& $pythonroot/$pythonexe setup.py bdist_wheel *>> $log
	# yes, this copies the same file three times, but since it's conceptually linked to 
	# the python wrapper, I kept this here for ease of maintenance
	cp $root\src-stage1-dependencies\pkg-config-lite-0.28-1\bin\pkg-config.exe $root\bin -Force  *>> $log
	New-Item -ItemType Directory -Force $pythonroot\lib\pkgconfig *>> $log
	$ErrorActionPreference = "Stop"
	Validate "$root\bin\pkg-config.exe" "dist/pkgconfig-$pkgconfig_version-py3-none-any.whl" "$pythonroot/lib/site-packages/pkgconfig/pkgconfig.py"
} else {
	Write-Host "pkg-config already built..."
}
popd

#__________________________________________________________________________________________
# pycairo
#
PipInstall pycairo "$pythonroot\lib\site-packages\cairo\_cairo.cp$pyver-win_amd64.pyd"

#__________________________________________________________________________________________
# Pygobject
#
# introspection library could not be built via pip install
# and it is not installed via vcpkg yet either (the rest of the GTK is, however)
#
SetLog "Pygobject"
pushd $root\src-stage1-dependencies\Pygobject-$pygobject3_version
if ($false) {
	PipInstall pygobject "$pythonroot\lib\site-packages\gi\_gi.cp$pyver-win_amd64.pyd"
} else {
	if ((TryValidate "dist/pygobject-$pygobject3_version-cp$pyver-cp${pyver}-win_amd64.whl" "$pythonroot\lib\site-packages\gi\_gi.cp$pyver-win_amd64.pyd") -eq $false) {
		Write-Host -NoNewline "building Pygobject 3..."
		$ErrorActionPreference = "Continue" 
		$env:INCLUDE = "$root/src-stage1-dependencies/vcpkg/installed/x64-windows/include;$root/src-stage1-dependencies/vcpkg/installed/x64-windows/include/glib-2.0;$pythonroot/../../include/python3.9;$root/src-stage1-dependencies/x64/include/gobject-introspection-1.0/girepository;$root/src-stage1-dependencies/x64/include/glib-2.0;$root/src-stage1-dependencies/x64/include;$root/src-stage1-dependencies/x64/include/cairo;$root/src-stage1-dependencies/x64/include;$root/src-stage1-dependencies/x64/lib/glib-2.0/include;$root/src-stage1-dependencies/x64/include/gobject-introspection-1.0;$root/src-stage1-dependencies/x64/include/gtk-3.0" + $oldInclude 
		$env:PATH = "$root/bin;$root/src-stage1-dependencies/vcpkg/installed/x64-windows/bin;$root/src-stage1-dependencies/x64/bin" + $oldpath
		$env:PKG_CONFIG_PATH = "$root/bin;$root/src-stage1-dependencies/vcpkg/installed/x64-windows/pkgconfig;$root/src-stage1-dependencies/x64/lib/pkgconfig;$pythonroot/lib/pkgconfig"
		$env:LIB = "$root/src-stage1-dependencies/vcpkg/installed/x64-windows/lib;$root/src-stage1-dependencies/x64/lib;" + $oldlib
		if ((Test-Path "$root/src-stage1-dependencies/x64/lib/libffi.lib") -and !(Test-Path "$root/src-stage1-dependencies/x64/lib/ffi.lib")) {
			Rename-Item -Path "$root/src-stage1-dependencies/x64/lib/libffi.lib" -NewName "ffi.lib"
		}
		& $pythonroot/$pythonexe setup.py build --compiler=msvc  *>> $Log
		Write-Host -NoNewline "installing..."
		& $pythonroot/$pythonexe setup.py install --single-version-externally-managed  --root=/ *>> $Log
		Write-Host -NoNewline "creating exe..."
		& $pythonroot/$pythonexe setup.py bdist_wininst *>> $Log
		Write-Host -NoNewline "crafting wheel..."
		& $pythonroot/$pythonexe setup.py bdist_wheel *>> $Log
		$env:_CL_ = ""
		$env:LIB = $oldLIB 
		$env:PATH = $oldPath
		$env:PKG_CONFIG_PATH = ""
		$ErrorActionPreference = "Stop" 
		Validate "dist/pygobject-$pygobject3_version-cp$pyver-cp${pyver}-win_amd64.whl" "$pythonroot\lib\site-packages\gi\_gi.cp$pyver-win_amd64.pyd"
	} else {
		Write-Host "pygobject3 already built..."
	}
}
popd

"finished installing python packages for $configuration"

cd $root/scripts 

""
"COMPLETED STEP 4: Python dependencies / packages have been built and installed"
""

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

$env:Path = "$pythonroot;$pythonroot/Dlls"+ ";$oldPath"
$env:PYTHONHOME="$pythonroot"
$mm = GetMajorMinor($gnuradio_version)

#__________________________________________________________________________________________
# sip
#
$ErrorActionPreference = "Continue"
SetLog "sip"
Write-Host "building sip..."
pushd $root\src-stage1-dependencies\sip-$sip_version
# reset these in case previous run was stopped in mid-build
$env:_LINK_ = ""
$env:_CL_ = ""

$type = "ReleaseDLL"
Write-Host -NoNewline "  $type..."
$dflag = if ($type -match "Debug") {"--debug"} else {""}
$kflag = if ($type -match "Dll") {""} else {" --static"}
$debugext = if ($type -match "Debug") {"_d"} else {""}
if ((TryValidate "$pythonroot/sip.exe" "$pythonroot/include/sip.h" "$pythonroot/lib/site-packages/sip$debugext.pyd") -eq $false) {
	if ($type -match "AVX2") {$env:_CL_ = "/Ox /arch:AVX2 "} else {$env:_CL_ = ""}
	if (Test-Path sipconfig.py) {del sipconfig.py}
	"FLAGS: $kflag $dflag" >> $Log 
	"command line : configure.py $dflag $kflag -p win32-msvc2015" >> $Log
	Write-Host -NoNewline "configuring..."
	& $pythonroot\python$debugext.exe configure.py $dflag $kflag --platform win32-msvc2015 *>> $Log
	Write-Host -NoNewline "building..."
	nmake clean *>> $Log
	nmake *>> $Log
	New-Item -ItemType Directory -Force -Path ./build/x64/$type *>> $Log
	cd siplib
	if ($type -match "Dll") {
		copy sip$debugext.pyd ../build/x64/$type/sip$debugext.pyd
		copy sip$debugext.exp ../build/x64/$type/sip$debugext.exp
		if ($type -match "Debug") {
			copy sip$debugext.pdb ../build/x64/$type/sip$debugext.pdb
			copy sip$debugext.ilk ../build/x64/$type/sip$debugext.ilk
		}
	}
	copy sip$debugext.lib ../build/x64/$type/sip$debugext.lib
	copy sip.h ../build/x64/$type/sip.h
	cd ../sipgen
	copy sip.exe ../build/x64/$type/sip.exe
	cd ..
	copy sipdistutils.py ./build/x64/$type/sipdistutils.py
	if ($type -match "Dll") {
		Write-Host -NoNewline "installing..."
		copy sipconfig.py ./build/x64/$type/sipconfig.py
    	nmake install *>> $Log
		Validate "$pythonroot/sip.exe" "$pythonroot/include/sip.h" "$pythonroot/lib/site-packages/sip$debugext.pyd" 
	}
	nmake clean *>> $Log
	$env:_CL_ = ""
} else {
	Write-Host "already built"
}
popd

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
# PyQwt5
# requires Python, Qwt, Qt, PyQt, and Numpy
#
if ($mm -eq "3.7") {
	SetLog "$configuration PyQwt5"
	pushd $root\src-stage1-dependencies\PyQwt5-master
	if ((TryValidate "dist/PyQwt-5.2.1.win-amd64.$configuration.exe" "$pythonroot/lib/site-packages/PyQt4/Qwt5/Qwt$debugext.pyd" "$pythonroot/lib/site-packages/PyQt4/Qwt5/_iqt.pyd" "$pythonroot/lib/site-packages/PyQt4/Qwt5/qplt.py") -eq $false) {
		Write-Host -NoNewline "configuring PyQwt5..."
		$ErrorActionPreference = "Continue" 
		# qwt_version_info will look for QtCore4.dll, never Qt4Core4d.dll so point it to the ReleaseDLL regardless of the desired config
		if ($configuration -eq "DebugDLL") {$QtVersion = "ReleaseDLL"} else {$QtVersion = $configuration}
		$env:Path = "$root\src-stage1-dependencies\Qt4\build\$QtVersion\bin;$root\src-stage1-dependencies\Qwt-$qwt_version\build\x64\Debug-Release\lib;" + $oldpath
		$envLib = $oldlib
		if ($type -match "AVX2") {$env:_CL_ = "/Ox /arch:AVX2 /wd4577 " } else {$env:_CL_ = "/wd4577 " }
		cd configure
		# CALL "../../%1/Release/python$pyver/python.exe" configure.py %DEBUG% --extra-cflags=%FLAGS% %DEBUG% -I %~dp0..\qwt-5.2.3\build\include -L %~dp0..\Qt-4.8.7\lib -L %~dp0..\qwt-5.2.3\build\lib -l%QWT_LIB%
		if ($configuration -eq "DebugDLL") {
			$env:_LINK_ = " /FORCE /LIBPATH:""$root/src-stage1-dependencies/Qt4/build/ReleaseDLL/lib"" /LIBPATH:""$root/src-stage1-dependencies/Qt4/build/Release-AVX2/lib"" /DEFAULTLIB:user32  /DEFAULTLIB:advapi32  /DEFAULTLIB:ole32  /DEFAULTLIB:ws2_32  /DEFAULTLIB:qtcored4 " 
			& $pythonroot/$pythonexe configure.py --debug --extra-cflags="-Zi -wd4577"                -I $root\src-stage1-dependencies\Qwt-$qwt_version\build\x64\Debug-Release\include -L $root\src-stage1-dependencies\Qt4\build\$QtVersion\lib   -l qtcored4     -L $root\src-stage1-dependencies\Qwt-$qwt_version\build\x64\Debug-Release\lib -l"$root\src-stage1-dependencies\Qwt-$qwt_version\build\x64\Debug-Release\lib\qwtd" -j4 --sip-include-dirs ..\..\sip-$sip_version\build\x64\Debug --sip-include-dirs ..\..\PyQt4\sip *>> $log
		} elseif ($configuration -eq "ReleaseDLL") {
			& $pythonroot/$pythonexe configure.py         --extra-cflags="-Zi -wd4577"                -I $root\src-stage1-dependencies\Qwt-$qwt_version\build\x64\Debug-Release\include -L $root\src-stage1-dependencies\Qt4\build\ReleaseDLL\lib -l qtcore4       -L $root\src-stage1-dependencies\Qwt-$qwt_version\build\x64\Debug-Release\lib -l"$root\src-stage1-dependencies\Qwt-$qwt_version\build\x64\Debug-Release\lib\qwt"  -j4 --sip-include-dirs ..\..\sip-$sip_version\build\x64\Release *>> $log
		} else {
			& $pythonroot/$pythonexe configure.py         --extra-cflags="-Zi -Ox -arch:AVX2 -wd4577" -I $root\src-stage1-dependencies\Qwt-$qwt_version\build\x64\Release-AVX2\include  -L $root\src-stage1-dependencies\Qt4\build\ReleaseDLL-AVX2\lib -l qtcore4  -L $root\src-stage1-dependencies\Qwt-$qwt_version\build\x64\Release-AVX2\lib  -l"$root\src-stage1-dependencies\Qwt-$qwt_version\build\x64\Release-AVX2\lib\qwt"   -j4 --sip-include-dirs ..\..\sip-$sip_version\build\x64\Release-AVX2 *>> $log
		}
		nmake clean *>> $log
		Write-Host -NoNewline "building..."
		Exec {nmake} *>> $log
		Write-Host -NoNewline "installing..."
		Exec {nmake install} *>> $log
		Write-Host -NoNewline "creating winstaller..."
		cd ..
		& $pythonroot/$pythonexe setup.py bdist_wininst   *>> $log
		move dist/PyQwt-5.2.1.win-amd64.exe dist/PyQwt-5.2.1.win-amd64.$configuration.exe -Force
		$env:Path = $oldpath
		$env:_CL_ = ""
		$env:_LINK_ = ""
		$ErrorActionPreference = "Stop"
		Validate "dist/PyQwt-5.2.1.win-amd64.$configuration.exe" "$pythonroot/lib/site-packages/PyQt4/Qwt5/Qwt$debugext.pyd" "$pythonroot/lib/site-packages/PyQt4/Qwt5/_iqt.pyd" "$pythonroot/lib/site-packages/PyQt4/Qwt5/qplt.py"
	} else {
		Write-Host "PyQwt5 already built..."
	}
	popd
}

#__________________________________________________________________________________________
# PyOpenGL
#
PipInstall PyOpenGL "$pythonroot/lib/site-packages/OpenGL/version.py"

#__________________________________________________________________________________________
# PyOpenGL-accelerate
#
PipInstall PyOpenGL_accelerate "$pythonroot/lib/site-packages/OpenGL_accelerate/wrapper.cp$pyver-win_amd64.pyd"

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
# requires pkg-config
# While the latest version gets rid of the WAF build system (thank you!) 
# the new version doesn't generate a pkgconfig file that pyGTK is looking for later.
# So we need to manually build it for the moment
#
PipInstall pycairo "$pythonroot\lib\site-packages\cairo\_cairo.cp$pyver-win_amd64.pyd"

#__________________________________________________________________________________________
# Pygobject
#
# introspection library could not be built via pip install
#
SetLog "Pygobject"
pushd $root\src-stage1-dependencies\Pygobject-$pygobject3_version
if ((TryValidate "dist/gtk-3.0/pygobject-$pygobject3_version-cp$pyver-cp${pyver}m-win_amd64.whl" "$pythonroot\lib\site-packages\gi\_gi.cp$pyver-win_amd64.pyd") -eq $false) {
	Write-Host -NoNewline "building Pygobject 3..."
	$ErrorActionPreference = "Continue" 
	$env:INCLUDE = "$root/src-stage1-dependencies/x64/include;$root/src-stage1-dependencies/x64/include/gobject-introspection-1.0/girepository;$root/src-stage1-dependencies/x64/include/glib-2.0;$root/src-stage1-dependencies/x64/include;$root/src-stage1-dependencies/x64/include/cairo;$root/src-stage1-dependencies/x64/include;$root/src-stage1-dependencies/x64/lib/glib-2.0/include;$root/src-stage1-dependencies/x64/include/gobject-introspection-1.0;$root/src-stage1-dependencies/x64/include/gtk-3.0" + $oldInclude 
	$env:PATH = "$root/bin;$root/src-stage1-dependencies/x64/bin;$root/src-stage1-dependencies/x64/lib;" + $oldpath
	$env:PKG_CONFIG_PATH = "$root/bin;$root/src-stage1-dependencies/x64/lib/pkgconfig;$pythonroot/lib/pkgconfig"
	$env:LIB = "$root/src-stage1-dependencies/x64/lib;" + $oldlib
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
	New-Item -ItemType Directory -Force -Path .\dist\gtk-3.0 *>> $Log
	cd dist
	move ./pygobject-$pygobject3_version-cp$pyver-cp${pyver}m-win_amd64.whl gtk-3.0/pygobject-$pygobject3_version-cp$pyver-cp${pyver}m-win_amd64.whl -Force
	cd ..
	$env:_CL_ = ""
	$env:LIB = $oldLIB 
	$env:PATH = $oldPath
	$env:PKG_CONFIG_PATH = ""
	$ErrorActionPreference = "Stop" 
	Validate "dist/gtk-3.0/pygobject-$pygobject3_version-cp$pyver-cp${pyver}m-win_amd64.whl" "$pythonroot\lib\site-packages\gi\_gi.cp$pyver-win_amd64.pyd"
} else {
	Write-Host "pygobject3 already built..."
}
popd

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
PipInstall Sphinx "$pythonroot/lib/site-packages/Sphinx/__main__.py"

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
PipInstall tensorflow "$pythonroot/lib/site-packages/tensorflow/__init__.py"
	
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

"finished installing python packages for $configuration"

cd $root/scripts 

""
"COMPLETED STEP 4: Python dependencies / packages have been built and installed"
""

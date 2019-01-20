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

# Build packages needed for Stage 1
cd src-stage1-dependencies

# ____________________________________________________________________________________________________________
# libusb
#

SetLog "libusb"
cd $root\src-stage1-dependencies\libusb\msvc
if ((TryValidate "../x64/Debug/dll/libusb-1.0.dll" "../x64/Debug/lib/libusb-1.0.lib" `
	"../x64/Release/dll/libusb-1.0.dll" "../x64/Release/lib/libusb-1.0.lib" `
	"../x64/Release-AVX2/dll/libusb-1.0.dll" "../x64/Release-AVX2/lib/libusb-1.0.lib") -eq $false) {
	Write-Host -NoNewline "building libusb..."
	Write-Host -NoNewline "Debug..."
	msbuild .\libusb_2015.sln /m /p:"configuration=Debug;platform=x64" >> $Log
	Write-Host -NoNewline "Release..."
	msbuild .\libusb_2015.sln /m /p:"configuration=Release;platform=x64" >> $Log
	Write-Host -NoNewline "Release-AVX2..."
	msbuild .\libusb_2015.sln /m /p:"configuration=Release-AVX2;platform=x64" >> $Log 
	Validate "../x64/Debug/dll/libusb-1.0.dll" "../x64/Debug/lib/libusb-1.0.lib" `
		"../x64/Release/dll/libusb-1.0.dll" "../x64/Release/lib/libusb-1.0.lib" `
		"../x64/Release-AVX2/dll/libusb-1.0.dll" "../x64/Release-AVX2/lib/libusb-1.0.lib"
} else {
	Write-Host "libusb already built"
}

# ____________________________________________________________________________________________________________
# libpng 
# uses zlib but incorporates the source directly so doesn't need to be built after zlib
SetLog "libpng"
cd $root\src-stage1-dependencies\libpng\projects\vstudio-vs2015
if ((TryValidate "x64/Debug/libpng16.dll" "x64/Debug Library/libpng16.lib" "x64/Release/libpng16.dll" "x64/Release Library/libpng16.lib" "x64/Release-AVX2/libpng16.dll" "x64/Release Library-AVX2/libpng16.lib") -eq $false) {
	Write-Host -NoNewline "building libpng..."
	msbuild vstudio.sln /m /p:"configuration=Debug;platform=x64" >> $Log 
	msbuild vstudio.sln /m /p:"configuration=Debug Library;platform=x64" >> $Log
	msbuild vstudio.sln /m /p:"configuration=Release;platform=x64" >> $Log
	msbuild vstudio.sln /m /p:"configuration=Release Library;platform=x64" >> $Log
	msbuild vstudio.sln /m /p:"configuration=Release-AVX2;platform=x64" >> $Log
	msbuild vstudio.sln /m /p:"configuration=Release Library-AVX2;platform=x64" >> $Log
	Validate "x64/Debug/libpng16.dll" "x64/Debug Library/libpng16.lib" "x64/Release/libpng16.dll" "x64/Release Library/libpng16.lib" "x64/Release-AVX2/libpng16.dll" "x64/Release Library-AVX2/libpng16.lib"
} else {
	Write-Host "libpng already built"
}

# ____________________________________________________________________________________________________________
# zlib
SetLog "zlib"
Write-Host -NoNewline "Building zlib..."
cd $root\src-stage1-dependencies\zlib-1.2.8/contrib/vstudio/vc14
if ((TryValidate "x64/ZlibDllDebug/zlibwapi.dll" "x64/ZlibDllRelease/zlibwapi.dll" "x64/ZlibDllRelease-AVX2/zlibwapi.dll" "x64/ZlibDllReleaseWithoutAsm/zlibwapi.dll" `
	"x64/ZlibStatDebug/zlib.lib" "x64/ZlibStatRelease/zlib.lib" "x64/ZlibStatRelease-AVX2/zlib.lib" "x64/ZlibStatReleaseWithoutAsm/zlib.lib") -eq $false) {
	msbuild zlibvc.sln /m /p:"configuration=Release;platform=x64" >> $Log
	msbuild zlibvc.sln /m /p:"configuration=Debug;platform=x64" >> $Log
	msbuild zlibvc.sln /m /p:"configuration=Release-AVX2;platform=x64" >> $Log
	msbuild zlibvc.sln /m /p:"configuration=ReleaseWithoutAsm;platform=x64" >> $Log
	Validate "x64/ZlibDllDebug/zlibwapi.dll" "x64/ZlibDllRelease/zlibwapi.dll" "x64/ZlibDllRelease-AVX2/zlibwapi.dll" "x64/ZlibDllReleaseWithoutAsm/zlibwapi.dll" `
		"x64/ZlibStatDebug/zlib.lib" "x64/ZlibStatRelease/zlib.lib" "x64/ZlibStatRelease-AVX2/zlib.lib" "x64/ZlibStatReleaseWithoutAsm/zlib.lib"
} else {
	Write-Host "already built"
}

# __________________________________________________________________
# get-text / libiconv / libintl
#
SetLog "gettext"
Write-Host -NoNewline "building gettext..."
cd $root\src-stage1-dependencies\gettext-msvc
if ((TryValidate "x64/DebugDLL/libiconv.dll" "x64/ReleaseDLL/libiconv.dll" "x64/ReleaseDLL-AVX2/libiconv.dll" `
				"x64/Debug/libiconv.lib" "x64/Release/libiconv.lib" "x64/Release-AVX2/libiconv.lib" `
				) -eq $false) {
	msbuild .\gettext.sln /p:"configuration=Debug;platform=x64" >> $Log
	msbuild .\gettext.sln /p:"configuration=DebugDLL;platform=x64" >> $Log
	msbuild .\gettext.sln /p:"configuration=Release;platform=x64" >> $Log
	msbuild .\gettext.sln /p:"configuration=ReleaseDLL;platform=x64" >> $Log
	msbuild .\gettext.sln /p:"configuration=Release-AVX2;platform=x64" >> $Log
	msbuild .\gettext.sln /p:"configuration=ReleaseDLL-AVX2;platform=x64" >> $Log
	"complete"
} else {
	"already built"
}

# __________________________________________________________________
# libxml2
# must be after libiconv
#
SetLog "libxml2"
Write-Host -NoNewline "building libxml2..."
cd $root\src-stage1-dependencies\libxml2\win32
if ((TryValidate "..\build\X64\Debug\lib\libxml2.lib" "..\build\X64\Release\lib\libxml2.lib" "..\build\X64\Release-AVX2\lib\libxml2.lib" "..\build\X64\Debug\bin\libxml2.dll" "..\build\X64\Release\bin\libxml2.dll" "..\build\X64\Release-AVX2\bin\libxml2.dll") -eq $false) {
	# libxml is looking for slightly different filename than what is generated by default
	cp ..\..\gettext-msvc\x64\Debug\libiconv.lib ..\..\gettext-msvc\x64\Debug\iconv.lib
	cp ..\..\zlib-1.2.8\contrib\vstudio\vc14\x64\ZlibStatDebug\zlib.lib ..\..\zlib-1.2.8\contrib\vstudio\vc14\x64\ZlibStatDebug\zlibstat.lib
	cp ..\..\gettext-msvc\x64\Release\libiconv.lib ..\..\gettext-msvc\x64\Release\iconv.lib
	cp ..\..\zlib-1.2.8\contrib\vstudio\vc14\x64\ZlibStatRelease\zlib.lib ..\..\zlib-1.2.8\contrib\vstudio\vc14\x64\ZlibStatRelease\zlibstat.lib
	cp ..\..\gettext-msvc\x64\Release-AVX2\libiconv.lib ..\..\gettext-msvc\x64\Release-AVX2\iconv.lib

	$ErrorActionPreference = "Continue"
	# the "static" option builds the test programs statically link, not relevant to the libraries
	& cscript.exe configure.js iconv=yes compiler=msvc zlib=yes python=yes cruntime=/MDd  debug=yes prefix="..\build\x64\Debug" static=no lib="..\..\gettext-msvc\x64\Debug;..\..\zlib-1.2.8\contrib\vstudio\vc14\x64\ZLibStatDebug" include="..\..\gettext-msvc\libiconv-1.14;..\..\zlib-1.2.8" 2>&1 >> $Log
	nmake Makefile.msvc libxml install 2>&1 >> $Log
	nmake clean 2>&1 >> $Log
	& cscript.exe configure.js iconv=yes compiler=msvc zlib=yes python=yes cruntime=/MD  debug=no prefix="..\build\x64\Release" static=no lib="..\..\gettext-msvc\x64\Release;..\..\zlib-1.2.8\contrib\vstudio\vc14\x64\ZLibStatRelease" include="..\..\gettext-msvc\libiconv-1.14;..\..\zlib-1.2.8" 2>&1 >> $Log
	nmake Makefile.msvc libxml install 2>&1 >> $Log
	nmake clean 2>&1 >> $Log
	& cscript.exe configure.js iconv=yes compiler=msvc zlib=yes python=yes cruntime="/MD /arch:AVX2"  debug=no prefix="..\build\x64\Release-AVX2" static=no lib="..\..\gettext-msvc\x64\Release;..\..\zlib-1.2.8\contrib\vstudio\vc14\x64\ZLibStatRelease" include="..\..\gettext-msvc\libiconv-1.14;..\..\zlib-1.2.8" 2>&1 >> $Log
	nmake Makefile.msvc libxml install 2>&1 >> $Log
	nmake clean 2>&1 >> $Log
	$ErrorActionPreference = "Stop"
	"complete"
} else {
	Write-Host "already built"
}

# ____________________________________________________________________________________________________________
# libxslt 1.1.29
#
# uses libxml, zlib, and iconv
# TODO PATCH REQUIRED, has option NOWIN98 l
SetLog "libxslt"
Write-Host "building libxslt..."
$ErrorActionPreference = "Continue"
cd $root\src-stage1-dependencies\libxslt-$libxslt_version\win32
function MakeXSLT {
	$configuration = $args[0]
	Write-Host -NoNewline "  $configuration..."
	if ((TryValidate "..\build\$configuration\lib\libxslt.dll" "..\build\$configuration\lib\libxslt_a.lib") -eq $false) {
		if ($configuration -match "Debug") {$de="yes"; $runtime="/MD"} else {$de="no"; $runtime="/MDd"}
		& nmake /NOLOGO clean 2>&1 >> $Log 
		Write-Host -NoNewline "configuring..."
		& cscript configure.js zlib=yes compiler=msvc cruntime="$runtime" static=yes prefix=..\build\$configuration include="../../zlib-1.2.8;../../libxml2/include;../../gettext-msvc/libiconv-1.14" lib="../../libxml2/build/x64/$configuration/lib;../../gettext-msvc/x64/$configuration;../../zlib-1.2.8/contrib/vstudio/vc14/x64/ZlibStat$configuration" debug=$de 2>&1 >> $Log 
		Write-Host -NoNewline "building..." 
		& nmake /NOLOGO 2>&1 >> $Log 
		Write-Host -NoNewline "installing..."
		& nmake /NOLOGO install 2>&1 >> $Log 
		if (Test-Path ..\build\$configuration\bin\libexslt.pdb) {Copy-Item -Path ..\build\$configuration\bin\libexslt.pdb ..\build\$configuration\lib}
		if (Test-Path ..\build\$configuration\bin\libxslt.pdb) {Copy-Item -Path ..\build\$configuration\bin\libxslt.pdb ..\build\$configuration\lib}
		Validate "..\build\$configuration\lib\libxslt.dll" "..\build\$configuration\lib\libxslt_a.lib"
	} else {
		Write-Host "already built"
	}
}
MakeXSLT "Release"
MakeXSLT "Release-AVX2"
MakeXSLT "Debug"
$ErrorActionPreference = "Stop"

if ($Config.BuildGTKFromSource) {

	# __________________________________________________________________
	# freetype
	# freetype is only ever used as a static library, no AVX2
	# ignore the multi/single threaded options as they build against static runtime libs
	SetLog "freetype"
	Write-Host -NoNewline "building freetype..."
	cd $root\src-stage1-dependencies\freetype\builds\windows\vc2015
	msbuild freetype.sln /p:"configuration=Release;platform=x64" >> $Log
	msbuild freetype.sln /p:"configuration=Debug;platform=x64" >> $Log
	"complete"

	# __________________________________________________________________
	# pixman
	SetLog "pixman"
	Write-Host -NoNewline "building pixman..."
	cd $root\src-stage1-dependencies\pixman\build
	msbuild .\pixman.sln /p:"configuration=Debug;platform=x64" >> $Log
	msbuild .\pixman.sln /p:"configuration=DebugDLL;platform=x64" >> $Log
	msbuild .\pixman.sln /p:"configuration=Release;platform=x64" >> $Log
	msbuild .\pixman.sln /p:"configuration=ReleaseDLL;platform=x64" >> $Log
	msbuild .\pixman.sln /p:"configuration=Release-AVX2;platform=x64" >> $Log
	msbuild .\pixman.sln /p:"configuration=ReleaseDLL-AVX2;platform=x64" >> $Log
	"complete"

	# __________________________________________________________________
	# cairo
	# must be after pixman, zlib, libpng, and freetype
	SetLog "cairo"
	Write-Host -NoNewline "building cairo..."
	cd $root\src-stage1-dependencies\cairo\build
	msbuild .\cairo.sln /p:"configuration=Debug;platform=x64" >> $Log
	msbuild .\cairo.sln /p:"configuration=DebugDLL;platform=x64" >> $Log
	msbuild .\cairo.sln /p:"configuration=Release;platform=x64" >> $Log
	msbuild .\cairo.sln /p:"configuration=ReleaseDLL;platform=x64" >> $Log
	msbuild .\cairo.sln /p:"configuration=Release-AVX2;platform=x64" >> $Log
	msbuild .\cairo.sln /p:"configuration=ReleaseDLL-AVX2;platform=x64" >> $Log
	"complete"

	# __________________________________________________________________
	# libffi
	SetLog "libffi"
	Write-Host -NoNewline "building libffi..."
	cd $root\src-stage1-dependencies\libffi\win32\vc14_x64
	msbuild .\libffi-msvc.sln /p:"configuration=Debug;platform=x64" >> $Log
	msbuild .\libffi-msvc.sln /p:"configuration=Release;platform=x64" >> $Log
	 "complete"

	# __________________________________________________________________
	# JasPer
	# static only build
	SetLog "jasper"
	Write-Host -NoNewline "building jasper..."
	cd $root\src-stage1-dependencies\jasper-1.900.1\src\msvc14
	msbuild .\jasper.sln /p:"configuration=Debug;platform=x64" >> $Log
	msbuild .\jasper.sln /p:"configuration=Release;platform=x64" >> $Log
	msbuild .\jasper.sln /p:"configuration=Release-AVX2;platform=x64" >> $Log
	"complete"

	# __________________________________________________________________
	# glib
	# THIS IS NOT YET WORKING
	# Everything above does at least build, this is the point where
	# the result wasn't worth the squeeze since Hexchat has exactly what
	# we need (VS2015 binaries) for a stack that is non-trivial to build
	# someday will revisit in order to add AVX2 options but again, not 
	# work the effort since the priority is a native build of GNURadio 
	# first and foremost.
	SetLog "glib"
	Write-Host -NoNewline "building glib..."
	cd $root\src-stage1-dependencies\glib\build\win32\vs14
	$GlibEtcInstallRoot = "..\..\..\..\gtk-build\x64\Release"
	New-Item -ItemType Directory -Force -Path $GlibEtcInstallRoot  >> $Log
	New-Item -ItemType Directory -Force -Path $GlibEtcInstallRoot\include >> $Log
	New-Item -ItemType Directory -Force -Path $GlibEtcInstallRoot\lib >> $Log
	$ErrorActionPreference = "Continue"
	$env:_CL_ = "/I$root/src-stage1-dependencies/glib/glib/pcre /MD"
	$env:LIB = "$root\src-stage1-dependencies\x64\lib;" + $oldlib
	msbuild .\glib.vcxproj /p:"configuration=Release;platform=x64;glibetcinstallroot=$GlibEtcInstallRoot" >> $Log
	$ErrorActionPreference = "Stop"
	"complete"

} else {
	# no action needed here if we are using the binaries.
	# if we use the premade build environment from hexchat, that
	# would replace the above code.
	# 
	# below is the command line used to build gtk3 using the gvsbuild code on github.  Similar to these scripts, there be dragons and some manual tweaking is required, not for the faint of heart.
	# z:/gr-build/python36/python.exe ./build.py build --vs-ver 14 -p x64 -c release --build-dir z:\gr-build\src-stage1-dependencies\gvsbuild\build --msys-dir z:/gr-build/msys64 --patches-root-dir z:/gr-build/src-stage1-dependencies/gvsbuild/patches --python-dir z:/gr-build/Python36 --py-wheel --enable-gi --win-sdk-ver 10.0.15063.0 gtk3-full
}
# ____________________________________________________________________________________________________________
# SDL
SetLog "SDL"
Write-Host -NoNewline "building SDL..."
cd $root\src-stage1-dependencies\sdl-$sdl_version\VisualC
if ((TryValidate "x64/Debug/SDL.dll" "x64/Release/SDL.dll" "x64/Release-AVX2/SDL.dll") -eq $false) {
	msbuild .\sdl.sln /m /p:"configuration=Debug;platform=x64" >> $Log
	msbuild .\sdl.sln /m /p:"configuration=Release-AVX2;platform=x64" >> $Log
	msbuild .\sdl.sln /m /p:"configuration=Release;platform=x64" >> $Log
	Validate "x64/Debug/SDL.dll" "x64/Release/SDL.dll" "x64/Release-AVX2/SDL.dll"
} else {
	Write-Host "already built"
}
# ____________________________________________________________________________________________________________
# portaudio
SetLog "portaudio"
Write-Host -NoNewline "building portaudio..."
cd $root\src-stage1-dependencies\portaudio\build\msvc
if ((TryValidate "x64/Debug/portaudio_x64.dll" "x64/Release/portaudio_x64.dll" "x64/Release-AVX2/portaudio_x64.dll" `
	"x64/Debug-Static/portaudio.lib" "x64/Release-Static/portaudio.lib" "x64/Release-Static-AVX2/portaudio.lib") -eq $false) {
	msbuild .\portaudio.vcxproj /m /p:"configuration=Debug;platform=x64" >> $Log
	msbuild .\portaudio.vcxproj /m /p:"configuration=Debug-Static;platform=x64" >> $Log
	msbuild .\portaudio.vcxproj /m /p:"configuration=Release;platform=x64" >> $Log
	msbuild .\portaudio.vcxproj /m /p:"configuration=Release-Static;platform=x64" >> $Log
	msbuild .\portaudio.vcxproj /m /p:"configuration=Release-AVX2;platform=x64" >> $Log
	msbuild .\portaudio.vcxproj /m /p:"configuration=Release-Static-AVX2;platform=x64" >> $Log
	Validate "x64/Debug/portaudio_x64.dll" "x64/Release/portaudio_x64.dll" "x64/Release-AVX2/portaudio_x64.dll" `
		"x64/Debug-Static/portaudio.lib" "x64/Release-Static/portaudio.lib" "x64/Release-Static-AVX2/portaudio.lib"
} else {
	Write-Host "already built"
}
# ____________________________________________________________________________________________________________
# cppunit
SetLog "cppunit"
Write-Host -NoNewline "building cppunit..."
cd $root\src-stage1-dependencies\cppunit-$cppunit_version\src >> $Log
if ((TryValidate "x64/Debug/dll/cppunit.dll" "x64/Release/dll/cppunit.dll" "x64/Debug/lib/cppunit.lib" "x64/Release/lib/cppunit.lib") -eq $false) {
	msbuild .\CppUnitLibraries.sln /m /p:"configuration=Debug;platform=x64" >> $Log
	msbuild .\CppUnitLibraries.sln /m /p:"configuration=Release;platform=x64" >> $Log
	Validate "x64/Debug/dll/cppunit.dll" "x64/Release/dll/cppunit.dll" "x64/Debug/lib/cppunit.lib" "x64/Release/lib/cppunit.lib"
} else {
	Write-Host "already built"
}

# ____________________________________________________________________________________________________________
# fftw3
SetLog "fftw3"
Write-Host -NoNewline "building fftw3..."
cd $root\src-stage1-dependencies\fftw-$fftw_version\msvc
if ((TryValidate "x64/Release/libfftwf-3.3.lib" "x64/Release-AVX2/libfftwf-3.3.lib" "x64/Debug/libfftwf-3.3.lib" `
	"x64/Release DLL/libfftwf-3.3.DLL" "x64/Release DLL-AVX2/libfftwf-3.3.DLL" "x64/Debug DLL/libfftwf-3.3.DLL" ) -eq $false) {
	msbuild .\fftw-3.3-libs.sln /m /p:"configuration=Debug;platform=x64" >> $Log
	msbuild .\fftw-3.3-libs.sln /m /p:"configuration=Debug DLL;platform=x64" >> $Log
	msbuild .\fftw-3.3-libs.sln /m /p:"configuration=Release;platform=x64" >> $Log
	msbuild .\fftw-3.3-libs.sln /m /p:"configuration=Release DLL;platform=x64" >> $Log
	msbuild .\fftw-3.3-libs.sln /m /p:"configuration=Release-AVX2;platform=x64" >> $Log 
	msbuild .\fftw-3.3-libs.sln /m /p:"configuration=Release DLL-AVX2;platform=x64" >> $Log
	Validate "x64/Release/libfftwf-3.3.lib" "x64/Release-AVX2/libfftwf-3.3.lib" "x64/Debug/libfftwf-3.3.lib" `
		"x64/Release DLL/libfftwf-3.3.DLL" "x64/Release DLL-AVX2/libfftwf-3.3.DLL" "x64/Debug DLL/libfftwf-3.3.DLL" 
	CheckNoAVX "$root/src-stage1-dependencies/fftw-$fftw_version/msvc/x64/Release"
	CheckNoAVX "$root/src-stage1-dependencies/fftw-$fftw_version/msvc/x64/Release DLL"
} else {
	Write-Host "already built"
}
# ____________________________________________________________________________________________________________
# openssl (python depends on this)
SetLog "openssl"
Write-Host -NoNewline "building openssl..."
cd $root/src-stage1-dependencies/openssl
# The TEST target will not only build but also test
# Note, it appears the static libs are still linked to the /MT runtime
# don't change config names because they are linked to python's config names below
if ((TryValidate "build/x64/Release/ssleay32.lib" "build/x64/Release-AVX2/ssleay32.lib" "build/x64/Debug/ssleay32.lib" `
	"build/x64/ReleaseDLL/libeay32.DLL" "build/x64/ReleaseDLL-AVX2/libeay32.DLL" "build/x64/DebugDLL/libeay32.DLL" `
	"build/x64/Release/libeay32.lib" "build/x64/Release-AVX2/libeay32.lib" "build/x64/Debug/libeay32.lib" `
	"build/x64/ReleaseDLL/ssleay32.DLL" "build/x64/ReleaseDLL-AVX2/ssleay32.DLL" "build/x64/DebugDLL/ssleay32.DLL" ) -eq $false) {
	msbuild openssl.vcxproj /m /t:"Build" /p:"configuration=Debug;platform=x64" >> $Log
	msbuild openssl.vcxproj /m /t:"Build" /p:"configuration=DebugDLL;platform=x64" >> $Log
	msbuild openssl.vcxproj /m /t:"Build" /p:"configuration=Release;platform=x64" >> $Log
	msbuild openssl.vcxproj /m /t:"Build" /p:"configuration=Release-AVX2;platform=x64" >> $Log
	msbuild openssl.vcxproj /m /t:"Build" /p:"configuration=ReleaseDLL;platform=x64" >> $Log
	msbuild openssl.vcxproj /m /t:"Build" /p:"configuration=ReleaseDLL-AVX2;platform=x64" >> $Log
	Validate "build/x64/Release/ssleay32.lib" "build/x64/Release-AVX2/ssleay32.lib" "build/x64/Debug/ssleay32.lib" `
		"build/x64/ReleaseDLL/libeay32.DLL" "build/x64/ReleaseDLL-AVX2/libeay32.DLL" "build/x64/DebugDLL/libeay32.DLL" `
		"build/x64/Release/libeay32.lib" "build/x64/Release-AVX2/libeay32.lib" "build/x64/Debug/libeay32.lib" `
		"build/x64/ReleaseDLL/ssleay32.DLL" "build/x64/ReleaseDLL-AVX2/ssleay32.DLL" "build/x64/DebugDLL/ssleay32.DLL" 
} else {
	Write-Host "already built"
}

# ____________________________________________________________________________________________________________
# python (boost depends on this)
# 
SetLog "python"
Write-Host -NoNewline "building core python..."
cd $root/src-stage1-dependencies/python27/Python-2.7.10/PCbuild.vc14
if ((TryValidate "amd64/_ssl.pyd" "amd64/_ctypes.pyd" "amd64/_tkinter.pyd" "amd64/python.exe" "amd64/python27.dll" `
	"amd64-avx2/_ssl.pyd" "amd64-avx2/_ctypes.pyd" "amd64-avx2/_tkinter.pyd" "amd64-avx2/python.exe" "amd64-avx2/python27.dll" `
	"amd64/_ssl_d.pyd" "amd64/_ctypes_d.pyd" "amd64/_tkinter_d.pyd" "amd64/python_d.exe" "amd64/python27_d.dll" ) -eq $false) {
	$env:_CL_ = " -DPy_DEBUG; -D_DEBUG "
	msbuild pcbuild.sln /m /p:"configuration=Debug;platform=x64" >> $Log
	$env:_CL_ = ""
	msbuild pcbuild.sln /m /p:"configuration=Release;platform=x64" >> $Log
	msbuild pcbuild.sln /m /p:"configuration=Release-AVX2;platform=x64" >> $Log
	Validate "amd64/_ssl.pyd" "amd64/_ctypes.pyd" "amd64/_tkinter.pyd" "amd64/python.exe" "amd64/python27.dll" `
		"amd64-avx2/_ssl.pyd" "amd64-avx2/_ctypes.pyd" "amd64-avx2/_tkinter.pyd" "amd64-avx2/python.exe" "amd64-avx2/python27.dll" `
		"amd64/_ssl_d.pyd" "amd64/_ctypes_d.pyd" "amd64/_tkinter_d.pyd" "amd64/python_d.exe" "amd64/python27_d.dll" 
} else {
	Write-Host "python already built"
}

# now place the binaries where we need them
# install the main python and minimal dependencies
Function gatherPython {

	New-Item -ItemType Directory -Force -Path $pythonroot >> $Log
	New-Item -ItemType Directory -Force -Path $pythonroot/DLLs >> $Log
	New-Item -ItemType Directory -Force -Path $pythonroot/Libs >> $Log
	New-Item -ItemType Directory -Force -Path $pythonroot/Docs >> $Log 
	New-Item -ItemType Directory -Force -Path $pythonroot/lib >> $Log
	New-Item -ItemType Directory -Force -Path $pythonroot/lib/site-packages >> $Log
	New-Item -ItemType Directory -Force -Path $pythonroot/tcl >> $Log
	$env:Path = $pythonroot+ ";$oldPath"

	# no DOCs dir
	# copy the files
	# amd64 for regular build (release and debug combined), amd64-avx for release AVX2 build
	if (Test-Path .\python_d.exe) {cp python_d.exe $pythonroot} 
	if (Test-Path .\pythonw_d.exe) {cp pythonw_d.exe $pythonroot}
	if (Test-Path .\python27_d.dll) {cp python27_d.dll $pythonroot}
	cp python.exe $pythonroot
	cp pythonw.exe $pythonroot
	cp python27.dll $pythonroot
	cp *.pyd $pythonroot/DLLs
	cp *.dll $pythonroot/DLLs
	cp *.lib $pythonroot/libs
	cp *.pdb $pythonroot/libs
	cp ../../PC/py.ico $pythonroot/DLLs
	cp ../../PC/pyc.ico $pythonroot/DLLs
	cp -r -fo ../../Tools $pythonroot
	cp -r -fo ../../../tcltk64/lib/*.* $pythonroot/tcl
	cp -r -fo ../../Include $pythonroot
	cp ../../PC/pyconfig.h $pythonroot/Include
	cp ../../README $pythonroot/README.txt
	cp ../../LICENSE $pythonroot/LICENSE.txt
	cp -r -fo ../../Lib/bsddb $pythonroot/Lib
	cp -r -fo ../../Lib/compiler $pythonroot/Lib
	cp -r -fo ../../Lib/ctypes $pythonroot/Lib
	cp -r -fo ../../Lib/curses $pythonroot/Lib
	cp -r -fo ../../Lib/distutils $pythonroot/Lib
	cp -fo $pythonroot/lib/distutils/command/wininst-9.0-amd64.exe $pythonroot/lib/distutils/command/wininst-14.0-amd64.exe
	cp -r -fo ../../Lib/email $pythonroot/Lib
	cp -r -fo ../../Lib/encodings $pythonroot/Lib
	cp -r -fo ../../Lib/hotshot $pythonroot/Lib
	cp -r -fo ../../Lib/idlelib $pythonroot/Lib
	cp -r -fo ../../Lib/importlib $pythonroot/Lib
	cp -r -fo ../../Lib/json $pythonroot/Lib
	cp -r -fo ../../Lib/lib2to3 $pythonroot/Lib
	cp -r -fo ../../Lib/lib-tk $pythonroot/Lib
	cp -r -fo ../../Lib/logging $pythonroot/Lib
	cp -r -fo ../../Lib/msilib $pythonroot/Lib
	cp -r -fo ../../Lib/multiprocessing $pythonroot/Lib
	cp -r -fo ../../Lib/pydoc_data $pythonroot/Lib
	cp -r -fo ../../Lib/sqlite3 $pythonroot/Lib
	cp -r -fo ../../Lib/test $pythonroot/Lib
	cp -r -fo ../../Lib/unittest $pythonroot/Lib
	cp -r -fo ../../Lib/wsgiref $pythonroot/Lib
	cp -r -fo ../../Lib/xml $pythonroot/Lib
	cp ../../Lib/*.* $pythonroot/Lib

	# then install key packages
	$env:Path = $pythonroot+ ";$oldPath"
	# these packages will give warnings about files not found that will be errors on powershell if set to "Stop"
	$ErrorActionPreference = "Continue"
	cd $root/src-stage1-dependencies/setuptools-20.1.1
	& $pythonroot\$pythonexe setup.py install --single-version-externally-managed --root=/ 2>&1  >> $Log
	cd $root/src-stage1-dependencies/pip-9.0.1
	& $pythonroot\$pythonexe setup.py install --force 2>&1 >> $Log
	cd $root\src-stage1-dependencies/wheel-0.29.0
	& $pythonroot\$pythonexe setup.py install --force 2>&1 >> $Log
	$ErrorActionPreference = "Stop"
	$env:Path = $oldPath
}

Write-Host -NoNewline "staging core python..." 
$pythonexe = "python.exe"
$pythonroot = "$root\src-stage2-python\gr-python27"
cd $root/src-stage1-dependencies/python27/Python-2.7.10/PCbuild.vc14/amd64
GatherPython
$pythonroot = "$root\src-stage2-python\gr-python27-avx2"
cd $root/src-stage1-dependencies/python27/Python-2.7.10/PCbuild.vc14/amd64-avx2
GatherPython
$pythonexe = "python_d.exe"
$pythonroot = "$root\src-stage2-python\gr-python27-debug"
cd $root/src-stage1-dependencies/python27/Python-2.7.10/PCbuild.vc14/amd64
GatherPython
"complete"


# ____________________________________________________________________________________________________________
# boost
SetLog "boost"
Write-Host -NoNewline "building boost..."
cd $root/src-stage1-dependencies/boost
if ((TryValidate "build/x64/Debug/lib/boost_python-vc140-mt-gd-1_60.dll" "build/x64/Debug/lib/boost_system-vc140-mt-gd-1_60.dll" `
	"build/x64/Release/lib/boost_python-vc140-mt-1_60.dll" "build/x64/Release/lib/boost_system-vc140-mt-1_60.dll" `
	"build/avx2/Release/lib/boost_python-vc140-mt-1_60.dll" "build/avx2/Release/lib/boost_system-vc140-mt-1_60.dll") -eq $false) {
	cmd /c "bootstrap.bat" >> $Log
	# point boost build to our custom python libraries
	$doubleroot = $root -replace "\\", "\\"
	Add-Content .\project-config.jam "`nusing python : 2.7 : $doubleroot\\src-stage2-python\\gr-python27\\python.exe : $doubleroot\\src-stage2-python\\gr-python27\\Include : $doubleroot\\src-stage2-python\\gr-python27\\Libs ;"
	# always rebuild all because boost will reuse objects from a previous build with different command line options
	# Optimized static+shared release libraries
	$cores = Get-WmiObject -class win32_processor -Property "numberOfCores"
	$corestr = $cores.NumberOfCores
	cmd /c "b2.exe -j$corestr -a --build-type=minimal --prefix=build\avx2\Release --libdir=build\avx2\Release\lib --includedir=build\avx2\Release\include --stagedir=build\avx2\Release --layout=versioned address-model=64 threading=multi link=static,shared variant=release cxxflags=""/arch:AVX2 /Ox /FS"" cflags=""/arch:AVX2 /Ox /FS"" install" >> $Log
	# Regular  static+shared release libraries
	cmd /c "b2.exe -j$corestr -a --build-type=minimal --prefix=build\x64\Release --libdir=build\x64\Release\lib --includedir=build\x64\Release\include --stagedir=build\x64\Release --layout=versioned address-model=64 threading=multi link=static,shared variant=release cxxflags="" -FS"" cflags="" -FS"" install" >> $Log
	# Regular  static+shared debug libraries
	cmd /c "b2.exe -j$corestr -a --build-type=minimal --prefix=build\x64\Debug --libdir=build\x64\Debug\lib --includedir=build\x64\Debug\include --stagedir=build\x64\Debug --layout=versioned address-model=64 threading=multi link=static,shared variant=debug cxxflags="" -FS"" cflags="" -FS"" install" >> $Log
	Validate "build/x64/Debug/lib/boost_python-vc140-mt-gd-1_60.dll" "build/x64/Debug/lib/boost_system-vc140-mt-gd-1_60.dll" `
		"build/x64/Release/lib/boost_python-vc140-mt-1_60.dll" "build/x64/Release/lib/boost_system-vc140-mt-1_60.dll" `
		"build/avx2/Release/lib/boost_python-vc140-mt-1_60.dll" "build/avx2/Release/lib/boost_system-vc140-mt-1_60.dll"
} else {
	Write-Host "already built"
}

# ____________________________________________________________________________________________________________
# libsodium
# must be before libzmq
SetLog "libsodium"
Write-Host -NoNewline "building libsodium..."
cd $root/src-stage1-dependencies/libsodium
if ((TryValidate "bin/x64/Release/v140/dynamic/libsodium.dll" "bin/x64/Release/v140/static/libsodium.lib" "bin/x64/Release/v140/ltcg/libsodium.lib" `
	"bin/x64/Debug/v140/dynamic/libsodium.dll" "bin/x64/Debug/v140/static/libsodium.lib" "bin/x64/Debug/v140/ltcg/libsodium.lib") -eq $false) {
	cd builds\msvc\build
	& .\buildbase.bat ..\vs2015\libsodium.sln 14 >> $Log
	cd ../../../bin/x64
	Validate "Release/v140/dynamic/libsodium.dll" "Release/v140/static/libsodium.lib" "Release/v140/ltcg/libsodium.lib" `
		"Debug/v140/dynamic/libsodium.dll" "Debug/v140/static/libsodium.lib" "Debug/v140/ltcg/libsodium.lib"
} else {
	Write-Host "already built"
}

# ____________________________________________________________________________________________________________
# libzmq
# must be after libsodium
# libzmq switched to cmake, so thus why the two build options below
SetLog "libzmq"
Write-Host -NoNewline "building libzmq..."
if (Test-Path $root/src-stage1-dependencies/libzmq/builds/msvc) {
	cd $root/src-stage1-dependencies/libzmq/builds/msvc
	if ((TryValidate "../../bin/x64/Release/v140/dynamic/libzmq.dll" "../../bin/x64/Release/v140/static/libzmq.lib" "../../bin/x64/Release/v140/ltcg/libzmq.lib" `
	"../../bin/x64/Debug/v140/dynamic/libzmq.dll" "../../bin/x64/Debug/v140/static/libzmq.lib" "../../bin/x64/Debug/v140/ltcg/libzmq.lib") -eq $false) {
		cd build
		& .\buildbase.bat ..\vs2015\libzmq.sln 14 2>&1 >> $Log
		cd ../../../bin/x64
		Validate "Release/v140/dynamic/libzmq.dll" "Release/v140/static/libzmq.lib" "Release/v140/ltcg/libzmq.lib" `
			"Debug/v140/dynamic/libzmq.dll" "Debug/v140/static/libzmq.lib" "Debug/v140/ltcg/libzmq.lib"
	} else {
		Write-Host "already built"
	}
} else {
	cd $root/src-stage1-dependencies/libzmq
	if ((TryValidate "./bin/Release/bin/libzmq-v140-mt-4_3_1.dll" "./bin/Release/lib/libzmq-v140-mt-4_3_1.lib" "./bin/Release/lib/libzmq-v140-mt-s-4_3_1.lib" `
	"./bin/Debug/bin/libzmq-v140-mt-gd-4_3_1.dll" "./bin/Debug/lib/libzmq-v140-mt-gd-4_3_1.lib" "./bin/Debug/lib/libzmq-v140-mt-sgd-4_3_1.lib") -eq $false) {
	
		#newer versions use cmake 
		Write-Host ""
		New-Item -ItemType Directory -Force $root\src-stage1-dependencies\libzmq\build 2>&1 >> $Log 
		cd build
		
		Function MakeLibZMQ {
			$type = $args[0]
			$flag = if ($type -match "Debug") {"-gd"} else {""}
			$sflag = if ($type -match "Debug") {"gd"} else {""}
			Write-Host -NoNewline "  $type...configuring..."
			cmake ..\ `
				-Wno-dev `
				-G "Visual Studio 14 Win64" `
				-DCMAKE_BUILD_TYPE="$type" `
				-DCMAKE_INSTALL_PREFIX="$root/src-stage1-dependencies/libzmq/bin/$type/" 2>&1 >> $Log 
			Write-Host -NoNewline "building..."
			msbuild ".\ZeroMQ.sln" /m /p:"configuration=$type;platform=x64" 2>&1 >> $Log 
			Write-Host -NoNewline "installing..."
			msbuild .\INSTALL.vcxproj /m /p:"configuration=$type;platform=x64;BuildProjectReferences=false" 2>&1 >> $Log
			$env:_CL_ = ""
			Validate "../bin/$type/bin/libzmq-v140-mt$flag-4_3_1.dll" "../bin/$type/lib/libzmq-v140-mt$flag-4_3_1.lib" "../bin/$type/lib/libzmq-v140-mt-s$sflag-4_3_1.lib" 
		}
		MakeLibZMQ "Debug"
		MakeLibZMQ "Release"
	} else {
		Write-Host "already built"
	}
}



# ____________________________________________________________________________________________________________
# gsl
SetLog "gsl"
Write-Host -NoNewline "building gsl..."
cd $root/src-stage1-dependencies/gsl-$gsl_version/build.vc14
if ((TryValidate "x64/Debug/dll/gsl.dll" "x64/Debug/dll/cblas.dll" "x64/Debug/lib/gsl.lib" "x64/Debug/lib/cblas.lib" `
	"x64/Release/dll/gsl.dll" "x64/Release/dll/cblas.dll" "x64/Release/lib/gsl.lib" "x64/Release/lib/cblas.lib" `
	"x64/Release-AVX2/dll/gsl.dll" "x64/Release-AVX2/dll/cblas.dll" "x64/Release-AVX2/lib/gsl.lib" "x64/Release-AVX2/lib/cblas.lib" ) -eq $false) {
	#prep headers
	msbuild gsl.lib.sln /t:gslhdrs >> $Log
	#static
	msbuild gsl.lib.sln /m /t:cblaslib /t:gsllib /maxcpucount /p:"configuration=Release;platform=x64"  >> $Log
	msbuild gsl.lib.sln /m /t:cblaslib /t:gsllib /maxcpucount /p:"configuration=Debug;platform=x64"  >> $Log
	msbuild gsl.lib.sln /m /t:cblaslib /t:gsllib /maxcpucount /p:"configuration=Release-AVX2;platform=x64"  >> $Log
	#dll
	msbuild gsl.dll.sln /m /t:cblasdll /t:gsldll /maxcpucount /p:"configuration=Release;platform=x64"  >> $Log
	msbuild gsl.dll.sln /m /t:cblasdll /t:gsldll /maxcpucount /p:"configuration=Debug;platform=x64"  >> $Log
	msbuild gsl.dll.sln /m /t:cblasdll /t:gsldll /maxcpucount /p:"configuration=Release-AVX2;platform=x64"  >> $Log
	Validate "x64/Debug/dll/gsl.dll" "x64/Debug/dll/cblas.dll" "x64/Debug/lib/gsl.lib" "x64/Debug/lib/cblas.lib" `
		"x64/Release/dll/gsl.dll" "x64/Release/dll/cblas.dll" "x64/Release/lib/gsl.lib" "x64/Release/lib/cblas.lib" `
		"x64/Release-AVX2/dll/gsl.dll" "x64/Release-AVX2/dll/cblas.dll" "x64/Release-AVX2/lib/gsl.lib" "x64/Release-AVX2/lib/cblas.lib" 
} else {
	Write-Host "already built"
}

# ____________________________________________________________________________________________________________
# qt4
# must be after openssl
SetLog "Qt4"
Write-Host "building Qt4..."
Function MakeQt 
{
	$type = $args[0]
	Write-Host -NoNewline "  $type...configuring..."
	$ssltype = ($type -replace "Dll", "") -replace "-AVX2", ""
	$flags = if ($type -match "Debug") {"-debug"} else {"-release"}
	$staticflag = if ($type -match "Dll") {""} else {"-static"}
	if ($type -match "AVX2") {$env:_CL_ = "/Ox /arch:AVX2 "} else {$env:_CL_ =""}
	New-Item -ItemType Directory -Force -Path $root/src-stage1-dependencies/Qt4/build/$type/bin >> $Log
	cp -Force $root\src-stage1-dependencies/Qt4/bin/qmake.exe $root/src-stage1-dependencies/Qt4/build/$type/bin
	.\configure.exe $flags $staticflag -prefix $root/src-stage1-dependencies/Qt4/build/$type -platform win32-msvc2015 -opensource -confirm-license -qmake -ltcg -nomake examples -nomake network -nomake demos -nomake tools -nomake sql -no-script -no-scripttools -no-qt3support -sse2 -directwrite -mp -qt-libpng -qt-libjpeg -opengl desktop -graphicssystem opengl -no-webkit -qt-sql-sqlite -plugin-sql-sqlite -openssl -L "$root\src-stage1-dependencies\openssl\build\x64\$ssltype" -l ssleay32 -l libeay32 -l crypt32 -l kernel32 -l user32 -l gdi32 -l winspool -l comdlg32 -l advapi32 -l shell32 -l ole32 -l oleaut32 -l uuid -l odbc32 -l odbccp32 -l advapi32 OPENSSL_LIBS="-L$root\src-stage1-dependencies\openssl\build\x64\$ssltype -lssleay32 -llibeay32" -I "$root\src-stage1-dependencies\openssl\build\x64\$ssltype\Include" -make nmake  2>&1 >> $Log
	$env:_CL_ = $env:_CL_  + " /Zi /EHsc "
	$env:_LINK_ = " /DEBUG:FULL "
	Write-Host -NoNewline "building..."
	nmake 2>&1 >> $Log
	Write-Host -NoNewline "installing..."
	nmake install 2>&1 >> $Log 
	Copy-Item -Force $root\src-stage1-dependencies/Qt4/lib/*.pdb  $root/src-stage1-dependencies/Qt4/build/$type/lib
	nmake confclean 2>&1 >> $Log
	$env:_CL_  = ""
	Write-Host "done"
}
# TODO find/copy over vc140.pdb
cd $root/src-stage1-dependencies/Qt4
# Various things in Qt4 build are intepreted as errors so 
$ErrorActionPreference = "Continue"
$env:QMAKESPEC = "$root/src-stage1-dependencies/Qt4/mkspecs/win32-msvc2015"
$env:QTDIR = "$root/src-stage1-dependencies/Qt4"
$env:Path = "$root\src-stage1-dependencies\Qt4\bin;" + $oldPath
if ((TryValidate "build/DebugDLL/bin/qmake.exe" "build/DebugDLL/lib/QtCored4.dll" "build/DebugDLL/lib/QtOpenGLd4.dll" "build/DebugDLL/lib/QtSvgd4.dll" "build/DebugDLL/lib/QtGuid4.dll" `
	"build/Releasedll/bin/qmake.exe" "build/Releasedll/lib/QtCore4.dll" "build/Releasedll/lib/QtOpenGL4.dll" "build/Releasedll/lib/QtSvg4.dll" "build/Releasedll/lib/QtGui4.dll" `
	"build/Releasedll-AVX2/bin/qmake.exe" "build/Releasedll-AVX2/lib/QtCore4.dll" "build/Releasedll-AVX2/lib/QtOpenGL4.dll" "build/Releasedll-AVX2/lib/QtSvg4.dll" "build/Releasedll-AVX2/lib/QtGui4.dll" ) -eq $false) {
	# Qt doesn't do a great job of allowing reconfiguring, so we go a little overkill
	# with the "extra strong" cleaning routines.
	# even this doesn't always work (50%??) so your best bet really is to wipe the Qt4 folder every time you rebuild.
	# more experimentation needed.
	if (Test-Path $root/src-stage1-dependencies/Qt4/Makefile) 
	{
		nmake clean 2>&1 >> $Log
		nmake confclean 2>&1 >> $Log
		nmake distclean 2>&1 >> $Log
	}
	# The below configure builds the base qmake.exe in the "root" directory and will point the environment to the main source tree.  Then the following build commands will convince Qt to build in a different directory
	# while still using the original as the source base.  THIS IS A HACK.  Qt4 does not like there to be more than one build on the same machine and is very troublesome in that regard.
	# If there are build fails, wipe the whole Qt4 directory and start over.  confclean doesn't do everything it promises.
	.\configure.exe -opensource -confirm-license -platform win32-msvc2015 -qmake -make nmake -prefix .  -nomake examples -nomake network -nomake demos -nomake tools -nomake sql -no-script -no-scripttools -no-qt3support -sse2 -directwrite -mp 2>&1 >> $Log
	nmake confclean 2>&1 >> $Log
	# debugDLL build
	MakeQT "DebugDLL"
	# release AVX2 DLL build
	MakeQT "ReleaseDLL-AVX2"
	# releaseDLL build
	MakeQT "ReleaseDLL"

	#clean up enormous amount of temp files
	nmake clean  2>&1>> $Log

	Validate "build/DebugDLL/bin/qmake.exe" "build/DebugDLL/lib/QtCored4.dll" "build/DebugDLL/lib/QtOpenGLd4.dll" "build/DebugDLL/lib/QtSvgd4.dll" "build/DebugDLL/lib/QtGuid4.dll" `
		"build/Releasedll/bin/qmake.exe" "build/Releasedll/lib/QtCore4.dll" "build/Releasedll/lib/QtOpenGL4.dll" "build/Releasedll/lib/QtSvg4.dll" "build/Releasedll/lib/QtGui4.dll" `
		"build/Releasedll-AVX2/bin/qmake.exe" "build/Releasedll-AVX2/lib/QtCore4.dll" "build/Releasedll-AVX2/lib/QtOpenGL4.dll" "build/Releasedll-AVX2/lib/QtSvg4.dll" "build/Releasedll-AVX2/lib/QtGui4.dll" 
} else {
	Write-Host "already built"
}
$env:Path = $oldPath

# ____________________________________________________________________________________________________________
# Qt5
#
# not needed specifically by GNURadio (as of 3.7) but is used by gqrx
# needs openssl and python
#
SetLog "Qt5"
Write-Host "building Qt5..."
Function MakeQt5 
{
	$type = $args[0] 
	Write-Host -NoNewline "  $type...configuring..."
	$ssltype = ($type -replace "Dll", "") -replace "-AVX2", ""
	$flags = if ($type -match "Debug") {"-debug"} else {"-release"}
	$debug = if ($type -match "Debug") {"d"} else {""}
	$staticflag = if ($type -match "Dll") {""} else {"-static"}
	if ($type -match "AVX2") {$env:_CL_ = "/Ox /arch:AVX2 "; $archflags=@('-sse3','-ssse3','-sse4.1','-sse4.2','-avx','-avx2')} else {$env:_CL_ = ""; $archflags=""}
	cd $root/src-stage1-dependencies/Qt5
	if ((TryValidate "build/$type/bin/qmake.exe" "build/$type/bin/Qt5Core$debug.dll" "build/$type/bin/Qt5OpenGL$debug.dll" "build/$type/bin/Qt5Svg$debug.dll" "build/$type/bin/Qt5Gui$debug.dll") -eq $false) {
		if (Test-Path  $root/src-stage1-dependencies/Qt5/build/$type) {rm -r -Force $root/src-stage1-dependencies/Qt5/build/$type}
		New-Item -ItemType Directory -Force -Path $root/src-stage1-dependencies/Qt5/build/$type >> $Log
		cd $root/src-stage1-dependencies/Qt5/build/$type
		../../configure.bat $flags $staticflag -prefix $root/src-stage1-dependencies/Qt5/build/$type `
			-skip qtdeclarative -skip qttools -skip qtconnectivity -skip qtscript -skip qtcanvas3d -skip qtdoc -skip qtserialbus -skip qtserialport `
			-skip qtwebview -skip qtactiveqt -skip qtenginio -skip qtandroidextras -skip qtwebsockets -skip qtwebengine -skip qtwebchannel -skip qtxmlpatterns `
			-nomake examples -nomake tools -nomake tests `
			-platform win32-msvc2015 -opensource -confirm-license -qmake $archflags -sse2 -ltcg -directwrite -mp -qt-libpng -qt-libjpeg -opengl desktop `
			-qt-sql-sqlite -plugin-sql-sqlite -openssl -L "$root\src-stage1-dependencies\openssl\build\x64\$ssltype" `
			-l ssleay32 -l libeay32 -l crypt32 -l kernel32 -l user32 -l gdi32 -l winspool -l comdlg32 -l advapi32 -l shell32 -l ole32 -l oleaut32 -l uuid -l odbc32 -l odbccp32 -l advapi32 `
			OPENSSL_LIBS="-L$root\src-stage1-dependencies\openssl\build\x64\$ssltype -lssleay32 -llibeay32" -I "$root\src-stage1-dependencies\openssl\build\x64\$ssltype\Include"  2>&1 >> $Log
		Write-Host -NoNewline "building..."
		nmake module-qtbase 2>&1 >> $Log
		nmake module-qtsvg 2>&1 >> $Log
		nmake module-qtbase install 2>&1 >> $Log
		nmake module-qtsvg install 2>&1 >> $Log
		$env:_CL_ = ""
		Validate "bin/qmake.exe" "bin/Qt5Core$debug.dll" "bin/Qt5OpenGL$debug.dll" "bin/Qt5Svg$debug.dll" "bin/Qt5Gui$debug.dll"
	} else {
		Write-Host "already built"
	}
}
cd $root/src-stage1-dependencies/Qt5
# Various things in Qt build are intepreted as errors so 
$ErrorActionPreference = "Continue"
$env:QMAKESPEC = "$root/src-stage1-dependencies/Qt5/qtbase/mkspecs/win32-msvc2015"
$env:QTDIR = "$root/src-stage1-dependencies/Qt5"
$env:Path = "$root\src-stage1-dependencies\Qt5\qtbase\bin;" + $oldPath
# debugDLL build
MakeQT5 "DebugDLL"
# release AVX2 DLL build
MakeQT5 "ReleaseDLL-AVX2"
# releaseDLL build
MakeQT5 "ReleaseDLL"
# Static builds (Disabled for speed since we aren't using them)
#MakeQT5 "Debug"
#MakeQT5 "Release-AVX2"
#MakeQT5 "Release"
$env:Path = $oldPath
$ErrorActionPreference = "Stop"

# ____________________________________________________________________________________________________________
# QWT 5.2.3
# must be after Qt4
# all those cleans are important because like Qt, QMAKE does a terrible job of cleaning up makefiles and configs
# when building in more than one configuration
# Also note that 4 builds go into a single folder... because debug and release libraries have different names
# and the static/dll libs have different names, so no conflict...
# Note that even the static builds are linking against the DLL builds of Qt.  This is important, PyQwt will
# fail with 10 linker errors otherwise.
SetLog "Qwt"
Write-Host -NoNewline "building qwt5..."
Function MakeQwt {
	Write-Host -NoNewLine $args[0]"..."
	nmake /NOLOGO clean 2>&1 >> $Log
	nmake /NOLOGO distclean 2>&1 >> $Log
	Invoke-Expression $command 2>&1 >> $Log
	nmake /NOLOGO 2>&1 >>  $Log
	nmake /NOLOGO install 2>&1 >> $Log
}
$ErrorActionPreference = "Continue"

cd $root\src-stage1-dependencies\qwt-$qwt_version 
if ((TryValidate "build/x64/Debug-Release/lib/qwtd.lib" "build/x64/Debug-Release/lib/qwtd5.dll" "build/x64/Debug-Release/lib/qwt5.dll" "build/x64/Debug-Release/lib/qwt.lib" `
	"build/x64/Release-AVX2/lib/qwt5.dll" "build/x64/Release-AVX2/lib/qwt.lib") -eq $false) {
	$env:QMAKESPEC = "win32-msvc2015"
	$env:QTDIR = "$root/src-stage1-dependencies/Qt4"
	Copy-Item -Force $root\src-stage1-dependencies\Qt4\build\ReleaseDLL\lib\*4.lib $root\src-stage1-dependencies\Qt4\build\DebugDLL\lib
	Copy-Item -Force $root\src-stage1-dependencies\Qt4\build\DebugDLL\lib\*d4.lib $root\src-stage1-dependencies\Qt4\build\ReleaseDLL\lib
	Copy-Item -Force $root\src-stage1-dependencies\Qt4\build\DebugDLL\lib\*d4.lib $root\src-stage1-dependencies\Qt4\build\ReleaseDLL-AVX2\lib

	$env:_CL_ = ""
	$env:_LINK_ = "  /LIBPATH:""$root\src-stage1-dependencies\Qt4\build\DebugDLL\lib"" /DEBUG:FULL /PDB:""$root/src-stage1-dependencies/qwt-$qwt_version/build/x64/Debug-Release/lib/qwtd.pdb"" "
	$command = "$root\src-stage1-dependencies\Qt4\build\DebugDLL\bin\qmake.exe qwt.pro ""CONFIG-=release_with_debuginfo"" ""CONFIG+=debug"" ""PREFIX=$root/src-stage1-dependencies/qwt-$qwt_version/build/x64/Debug-Release"" ""MAKEDLL=NO"" ""AVX2=NO"""
	MakeQwt "Debug"
	$env:_LINK_ = "  /LIBPATH:""$root\src-stage1-dependencies\Qt4\build\DebugDLL\lib"" /DEBUG:FULL /PDB:""$root/src-stage1-dependencies/qwt-$qwt_version/build/x64/Debug-Release/lib/qwtd5.pdb"" "
	$command = "$root\src-stage1-dependencies\Qt4\build\DebugDLL\bin\qmake.exe qwt.pro ""CONFIG+=debug"" ""PREFIX=$root/src-stage1-dependencies/qwt-$qwt_version/build/x64/Debug-Release"" ""MAKEDLL=YES"" ""AVX2=NO"""
	MakeQwt "DebugDLL"
	$env:_LINK_ = "  /LIBPATH:""$root\src-stage1-dependencies\Qt4\build\ReleaseDLL\lib"" /DEBUG:FULL /PDB:""$root/src-stage1-dependencies/qwt-$qwt_version/build/x64/Debug-Release/lib/qwt.pdb"" "
	$command = "$root\src-stage1-dependencies\Qt4\build\ReleaseDLL\bin\qmake.exe qwt.pro ""CONFIG-=debug"" ""CONFIG+=release_with_debuginfo"" ""PREFIX=$root/src-stage1-dependencies/qwt-$qwt_version/build/x64/Debug-Release"" ""MAKEDLL=NO"" ""AVX2=NO"""
	MakeQwt "Release"
	$env:_LINK_ = "  /LIBPATH:""$root\src-stage1-dependencies\Qt4\build\ReleaseDLL\lib"" /DEBUG:FULL /PDB:""$root/src-stage1-dependencies/qwt-$qwt_version/build/x64/Debug-Release/lib/qwt5.pdb"" "
	$command = "$root\src-stage1-dependencies\Qt4\build\ReleaseDLL\bin\qmake.exe qwt.pro ""CONFIG+=release_with_debuginfo"" ""PREFIX=$root/src-stage1-dependencies/qwt-$qwt_version/build/x64/Debug-Release"" ""MAKEDLL=YES"" ""AVX2=NO"""
	MakeQwt "ReleaseDLL"

	$env:_CL_ = "/Ox /arch:AVX2 /Zi /Gs- " 
	$env:_LINK_ = "  /LIBPATH:""$root\src-stage1-dependencies\Qt4\build\ReleaseDLL-AVX2\lib"" /DEBUG:FULL /PDB:""$root/src-stage1-dependencies/qwt-$qwt_version/build/x64/Release-AVX2/lib/qwt.pdb"" "
	$command = "$root\src-stage1-dependencies\Qt4\build\ReleaseDLL-AVX2\bin\qmake.exe qwt.pro ""CONFIG+=release_with_debuginfo"" ""PREFIX=$root/src-stage1-dependencies/qwt-$qwt_version/build/x64/Release-AVX2"" ""MAKEDLL=NO"" ""AVX2=YES"""
	MakeQwt "Release-AVX2"
	$env:_LINK_ = "  /LIBPATH:""$root\src-stage1-dependencies\Qt4\build\ReleaseDLL-AVX2\lib"" /DEBUG:FULL /PDB:""$root/src-stage1-dependencies/qwt-$qwt_version/build/x64/Release-AVX2/lib/qwt5.pdb"" "
	$command = "$root\src-stage1-dependencies\Qt4\build\ReleaseDLL-AVX2\bin\qmake.exe qwt.pro ""CONFIG+=release_with_debuginfo"" ""PREFIX=$root/src-stage1-dependencies/qwt-$qwt_version/build/x64/Release-AVX2"" ""MAKEDLL=YES"" ""AVX2=YES"""
	MakeQwt "ReleaseDLL-AVX2"

	$env:_CL_ = ""
	$env:_LINK_ = ""
	$ErrorActionPreference = "Stop"
	Validate "build/x64/Debug-Release/lib/qwtd.lib" "build/x64/Debug-Release/lib/qwtd5.dll" "build/x64/Debug-Release/lib/qwt5.dll" "build/x64/Debug-Release/lib/qwt.lib" `
		"build/x64/Release-AVX2/lib/qwt5.dll" "build/x64/Release-AVX2/lib/qwt.lib"
	CheckNoAVX "$root\src-stage1-dependencies\qwt-$qwt_version/build/x64/Debug-Release/lib"
} else {
	Write-Host "already built"
}

# ____________________________________________________________________________________________________________
# QWT 6
#
# requires Qt4
#
# This builds both debug and release libraries versions for each 
#
SetLog "Qwt6"
Write-Host -NoNewline "building qwt6..."
Function MakeQwt6 {
	Write-Host -NoNewLine $args[0]"..."
	nmake /NOLOGO clean 2>&1 >> $Log
	nmake /NOLOGO mocclean 2>&1 >> $Log
	nmake /NOLOGO distclean 2>&1 >> $Log
	Remove-Item -Force src/Makefile 2>&1 >> $Log
	Remove-Item -Force src/Makefile.Debug 2>&1 >> $Log
	Remove-Item -Force src/Makefile.Release 2>&1 >> $Log
	Invoke-Expression $command 2>&1 >> $Log
	nmake /NOLOGO 2>&1 >>  $Log
	nmake /NOLOGO install 2>&1 >> $Log
}
$ErrorActionPreference = "Continue"
$env:QMAKESPEC = "win32-msvc2015"
$env:QTDIR = "$root/src-stage1-dependencies/Qt4"
cd $root\src-stage1-dependencies\qwt-$qwt6_version
if ((TryValidate "build/x64/Debug/lib/qwtd.lib" "build/x64/Debug/lib/qwtd6.dll" "build/x64/Release/lib/qwt6.dll" "build/x64/Release/lib/qwt.lib" `
	"build/x64/Release-AVX2/lib/qwt6.dll" "build/x64/Release-AVX2/lib/qwt.lib" "build/x64/Release-AVX2/lib/qwt6.lib") -eq $false) {
	# Debug DLL (linked to debug Qt4 libraries)
	$env:_CL_ = " /Zi /EHsc "
	$env:_LINK_ = "  /LIBPATH:""$root\src-stage1-dependencies\Qt4\build\DebugDLL\lib""  "
	$env:Path =  " $root\src-stage1-dependencies\Qt4\build\DebugDLL\lib;$root\src-stage1-dependencies\Qt4\build\ReleaseDLL\lib" + $oldPath
	$command = "$root\src-stage1-dependencies\Qt4\build\DebugDLL\bin\qmake.exe qwt.pro ""PREFIX=$root/src-stage1-dependencies/qwt-$qwt6_version/build/x64/Debug"" ""CONFIG-=release_with_debuginfo"" ""CONFIG=debug"" ""MAKEDLL=YES"" ""AVX2=NO"" ""QT_DLL=YES"""
	MakeQwt6 "DebugDLL"
	# Debug static
	$env:_LINK_ = "  /LIBPATH:""$root\src-stage1-dependencies\Qt4\build\DebugDLL\lib""  "
	$command = "$root\src-stage1-dependencies\Qt4\build\DebugDLL\bin\qmake.exe qwt.pro ""PREFIX=$root/src-stage1-dependencies/qwt-$qwt6_version/build/x64/Debug"" ""CONFIG-=release_with_debuginfo"" ""CONFIG=debug"" ""MAKEDLL=NO"" ""AVX2=NO"" ""QT_DLL=YES"""
	MakeQwt6 "Debug"

	# Release DLL
	$env:_CL_ = " /Zi /EHsc "
	$env:_LINK_ = "  /LIBPATH:""$root\src-stage1-dependencies\Qt4\build\ReleaseDLL\lib""  "
	$env:Path = " $root\src-stage1-dependencies\Qt4\build\DebugDLL\lib;$root\src-stage1-dependencies\Qt4\build\ReleaseDLL\lib" + $oldPath
	$command = "$root\src-stage1-dependencies\Qt4\build\ReleaseDLL\bin\qmake.exe qwt.pro ""PREFIX=$root/src-stage1-dependencies/qwt-$qwt6_version/build/x64/Release"" ""CONFIG-=release_with_debuginfo"" ""CONFIG+=release"" ""MAKEDLL=YES"" ""AVX2=NO"" ""QT_DLL=YES"""
	MakeQwt6 "ReleaseDLL"
	# Release static
	$env:_LINK_ = "  /LIBPATH:""$root\src-stage1-dependencies\Qt4\build\ReleaseDLL\lib"" /LIBPATH:""$root\src-stage1-dependencies\Qt4\build\DebugDLL\lib"" "" "
	$command = "$root\src-stage1-dependencies\Qt4\build\ReleaseDLL\bin\qmake.exe qwt.pro  ""PREFIX=$root/src-stage1-dependencies/qwt-$qwt6_version/build/x64/Release""  ""CONFIG-=release_with_debuginfo"" ""CONFIG+=release"" ""MAKEDLL=NO"" ""AVX2=NO"" ""QT_DLL=YES"""
	MakeQwt6 "Release"


	# Release AVX2 DLL
	$env:_CL_ = " /Ox /arch:AVX2 /Zi /Gs- /EHsc " 
	$env:_LINK_ = "  /LIBPATH:""$root\src-stage1-dependencies\Qt4\build\ReleaseDLL-AVX2\lib"" "
	$env:Path = " $root\src-stage1-dependencies\Qt4\build\DebugDLL\lib;$root\src-stage1-dependencies\Qt4\build\ReleaseDLL\lib" + $oldPath
	$command = "$root\src-stage1-dependencies\Qt4\build\ReleaseDLL-AVX2\bin\qmake.exe qwt.pro ""PREFIX=$root/src-stage1-dependencies/qwt-$qwt6_version/build/x64/Release-AVX2"" ""CONFIG-=release_with_debuginfo"" ""CONFIG+=release"" ""MAKEDLL=YES"" ""AVX2=YES"" ""QT_DLL=YES"""
	MakeQwt6 "ReleaseDLL-AVX2"
	# Release AVX2 Static
	$env:_LINK_ = "  /LIBPATH:""$root\src-stage1-dependencies\Qt4\build\ReleaseDLL-AVX2\lib"" "
	$command = "$root\src-stage1-dependencies\Qt4\build\ReleaseDLL-AVX2\bin\qmake.exe qwt.pro ""PREFIX=$root/src-stage1-dependencies/qwt-$qwt6_version/build/x64/Release-AVX2""  ""CONFIG-=release_with_debuginfo"" ""CONFIG+=release"" ""MAKEDLL=NO"" ""AVX2=YES"" ""QT_DLL=YES"""
	MakeQwt6 "Release-AVX2"

	$env:_CL_ = ""
	$env:_LINK_ = ""
	$ErrorActionPreference = "Stop"
	cd $root\src-stage1-dependencies\qwt-$qwt6_version
	Validate "build/x64/Debug/lib/qwtd.lib" "build/x64/Debug/lib/qwtd6.dll" "build/x64/Release/lib/qwt6.dll" "build/x64/Release/lib/qwt.lib" `
		"build/x64/Release-AVX2/lib/qwt6.dll" "build/x64/Release-AVX2/lib/qwt.lib" "build/x64/Release-AVX2/lib/qwt6.lib"
	CheckNoAVX "$root\src-stage1-dependencies\qwt-$qwt6_version/build/x64/Release/lib"
} else {
	Write-Host "already built"
}

# ____________________________________________________________________________________________________________
# QwtPlot3D
#
# requires Qt4
#
# 
SetLog "QwtPlot3d"
Function MakeQwtPlot3d { 
	$configuration = $args[0]
	cd $root\src-stage1-dependencies\qwtplot3d
	Write-Host -NoNewline "building QwtPlot3d $configuration..."
	if ((TryValidate "build/$configuration/qwtplot3d.dll") -eq $false) {
		New-Item -Force -ItemType Directory build/$configuration  2>&1 >> $Log  
		$env:QMAKESPEC = "$root/src-stage1-dependencies/Qt4/mkspecs/win32-msvc2015"
		$env:QTDIR = "$root/src-stage1-dependencies/Qt4"
		if ($configuration -match "Debug") {$buildconfig="Debug"; $debug = "d"} else {$buildconfig="Release"; $debug = ""}
		if ($configuration -match "AVX2") {
			$configDLL = "ReleaseDLL-AVX2"
			$env:_CL_ = " /Fdbuild/$configuration/qwtplot3d.pdb /I$root/src-stage1-dependencies/zlib-1.2.8 /I$root/src-stage1-dependencies/Qt4/build/$configDLL/include/QtCore /D_M_X64 /D_WIN64 /UQT_NO_DYNAMIC_CAST /GR /EHsc /arch:AVX2 /Ox /Zi "
			$env:_LINK_ = " /LIBPATH:""$root\src-stage1-dependencies\zlib-1.2.8\contrib\vstudio\vc14\x64\ZlibStat$configuration"" /LIBPATH:""$root/src-stage1-dependencies/Qt4/build/$configDLL/lib"" /LTCG /DEFAULTLIB:""$root/src-stage1-dependencies/qwt-$qwt6_version/build/x64/$configuration/lib/qwt6.lib "
		} else {
			$configDLL = $configuration + "DLL"
			$env:_CL_ = " /Fdbuild/$configuration/qwtplot3d.pdb /I$root/src-stage1-dependencies/zlib-1.2.8 /I$root/src-stage1-dependencies/Qt4/build/$configDLL/include/QtCore /D_M_X64 /D_WIN64 /UQT_NO_DYNAMIC_CAST /GR /EHsc /Zi "
			$env:_LINK_ = " /LIBPATH:""$root\src-stage1-dependencies\zlib-1.2.8\contrib\vstudio\vc14\x64\ZlibStat$configuration"" /LIBPATH:""$root/src-stage1-dependencies/Qt4/build/$configDLL/lib"" /LTCG /DEFAULTLIB:""$root/src-stage1-dependencies/qwt-$qwt6_version/build/x64/$configuration/lib/qwt$debug6.lib "
		}
		$env:Path = "${env:ProgramFiles(x86)}\Microsoft Visual Studio 14.0\VC\bin\amd64;$root\src-stage1-dependencies\Qt4\build\$configDLL\bin;" +  $oldPath
		$ErrorActionPreference = "Continue"
		& qmake.exe qwtplot3d.pro  2>&1 >> $Log  
		# this invocation of qmake seems to get confused about what version of msvc to build for so we need to manually upgrade
		devenv qwtplot3d.vcxproj /Upgrade 2>&1 >> $Log  
		msbuild .\qwtplot3d.vcxproj /m /p:"configuration=$buildconfig;platform=x64" 2>&1 >> $Log  
		Move-Item -Force lib/qwtplot3d.lib build/$configuration
		Move-Item -Force lib/qwtplot3d.dll build/$configuration
		Move-Item -Force lib/qwtplot3d.exp build/$configuration
		if ($configuration -eq "Debug") {Move-Item -Force lib/qwtplot3d.pdb build/$configuration}
		Remove-Item Backup -Recurse  
		Remove-Item UpgradeLog.htm 
		Validate "build/$configuration/qwtplot3d.dll"
		$env:_CL_ = " "
		$env:_LINK_ = ""
		$env:Path = $oldPath
	} else {
		Write-Host "already built"
	}
}
MakeQwtPlot3d "Debug"
MakeQwtPlot3d "Release"
MakeQwtPlot3d "Release-AVX2"

# ____________________________________________________________________________________________________________
# Mako
# Mako is a python-only package can be installed automatically
# used by UHD drivers
#
SetLog "Mako"
Write-Host -NoNewline "installing Mako using pip..."
if ((TryValidate "$root\src-stage2-python\gr-python27\lib\site-packages\mako" "$root\src-stage2-python\gr-python27-avx2\lib\site-packages\mako" "$root\src-stage2-python\gr-python27-debug\lib\site-packages\mako") -eq $false) {
	$pythonroot = "$root\src-stage2-python\gr-python27"
	& $pythonroot/Scripts/pip.exe --disable-pip-version-check -v install mako -U -t $pythonroot\lib\site-packages 2>&1 >> $log
	$pythonroot = "$root\src-stage2-python\gr-python27-avx2"
	& $pythonroot/Scripts/pip.exe --disable-pip-version-check -v install mako -U -t $pythonroot\lib\site-packages 2>&1 >> $log
	$pythonroot = "$root\src-stage2-python\gr-python27-debug"
	$ErrorActionPreference = "Continue" # pip will "error" on debug
	& $pythonroot/Scripts/pip.exe --disable-pip-version-check -v install mako -U -t $pythonroot\lib\site-packages 2>&1 >> $log
	$ErrorActionPreference = "Stop"
	"complete"
} else {
	Write-Host "already built"
}

# ____________________________________________________________________________________________________________
# Requests
# Requests is a python-only package can be installed automatically
# used by UHD helper script that downloads the UHD firmware images in step 8
#
SetLog "Requests"
Write-Host -NoNewline "installing Requests using pip..."
if ((TryValidate "$root\src-stage2-python\gr-python27\lib\site-packages\requests" "$root\src-stage2-python\gr-python27-avx2\lib\site-packages\requests" "$root\src-stage2-python\gr-python27-debug\lib\site-packages\requests") -eq $false) {
	$pythonroot = "$root\src-stage2-python\gr-python27"
	& $pythonroot/Scripts/pip.exe --disable-pip-version-check -v install requests -U -t $pythonroot\lib\site-packages 2>&1 >> $log
	$pythonroot = "$root\src-stage2-python\gr-python27-avx2"
	& $pythonroot/Scripts/pip.exe --disable-pip-version-check -v install requests -U -t $pythonroot\lib\site-packages 2>&1 >> $log
	$pythonroot = "$root\src-stage2-python\gr-python27-debug"
	$ErrorActionPreference = "Continue" # pip will "error" on debug
	& $pythonroot/Scripts/pip.exe --disable-pip-version-check -v install requests -U -t $pythonroot\lib\site-packages 2>&1 >> $log
	$ErrorActionPreference = "Stop"
	"complete"
} else {
	Write-Host "already built"
}

# ____________________________________________________________________________________________________________
# UHD 
#
# requires libusb, boost, python, mako
# FYI BOOST_FORCE_SYMMETRIC_OPERATORS is required for debug versions because MSVC 2015 disable NRVO for debug builds which causes duplicate operator error

SetLog "UHD"
Write-Host "building uhd..."
$ErrorActionPreference = "Continue"
cd $root\src-stage1-dependencies\uhd-$UHD_version\host
New-Item -ItemType Directory -Force -Path .\build  2>&1 >> $Log
cd build 

Function makeUHD {
	$configuration = $args[0]
	if ((TryValidate "..\..\dist\$configuration\bin\uhd.dll" "..\..\dist\$configuration\lib\uhd.lib" "..\..\dist\$configuration\include\uhd.h") -eq $false) {
		Write-Host -NoNewline "  configuring $configuration..."
		if ($configuration -match "AVX2") {$platform = "avx2"; $env:_CL_ = "/arch:AVX2 "} else {$platform = "x64"; $env:_CL_ = ""}
		if ($configuration -match "Release") {$boostconfig = "Release"; $buildconfig="RelWithDebInfo"; $pythonexe = "python.exe"; $env:_CL_ = $env:_CL_ + " /MD "} else {$boostconfig = "Debug"; $buildconfig="Debug"; $pythonexe = "python_d.exe"; $env:_CL_ = $env:_CL_ + " /MDd "}
		$linkflags= " /DEBUG  /NODEFAULTLIB:LIBCMT.lib /NODEFAULTLIB:LIBCMTD.lib "
		& cmake .. `
			-G "Visual Studio 14 2015 Win64" `
			-DPYTHON_EXECUTABLE="$pythonroot\$pythonexe" `
			-DCMAKE_SHARED_LINKER_FLAGS=" $linkflags " `
			-DCMAKE_EXE_LINKER_FLAGS=" $linkflags " `
			-DCMAKE_STATIC_LINKER_FLAGS=" $linkflags " `
			-DCMAKE_MODULE_LINKER_FLAGS=" $linkflags  " `
			-DCMAKE_CXX_FLAGS=" /DBOOST_FORCE_SYMMETRIC_OPERATORS " `
			-DBoost_INCLUDE_DIR="$root/src-stage1-dependencies/boost/build/$platform/$boostconfig/include/boost-1_60" `
			-DBoost_LIBRARY_DIR="$root/src-stage1-dependencies/boost/build/$platform/$boostconfig/lib" `
			-DLIBUSB_INCLUDE_DIRS="$root/src-stage1-dependencies/libusb/libusb" `
			-DLIBUSB_LIBRARIES="$root/src-stage1-dependencies/libusb/x64/$configuration/lib/libusb-1.0.lib" 2>&1 >> $Log 
		Write-Host -NoNewline "building..."
		msbuild .\UHD.sln /m /p:"configuration=$buildconfig;platform=x64" 2>&1 >> $Log 
		Write-Host -NoNewline "installing..."
		& cmake -DCMAKE_INSTALL_PREFIX="$root/src-stage1-dependencies/uhd-$UHD_version\dist\$configuration" -DBUILD_TYPE="$buildconfig" -P cmake_install.cmake 2>&1 >> $Log
		New-Item -ItemType Directory -Path $root/src-stage1-dependencies/uhd-$UHD_version\dist\$configuration\share\uhd\examples\ -Force 2>&1 >> $Log
		cp -Recurse -Force $root/src-stage1-dependencies/uhd-$UHD_version/host/build/examples/$buildconfig/* $root/src-stage1-dependencies/uhd-$UHD_version\dist\$configuration\share\uhd\examples\
		Validate "..\..\dist\$configuration\bin\uhd.dll" "..\..\dist\$configuration\lib\uhd.lib" "..\..\dist\$configuration\include\uhd.h"
		$env:_CL_ = ""
	} else {
		Write-Host "  $configuration already built"
	}
}

# AVX2 build
$pythonroot = "$root\src-stage2-python\gr-python27-avx2"
makeUHD "Release-AVX2"

# Release build
$pythonroot = "$root\src-stage2-python\gr-python27"
makeUHD "Release"

# Debug build
$pythonroot = "$root\src-stage2-python\gr-python27-debug"
makeUHD "Debug"


# ____________________________________________________________________________________________________________
# pthreads
#
SetLog "pthreads"
Write-Host "building pthreads..."
$ErrorActionPreference = "Continue"
$env:_CL_ = ""
cd $root\src-stage1-dependencies\pthreads\pthreads.2
if ((TryValidate "x64\Debug\pthreadVC2.lib" "x64\Release\pthreadVC2.lib" "x64\Release-AVX2\pthreadVC2.lib" `
	"x64\DebugDLL\pthreadVC2.dll" "x64\ReleaseDLL\pthreadVC2.dll" "x64\ReleaseDLL-AVX2\pthreadVC2.dll") -eq $false) {
	Write-Host -NoNewline "Debug..."
	msbuild .\pthread.sln /m /p:"configuration=Debug;platform=x64" >> $Log
	Write-Host -NoNewline "DLL..."
	msbuild .\pthread.sln /m /p:"configuration=DebugDLL;platform=x64" >> $Log
	Write-Host -NoNewline "Release..."
	msbuild .\pthread.sln /m /p:"configuration=Release;platform=x64" >> $Log
	Write-Host -NoNewline "DLL..."
	msbuild .\pthread.sln /m /p:"configuration=ReleaseDLL;platform=x64" >> $Log
	Write-Host -NoNewline "Release-AVX2..."
	msbuild .\pthread.sln /m /p:"configuration=Release-AVX2;platform=x64" >> $Log 
	Write-Host -NoNewline "DLL..."
	msbuild .\pthread.sln /m /p:"configuration=ReleaseDLL-AVX2;platform=x64" >> $Log 
	Validate "x64\Debug\pthreadVC2.lib" "x64\Release\pthreadVC2.lib" "x64\Release-AVX2\pthreadVC2.lib" `
		"x64\DebugDLL\pthreadVC2.dll" "x64\ReleaseDLL\pthreadVC2.dll" "x64\ReleaseDLL-AVX2\pthreadVC2.dll"
	CheckNoAVX "$root\src-stage1-dependencies\pthreads\pthreads.2\x64\Release"
	CheckNoAVX "$root\src-stage1-dependencies\pthreads\pthreads.2\x64\ReleaseDLL"
} else {
	Write-Host "already built"
}

# ____________________________________________________________________________________________________________
# openblas
#
# Note that openblas will be slow as the assembly code is not used because it's not in MSVC format
# TODO upgrade openblas asm format
# openblas lapack and lapacke have a ton of external errors during build
# TODO build patch for modified CMAKE
# TODO we will always build this for now because gr-specest and Armadillo also would need to point to MKL and right now they don't
if (!$BuildNumpyWithMKL -or $true) {
	SetLog "openblas"
	Write-Host "building openblas..."
	function MakeOpenBLAS {
		$ErrorActionPreference = "Continue"
		$configuration = $args[0]
		if ($configuration -match "Debug") {$cmakebuildtype = "Debug"; $debug="ON"} else {$cmakebuildtype = "Release"; $debug="OFF"}
		if ($configuration -match "AVX2") {$env:_CL_ = " -D__64BIT__ /arch:AVX2 "} else {$env:_CL_ = " -D__64BIT__ "}
		Write-Host -NoNewline "  configuring $configuration..."
		New-Item -ItemType Directory -Force $root\src-stage1-dependencies\OpenBLAS-$openblas_version\build\$configuration 2>&1 >> $Log 
		cd $root\src-stage1-dependencies\openblas-$openblas_version\build\$configuration
		if ((TryValidate "lib\libopenblas.lib" "lib\libopenblas.dll" "lib\libopenblas_static.lib") -eq $false) {
			cmake ..\..\ `
				-Wno-dev `
				-G "Visual Studio 14 Win64" `
				-DTARGET="HASWELL" `
				-DBUILD_DEBUG="$debug" `
				-DF_COMPILER="INTEL" `
				-DCMAKE_Fortran_COMPILER="ifort" `
				-DCMAKE_Fortran_FLAGS=" /assume:underscore /names:lowercase " `
				-DNO_LAPACKE="1" `
				-DNO_LAPACK="1"  2>&1 >> $Log 
			$env:__INTEL_POST_FFLAGS = " /assume:underscore /names:lowercase "
			Write-Host -NoNewline "building..."
			msbuild .\OpenBLAS.sln /m /p:"configuration=$cmakebuildtype;platform=x64" 2>&1 >> $Log 
			cp $root\src-stage1-dependencies\OpenBLAS-$openblas_version\build\$configuration\lib\$cmakebuildtype\libopenblas.lib $root\src-stage1-dependencies\OpenBLAS-$openblas_version\build\$configuration\lib\libopenblas_static.lib 2>&1 >> $Log 
			$env:_CL_ = ""
			$env:__INTEL_POST_FFLAGS = ""
			Validate "lib\libopenblas.lib" "lib\libopenblas.dll" "lib\libopenblas_static.lib"
			$ErrorActionPreference = "Stop"
		} else {
			Write-Host "already built"
		}
	}
	MakeOpenBlas "Debug"
	MakeOpenBlas "Release"
	MakeOpenBlas "Release-AVX2"
}

# ____________________________________________________________________________________________________________
# lapack
#
# like scipy, this requires a fortran compiler to be installed, and gfortran doesn't work well with MSVC
# so there isn't a free option, we look for Intel Fortran Compiler during setup.
# Don't despair though, if not fort then we'll just download binary wheels later.
if (!$BuildNumpyWithMKL -and $hasIFORT) {
	SetLog "lapack"
	Write-Host "building lapack..."
	function MakeLapack {
		$ErrorActionPreference = "Continue"
		$configuration = $args[0]
		if ($configuration -match "Debug") {$cmakebuildtype = "Debug"} else {$cmakebuildtype = "Release"}
		if ($configuration -match "AVX2") {$env:_CL_ = " /arch:AVX2 "} else {$env:_CL_ = ""}
		Write-Host -NoNewline "  configuring $configuration..."
		New-Item -ItemType Directory -Force $root\src-stage1-dependencies\lapack\build\$configuration 2>&1 >> $Log 
		cd $root\src-stage1-dependencies\lapack\build\$configuration
		if ((TryValidate "../../dist/$configuration/lib/blas.lib" "../../dist/$configuration/lib/lapack.lib") -eq $false) {
			cmake ..\..\ `
				-Wno-dev `
				-G "Visual Studio 14 Win64" `
				-DCMAKE_BUILD_TYPE="$cmakebuildtype" `
				-DPYTHON_EXECUTABLE="$pythonroot\$pythonexe" `
				-DCMAKE_INSTALL_PREFIX="$root/src-stage1-dependencies/lapack/dist/$configuration/" `
				-DCMAKE_Fortran_FLAGS=" /assume:underscore /names:lowercase " 2>&1 >> $Log 
			$env:__INTEL_POST_FFLAGS = " /assume:underscore /names:lowercase "
			Write-Host -NoNewline "building..."
			# use devenv instead of msbuild because of vfproj files unsupported by msbuild
			devenv .\lapack.sln /project lapack /rebuild "$cmakebuildtype|x64"  2>&1 >> $Log 
			devenv .\lapack.sln /project blas /rebuild "$cmakebuildtype|x64"  2>&1 >> $Log 
			Write-Host -NoNewline "packaging..."
			# don't run the INSTALL vcproj because it will fail because the dependencies won't link
			cmake -DBUILD_TYPE="$cmakebuildtype" -P cmake_install.cmake 2>&1 >> $Log 
			$env:_CL_ = ""
			$env:__INTEL_POST_FFLAGS = ""
			Validate "../../dist/$configuration/lib/blas.lib" "../../dist/$configuration/lib/lapack.lib"
		} else {
			Write-Host "already built"
		}
	}
	MakeLapack "Debug"
	MakeLapack "Release"
	MakeLapack "Release-AVX2"
}

# ____________________________________________________________________________________________________________
# mbedtls (polarssl)
#
Write-Host "building mbedtls..."
SetLog "mbedtls (polarssl)"
$ErrorActionPreference = "Continue"
$env:_LINK_ = ""
function MakembedTLS {
	$ErrorActionPreference = "Continue"
	$configuration = $args[0]
	if ($configuration -match "Debug") {$cmakebuildtype = "Debug"; $debug="Debug"} else {$cmakebuildtype = "Release"; $debug="RelWithDebInfo"}
	if ($configuration -match "AVX2") {$env:_CL_ = " /arch:AVX2 "} else {$env:_CL_ = ""}
	if ($configuration -match "DLL") {$DLL = "ON"} else {$DLL = "OFF"}
	Write-Host -NoNewline "  configuring $configuration..."
	New-Item -ItemType Directory -Force $root\src-stage1-dependencies\mbedtls-mbedtls-$mbedtls_version\build\$configuration 2>&1 >> $Log 
	cd $root\src-stage1-dependencies\mbedtls-mbedtls-$mbedtls_version\build\$configuration
	if (((TryValidate "..\..\dist\$configuration\lib\mbedtls.dll") -eq $false -and ($DLL -eq "ON")) -or `
		((TryValidate "..\..\dist\$configuration\lib\mbedtls.lib") -eq $false)) {
		cmake ..\..\ `
			-Wno-dev `
			-G "Visual Studio 14 Win64" `
			-DENABLE_TESTING="ON" `
			-DCMAKE_BUILD_TYPE="$cmakebuildtype" `
			-DUSE_SHARED_MBEDTLS_LIBRARY="$DLL" `
			-DCMAKE_INSTALL_PREFIX="$root/src-stage1-dependencies/mbedtls-mbedtls-$mbedtls_version/dist/$configuration/" 2>&1 >> $Log 
		Write-Host -NoNewline "building..."
		msbuild ".\mbed TLS.sln" /m /p:"configuration=$debug;platform=x64" 2>&1 >> $Log 
		Write-Host -NoNewline "installing..."
		msbuild .\INSTALL.vcxproj /m /p:"configuration=$debug;platform=x64;BuildProjectReferences=false" 2>&1 >> $Log
		$env:_CL_ = ""
		if ($configuration -match "DLL") {
			Validate "..\..\dist\$configuration\lib\mbedtls.lib" "..\..\dist\$configuration\lib\mbedtls.dll" 
		} else {
			Validate "..\..\dist\$configuration\lib\mbedtls.lib"
		}
	} else {
		Write-Host "already built"
	}
	$ErrorActionPreference = "Stop"
}
MakembedTLS "Debug"
MakembedTLS "Release"
MakembedTLS "Release-AVX2"
MakembedTLS "DebugDLL"
MakembedTLS "ReleaseDLL"
MakembedTLS "ReleaseDLL-AVX2"
	
# Build GNURadio 3.8+ dependencies only if applicable
$mm = GetMajorMinor($gnuradio_version)
if ($mm -eq "3.8") {

# ____________________________________________________________________________________________________________
# log4cpp
# log utility library used in GNURadio 3.8+

	SetLog "log4cpp"
	Write-Host -NoNewline "Building log4cpp..."
	cd $root\src-stage1-dependencies\log4cpp\msvc14
	if ((TryValidate "x64/Release/log4cpp.dll" "x64/Release/log4cpp.pdb"  "x64/Release/log4cpp.lib" `
		"x64/Debug/log4cpp.dll" "x64/Debug/log4cpp.pdb"  "x64/Debug/log4cpp.lib" ) -eq $false) {
		msbuild msvc14.sln /m /p:"configuration=Release;platform=x64" >> $Log
		msbuild msvc14.sln /m /p:"configuration=Debug;platform=x64" >> $Log
		Validate "x64/Release/log4cpp.dll" "x64/Release/log4cpp.pdb"  "x64/Release/log4cpp.lib" `
			"x64/Debug/log4cpp.dll" "x64/Debug/log4cpp.pdb"  "x64/Debug/log4cpp.lib" 
	} else {
		Write-Host "already built"
	}

# ____________________________________________________________________________________________________________
# PyQt5

# ____________________________________________________________________________________________________________
# MPIR

	SetLog "MPIR"
	Write-Host -NoNewline "Building MPIR..."
	cd $root\src-stage1-dependencies\mpir\build.vc14 
	if ((TryValidate "../dll/x64/Release/mpir.dll" "../dll/x64/Release/mpir.lib"  "../dll/x64/Release/mpir.pdb" `
		"../dll/x64/Debug/mpir.dll" "../dll/x64/Debug/mpir.lib"  "../dll/x64/Debug/mpir.pdb" `
		"../lib/x64/Release/mpirxx.lib" "../lib/x64/Release/mpir.lib"  "../lib/x64/Release/mpir.pdb" `
		"../lib/x64/Debug/mpirxx.lib" "../lib/x64/Debug/mpir.lib"  "../lib/x64/Debug/mpir.pdb"		) -eq $false) {
		./msbuild.bat gc dll x64 release 2>&1 >> $Log
		./msbuild.bat gc dll x64 debug 2>&1 >> $Log
		./msbuild.bat gc lib x64 release 2>&1 >> $Log
		./msbuild.bat gc lib x64 debug 2>&1 >> $Log
		./msbuild.bat cxx lib x64 release 2>&1 >> $Log
		./msbuild.bat cxx lib x64 debug 2>&1 >> $Log
		Validate "../dll/x64/Release/mpir.dll" "../dll/x64/Release/mpir.lib"  "../dll/x64/Release/mpir.pdb" `
		"../dll/x64/Debug/mpir.dll" "../dll/x64/Debug/mpir.lib"  "../dll/x64/Debug/mpir.pdb"`
		"../lib/x64/Release/mpirxx.lib" "../lib/x64/Release/mpir.lib"  "../lib/x64/Release/mpir.pdb" `
		"../lib/x64/Debug/mpirxx.lib" "../lib/x64/Debug/mpir.lib"  "../lib/x64/Debug/mpir.pdb"	
	} else {
		Write-Host "already built"
	}
}


cd $root/scripts

""
"COMPLETED STEP 3: Core Win32 dependencies have been built"
""
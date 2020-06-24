#
# Step8_BuildOOTModules.ps1
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

$configmode = $args[0]
if ($configmode -eq $null) {$configmode = "all"}
$env:PYTHONPATH=""
$mm = GetMajorMinor($gnuradio_version)

function BuildDrivers 
{
	$configuration = $args[0]
	$buildsymbols=$true
	$pythonroot = "$root/src-stage3/staged_install/$configuration/gr-python27"
	if ($configuration -match "Release") {
		$buildconfig="Release";$pythonexe = "python.exe";  $debugext = "";  $debug_ext = "";  $runtime = "/MD"
	} 
	else {
		$buildconfig="Debug";  $pythonexe = "python_d.exe";$debugext = "d"; $debug_ext = "_d";$runtime = "/MDd"
	}
	if ($buildsymbols -and $buildconfig -eq "Release") {$buildconfig="RelWithDebInfo"}
	if ($configuration -match "AVX2") {$arch="/arch:AVX2"} else {$arch=""}

	# ____________________________________________________________________________________________________________
	#
	# airspy
	#
	# links to libusb dynamically and pthreads statically
	#
	SetLog "airspy $configuration"
	Write-Host -NoNewline "building $configuration airspy..."
	cd $root/src-stage3/oot_code/airspy/libairspy/vc
	$env:_CL_ = " $arch $runtime "
	msbuild .\airspy_2015.sln /m /p:"configuration=$configuration;platform=x64"  *>> $Log
	Write-Host -NoNewLine "installing..."
	New-Item -ItemType Directory -Force -Path $root/src-stage3/staged_install/$configuration/include/libairspy  *>> $Log
	Copy-Item -Force -Path "$root/src-stage3/oot_code/airspy/libairspy/x64/$configuration/airspy.lib" "$root/src-stage3/staged_install/$configuration/lib" *>> $Log
	Copy-Item -Force -Path "$root/src-stage3/oot_code/airspy/libairspy/x64/$configuration/airspy.dll" "$root/src-stage3/staged_install/$configuration/bin" *>> $Log
	Copy-Item -Force -Path "$root/src-stage3/oot_code/airspy/libairspy/x64/$configuration/*.exe" "$root/src-stage3/staged_install/$configuration/bin" *>> $Log
	Copy-Item -Force -Path "$root/src-stage3/oot_code/airspy/libairspy/src/airspy.h" "$root/src-stage3/staged_install/$configuration/include/libairspy" *>> $Log
	Copy-Item -Force -Path "$root/src-stage3/oot_code/airspy/libairspy/src/airspy_commands.h" "$root/src-stage3/staged_install/$configuration/include/libairspy" *>> $Log
	Validate "$root/src-stage3/oot_code/airspy/libairspy/x64/$configuration/airspy.dll"
	CheckNoAVX "$root/src-stage3/oot_code/airspy/libairspy/x64/$configuration"

	# ____________________________________________________________________________________________________________
	#
	# airspyhf
	#
	# links to libusb dynamically and pthreads statically
	#
	# Note no AVX config is present, so the Release will actually be built twice.
	#
 	SetLog "airspyhf $configuration"
	Write-Host -NoNewline "building $configuration airspyhf..."
	cd $root/src-stage3/oot_code/airspyhf/libairspyhf
	if ($configuration -match "Release") {
		$airspyhf_buildconfig="Release"
	} else {
		$airspyhf_buildconfig="Debug"
	}
	$env:_CL_ = " $arch $runtime /I$root/build/$configuration/include"
	$env:_LINK_ = " $root/build/$configuration/lib/libusb-1.0.lib "
	msbuild .\airspyhf.sln /m /p:"PlatformToolset=v140;configuration=$airspyhf_buildconfig;platform=x64"  *>> $Log
	Write-Host -NoNewLine "installing..."
	New-Item -ItemType Directory -Force -Path $root/src-stage3/staged_install/$configuration/include/libairspyhf  *>> $Log
	Copy-Item -Force -Path "$root/src-stage3/oot_code/airspyhf/libairspyhf/x64/$airspyhf_buildconfig/airspyhf.lib" "$root/src-stage3/staged_install/$configuration/lib" *>> $Log
	Copy-Item -Force -Path "$root/src-stage3/oot_code/airspyhf/libairspyhf/x64/$airspyhf_buildconfig/airspyhf.dll" "$root/src-stage3/staged_install/$configuration/bin" *>> $Log
	Copy-Item -Force -Path "$root/src-stage3/oot_code/airspyhf/libairspyhf/x64/$airspyhf_buildconfig/*.exe" "$root/src-stage3/staged_install/$configuration/bin" *>> $Log
	Copy-Item -Force -Path "$root/src-stage3/oot_code/airspyhf/libairspyhf/src/airspyhf.h" "$root/src-stage3/staged_install/$configuration/include/libairspyhf" *>> $Log
	Copy-Item -Force -Path "$root/src-stage3/oot_code/airspyhf/libairspyhf/src/airspyhf_commands.h" "$root/src-stage3/staged_install/$configuration/include/libairspyhf" *>> $Log
	Validate "$root/src-stage3/oot_code/airspyhf/libairspyhf/x64/$airspyhf_buildconfig/airspyhf.dll" "$root/src-stage3/staged_install/$configuration/include/libairspyhf/airspyhf.h"
	CheckNoAVX "$root/src-stage3/oot_code/airspyhf/libairspyhf/x64/$airspyhf_buildconfig" 
	$env:_CL_ = ""
	$env:_LINK_ = ""

	# ____________________________________________________________________________________________________________
	#
	# SoapySDR
	#
	# links to libusb dynamically and pthreads statically
	#
 	SetLog "SoapySDR $configuration"
	Write-Host -NoNewline "building $configuration SoapySDR..."
	New-Item -ItemType Directory -Force -Path $root/src-stage3/oot_code/SoapySDR/build/$configuration  *>> $Log
	$env:_CL_ = " $arch $runtime "
	cd $root/src-stage3/oot_code/SoapySDR/build/$configuration
	$ErrorActionPreference = "Continue"
	cmake ../../ `
		-G "Visual Studio 14 2015 Win64" `
		-DLIBUSB_PATH="$root/build/$configuration" `
		-DLIBUSB_LIBRARY_PATH_SUFFIX="lib" `
		-DLIBUSB_LIBRARIES="$root/build/$configuration/lib/libusb-1.0.lib" `
		-DLIBUSB_HEADER_FILE="$root/build/$configuration/include/libusb.h" `
		-DLIBUSB_VERSION="$libusb_version" `
		-DLIBUSB_SKIP_VERSION_CHECK=TRUE `
		-DENABLE_BACKEND_LIBUSB=TRUE `
		-DLIBPTHREADSWIN32_PATH="$root/build/$configuration" `
		-DLIBPTHREADSWIN32_LIB_COPYING="$root/build/$configuration/lib/COPYING.lib" `
		-DPTHREAD_LIBRARY="$root/build/$configuration/lib/pthreadVC2.lib" `
		-DPYTHON_LIBRARY="$root/src-stage3/staged_install/$configuration/gr-python27/libs/python27$debug_ext.lib" `
		-DPYTHON_LIBRARY_DEBUG="$root/src-stage3/staged_install/$configuration/gr-python27/libs/python27_d.lib" `
		-DPYTHON_EXECUTABLE="$root/src-stage3/staged_install/$configuration/gr-python27/$pythonexe" `
		-DPYTHON_INCLUDE_DIR="$root/src-stage3/staged_install/$configuration/gr-python27/include" `
		-DSWIG_EXECUTABLE="$root/bin/swig.exe" `
		-DCMAKE_INSTALL_PREFIX="$root/src-stage3/staged_install/$configuration" `
		-Wno-dev `
		-DCMAKE_C_FLAGS="/D_TIMESPEC_DEFINED $arch /DWIN32 /D_WINDOWS /W3 /DPTW32_STATIC_LIB " *>> $Log
	Write-Host -NoNewline "building..."
	msbuild .\SoapySDR.sln /m /p:"configuration=$buildconfig;platform=x64"  *>> $Log
	Write-Host -NoNewline "installing..."
	msbuild .\INSTALL.vcxproj /m /p:"configuration=$buildconfig;platform=x64;BuildProjectReferences=false" *>> $Log
	Validate "$root/src-stage3/staged_install/$configuration/bin/SoapySDR.dll"
	$ErrorActionPreference = "Stop"

<# 	# ____________________________________________________________________________________________________________
	#
	# freeSRP
	#
	# not working currently, CMAKE files have windows issues and then duplicate ambiguous symbols
	#
 	SetLog "freeSRP $configuration"
	Write-Host -NoNewline "building $configuration freeSRP..."
	New-Item -ItemType Directory -Force -Path $root/src-stage3/oot_code/libfreesrp/build/$configuration  *>> $Log
	$env:_CL_ = " $arch $runtime "
	cd $root/src-stage3/oot_code/libfreesrp/build/$configuration
	$ErrorActionPreference = "Continue"	
	cmake ../../ `
		-G "Visual Studio 14 2015 Win64" `
		-DCMAKE_INSTALL_PREFIX="$root/src-stage3/staged_install/$configuration" `
		-DLIBUSB_PATH="$root/build/$configuration" `
		-DLIBUSB_1_LIBRARY="$root/build/$configuration/lib/libusb-1.0.lib" `
		-DLIBUSB_1_INCLUDE_DIR="$root/build/$configuration/include" `
		-DLIBUSB_SKIP_VERSION_CHECK=TRUE `
		-DENABLE_BACKEND_LIBUSB=TRUE `
		-DLIBPTHREADSWIN32_PATH="$root/build/$configuration" `
		-DLIBPTHREADSWIN32_LIB_COPYING="$root/build/$configuration/lib/COPYING.lib" `
		-DPTHREAD_LIBRARY="$root/build/$configuration/lib/pthreadVC2.lib" `
		-Wno-dev `
		-DCMAKE_C_FLAGS="/D_TIMESPEC_DEFINED $arch /DWIN32 /D_WINDOWS /W3 /DPTW32_STATIC_LIB " *>> $Log
	Write-Host -NoNewline "building..."
	msbuild .\libfreesrp.sln /m /p:"configuration=$buildconfig;platform=x64"  *>> $Log
	Write-Host -NoNewline "installing..."
	msbuild .\INSTALL.vcxproj /m /p:"configuration=$buildconfig;platform=x64;BuildProjectReferences=false" *>> $Log
	Validate "$root/src-stage3/staged_install/$configuration/bin/libfreesrp.dll"
	$ErrorActionPreference = "Stop" #>

	# ____________________________________________________________________________________________________________
	#
	# bladeRF
	#
	# links to libusb dynamically and pthreads statically
	# Note that to get this to build without a patch, we needed to place pthreads and libusb dll's in non-standard locations.
	# pthreads dll can actually be deleted afterwards since we statically link it in this build
	# 

	SetLog "bladeRF $configuration"
	Write-Host -NoNewline "configuring $configuration bladeRF..."
	New-Item -ItemType Directory -Force -Path $root/src-stage3/oot_code/bladeRF/host/build/$configuration  *>> $Log
	$env:_CL_ = " $arch $runtime "
	cd $root/src-stage3/oot_code/bladeRF/host/build/$configuration
	cmake ../../ `
		-G "Visual Studio 14 2015 Win64" `
		-DLIBUSB_PATH="$root/build/$configuration" `
		-DLIBUSB_LIBRARY_PATH_SUFFIX="lib" `
		-DLIBUSB_LIBRARIES="$root/build/$configuration/lib/libusb-1.0.lib" `
		-DLIBUSB_HEADER_FILE="$root/build/$configuration/include/libusb.h" `
		-DLIBUSB_VERSION="$libusb_version" `
		-DLIBUSB_SKIP_VERSION_CHECK=TRUE `
		-DENABLE_BACKEND_LIBUSB=TRUE `
		-DLIBPTHREADSWIN32_PATH="$root/build/$configuration" `
		-DLIBPTHREADSWIN32_LIB_COPYING="$root/build/$configuration/lib/COPYING.lib" `
		-DPTHREAD_LIBRARY="$root/build/$configuration/lib/pthreadVC2.lib" `
		-DCMAKE_INSTALL_PREFIX="$root/src-stage3/staged_install/$configuration" `
		-Wno-dev `
		-DCMAKE_C_FLAGS="/D_TIMESPEC_DEFINED $arch /DWIN32 /D_WINDOWS /W3 /DPTW32_STATIC_LIB " *>> $Log
	Write-Host -NoNewline "building..."
	msbuild .\bladeRF.sln /m /p:"configuration=$buildconfig;platform=x64"  *>> $Log
	Write-Host -NoNewline "installing..."
	msbuild .\INSTALL.vcxproj /m /p:"configuration=$buildconfig;platform=x64;BuildProjectReferences=false" *>> $Log
	Copy-Item -Force -Path "$root/src-stage3/staged_install/$configuration/lib/bladeRF.dll" "$root/src-stage3/staged_install/$configuration/bin"
	Remove-Item -Force -Path "$root/src-stage3/staged_install/$configuration/lib/bladeRF.dll"
	Validate "$root/src-stage3/oot_code/bladeRF/host/build/$configuration/output/$buildconfig/bladeRF.dll"
	CheckNoAVX "$root/src-stage3/oot_code/bladeRF/host/build/$configuration/output/$buildconfig"

	# ____________________________________________________________________________________________________________
	#
	# rtl-sdr
	#
	# links to libusb dynamically and pthreads statically
	#
	SetLog "rtl-sdr $configuration"
	Write-Host -NoNewline "configuring $configuration rtl-sdr..."
	New-Item -ItemType Directory -Force -Path $root/src-stage3/oot_code/rtl-sdr/build/$configuration  *>> $Log
	$env:_CL_ = " $arch $runtime "
	cd $root/src-stage3/oot_code/rtl-sdr/build/$configuration 
	cmake ../../ `
		-G "Visual Studio 14 2015 Win64" `
		-DTHREADS_PTHREADS_WIN32_LIBRARY="$root/build/$configuration/lib/pthreadVC2.lib" `
		-DTHREADS_PTHREADS_INCLUDE_DIR="$root/build/$configuration/include" `
		-DLIBUSB_LIBRARIES="$root/build/$configuration/lib/libusb-1.0.lib" `
		-DLIBUSB_INCLUDE_DIR="$root/build/$configuration/include/" `
		-DCMAKE_C_FLAGS="/D_TIMESPEC_DEFINED $arch /DWIN32 /D_WINDOWS /W3 /DPTW32_STATIC_LIB " `
		-DCMAKE_INSTALL_PREFIX="$root/src-stage3/staged_install/$configuration" *>> $Log
	Write-Host -NoNewline "building..."
	msbuild .\rtlsdr.sln /m /p:"configuration=$buildconfig;platform=x64" *>> $Log
	Write-Host -NoNewline "installing..."
	msbuild .\INSTALL.vcxproj /m /p:"configuration=$buildconfig;platform=x64;BuildProjectReferences=false" *>> $Log
	Validate "$root/src-stage3/oot_code/rtl-sdr/build/$configuration/src/$buildconfig/rtlsdr.dll"
	CheckNoAVX "$root/src-stage3/oot_code/rtl-sdr/build/$configuration/src/$buildconfig"

	# ____________________________________________________________________________________________________________
	#
	# hackRF
	#
	# links to libusb dynamically and pthreads statically
	#
	SetLog "HackRF $configuration"
	Write-Host -NoNewline "configuring $configuration HackRF..."
	New-Item -ItemType Directory -Force -Path $root/src-stage3/oot_code/hackrf/build/$configuration  *>> $Log
	cd $root/src-stage3/oot_code/hackrf/build/$configuration 
	$env:_CL_ = " $arch $runtime "
	$ErrorActionPreference = "Continue"
	cmake ../../host/ `
		-G "Visual Studio 14 2015 Win64" `
		-DCMAKE_PREFIX_PATH="$root\build\$configuration" `
		-DLIBUSB_INCLUDE_DIR="$root/build/$configuration/include/" `
		-DLIBUSB_LIBRARIES="$root/build/$configuration/lib/libusb-1.0.lib" `
		-DTHREADS_PTHREADS_INCLUDE_DIR="$root/build/$configuration/include" `
		-DTHREADS_PTHREADS_WIN32_LIBRARY="$root/build/$configuration/lib/pthreadVC2.lib" `
		-DCMAKE_C_FLAGS="/D_TIMESPEC_DEFINED $arch /DWIN32 /D_WINDOWS /W3 /DPTW32_STATIC_LIB " `
		-DFFTW_LIBRARIES="$root/build/$configuration/lib/libfftw3f.lib" `
		-DCMAKE_INSTALL_PREFIX="$root/src-stage3/staged_install/$configuration" *>> $Log
	Write-Host -NoNewline "building..."
	msbuild .\hackrf_all.sln /m /p:"configuration=$buildconfig;platform=x64" *>> $Log
	Write-Host -NoNewline "installing..."
	msbuild .\INSTALL.vcxproj /m /p:"configuration=$buildconfig;platform=x64;BuildProjectReferences=false" *>> $Log
	# this installs hackrf libs to the bin dir, we want to move them
	Copy-Item -Force -Path "$root/src-stage3/staged_install/$configuration/bin/hackrf.lib" "$root/src-stage3/staged_install/$configuration/lib"
	Copy-Item -Force -Path "$root/src-stage3/staged_install/$configuration/bin/hackrf_static.lib" "$root/src-stage3/staged_install/$configuration/lib"
	$ErrorActionPreference = "Stop"
	Validate "$root\src-stage3\oot_code\hackrf\build\$configuration\libhackrf\src\$buildconfig\hackrf.dll"
	CheckNoAVX "$root\src-stage3\oot_code\hackrf\build\$configuration\libhackrf\src\$buildconfig"

	# ____________________________________________________________________________________________________________
	#
	# osmo-sdr
	#
	# links to libusb dynamically and pthreads statically
	#
	SetLog "osmo-sdr $configuration"
	Write-Host -NoNewline "configuring $configuration osmo-sdr..."
	New-Item -ItemType Directory -Force -Path $root/src-stage3/oot_code/osmo-sdr/build/$configuration  *>> $Log
	cd $root/src-stage3/oot_code/osmo-sdr/build/$configuration 
	$env:_CL_ = " $arch $runtime "
	cmake ../../software/libosmosdr/ `
		-G "Visual Studio 14 2015 Win64" `
		-DCMAKE_PREFIX_PATH="$root\build\$configuration" `
		-DLIBUSB_INCLUDE_DIR="$root/build/$configuration/include/" `
		-DLIBUSB_LIBRARIES="$root/build/$configuration/lib/libusb-1.0.lib" `
		-DCMAKE_C_FLAGS="/D_TIMESPEC_DEFINED $arch /DWIN32 /D_WINDOWS /W3 /DPTW32_STATIC_LIB " `
		-DCMAKE_INSTALL_PREFIX="$root/src-stage3/staged_install/$configuration" *>> $Log
	Write-Host -NoNewline "building osmo-sdr..."
	msbuild .\osmosdr.sln /m /p:"configuration=$buildconfig;platform=x64" *>> $Log
	Write-Host -NoNewline "installing..."
	msbuild .\INSTALL.vcxproj /m /p:"configuration=$buildconfig;platform=x64;BuildProjectReferences=false" *>> $Log
	Validate "$root\src-stage3\oot_code\osmo-sdr\build\$configuration\src\$buildconfig\osmosdr.dll"
	CheckNoAVX "$root\src-stage3\oot_code\osmo-sdr\build\$configuration\src\$buildconfig"
	
	# ____________________________________________________________________________________________________________
	#
	# UHD
	#
	# This was previously built, but now we want to install it properly over top of the GNURadio install
	# and also retrieve the UHD firmware images as the utility script has now been installed
	#
	# TODO download firmware once and copy into each location instead of downloading separately for each configuration
	#
	SetLog "UHD $configuration configuration"
	Write-Host -NoNewline "configuring $configuration UHD..."
	robocopy "$root/build/$configuration/uhd" "$root/src-stage3/staged_install/$configuration" /e *>> $log 
	New-Item -ItemType Directory $root/src-stage3/staged_install/$configuration/share/uhd/images -Force *>> $log 
	"complete"
	Write-Host -NoNewline "downloading $configuration UHD firmware images..."
	$ErrorActionPreference = "Continue"
	& $pythonroot/$pythonexe $root/src-stage3/staged_install/$configuration/lib/uhd/utils/uhd_images_downloader.py -v -i "$root/src-stage3/staged_install/$configuration/share/uhd/images" *>> $log 
	"complete"
	$ErrorActionPreference = "Stop"
	
	# ____________________________________________________________________________________________________________
	#
	# gr-iqbal
	#
	# this doesn't add gnuradio-pmt.lib as a linker input, so we hack it manually
	# TODO submit issue to source (add gnuradio-pmt.lib as a linker input to gr-iqbal)
	# Also the upstream sources uses C99 complex constructs that MSVC doesn't support
	# so we're using a custom version of the source.
	#
	if ($mm -eq "3.8") {
		Write-Host "gr-iqbal not gr3.8 compatible"
	} else {
		SetLog "gr-iqbal $configuration"
		$ErrorActionPreference = "Continue"
		Write-Host -NoNewline "configuring $configuration gr-iqbal..."
		New-Item -ItemType Directory -Force -Path $root/src-stage3/oot_code/gr-iqbal/build/$configuration  *>> $Log
		cd $root/src-stage3/oot_code/gr-iqbal/build/$configuration 
		$env:_CL_ = " $arch $runtime "
		$env:_LINK_= " $root/src-stage3/staged_install/$configuration/lib/gnuradio-pmt.lib /DEBUG "
		if ($mm -eq '3.8') {$env:_LINK_= $env:_LINK_ + " $root/build/$configuration/lib/log4cpp.lib "}
		if (Test-Path CMakeCache.txt) {Remove-Item -Force CMakeCache.txt} # Don't keep the old cache because if the user is fixing a config problem it may not re-check the fix
		cmake ../../ `
			-G "Visual Studio 14 2015 Win64" `
			-DCMAKE_PREFIX_PATH="$root\build\$configuration" `
			-DCMAKE_C_FLAGS="/D_TIMESPEC_DEFINED $arch $runtime /EHsc /DWIN32 /DNOMINMAX /D_WINDOWS /W3 /DENABLE_GR_LOG=ON " `
			-DCMAKE_CXX_FLAGS="/D_TIMESPEC_DEFINED $arch $runtime /EHsc /DWIN32 /DNOMINMAX /D_WINDOWS /W3 /DENABLE_GR_LOG=ON " `
			-DPYTHON_LIBRARY="$root/src-stage3/staged_install/$configuration/gr-python27/libs/python27$debug_ext.lib" `
			-DPYTHON_LIBRARY_DEBUG="$root/src-stage3/staged_install/$configuration/gr-python27/libs/python27_d.lib" `
			-DPYTHON_EXECUTABLE="$root/src-stage3/staged_install/$configuration/gr-python27/$pythonexe" `
			-DPYTHON_INCLUDE_DIR="$root/src-stage3/staged_install/$configuration/gr-python27/include" `
			-DBOOST_LIBRARYDIR=" $root/build/$configuration/lib/" `
			-DBOOST_INCLUDEDIR="$root/build/$configuration/include" `
			-DBOOST_ROOT="$root/build/$configuration/" `
			-DCMAKE_INSTALL_PREFIX="$root/src-stage3/staged_install/$configuration" `
			-DFFTW3F_LIBRARIES="$root/build/Release/lib/libfftw3f.lib" `
			-DFFTW3F_INCLUDE_DIRS="$root/build/Release/include/" `
			-DLINK_LIBRARIES="gnuradio-pmt.lib"  `
			-DSWIG_EXECUTABLE="$root/bin/swig.exe" `
			-Wno-dev *>> $Log
		Write-Host -NoNewline "building..."
		msbuild .\gr-iqbalance.sln /m /p:"configuration=$buildconfig;platform=x64" *>> $Log
		Write-Host -NoNewline "installing..."
		msbuild .\INSTALL.vcxproj /m /p:"configuration=$buildconfig;platform=x64;BuildProjectReferences=false" *>> $Log
		Validate "$root\src-stage3\oot_code\gr-iqbal\build\$configuration\lib\$buildconfig\gnuradio-iqbalance.dll" "$root\src-stage3\staged_install\$configuration\lib\site-packages\gnuradio\iqbalance\_iqbalance_swig.pyd"
		CheckNoAVX "$root\src-stage3\oot_code\gr-iqbal\build\$configuration\lib\$buildconfig"
		$env:_LINK_ = ""
		$ErrorActionPreference = "Stop"
	}

	# ____________________________________________________________________________________________________________
	#
	# gr-osmosdr
	# 
	# Note this must be built at the end, after all the other libraries are ready
	#
	# /EHsc is important or else you get boost::throw_exception linker errors
	# ENABLE_RFSPACE=False is because the latest gr-osmosdr has linux-only support for that SDR
	# /DNOMINMAX prevents errors related to std::min definition
	# 
	SetLog "gr-osmosdr $configuration"
	Write-Host -NoNewline "configuring $configuration gr-osmosdr..."
	New-Item -Force -ItemType Directory $root/src-stage3/oot_code/gr-osmosdr/build/$configuration *>> $Log
	cd $root/src-stage3/oot_code/gr-osmosdr/build/$configuration
	$ErrorActionPreference = "Continue"
	$env:LIB = "$root/build/$configuration/lib;" + $oldlib
	$env:_CL_ = " $arch $runtime "
	$env:_LINK_= " $root/src-stage3/staged_install/$configuration/lib/gnuradio-pmt.lib  /DEBUG "
	if ($mm -eq '3.8') {$env:_LINK_= $env:_LINK_ + " $root/build/$configuration/lib/log4cpp.lib "}
	if ($configuration -match "AVX") {$SIMD="-DUSE_SIMD=""AVX"""} else {$SIMD=""}
	& cmake ../../ `
		-G "Visual Studio 14 2015 Win64" `
		-DCMAKE_PREFIX_PATH="$root\build\$configuration" `
		-DCMAKE_INCLUDE_PATH="$root/build/$configuration/include" `
		-DCMAKE_LIBRARY_PATH="$root/build/$configuration/lib" `
		-DCMAKE_INSTALL_PREFIX="$root/src-stage3/staged_install/$configuration" `
		-DBOOST_LIBRARYDIR="$root/build/$configuration/lib" `
		-DBOOST_INCLUDEDIR="$root/build/$configuration/include" `
		-DBOOST_ROOT="$root/build/$configuration/" `
		-DPYTHON_LIBRARY="$root/src-stage3/staged_install/$configuration/gr-python27/libs/python27.lib" `
		-DPYTHON_LIBRARY_DEBUG="$root/src-stage3/staged_install/$configuration/gr-python27/libs/python27_d.lib" `
		-DPYTHON_EXECUTABLE="$root/src-stage3/staged_install/$configuration/gr-python27/$pythonexe" `
		-DPYTHON_INCLUDE_DIR="$root/src-stage3/staged_install/$configuration/gr-python27/include" `
		-DLIBAIRSPY_INCLUDE_DIRS="..\libairspy\src" `
		-DLIBAIRSPY_LIBRARIES="$root\src-stage3\staged_install\$configuration\lib\airspy.lib" `
		-DLIBBLADERF_INCLUDE_DIRS="$root\src-stage3\staged_install\$configuration\include\"  `
		-DLIBBLADERF_LIBRARIES="$root\src-stage3\staged_install\$configuration\lib\bladeRF.lib" `
		-DLIBHACKRF_INCLUDE_DIRS="$root\src-stage3\staged_install\$configuration\include\"  `
		-DLIBHACKRF_LIBRARIES="$root\src-stage3\staged_install\$configuration\lib\hackrf.lib" `
		-DLIBRTLSDR_INCLUDE_DIRS="$root\src-stage3\staged_install\$configuration\include\"  `
		-DLIBRTLSDR_LIBRARIES="$root\src-stage3\staged_install\$configuration\lib\rtlsdr.lib" `
		-DLIBOSMOSDR_INCLUDE_DIRS="$root\src-stage3\staged_install\$configuration\include\"  `
		-DLIBOSMOSDR_LIBRARIES="$root\src-stage3\staged_install\$configuration\lib\osmosdr.lib" `
		-DVOLK_LIBRARIES="$root\src-stage3\staged_install\$configuration\lib\volk.lib" `
		-DVOLK_INCLUDE_DIRS="$root\src-stage3\staged_install\$configuration\include\"  `
		-DCMAKE_CXX_FLAGS="/DNOMINMAX /D_TIMESPEC_DEFINED $arch /DWIN32 /D_WINDOWS /W3 /DPTW32_STATIC_LIB /I$root/build/$configuration/include /EHsc " `
		-DCMAKE_C_FLAGS="/DNOMINMAX /D_TIMESPEC_DEFINED $arch  /DWIN32 /D_WINDOWS /W3 /DPTW32_STATIC_LIB /EHsc " `
		-DSWIG_EXECUTABLE="$root/bin/swig.exe" `
		$SIMD `
		-DENABLE_DOXYGEN="TRUE" `
		-DENABLE_RFSPACE="FALSE" *>> $Log  # RFSPACE not building in current git pull (0.1.5git 164a09fc 3/13/2016), due to having linux-only headers being added
	
	Write-Host -NoNewline "building..."
	msbuild .\gr-osmosdr.sln /m /p:"configuration=$buildconfig;platform=x64" *>> $Log
	Write-Host -NoNewline "installing..."
	msbuild .\INSTALL.vcxproj /m /p:"configuration=$buildconfig;platform=x64;BuildProjectReferences=false" *>> $Log
	# osmocom_fft.py tries to set up a file sink to /dev/null, so we need to replace that with nul
	(Get-Content $root\src-stage3\staged_install\$configuration\bin\osmocom_fft.py).replace('/dev/null', 'nul') | Set-Content $root\src-stage3\staged_install\$configuration\bin\osmocom_fft.py
	Validate "$root\src-stage3\oot_code\gr-osmosdr\build\$configuration\lib\$buildconfig\gnuradio-osmosdr.dll"
	CheckNoAVX "$root\src-stage3\oot_code\gr-osmosdr\build\$configuration\lib\$buildconfig"
	$env:_LINK_ = ""
}

function BuildOOTModules 
{
	$configuration = $args[0]
	$buildsymbols=$true
	$pythonroot = "$root/src-stage3/staged_install/$configuration/gr-python27"
	if ($configuration -match "Release") {
		$buildconfig="Release";$pythonexe = "python.exe";  $debugext = "";  $debug_ext = "";  $runtime = "/MD"
	} 
	else {
		$buildconfig="Debug";  $pythonexe = "python_d.exe";$debugext = "d"; $debug_ext = "_d";$runtime = "/MDd"
	}
	if ($buildsymbols -and $buildconfig -eq "Release") {$buildconfig="RelWithDebInfo"}
	if ($configuration -match "AVX2") {$arch="/arch:AVX2"} else {$arch=""}

	# ____________________________________________________________________________________________________________
	#
	# gr-soapy
	#
	#
	SetLog "gr-soapy $configuration"
	$ErrorActionPreference = "Continue"
	Write-Host -NoNewline "configuring $configuration gr-soapy..."
	New-Item -ItemType Directory -Force -Path $root/src-stage3/oot_code/gr-soapy/build/$configuration  *>> $Log
	Copy-Item -Force $root\src-stage3\staged_install\$configuration\include\gnuradio\swig\gnuradio.i $root/bin/Lib
	cd $root/src-stage3/oot_code/gr-soapy/build/$configuration 
	$linkflags = " /DEFAULTLIB:$root/src-stage3/staged_install/$configuration/lib/gnuradio-pmt.lib /DEBUG /NODEFAULTLIB:m.lib "
	$env:_LINK_= ""
	$env:_CL_ = ""
	$env:Path="" 
	cmake ../../ `
		-G "Visual Studio 14 2015 Win64" `
		-DCMAKE_PREFIX_PATH="$root\build\$configuration" `
		-DCMAKE_C_FLAGS=" /DBOOST_ALL_DYN_LINK /DUSING_GLEW /EHsc /D_USE_MATH_DEFINES /DNOMINMAX /D_TIMESPEC_DEFINED $arch $runtime  /DWIN32 /D_WINDOWS /W3 /I""$root/src-stage3/staged_install/$configuration"" /I""$root/src-stage3/staged_install/$configuration/include""  /I""$root/src-stage3/staged_install/$configuration/include/swig"" " `
		-DCMAKE_CXX_FLAGS=" /DBOOST_ALL_DYN_LINK /DUSING_GLEW /EHsc /D_USE_MATH_DEFINES /DNOMINMAX /D_TIMESPEC_DEFINED $arch $runtime  /DWIN32 /D_WINDOWS /W3 /I""$root/src-stage3/staged_install/$configuration"" /I""$root/src-stage3/staged_install/$configuration/include""  /I""$root/src-stage3/staged_install/$configuration/include/swig"" " `
		-DPYTHON_LIBRARY="$root/src-stage3/staged_install/$configuration/gr-python27/libs/python27.lib" `
		-DPYTHON_LIBRARY_DEBUG="$root/src-stage3/staged_install/$configuration/gr-python27/libs/python27_d.lib" `
		-DPYTHON_EXECUTABLE="$root/src-stage3/staged_install/$configuration/gr-python27/$pythonexe" `
		-DPYTHON_INCLUDE_DIR="$root/src-stage3/staged_install/$configuration/gr-python27/include" `
		-DBOOST_LIBRARYDIR=" $root/build/$configuration/lib" `
		-DBOOST_INCLUDEDIR="$root/build/$configuration/include" `
		-DBOOST_ROOT="$root/build/$configuration/" `
		-DCMAKE_INSTALL_PREFIX="$root/src-stage3/staged_install/$configuration" `
		-DSWIG_EXECUTABLE="$root/bin/swig.exe" `
		-DCMAKE_SHARED_LINKER_FLAGS=" $linkflags " `
		-DCMAKE_EXE_LINKER_FLAGS=" $linkflags " `
		-DCMAKE_STATIC_LINKER_FLAGS=" $linkflags " `
		-DCMAKE_MODULE_LINKER_FLAGS=" $linkflags  " `
		-Wno-dev *>> $Log
	$env:Path = $oldPath
	Write-Host -NoNewline "building gr-soapy..."
	msbuild .\gr-soapy.sln /m /p:"configuration=$buildconfig;platform=x64" *>> $Log
	Write-Host -NoNewline "installing..."
	msbuild .\INSTALL.vcxproj /m /p:"configuration=$buildconfig;platform=x64;BuildProjectReferences=false" *>> $Log
	$env:_CL_ = ""
	$env:_LINK_ = ""
	$ErrorActionPreference = "Stop"
	Validate "$root/src-stage3/staged_install/$configuration/bin/gnuradio-soapy.dll" 
	
	# ____________________________________________________________________________________________________________
	#
	# gr-acars2
	#
	# We can make up for most of the windows incompatibilities, but the inclusion of the "m" lib requires a CMake file change
	# so need to use a patch
	# TODO update CMake to include m only with not win32
	# fails on debug as the include/swig directory is not created during the Debug build
	#
	if ($mm -eq "3.8") {
		Write-Host "gr-acars2 not gr3.8 compatible"
	} else {
		SetLog "gr-acars2 $configuration"
		$ErrorActionPreference = "Continue"
		Write-Host -NoNewline "configuring $configuration gr-acars2..."
		New-Item -ItemType Directory -Force -Path $root/src-stage3/oot_code/gr-acars2/build/$configuration  *>> $Log
		Copy-Item -Force $root\src-stage3\staged_install\$configuration\include\gnuradio\swig\gnuradio.i $root/bin/Lib
		cd $root/src-stage3/oot_code/gr-acars2/build/$configuration 
		$linkflags = " /DEFAULTLIB:$root/src-stage3/staged_install/$configuration/lib/gnuradio-pmt.lib /DEBUG /NODEFAULTLIB:m.lib "
		if ($mm -eq '3.8') {$linkflags = $linkflags  + " /DEFAULTLIB:$root/build/$configuration/lib/log4cpp.lib "}
		$env:_LINK_= ""
		$env:_CL_ = ""
		$env:Path="" 
		cmake ../../ `
			-G "Visual Studio 14 2015 Win64" `
			-DCMAKE_PREFIX_PATH="$root\build\$configuration" `
			-DGNURADIO_RUNTIME_LIBRARIES="$root/src-stage3/staged_install/$configuration/lib/gnuradio-runtime.lib" `
			-DGNURADIO_RUNTIME_INCLUDE_DIRS="$root/src-stage3/staged_install/$configuration/include" `
			-DCPPUNIT_LIBRARIES="$root/build/$configuration/lib/cppunit.lib" `
			-DCMAKE_C_FLAGS=" /DUSING_GLEW /EHsc /D_USE_MATH_DEFINES /DNOMINMAX /D_TIMESPEC_DEFINED $arch $runtime  /DWIN32 /D_WINDOWS /W3 /I""$root/src-stage3/staged_install/$configuration"" /I""$root/src-stage3/staged_install/$configuration/include""  /I""$root/src-stage3/staged_install/$configuration/include/swig"" " `
			-DCMAKE_CXX_FLAGS=" /DUSING_GLEW /EHsc /D_USE_MATH_DEFINES /DNOMINMAX /D_TIMESPEC_DEFINED $arch $runtime  /DWIN32 /D_WINDOWS /W3 /I""$root/src-stage3/staged_install/$configuration"" /I""$root/src-stage3/staged_install/$configuration/include""  /I""$root/src-stage3/staged_install/$configuration/include/swig"" " `
			-DPYTHON_LIBRARY="$root/src-stage3/staged_install/$configuration/gr-python27/libs/python27.lib" `
			-DPYTHON_LIBRARY_DEBUG="$root/src-stage3/staged_install/$configuration/gr-python27/libs/python27_d.lib" `
			-DPYTHON_EXECUTABLE="$root/src-stage3/staged_install/$configuration/gr-python27/$pythonexe" `
			-DPYTHON_INCLUDE_DIR="$root/src-stage3/staged_install/$configuration/gr-python27/include" `
			-DBOOST_LIBRARYDIR=" $root/build/$configuration/lib" `
			-DBOOST_INCLUDEDIR="$root/build/$configuration/include" `
			-DBOOST_ROOT="$root/build/$configuration/" `
			-DCMAKE_INSTALL_PREFIX="$root/src-stage3/staged_install/$configuration" `
			-DSWIG_EXECUTABLE="$root/bin/swig.exe" `
			-DCMAKE_SHARED_LINKER_FLAGS=" $linkflags " `
			-DCMAKE_EXE_LINKER_FLAGS=" $linkflags " `
			-DCMAKE_STATIC_LINKER_FLAGS=" $linkflags " `
			-DCMAKE_MODULE_LINKER_FLAGS=" $linkflags  " `
			-Wno-dev *>> $Log
		$env:Path = $oldPath
		Write-Host -NoNewline "building gr-acars2..."
		msbuild .\gr-acars2.sln /m /p:"configuration=$buildconfig;platform=x64" *>> $Log
		Write-Host -NoNewline "installing..."
		msbuild .\INSTALL.vcxproj /m /p:"configuration=$buildconfig;platform=x64;BuildProjectReferences=false" *>> $Log
		# the cmake files don't install the samples or examples or docs so let's see what we can do here
		# TODO update the CMAKE file to move these over
		New-Item -ItemType Directory -Force $root/src-stage3/staged_install/$configuration/share/acars2/examples *>> $Log
		Copy-Item $root/src-stage3/oot_code/gr-acars2/examples/simple.grc $root/src-stage3/staged_install/$configuration/share/acars2/examples
		Copy-Item $root/src-stage3/oot_code/gr-acars2/samples/*.grc $root/src-stage3/staged_install/$configuration/share/acars2/examples
		Copy-Item $root/src-stage3/oot_code/gr-acars2/samples/*.wav $root/src-stage3/staged_install/$configuration/share/acars2/examples
		Copy-Item $root/src-stage3/oot_code/gr-acars2/samples/*.py $root/src-stage3/staged_install/$configuration/share/acars2/examples
		$env:_CL_ = ""
		$env:_LINK_ = ""
		$ErrorActionPreference = "Stop"
		Validate "$root/src-stage3/staged_install/$configuration/bin/gnuradio-acars2.dll" "$root/src-stage3/staged_install/$configuration/lib/site-packages/acars2/_acars2_swig.pyd"
	}

	# ____________________________________________________________________________________________________________
	#
	# gr-adsb
	#
	#
	SetLog "gr-adsb $configuration"
	$ErrorActionPreference = "Continue"
	Write-Host -NoNewline "configuring $configuration gr-adsb..."
	New-Item -ItemType Directory -Force -Path $root/src-stage3/oot_code/gr-adsb/build/$configuration  *>> $Log
	cd $root/src-stage3/oot_code/gr-adsb/build/$configuration 
	$env:_CL_ = " $arch $runtime "
	$env:_LINK_= "  $root/src-stage3/staged_install/$configuration/lib/gnuradio-pmt.lib /DEBUG /NODEFAULTLIB:m.lib "
	$env:_CL_ = $env:_CL_  + "  -D_USE_MATH_DEFINES -I""$root/src-stage3/staged_install/$configuration/include""  -I""$root/src-stage3/staged_install/$configuration/include/swig"" "
	$env:Path="" 
	cmake ../../ `
		-G "Visual Studio 14 2015 Win64" `
		-DCMAKE_PREFIX_PATH="$root\build\$configuration" `
		-DGNURADIO_RUNTIME_LIBRARIES="$root/src-stage3/staged_install/$configuration/lib/gnuradio-runtime.lib" `
		-DGNURADIO_RUNTIME_INCLUDE_DIRS="$root/src-stage3/staged_install/$configuration/include" `
		-DCMAKE_C_FLAGS="/D_USE_MATH_DEFINES /D_TIMESPEC_DEFINED $arch $runtime  /DWIN32 /D_WINDOWS /W3 /I""$root/src-stage3/staged_install/$configuration"" " `
		-DPYTHON_EXECUTABLE="$root/src-stage3/staged_install/$configuration/gr-python27/$pythonexe" `
		-DCMAKE_INSTALL_PREFIX="$root/src-stage3/staged_install/$configuration" `
		-Wno-dev *>> $Log
	$env:Path = $oldPath
	Write-Host -NoNewline "building gr-adsb..."
	msbuild .\gr-adsb.sln /m /p:"configuration=$buildconfig;platform=x64" *>> $Log
	Write-Host -NoNewline "installing..."
	msbuild .\INSTALL.vcxproj /m /p:"configuration=$buildconfig;platform=x64;BuildProjectReferences=false" *>> $Log
	# the cmake files don't install the samples or examples or docs so let's see what we can do here
	# TODO update the CMAKE file to move these over
	New-Item -ItemType Directory -Force $root/src-stage3/staged_install/$configuration/share/adsb/examples *>> $Log
	Copy-Item $root/src-stage3/oot_code/gr-adsb/examples/*.* $root/src-stage3/staged_install/$configuration/share/adsb/examples
	$env:_CL_ = ""
	$env:_LINK_ = ""
	$ErrorActionPreference = "Stop"
	Validate "$root/src-stage3/staged_install/$configuration/Lib/site-packages/adsb/decoder.py"

	# ____________________________________________________________________________________________________________
	#
	# gr-air-modes
	#
	# The modes_gui application will not work because Qt4 is currently built without webkit.  However, the command line portion will work just fine.
	#
	SetLog "gr-air-modes $configuration"
	$ErrorActionPreference = "Continue"
	Write-Host -NoNewline "configuring $configuration gr-air-modes..."
	New-Item -ItemType Directory -Force -Path $root/src-stage3/oot_code/gr-air-modes/build/$configuration  *>> $Log
	cd $root/src-stage3/oot_code/gr-air-modes/build/$configuration 
	$linkflags = " /DEFAULTLIB:$root/src-stage3/staged_install/$configuration/lib/gnuradio-pmt.lib /DEBUG /NODEFAULTLIB:m.lib "
	if ($mm -eq '3.8') {$linkflags = $linkflags  + " /DEFAULTLIB:$root/build/$configuration/lib/log4cpp.lib "}
	$env:_CL_ = ""
	$env:Path= "$root/build/$configuration/lib;" + $oldPath
	$env:PYTHONPATH="$pythonroot/Lib/site-packages"
	cmake ../../ `
		-G "Visual Studio 14 2015 Win64" `
		-DCMAKE_PREFIX_PATH="$root\build\$configuration" `
		-DCMAKE_INSTALL_PREFIX="$root/src-stage3/staged_install/$configuration" `
		-DGNURADIO_RUNTIME_LIBRARIES="$root/src-stage3/staged_install/$configuration/lib/gnuradio-runtime.lib" `
		-DGNURADIO_RUNTIME_INCLUDE_DIRS="$root/src-stage3/staged_install/$configuration/include" `
		-DCMAKE_C_FLAGS="/D_USE_MATH_DEFINES /DNOMINMAX /EHsc /D_TIMESPEC_DEFINED $arch $runtime  /DWIN32 /D_WINDOWS /W3 /I""$root/src-stage3/staged_install/$configuration"" /I""$root/src-stage3/staged_install/$configuration/include""  /I""$root/src-stage3/staged_install/$configuration/include/swig"" " `
		-DCMAKE_CXX_FLAGS="/D_USE_MATH_DEFINES /DNOMINMAX /EHsc /D_TIMESPEC_DEFINED $arch $runtime  /DWIN32 /D_WINDOWS /W3 /I""$root/src-stage3/staged_install/$configuration"" /I""$root/src-stage3/staged_install/$configuration/include""  /I""$root/src-stage3/staged_install/$configuration/include/swig"" " `
		-DPYTHON_LIBRARY="$root/src-stage3/staged_install/$configuration/gr-python27/libs/python27.lib" `
		-DPYTHON_LIBRARY_DEBUG="$root/src-stage3/staged_install/$configuration/gr-python27/libs/python27_d.lib" `
		-DPYTHON_EXECUTABLE="$root/src-stage3/staged_install/$configuration/gr-python27/$pythonexe" `
		-DPYTHON_INCLUDE_DIR="$root/src-stage3/staged_install/$configuration/gr-python27/include" `-DCMAKE_INSTALL_PREFIX="$root/src-stage3/staged_install/$configuration" `
		-DBOOST_LIBRARYDIR=" $root/build/$configuration/lib" `
		-DBOOST_INCLUDEDIR="$root/build/$configuration/include" `
		-DBOOST_ROOT="$root/build/$configuration/" `
		-DPYUIC4_EXECUTABLE="$root/src-stage3/staged_install/$configuration/gr-python27/pyuic4.bat" `
		-DSWIG_EXECUTABLE="$root/bin/swig.exe" `
		-DCMAKE_SHARED_LINKER_FLAGS=" $linkflags " `
		-DCMAKE_EXE_LINKER_FLAGS=" $linkflags " `
		-DCMAKE_STATIC_LINKER_FLAGS=" $linkflags " `
		-DCMAKE_MODULE_LINKER_FLAGS=" $linkflags  " `
		-Wno-dev *>> $Log
	Write-Host -NoNewline "building gr-air-modes..."
	msbuild .\gr-gr-air-modes.sln /m /p:"configuration=$buildconfig;platform=x64" *>> $Log
	Write-Host -NoNewline "installing..."
	msbuild .\INSTALL.vcxproj /m /p:"configuration=$buildconfig;platform=x64;BuildProjectReferences=false" *>> $Log
	$env:Path = $oldPath
	$env:PYTHONPATH=""
	$env:_CL_ = ""
	$env:_LINK_ = ""
	$ErrorActionPreference = "Stop"
	Validate "$root/src-stage3/oot_code/gr-air-modes/build/$configuration/lib/$buildconfig/air_modes.dll" "$root\src-stage3\staged_install\$configuration\lib\site-packages\air_modes\_air_modes_swig.pyd"

	# ____________________________________________________________________________________________________________
	#
	# glfw
	#
	# required by gr-fosphor
	#
	SetLog "glfw $configuration"
	Write-Host -NoNewline "configuring $configuration glfw..."
	New-Item -Force -ItemType Directory $root/src-stage3/oot_code/glfw/build/$configuration *>> $Log
	cd $root/src-stage3/oot_code/glfw/build/$configuration
	$env:_CL_ = " $arch $runtime "
	$ErrorActionPreference = "Continue"
	& cmake ../../ `
		-G "Visual Studio 14 2015 Win64" `
		-DBUILD_SHARED_LIBS="true"  *>> $Log
	Write-Host -NoNewline "building for shared..."
	msbuild .\glfw.sln /m /p:"configuration=$buildconfig;platform=x64" *>> $Log
	& cmake ../../ `
		-G "Visual Studio 14 2015 Win64" `
		-DBUILD_SHARED_LIBS="false"  *>> $Log
	Write-Host -NoNewline "building for static..."
	msbuild .\glfw.sln /m /p:"configuration=$buildconfig;platform=x64" *>> $Log
	$env:_CL_ = ""
	$ErrorActionPreference = "Stop"
	Validate "$root\src-stage3\oot_code\glfw\build\$configuration\src\$buildconfig\glfw3.dll"
	 

	# ____________________________________________________________________________________________________________
	#
	# gr-fosphor
	#
	# needed to macro out __attribute__, include gnuradio-pmt, and include glew64.lib and a glewInit() call
	# 
	SetLog "gr-fosphor $configuration"
	if ($env:AMDAPPSDKROOT) {
		if ($mm -eq "3.8") {
			"gr-fosphor with 3.8 requires python >= 3, skipping"		
		} else {
			$ErrorActionPreference = "Continue"
			Write-Host -NoNewline "configuring $configuration gr-fosphor..."
			New-Item -ItemType Directory -Force -Path $root/src-stage3/oot_code/gr-fosphor/build/$configuration  *>> $Log
			cd $root/src-stage3/oot_code/gr-fosphor/build/$configuration 
			if ($configuration -match "AVX2") {
				$DLLconfig="ReleaseDLL-AVX2"
			} else {
				$DLLconfig = $configuration + "DLL"
			}
			$env:_CL_ = ""
			$env:_LINK_= " /DEBUG /OPT:ref,icf "
			if ($mm -eq '3.8') {$env:_LINK_= $env:_LINK_ + " $root/build/$configuration/lib/log4cpp.lib "}
			$env:Path = $env:AMDAPPSDKROOT + ";" + $oldPath 
			cmake ../../ `
				-G "Visual Studio 14 2015 Win64" `
				-DCMAKE_PREFIX_PATH="$root\build\$configuration" `
				-DCMAKE_INSTALL_PREFIX="$root/src-stage3/staged_install/$configuration" `
				-DBOOST_LIBRARYDIR=" $root/build/$configuration/lib" `
				-DBOOST_INCLUDEDIR="$root/build/$configuration/include" `
				-DBOOST_ROOT="$root/build/$configuration/" `
				-DOpenCL_LIBRARY="$env:AMDAPPSDKROOT/lib/x86_64/OpenCL.lib" `
				-DOpenCL_INCLUDE_DIR="$env:AMDAPPSDKROOT/include" `
				-DFREETYPE2_PKG_INCLUDE_DIRS="$root/build/$configuration/include" `
				-DFREETYPE2_PKG_LIBRARY_DIRS="$root/build/$configuration/lib" `
				-DCMAKE_C_FLAGS="/D_TIMESPEC_DEFINED $arch $runtime /DNOMINMAX /DWIN32 /D_WINDOWS /W3 /Zi /EHsc " `
				-DCMAKE_CXX_FLAGS="/D_TIMESPEC_DEFINED $arch $runtime /DNOMINMAX  /DWIN32 /D_WINDOWS /W3 /Zi /EHsc" `
				-DPYTHON_LIBRARY="$root/src-stage3/staged_install/$configuration/gr-python27/libs/python27.lib" `
				-DPYTHON_LIBRARY_DEBUG="$root/src-stage3/staged_install/$configuration/gr-python27/libs/python27_d.lib" `
				-DPYTHON_EXECUTABLE="$root/src-stage3/staged_install/$configuration/gr-python27/$pythonexe" `
				-DPYTHON_INCLUDE_DIR="$root/src-stage3/staged_install/$configuration/gr-python27/include" `
				-DQT_QMAKE_EXECUTABLE="$root/build/$configuration/bin/qmake.exe" `
				-DQT_UIC_EXECUTABLE="$root/build/$configuration/bin/uic.exe" `
				-DQT_MOC_EXECUTABLE="$root/build/$configuration/bin/moc.exe" `
				-DQT_RCC_EXECUTABLE="$root/build/$configuration/bin/rcc.exe" `
				-DGLFW3_PKG_INCLUDE_DIRS="$root\src-stage3\oot_code\glfw\include\" `
				-DGLFW3_PKG_LIBRARY_DIRS="$root\src-stage3\oot_code\glfw\build\$configuration\src\$buildconfig" `
				-DSWIG_EXECUTABLE="$root/bin/swig.exe" `
				-Wno-dev *>> $Log
			Write-Host -NoNewline "building gr-fosphor..."
			msbuild .\gr-fosphor.sln /m /p:"configuration=$buildconfig;platform=x64" *>> $Log
			Write-Host -NoNewline "installing..."
			msbuild .\INSTALL.vcxproj /m /p:"configuration=$buildconfig;platform=x64;BuildProjectReferences=false" *>> $Log
			cp $env:AMDAPPSDKROOT/bin/x86_64/glew64.dll $root/src-stage3/staged_install/$configuration/bin
			$env:_LINK_ = ""
			$env:_CL_ = ""
			$env:Path = $oldPath 
			$ErrorActionPreference = "Stop"
			Validate "$root/src-stage3/staged_install/$configuration/bin/gnuradio-fosphor.dll" "$root\src-stage3\staged_install\$configuration\lib\site-packages\gnuradio\fosphor\_fosphor_swig.pyd"
		}
	} else {
		"Unable to build gr-fosphor, AMD APP SDK not found, skipping"
	}
	

	# ____________________________________________________________________________________________________________
	#
	# gqrx
	#
	# Requires Qt5,
	# TODO Doesn't currently seem to support UHD devices, even though the same gr-osmosdr block in GRC with the same device string will work.
	#
	SetLog "gqrx $configuration"
	Write-Host -NoNewline "configuring $configuration gqrx..."
	$env:_CL_ = ""
	if ($mm -eq "3.8") {	
		New-Item -Force -ItemType Directory $root/src-stage3/oot_code/gqrx/build/$configuration *>> $Log
		cd $root/src-stage3/oot_code/gqrx/build/$configuration
		$ErrorActionPreference = "Continue"
		$env:_LINK_= " /DEBUG  /DEFAULTLIB:$root/build/$configuration/lib/log4cpp.lib /DEFAULTLIB:$root/src-stage3/staged_install/$configuration/lib/volk.lib "
		& cmake ../../ `
			-G "Visual Studio 14 2015 Win64" `
			-DCMAKE_PREFIX_PATH="$root\build\$configuration;$root/src-stage3/staged_install/$configuration" `
			-DCMAKE_INSTALL_PREFIX="$root/src-stage3/staged_install/$configuration" `
			-DBOOST_LIBRARYDIR="$root\build\$configuration\lib" `
			-DCMAKE_C_FLAGS=" $arch $runtime  /EHsc /DENABLE_GR_LOG=ON " `
			-DCMAKE_CXX_FLAGS=" $arch $runtime  /EHsc /DENABLE_GR_LOG=ON " `
			-Wno-dev *>> $Log
		Write-Host -NoNewline "building..."
		msbuild .\gqrx.sln /m /p:"configuration=$buildconfig;platform=x64" *>> $Log
		Write-Host -NoNewline "installing..."
		msbuild .\INSTALL.vcxproj /m /p:"configuration=$buildconfig;platform=x64;BuildProjectReferences=false" *>> $Log		
		cp $root/build/$configuration/bin/Qt5Network*.dll $root\src-stage3\staged_install\$configuration\bin\
		cp $root/build/$configuration/bin/Qt5Core*.dll $root\src-stage3\staged_install\$configuration\bin\
		cp $root/build/$configuration/bin/Qt5Gui*.dll $root\src-stage3\staged_install\$configuration\bin\
		cp $root/build/$configuration/bin/Qt5Widgets*.dll $root\src-stage3\staged_install\$configuration\bin\
		cp $root/build/$configuration/bin/Qt5Svg*.dll $root\src-stage3\staged_install\$configuration\bin\
		New-Item -ItemType Directory $root\src-stage3\staged_install\$configuration\plugins -Force *>> $Log
		cp -Recurse -Force $root/build/$configuration/plugins/platforms $root\src-stage3\staged_install\$configuration\bin
		cp -Recurse -Force $root/build/$configuration/plugins/iconengines $root\src-stage3\staged_install\$configuration\bin
		cp -Recurse -Force $root/build/$configuration/plugins/imageformats $root\src-stage3\staged_install\$configuration\bin
		"[Paths]" | out-file -FilePath $root/src-stage3/staged_install/$configuration/bin/qt.conf -encoding ASCII
		"Prefix = ." | out-file -FilePath $root/src-stage3/staged_install/$configuration/bin/qt.conf -encoding ASCII -append 
		$env:_LINK_= ""
	} else {
		New-Item -Force -ItemType Directory $root/src-stage3/oot_code/gqrx/build/$configuration *>> $Log
		cd $root/src-stage3/oot_code/gqrx/build/$configuration
		$ErrorActionPreference = "Continue"
		& cmake ../../ `
			-G "Visual Studio 14 2015 Win64" `
			-DCMAKE_PREFIX_PATH="$root\build\$configuration\gqrx" `
			-DCMAKE_INSTALL_PREFIX="$root/src-stage3/staged_install/$configuration" `
			-DBOOST_LIBRARYDIR="$root\build\$configuration\lib" `
			-DCMAKE_C_FLAGS=" $arch $runtime  /EHsc /DENABLE_GR_LOG=ON " `
			-DCMAKE_CXX_FLAGS=" $arch $runtime  /EHsc /DENABLE_GR_LOG=ON " `
			-Wno-dev *>> $Log	
		Write-Host -NoNewline "building..."
		msbuild .\gqrx.sln /m /p:"configuration=$buildconfig;platform=x64" *>> $Log
		Write-Host -NoNewline "installing..."
		msbuild .\INSTALL.vcxproj /m /p:"configuration=$buildconfig;platform=x64;BuildProjectReferences=false" *>> $Log			
		cp $root/build/$configuration/gqrx/bin/Qt5Network*.dll $root\src-stage3\staged_install\$configuration\bin\
		cp $root/build/$configuration/gqrx/bin/Qt5Core*.dll $root\src-stage3\staged_install\$configuration\bin\
		cp $root/build/$configuration/gqrx/bin/Qt5Gui*.dll $root\src-stage3\staged_install\$configuration\bin\
		cp $root/build/$configuration/gqrx/bin/Qt5Widgets*.dll $root\src-stage3\staged_install\$configuration\bin\
		cp $root/build/$configuration/gqrx/bin/Qt5Svg*.dll $root\src-stage3\staged_install\$configuration\bin\
		New-Item -ItemType Directory $root\src-stage3\staged_install\$configuration\plugins -Force *>> $Log
		cp -Recurse -Force $root/build/$configuration/gqrx/plugins/platforms $root\src-stage3\staged_install\$configuration\bin
		cp -Recurse -Force $root/build/$configuration/gqrx/plugins/iconengines $root\src-stage3\staged_install\$configuration\bin
		cp -Recurse -Force $root/build/$configuration/gqrx/plugins/imageformats $root\src-stage3\staged_install\$configuration\bin
		"[Paths]" | out-file -FilePath $root/src-stage3/staged_install/$configuration/bin/qt.conf -encoding ASCII
		"Prefix = ." | out-file -FilePath $root/src-stage3/staged_install/$configuration/bin/qt.conf -encoding ASCII -append 
	}
	$env:_CL_ = ""
	Validate "$root/src-stage3/staged_install/$configuration/bin/gqrx.exe"

	# ____________________________________________________________________________________________________________
	#
	# Armadillo
	#
	# Required by GNSS-SDR and gr-specest
	#
	SetLog "Armadillo $configuration"
	$ErrorActionPreference = "Continue"
	Write-Host -NoNewline "configuring $configuration Armadillo..."
	New-Item -ItemType Directory -Force -Path $root/src-stage3/oot_code/armadillo-7.800.1/build/$configuration  *>> $Log
	cd $root/src-stage3/oot_code/armadillo-7.800.1/build/$configuration 
	$linkflags= " /DEFAULTLIB:$root/build/$configuration/lib/log4cpp.lib /DEFAULTLIB:$root/src-stage3/staged_install/$configuration/lib/gnuradio-pmt.lib /DEBUG /NODEFAULTLIB:m.lib "
	$env:_CL_ = ""
	$env:_LINK_ = ""
	cmake ../../ `
		-G "Visual Studio 14 2015 Win64" `
		-DCMAKE_PREFIX_PATH="$root\build\$configuration" `
		-DCMAKE_INSTALL_PREFIX="$root\build\$configuration" `
		-DCMAKE_SYSTEM_LIBRARY_PATH="$root\build\$configuration\lib" `
		-DCMAKE_C_FLAGS="/D_USE_MATH_DEFINES /D_TIMESPEC_DEFINED $arch $runtime  /DWIN32 /D_WINDOWS /W3 /EHsc /I""$root/src-stage3/staged_install/$configuration""  /I""$root/src-stage3/staged_install/$configuration/include/swig"" " `
		-DCMAKE_CXX_FLAGS="/D_USE_MATH_DEFINES /D_TIMESPEC_DEFINED $arch $runtime  /DWIN32 /D_WINDOWS /W3 /EHsc /I""$root/src-stage3/staged_install/$configuration""  /I""$root/src-stage3/staged_install/$configuration/include/swig"" " `
		-DCMAKE_SHARED_LINKER_FLAGS=" $linkflags " `
		-DCMAKE_EXE_LINKER_FLAGS=" $linkflags " `
		-DCMAKE_STATIC_LINKER_FLAGS=" $linkflags " `
		-DCMAKE_MODULE_LINKER_FLAGS=" $linkflags  " `
		-DOpenBLAS_NAMES="libopenblas_static" `
		-DMKL_ROOT="${MY_IFORT}mkl" `
		-Wno-dev *>> $Log
	Write-Host -NoNewline "building armadillo-7.800.1..."
	msbuild .\armadillo.sln /m /p:"configuration=$buildconfig;platform=x64" *>> $Log
	Write-Host -NoNewline "installing..."
	msbuild .\INSTALL.vcxproj /m /p:"configuration=$buildconfig;platform=x64;BuildProjectReferences=false" *>> $Log
	$env:_CL_ = ""
	$env:_LINK_ = ""
	$ErrorActionPreference = "Stop"
	Validate "$root/build/$configuration/lib/armadillo.lib"

	# ____________________________________________________________________________________________________________
	#
	# gr-specest
	# 
	if ($hasIFORT) {
		SetLog "gr-specest $configuration"
		$ErrorActionPreference = "Continue"
		Write-Host -NoNewline "configuring $configuration gr-specest..."
		New-Item -ItemType Directory -Force -Path $root/src-stage3/oot_code/gr-specest/build/$configuration  *>> $Log
		cd $root/src-stage3/oot_code/gr-specest/build/$configuration 
		# the quotes that are likely to be in the below path make it impossible to added to the cmake config
		$env:_LINK_ = " /LIBPATH:""${MY_IFORT}compiler/lib/intel64_win/"" "
		$linkflags= " /DEBUG  /NODEFAULTLIB:m.lib /NODEFAULTLIB:LIBCMT.lib /NODEFAULTLIB:LIBCMTD.lib  /DEFAULTLIB:$root/build/$configuration/lib/log4cpp.lib /DEFAULTLIB:$root/src-stage3/staged_install/$configuration/lib/gnuradio-pmt.lib "
		if ($configuration -match "AVX2") {$fortflags = " /QaxCORE-AVX2 /QxCORE-AVX2 /tune:haswell /arch:AVX2 "} else {$fortflags = " /arch:SSE2 "}
		$froot = $root.Replace('\','/')
		# set path to empty to ensure another GR install is not located
		$env:Path="" 
		cmake ../../ `
			-G "Visual Studio 14 2015 Win64" `
			-DCMAKE_PREFIX_PATH="$root\build\$configuration" `
			-DCMAKE_INSTALL_PREFIX="$root/src-stage3/staged_install/$configuration" `
			-DCMAKE_SYSTEM_LIBRARY_PATH="$root\build\$configuration\lib" `
			-DCMAKE_C_FLAGS="/D_USE_MATH_DEFINES /DNOMINMAX /D_TIMESPEC_DEFINED /DWIN32 /D_WINDOWS /W3 /EHsc /I""$root/src-stage3/staged_install/$configuration/include"" /I""$root/src-stage3/staged_install/$configuration/include/swig"" $arch $runtime  " `
			-DCMAKE_CXX_FLAGS="/D_USE_MATH_DEFINES /DNOMINMAX /D_TIMESPEC_DEFINED /DWIN32 /D_WINDOWS /W3 /EHsc /I""$root/src-stage3/staged_install/$configuration/include"" /I""$root/src-stage3/staged_install/$configuration/include/swig""  $arch $runtime  " `
			-DCMAKE_SHARED_LINKER_FLAGS=" $linkflags " `
			-DCMAKE_EXE_LINKER_FLAGS=" $linkflags " `
			-DCMAKE_STATIC_LINKER_FLAGS=" $linkflags " `
			-DCMAKE_MODULE_LINKER_FLAGS=" $linkflags  " `
			-DPYTHON_LIBRARY="$root/src-stage3/staged_install/$configuration/gr-python27/libs/python27.lib" `
			-DPYTHON_LIBRARY_DEBUG="$root/src-stage3/staged_install/$configuration/gr-python27/libs/python27_d.lib" `
			-DPYTHON_EXECUTABLE="$root/src-stage3/staged_install/$configuration/gr-python27/$pythonexe" `
			-DPYTHON_INCLUDE_DIR="$root/src-stage3/staged_install/$configuration/gr-python27/include" `
			-DGNURADIO_RUNTIME_LIBRARIES="$root/src-stage3/staged_install/$configuration/lib/gnuradio-runtime.lib" `
			-DGNURADIO_RUNTIME_INCLUDE_DIRS="$root/src-stage3/staged_install/$configuration/include" `
			-DBLAS_LIBRARIES="$froot/build/$configuration/lib/libopenblas_static.lib;$froot/build/$configuration/lib/cblas.lib;$froot/build/$configuration/lib/lapack.lib" `
			-DLAPACK_LIBRARIES="$froot/build/$configuration/lib/libopenblas_static.lib;$froot/build/$configuration/lib/lapack.lib" `
			-DCMAKE_Fortran_FLAGS=" /assume:underscore /names:lowercase $fortflags " `
			-DSWIG_EXECUTABLE="$root/bin/swig.exe" `
			-Wno-dev  *>> $Log
		$env:Path = $oldPath
		Write-Host -NoNewline "building gr-specest..."
		# use devenv instead of msbuild because of vfproj files unsupported by msbuild
		devenv .\gr-specest.sln  /project ALL_BUILD /clean "$buildconfig|x64" *>> $Log
		devenv .\gr-specest.sln  /project pygen_swig_9b7e5 /build "$buildconfig|x64" *>> $Log
		devenv .\gr-specest.sln  /project ALL_BUILD /build "$buildconfig|x64" *>> $Log
		# devenv .\gr-specest.sln  /project ALL_BUILD /build "$buildconfig|x64" *>> $Log
		Write-Host -NoNewline "installing..."
		msbuild .\INSTALL.vcxproj /m /p:"configuration=$buildconfig;platform=x64;BuildProjectReferences=false" *>> $Log
		$env:_CL_ = ""
		$env:_LINK_ = "" 
		$ErrorActionPreference = "Stop"
		Validate "$root/src-stage3/staged_install/$configuration/bin/gnuradio-specest.dll" "$root/src-stage3/staged_install/$configuration/lib/site-packages/specest/_specest_swig.pyd"
	} else {
		Write-Host "skipping $configuration gr-specest, no fortran compiler available"
	}

	# ____________________________________________________________________________________________________________
	#
	# gr-inspector
	#
	#
	if ($mm -eq "3.8") {
		Write-Host "gr-inspector not gr3.8 compatible"
	} else {
		SetLog "gr-inspector $configuration"
		if ($configuration -match "Debug") {
			Write-Host "skipping gr-inspector in debug" | Tee-Object -FilePath $Log
		} else {
			if ($mm -eq "3.8") {
				Write-Host "skipping gr-inspector in v3.8 as requires Qt4" | Tee-Object -FilePath $Log
			} else {
				Write-Host -NoNewline "configuring $configuration gr-inspector..."
				New-Item -Force -ItemType Directory $root/src-stage3/oot_code/gr-inspector/build/$configuration *>> $Log
				cd $root/src-stage3/oot_code/gr-inspector/build/$configuration
				$env:_CL_=""
				$env:_LINK_= " /DEBUG:FULL "
				$ErrorActionPreference = "Continue"
				$env:Path="" 
				& cmake ../../ `
					-G "Visual Studio 14 2015 Win64" `
					-DCMAKE_PREFIX_PATH="$root\build\$configuration" `
					-DCMAKE_INSTALL_PREFIX="$root/src-stage3/staged_install/$configuration" `
					-DCMAKE_C_FLAGS=" $arch $runtime  /D_USE_MATH_DEFINES /DNOMINMAX /D_TIMESPEC_DEFINED  /EHsc /Zi " `
					-DCMAKE_CXX_FLAGS=" $arch $runtime  /D_USE_MATH_DEFINES /DNOMINMAX /D_TIMESPEC_DEFINED  /EHsc /Zi " `
					-DBOOST_LIBRARYDIR="$root/build/$configuration/lib" `
					-DBOOST_INCLUDEDIR="$root/build/$configuration/include" `
					-DBOOST_ROOT="$root/build/$configuration/" `
					-DPYTHON_LIBRARY="$root/src-stage3/staged_install/$configuration/gr-python27/libs/python27.lib" `
					-DPYTHON_LIBRARY_DEBUG="$root/src-stage3/staged_install/$configuration/gr-python27/libs/python27_d.lib" `
					-DPYTHON_EXECUTABLE="$root/src-stage3/staged_install/$configuration/gr-python27/$pythonexe" `
					-DPYTHON_INCLUDE_DIR="$root/src-stage3/staged_install/$configuration/gr-python27/include" `
					-DQT_QWTPLOT3D_LIBRARY="$root\build\$configuration\lib\qwtplot3d.lib" `
					-DQT_QWTPLOT3D_INCLUDE_DIR="$root\build\$configuration\include\qwt3d" `
					-DQT_UIC_EXECUTABLE="$root/build/$configuration/bin/uic.exe" `
					-DQT_MOC_EXECUTABLE="$root/build/$configuration/bin/moc.exe" `
					-DQT_RCC_EXECUTABLE="$root/build/$configuration/bin/rcc.exe" `
					-DQWT_INCLUDE_DIRS="$root\build\$configuration\include\qwt6" `
					-DQWT_LIBRARIES="$root\build\$configuration\lib\qwt${debugext}6.lib" `
					-DSWIG_EXECUTABLE="$root/bin/swig.exe" `
					-DCMAKE_CXX_FLAGS="/D_USE_MATH_DEFINES /D_TIMESPEC_DEFINED /EHsc /Zi " `
					-DCMAKE_C_FLAGS="/D_USE_MATH_DEFINES /D_TIMESPEC_DEFINED /Zi " `
					-Wno-dev *>> $Log
				$env:Path = $oldPath
				Write-Host -NoNewline "building gr-inspector..."
				msbuild .\gr-inspector.sln /m /p:"configuration=$buildconfig;platform=x64" *>> $Log
				Write-Host -NoNewline "installing..."
				msbuild .\INSTALL.vcxproj /m /p:"configuration=$buildconfig;platform=x64;BuildProjectReferences=false" *>> $Log
				# copy the examples across
				New-Item -Force -ItemType Directory $root/src-stage3/staged_install/$configuration/share/gnuradio/examples/gr-inspector *>> $Log
				cp -Recurse -Force $root/src-stage3/oot_code/gr-inspector/examples/*.grc $root/src-stage3/staged_install/$configuration/share/gnuradio/examples/gr-inspector *>> $Log
				$env:_CL_ = ""
				$env:_LINK_ = ""
				Validate "$root/src-stage3/staged_install/$configuration/bin/gnuradio-inspector.dll" "$root\src-stage3\staged_install\$configuration\lib\site-packages\inspector\_inspector_swig.pyd"
			}
		}
	}

	# ____________________________________________________________________________________________________________
	#
	# gr-cdma
	#
	# TODO: need to manually change the cdma_parameters.py to alter the fixed path it is looking for
	#
	if ($mm -eq "3.8") {
		Write-Host "gr-cdma not gr3.8 compatible"
	} else {
		SetLog "gr-cdma $configuration"
		Write-Host -NoNewline "configuring $configuration gr-cdma..."
		New-Item -Force -ItemType Directory $root/src-stage3/oot_code/gr-cdma/build/$configuration *>> $Log
		cd $root/src-stage3/oot_code/gr-cdma/build/$configuration
		$env:_CL_=" $arch /DNOMINMAX  /D_USE_MATH_DEFINES /D_TIMESPEC_DEFINED /EHsc /Zi "
		$env:_LINK_= " /DEBUG:FULL $root/src-stage3/staged_install/$configuration/lib/gnuradio-pmt.lib "
		if ($mm -eq '3.8') {$env:_LINK_= $env:_LINK_ + " $root/build/$configuration/lib/log4cpp.lib "}
		(Get-Content "../../python/cdma_parameters.py").replace('/home/anastas/gr-cdma/', '../lib/site-packages/cdma') | Set-Content "../../python/cdma_parameters.py"
		$ErrorActionPreference = "Continue"
		$env:Path="" 
		& cmake ../../ `
			-G "Visual Studio 14 2015 Win64" `
			-DCMAKE_PREFIX_PATH="$root\build\$configuration" `
			-DCMAKE_INSTALL_PREFIX="$root/src-stage3/staged_install/$configuration" `
			-DGNURADIO_RUNTIME_LIBRARIES="$root/src-stage3/staged_install/$configuration/lib/gnuradio-runtime.lib" `
			-DGNURADIO_RUNTIME_INCLUDE_DIRS="$root/src-stage3/staged_install/$configuration/include" `
			-DBOOST_LIBRARYDIR="$root/build/$configuration/lib" `
			-DBOOST_INCLUDEDIR="$root/build/$configuration/include" `
			-DBOOST_ROOT="$root/build/$configuration/" `
			-DPYTHON_LIBRARY="$root/src-stage3/staged_install/$configuration/gr-python27/libs/python27.lib" `
			-DPYTHON_LIBRARY_DEBUG="$root/src-stage3/staged_install/$configuration/gr-python27/libs/python27_d.lib" `
			-DPYTHON_EXECUTABLE="$root/src-stage3/staged_install/$configuration/gr-python27/$pythonexe" `
			-DPYTHON_INCLUDE_DIR="$root/src-stage3/staged_install/$configuration/gr-python27/include" `
			-DSWIG_EXECUTABLE="$root/bin/swig.exe" `
			-DCMAKE_CXX_FLAGS="/D_USE_MATH_DEFINES /D_TIMESPEC_DEFINED /EHsc  /DNOMINMAX  /Zi $arch $runtime " `
			-DCMAKE_C_FLAGS="/D_USE_MATH_DEFINES /D_TIMESPEC_DEFINED /DNOMINMAX /Zi $arch $runtime " `
			-Wno-dev *>> $Log
		$env:Path = $oldPath
		Write-Host -NoNewline "building gr-cdma..."
		msbuild .\gr-cdma.sln /m /p:"configuration=$buildconfig;platform=x64" *>> $Log
		Write-Host -NoNewline "installing..."
		msbuild .\INSTALL.vcxproj /m /p:"configuration=$buildconfig;platform=x64;BuildProjectReferences=false" *>> $Log
		# copy the examples across
		New-Item -Force -ItemType Directory $root/src-stage3/staged_install/$configuration/share/gnuradio/examples/gr-cdma *>> $Log
		cp -Recurse -Force $root/src-stage3/oot_code/gr-cdma/apps/*.grc $root/src-stage3/staged_install/$configuration/share/gnuradio/examples/gr-cdma *>> $Log
		# copy the fsm files across
		New-Item -Force -ItemType Directory $root/src-stage3/staged_install/$configuration/lib/site-packages/cdma/python/fsm_files *>> $Log
		cp -Recurse -Force $root/src-stage3/oot_code/gr-cdma/python/fsm_files/*.fsm $root/src-stage3/staged_install/$configuration/lib/site-packages/cdma/python/fsm_files *>> $Log
		$env:_CL_ = ""
		$env:_LINK_ = ""
		Validate "$root/src-stage3/staged_install/$configuration/bin/gnuradio-cdma.dll" "$root\src-stage3\staged_install\$configuration\lib\site-packages\cdma\_cdma_swig.pyd"
	}

	# ____________________________________________________________________________________________________________
	#
	# gr-rds
	#
	#
	SetLog "gr-rds $configuration"
	Write-Host -NoNewline "configuring $configuration gr-rds..."
	New-Item -Force -ItemType Directory $root/src-stage3/oot_code/gr-rds/build/$configuration *>> $Log
	cd $root/src-stage3/oot_code/gr-rds/build/$configuration
	$env:_CL_ = " $arch ";
	$env:_LINK_= " /DEBUG:FULL $root/src-stage3/staged_install/$configuration/lib/gnuradio-pmt.lib "
	if ($mm -eq '3.8') {$env:_LINK_= $env:_LINK_ + " $root/build/$configuration/lib/log4cpp.lib "}
	$ErrorActionPreference = "Continue"
	$env:Path="" 
	& cmake ../../ `
		-G "Visual Studio 14 2015 Win64" `
		-DCMAKE_PREFIX_PATH="$root\build\$configuration" `
		-DCMAKE_INSTALL_PREFIX="$root/src-stage3/staged_install/$configuration" `
		-DGNURADIO_RUNTIME_LIBRARIES="$root/src-stage3/staged_install/$configuration/lib/gnuradio-runtime.lib" `
		-DGNURADIO_RUNTIME_INCLUDE_DIRS="$root/src-stage3/staged_install/$configuration/include" `
		-DBOOST_LIBRARYDIR="$root/build/$configuration/lib" `
		-DBOOST_INCLUDEDIR="$root/build/$configuration/include" `
		-DBOOST_ROOT="$root/build/$configuration/" `
		-DPYTHON_LIBRARY="$root/src-stage3/staged_install/$configuration/gr-python27/libs/python27.lib" `
		-DPYTHON_LIBRARY_DEBUG="$root/src-stage3/staged_install/$configuration/gr-python27/libs/python27_d.lib" `
		-DPYTHON_EXECUTABLE="$root/src-stage3/staged_install/$configuration/gr-python27/$pythonexe" `
		-DPYTHON_INCLUDE_DIR="$root/src-stage3/staged_install/$configuration/gr-python27/include" `
		-DSWIG_EXECUTABLE="$root/bin/swig.exe" `
		-DCMAKE_CXX_FLAGS="/D_USE_MATH_DEFINES /D_TIMESPEC_DEFINED /EHsc  /DNOMINMAX  /Zi $arch $runtime " `
		-DCMAKE_C_FLAGS="/D_USE_MATH_DEFINES /D_TIMESPEC_DEFINED /DNOMINMAX /Zi $arch $runtime " `
		-Wno-dev *>> $Log
	$env:Path = $oldPath
	Write-Host -NoNewline "building gr-rds..."
	msbuild .\gr-rds.sln /m /p:"configuration=$buildconfig;platform=x64" *>> $Log
	Write-Host -NoNewline "installing..."
	msbuild .\INSTALL.vcxproj /m /p:"configuration=$buildconfig;platform=x64;BuildProjectReferences=false" *>> $Log
	# copy the examples across
	New-Item -Force -ItemType Directory $root/src-stage3/staged_install/$configuration/share/gnuradio/examples/gr-rds *>> $Log
	cp -Recurse -Force $root/src-stage3/oot_code/gr-rds/apps/*.grc $root/src-stage3/staged_install/$configuration/share/gnuradio/examples/gr-rds *>> $Log
	$env:_CL_ = ""
	$env:_LINK_ = ""
	Validate "$root/src-stage3/staged_install/$configuration/bin/gnuradio-rds.dll" "$root\src-stage3\staged_install\$configuration\lib\site-packages\rds\_rds_swig.pyd"

	# ____________________________________________________________________________________________________________
	#
	# gr-ais
	#
	#
	if ($mm -eq "3.8") {
		Write-Host "gr-ais not gr3.8 compatible"
	} else {
		SetLog "gr-ais $configuration"
		Write-Host -NoNewline "configuring $configuration gr-ais..."
		New-Item -Force -ItemType Directory $root/src-stage3/oot_code/gr-ais/build/$configuration *>> $Log
		cd $root/src-stage3/oot_code/gr-ais/build/$configuration
		$env:_CL_ = " $arch ";
		$env:_LINK_= " /DEBUG:FULL $root/src-stage3/staged_install/$configuration/lib/gnuradio-pmt.lib $root/src-stage3/staged_install/$configuration/lib/volk.lib "
		$ErrorActionPreference = "Continue"
		$env:Path="" 
		& cmake ../../ `
			-G "Visual Studio 14 2015 Win64" `
			-DCMAKE_PREFIX_PATH="$root\build\$configuration" `
			-DCMAKE_INSTALL_PREFIX="$root/src-stage3/staged_install/$configuration" `
			-DGNURADIO_RUNTIME_LIBRARIES="$root/src-stage3/staged_install/$configuration/lib/gnuradio-runtime.lib" `
			-DGNURADIO_RUNTIME_INCLUDE_DIRS="$root/src-stage3/staged_install/$configuration/include" `
			-DBOOST_LIBRARYDIR="$root/build/$configuration/lib" `
			-DBOOST_INCLUDEDIR="$root/build/$configuration/include" `
			-DBOOST_ROOT="$root/build/$configuration/" `
			-DPYTHON_LIBRARY="$root/src-stage3/staged_install/$configuration/gr-python27/libs/python27.lib" `
			-DPYTHON_LIBRARY_DEBUG="$root/src-stage3/staged_install/$configuration/gr-python27/libs/python27_d.lib" `
			-DPYTHON_EXECUTABLE="$root/src-stage3/staged_install/$configuration/gr-python27/$pythonexe" `
			-DPYTHON_INCLUDE_DIR="$root/src-stage3/staged_install/$configuration/gr-python27/include" `
			-DSWIG_EXECUTABLE="$root/bin/swig.exe" `
			-DCMAKE_CXX_FLAGS="/D_USE_MATH_DEFINES /D_TIMESPEC_DEFINED /EHsc  /DNOMINMAX  /Zi $arch $runtime " `
			-DCMAKE_C_FLAGS="/D_USE_MATH_DEFINES /D_TIMESPEC_DEFINED /DNOMINMAX /Zi $arch $runtime " `
			-Wno-dev *>> $Log
		$env:Path = $oldPath
		Write-Host -NoNewline "building gr-ais..."
		msbuild .\gr-ais.sln /m /p:"configuration=$buildconfig;platform=x64" *>> $Log
		Write-Host -NoNewline "installing..."
		msbuild .\INSTALL.vcxproj /m /p:"configuration=$buildconfig;platform=x64;BuildProjectReferences=false" *>> $Log
		# copy the examples across
		New-Item -Force -ItemType Directory $root/src-stage3/staged_install/$configuration/share/gnuradio/examples/gr-ais *>> $Log
		cp -Recurse -Force $root/src-stage3/oot_code/gr-ais/apps/*.grc $root/src-stage3/staged_install/$configuration/share/gnuradio/examples/gr-ais *>> $Log
		$env:_CL_ = ""
		$env:_LINK_ = ""
		Validate "$root/src-stage3/staged_install/$configuration/bin/gnuradio-ais.dll" "$root\src-stage3\staged_install\$configuration\lib\site-packages\ais\_ais_swig.pyd"
	}

	# ____________________________________________________________________________________________________________
	#
	# gr-display
	#
	#
	SetLog "gr-display $configuration"
	Write-Host -NoNewline "configuring $configuration gr-display..."
	New-Item -Force -ItemType Directory $root/src-stage3/oot_code/gr-display/build/$configuration *>> $Log
	cd $root/src-stage3/oot_code/gr-display/build/$configuration
	$env:_CL_ = " $arch ";
	$env:_LINK_= " /DEBUG:FULL $root/src-stage3/staged_install/$configuration/lib/gnuradio-pmt.lib  "
	$ErrorActionPreference = "Continue"
	#$env:Path="" 
	& cmake ../../ `
		-G "Visual Studio 14 2015 Win64" `
		-DCMAKE_PREFIX_PATH="$root\build\$configuration" `
		-DCMAKE_INSTALL_PREFIX="$root/src-stage3/staged_install/$configuration" `
		-DGNURADIO_RUNTIME_LIBRARIES="$root/src-stage3/staged_install/$configuration/lib/gnuradio-runtime.lib" `
		-DGNURADIO_RUNTIME_INCLUDE_DIRS="$root/src-stage3/staged_install/$configuration/include" `
		-DBoost_NO_SYSTEM_PATHS=ON `
		-DBOOST_LIBRARYDIR="$root/build/$configuration/lib" `
		-DBOOST_INCLUDEDIR="$root/build/$configuration/include" `
		-DBOOST_ROOT="$root/build/$configuration/" `
		-DQT_UIC_EXECUTABLE="$root/build/$configuration/bin/uic.exe" `
		-DQT_MOC_EXECUTABLE="$root/build/$configuration/bin/moc.exe" `
		-DQT_RCC_EXECUTABLE="$root/build/$configuration/bin/rcc.exe" `
		-DPYTHON_LIBRARY="$root/src-stage3/staged_install/$configuration/gr-python27/libs/python27.lib" `
		-DPYTHON_LIBRARY_DEBUG="$root/src-stage3/staged_install/$configuration/gr-python27/libs/python27_d.lib" `
		-DPYTHON_EXECUTABLE="$root/src-stage3/staged_install/$configuration/gr-python27/$pythonexe" `
		-DPYTHON_INCLUDE_DIR="$root/src-stage3/staged_install/$configuration/gr-python27/include" `
		-DSWIG_EXECUTABLE="$root/bin/swig.exe" `
		-DCMAKE_CXX_FLAGS="/D_USE_MATH_DEFINES /D_TIMESPEC_DEFINED /EHsc  /DNOMINMAX  /Zi $arch $runtime /DBOOST_ALL_DYN_LINK " `
		-DCMAKE_C_FLAGS="/D_USE_MATH_DEFINES /D_TIMESPEC_DEFINED /DNOMINMAX /Zi $arch $runtime /DBOOST_ALL_DYN_LINK " `
		-DDOXY_FILE_PATH="$root/src-stage3/src/gnuradio/docs/doxygen" `
		-Wno-dev *>> $Log
	#$env:Path = $oldPath
	Write-Host -NoNewline "building gr-display..."
	msbuild .\gr-display.sln /m /p:"configuration=$buildconfig;platform=x64" *>> $Log
	Write-Host -NoNewline "installing..."
	msbuild .\INSTALL.vcxproj /m /p:"configuration=$buildconfig;platform=x64;BuildProjectReferences=false" *>> $Log
	# copy the examples across
	New-Item -Force -ItemType Directory $root/src-stage3/staged_install/$configuration/share/gnuradio/examples/gr-display *>> $Log
	cp -Recurse -Force $root/src-stage3/oot_code/gr-display/examples/*.grc $root/src-stage3/staged_install/$configuration/share/gnuradio/examples/gr-display *>> $Log
	$env:_CL_ = ""
	$env:_LINK_ = ""
	Validate "$root/src-stage3/staged_install/$configuration/bin/gnuradio-display.dll" "$root\src-stage3\staged_install\$configuration\lib\site-packages\display\_display_swig.pyd"

	# ____________________________________________________________________________________________________________
	#
	# gr-ax25
	#
	#
	if ($mm -eq "3.8") {
		Write-Host "gr-ax25 not gr3.8 compatible"
	} else {
		SetLog "gr-ax25 $configuration"
		Write-Host -NoNewline "configuring $configuration gr-ax25..."
		New-Item -Force -ItemType Directory $root/src-stage3/oot_code/gr-ax25/build/$configuration *>> $Log
		cd $root/src-stage3/oot_code/gr-ax25/build/$configuration
		$env:_CL_ = " $arch ";
		$env:_LINK_= " /DEBUG:FULL $root/src-stage3/staged_install/$configuration/lib/gnuradio-pmt.lib  "
		$ErrorActionPreference = "Continue"
		$env:Path="" 
		& cmake ../../ `
			-G "Visual Studio 14 2015 Win64" `
			-DCMAKE_PREFIX_PATH="$root\build\$configuration" `
			-DCMAKE_INSTALL_PREFIX="$root/src-stage3/staged_install/$configuration" `
			-DGNURADIO_RUNTIME_LIBRARIES="$root/src-stage3/staged_install/$configuration/lib/gnuradio-runtime.lib" `
			-DGNURADIO_RUNTIME_INCLUDE_DIRS="$root/src-stage3/staged_install/$configuration/include" `
			-DBOOST_LIBRARYDIR="$root/build/$configuration/lib" `
			-DBOOST_INCLUDEDIR="$root/build/$configuration/include" `
			-DBOOST_ROOT="$root/build/$configuration/" `
			-DPYTHON_LIBRARY="$root/src-stage3/staged_install/$configuration/gr-python27/libs/python27.lib" `
			-DPYTHON_LIBRARY_DEBUG="$root/src-stage3/staged_install/$configuration/gr-python27/libs/python27_d.lib" `
			-DPYTHON_EXECUTABLE="$root/src-stage3/staged_install/$configuration/gr-python27/$pythonexe" `
			-DPYTHON_INCLUDE_DIR="$root/src-stage3/staged_install/$configuration/gr-python27/include" `
			-DSWIG_EXECUTABLE="$root/bin/swig.exe" `
			-DCMAKE_CXX_FLAGS="/D_USE_MATH_DEFINES /D_TIMESPEC_DEFINED /EHsc  /DNOMINMAX  /Zi $arch $runtime " `
			-DCMAKE_C_FLAGS="/D_USE_MATH_DEFINES /D_TIMESPEC_DEFINED /DNOMINMAX /Zi $arch $runtime " `
			-Wno-dev *>> $Log
		$env:Path = $oldPath
		Write-Host -NoNewline "building gr-ax25..."
		msbuild .\gr-afsk.sln /m /p:"configuration=$buildconfig;platform=x64" *>> $Log
		Write-Host -NoNewline "installing..."
		msbuild .\INSTALL.vcxproj /m /p:"configuration=$buildconfig;platform=x64;BuildProjectReferences=false" *>> $Log
		# copy the examples across
		New-Item -Force -ItemType Directory $root/src-stage3/staged_install/$configuration/share/gnuradio/examples/gr-ax25 *>> $Log
		cp -Recurse -Force $root/src-stage3/oot_code/gr-ax25/apps/*.grc $root/src-stage3/staged_install/$configuration/share/gnuradio/examples/gr-ax25 *>> $Log
		$env:_CL_ = ""
		$env:_LINK_ = ""
		Validate "$root/src-stage3/staged_install/$configuration/bin/gnuradio-afsk.dll" "$root\src-stage3\staged_install\$configuration\lib\site-packages\afsk\_afsk_swig.pyd"
	}

	# ____________________________________________________________________________________________________________
	#
	# gr-radar
	#
	#
	if ($mm -eq "3.8") {
		Write-Host "gr-radar not gr3.8 compatible"
	} else {
		SetLog "gr-radar $configuration"
		Write-Host -NoNewline "configuring $configuration gr-radar..."
		New-Item -Force -ItemType Directory $root/src-stage3/oot_code/gr-radar/build/$configuration *>> $Log
		cd $root/src-stage3/oot_code/gr-radar/build/$configuration
		$env:_CL_ = ""
		$env:_LINK_ = ""
		$linkflags= " /DEBUG  /NODEFAULTLIB:m.lib  /DEFAULTLIB:$root/src-stage3/staged_install/$configuration/lib/gnuradio-pmt.lib /DEFAULTLIB:$root/src-stage3/staged_install/$configuration/lib/volk.lib "
		$ErrorActionPreference = "Continue"
		$env:Path="" 
		& cmake ../../ `
			-G "Visual Studio 14 2015 Win64" `
			-DCMAKE_PREFIX_PATH="$root\build\$configuration" `
			-DCMAKE_INSTALL_PREFIX="$root/src-stage3/staged_install/$configuration" `
			-DGNURADIO_RUNTIME_LIBRARIES="$root/src-stage3/staged_install/$configuration/lib/gnuradio-runtime.lib" `
			-DGNURADIO_RUNTIME_INCLUDE_DIRS="$root/src-stage3/staged_install/$configuration/include" `
			-DBOOST_LIBRARYDIR="$root/build/$configuration/lib" `
			-DBOOST_INCLUDEDIR="$root/build/$configuration/include" `
			-DBOOST_ROOT="$root/build/$configuration/" `
			-DPYTHON_LIBRARY="$root/src-stage3/staged_install/$configuration/gr-python27/libs/python27.lib" `
			-DPYTHON_LIBRARY_DEBUG="$root/src-stage3/staged_install/$configuration/gr-python27/libs/python27_d.lib" `
			-DPYTHON_EXECUTABLE="$root/src-stage3/staged_install/$configuration/gr-python27/$pythonexe" `
			-DPYTHON_INCLUDE_DIR="$root/src-stage3/staged_install/$configuration/gr-python27/include" `
			-DSWIG_EXECUTABLE="$root/bin/swig.exe" `
			-DQT_UIC_EXECUTABLE="$root/build/$configuration/bin/uic.exe" `
			-DQT_MOC_EXECUTABLE="$root/build/$configuration/bin/moc.exe" `
			-DQT_RCC_EXECUTABLE="$root/build/$configuration/bin/rcc.exe" `
			-DQWT_INCLUDE_DIRS="$root\build\$configuration\include\qwt6" `
			-DQWT_LIBRARIES="$root\build\$configuration\lib\qwt${debugext}6.lib" `
			-DCMAKE_CXX_FLAGS="/D_USE_MATH_DEFINES /D_TIMESPEC_DEFINED /EHsc  /DNOMINMAX  /Zi $arch $runtime " `
			-DCMAKE_C_FLAGS="/D_USE_MATH_DEFINES /D_TIMESPEC_DEFINED /DNOMINMAX /Zi $arch $runtime " `
			-DCMAKE_SHARED_LINKER_FLAGS=" $linkflags " `
			-DCMAKE_EXE_LINKER_FLAGS=" $linkflags " `
			-DCMAKE_STATIC_LINKER_FLAGS=" $linkflags " `
			-DCMAKE_MODULE_LINKER_FLAGS=" $linkflags  " `
			-Wno-dev *>> $Log
		$env:Path = $oldPath
		Write-Host -NoNewline "building gr-radar..."
		msbuild .\gr-radar.sln /m /p:"configuration=$buildconfig;platform=x64" *>> $Log
		Write-Host -NoNewline "installing..."
		msbuild .\INSTALL.vcxproj /m /p:"configuration=$buildconfig;platform=x64;BuildProjectReferences=false" *>> $Log
		# copy the examples across
		New-Item -Force -ItemType Directory $root/src-stage3/staged_install/$configuration/share/gnuradio/examples/gr-radar *>> $Log
		cp -Recurse -Force $root/src-stage3/oot_code/gr-radar/examples/* $root/src-stage3/staged_install/$configuration/share/gnuradio/examples/gr-radar *>> $Log
		$env:_CL_ = ""
		$env:_LINK_ = ""
		Validate "$root/src-stage3/staged_install/$configuration/bin/gnuradio-radar.dll" "$root\src-stage3\staged_install\$configuration\lib\site-packages\radar\_radar_swig.pyd"
	}
	
	# ____________________________________________________________________________________________________________
	#
	# gr-paint
	#
	#
	SetLog "gr-paint $configuration"
	Write-Host -NoNewline "configuring $configuration gr-paint..."
	if ($mm -eq "3.8") {
		$grpaint = "gr-paint38"
	} else {
		$grpaint = "gr-paint"
	}
	New-Item -Force -ItemType Directory $root/src-stage3/oot_code/$grpaint/build/$configuration *>> $Log
	cd $root/src-stage3/oot_code/$grpaint/build/$configuration
	$env:_CL_ = " $arch ";
	$env:_LINK_= " /DEBUG:FULL $root/src-stage3/staged_install/$configuration/lib/gnuradio-pmt.lib  $root/src-stage3/staged_install/$configuration/lib/volk.lib "
	$ErrorActionPreference = "Continue"
	$env:Path="" 
	& cmake ../../ `
		-G "Visual Studio 14 2015 Win64" `
		-DCMAKE_PREFIX_PATH="$root\build\$configuration" `
		-DCMAKE_INSTALL_PREFIX="$root/src-stage3/staged_install/$configuration" `
		-DGNURADIO_RUNTIME_LIBRARIES="$root/src-stage3/staged_install/$configuration/lib/gnuradio-runtime.lib" `
		-DGNURADIO_RUNTIME_INCLUDE_DIRS="$root/src-stage3/staged_install/$configuration/include" `
		-DBOOST_LIBRARYDIR="$root/build/$configuration/lib" `
		-DBOOST_INCLUDEDIR="$root/build/$configuration/include" `
		-DBOOST_ROOT="$root/build/$configuration/" `
		-DPYTHON_LIBRARY="$root/src-stage3/staged_install/$configuration/gr-python27/libs/python27.lib" `
		-DPYTHON_LIBRARY_DEBUG="$root/src-stage3/staged_install/$configuration/gr-python27/libs/python27_d.lib" `
		-DPYTHON_EXECUTABLE="$root/src-stage3/staged_install/$configuration/gr-python27/$pythonexe" `
		-DPYTHON_INCLUDE_DIR="$root/src-stage3/staged_install/$configuration/gr-python27/include" `
		-DSWIG_EXECUTABLE="$root/bin/swig.exe" `
		-DCMAKE_CXX_FLAGS="/D_USE_MATH_DEFINES /D_TIMESPEC_DEFINED /EHsc  /DNOMINMAX  /Zi $arch $runtime " `
		-DCMAKE_C_FLAGS="/D_USE_MATH_DEFINES /D_TIMESPEC_DEFINED /DNOMINMAX /Zi $arch $runtime " `
		-Wno-dev *>> $Log
	$env:Path = $oldPath
	Write-Host -NoNewline "building gr-paint..."
	msbuild .\gr-paint.sln /m /p:"configuration=$buildconfig;platform=x64" *>> $Log
	Write-Host -NoNewline "installing..."
	msbuild .\INSTALL.vcxproj /m /p:"configuration=$buildconfig;platform=x64;BuildProjectReferences=false" *>> $Log
	# copy the examples across
	New-Item -Force -ItemType Directory $root/src-stage3/staged_install/$configuration/share/gnuradio/examples/gr-paint *>> $Log
	cp -Recurse -Force $root/src-stage3/oot_code/$grpaint/apps/*.grc $root/src-stage3/staged_install/$configuration/share/gnuradio/examples/gr-paint *>> $Log
	cp -Recurse -Force $root/src-stage3/oot_code/$grpaint/apps/*.png $root/src-stage3/staged_install/$configuration/share/gnuradio/examples/gr-paint *>> $Log
	cp -Recurse -Force $root/src-stage3/oot_code/$grpaint/apps/*.bin $root/src-stage3/staged_install/$configuration/share/gnuradio/examples/gr-paint *>> $Log
	$env:_CL_ = ""
	$env:_LINK_ = ""
	Validate "$root/src-stage3/staged_install/$configuration/bin/gnuradio-paint.dll" "$root\src-stage3\staged_install\$configuration\lib\site-packages\paint\_paint_swig.pyd"

	# ____________________________________________________________________________________________________________
	#
	# gr-mapper
	#
	#
	SetLog "gr-mapper $configuration"
	Write-Host -NoNewline "configuring $configuration gr-mapper..."
	New-Item -Force -ItemType Directory $root/src-stage3/oot_code/gr-mapper/build/$configuration *>> $Log
	cd $root/src-stage3/oot_code/gr-mapper/build/$configuration
	$env:_CL_ = " $arch ";
	$env:_LINK_= " /DEBUG:FULL $root/src-stage3/staged_install/$configuration/lib/gnuradio-pmt.lib  $root/src-stage3/staged_install/$configuration/lib/volk.lib "
	$ErrorActionPreference = "Continue"
	$env:Path="" 
	& cmake ../../ `
		-G "Visual Studio 14 2015 Win64" `
		-DCMAKE_PREFIX_PATH="$root\build\$configuration" `
		-DCMAKE_INSTALL_PREFIX="$root/src-stage3/staged_install/$configuration" `
		-DGNURADIO_RUNTIME_LIBRARIES="$root/src-stage3/staged_install/$configuration/lib/gnuradio-runtime.lib" `
		-DGNURADIO_RUNTIME_INCLUDE_DIRS="$root/src-stage3/staged_install/$configuration/include" `
		-DBOOST_LIBRARYDIR="$root/build/$configuration/lib" `
		-DBOOST_INCLUDEDIR="$root/build/$configuration/include" `
		-DBOOST_ROOT="$root/build/$configuration/" `
		-DPYTHON_LIBRARY="$root/src-stage3/staged_install/$configuration/gr-python27/libs/python27.lib" `
		-DPYTHON_LIBRARY_DEBUG="$root/src-stage3/staged_install/$configuration/gr-python27/libs/python27_d.lib" `
		-DPYTHON_EXECUTABLE="$root/src-stage3/staged_install/$configuration/gr-python27/$pythonexe" `
		-DPYTHON_INCLUDE_DIR="$root/src-stage3/staged_install/$configuration/gr-python27/include" `
		-DSWIG_EXECUTABLE="$root/bin/swig.exe" `
		-DCMAKE_CXX_FLAGS="/D_USE_MATH_DEFINES /D_TIMESPEC_DEFINED /EHsc  /DNOMINMAX  /Zi $arch $runtime " `
		-DCMAKE_C_FLAGS="/D_USE_MATH_DEFINES /D_TIMESPEC_DEFINED /DNOMINMAX /Zi $arch $runtime " `
		-Wno-dev *>> $Log
	$env:Path = $oldPath
	Write-Host -NoNewline "building gr-mapper..."
	msbuild .\gr-mapper.sln /m /p:"configuration=$buildconfig;platform=x64" *>> $Log
	Write-Host -NoNewline "installing..."
	msbuild .\INSTALL.vcxproj /m /p:"configuration=$buildconfig;platform=x64;BuildProjectReferences=false" *>> $Log
	# copy the examples across
	New-Item -Force -ItemType Directory $root/src-stage3/staged_install/$configuration/share/gnuradio/examples/gr-mapper *>> $Log
	cp -Recurse -Force $root/src-stage3/oot_code/gr-mapper/apps/*.grc $root/src-stage3/staged_install/$configuration/share/gnuradio/examples/gr-mapper *>> $Log
	cp -Recurse -Force $root/src-stage3/oot_code/gr-paint/examples/*.py $root/src-stage3/staged_install/$configuration/share/gnuradio/examples/gr-mapper *>> $Log
	$env:_CL_ = ""
	$env:_LINK_ = ""
	Validate "$root/src-stage3/staged_install/$configuration/bin/gnuradio-mapper.dll" "$root\src-stage3\staged_install\$configuration\lib\site-packages\mapper\_mapper_swig.pyd"

	# ____________________________________________________________________________________________________________
	#
	# gr-nacl
	#
	#
	if ($mm -eq "3.8") {
		Write-Host "gr-nacl not gr3.8 compatible"
	} else {
		SetLog "gr-nacl $configuration"
		Write-Host -NoNewline "configuring $configuration gr-nacl..."
		New-Item -Force -ItemType Directory $root/src-stage3/oot_code/gr-nacl/build/$configuration *>> $Log
		cd $root/src-stage3/oot_code/gr-nacl/build/$configuration
		$env:_CL_ = " $arch ";
		$env:_LINK_= " /DEBUG:FULL $root/src-stage3/staged_install/$configuration/lib/gnuradio-pmt.lib "
		$ErrorActionPreference = "Continue"
		$env:Path="" 
		& cmake ../../ `
			-G "Visual Studio 14 2015 Win64" `
			-DCMAKE_PREFIX_PATH="$root\build\$configuration" `
			-DCMAKE_INSTALL_PREFIX="$root/src-stage3/staged_install/$configuration" `
			-DGNURADIO_RUNTIME_LIBRARIES="$root/src-stage3/staged_install/$configuration/lib/gnuradio-runtime.lib" `
			-DGNURADIO_RUNTIME_INCLUDE_DIRS="$root/src-stage3/staged_install/$configuration/include" `
			-DBOOST_LIBRARYDIR="$root/build/$configuration/lib" `
			-DBOOST_INCLUDEDIR="$root/build/$configuration/include" `
			-DBOOST_ROOT="$root/build/$configuration/" `
			-DSODIUM_LIBRARIES="$root/build/$configuration/lib/libsodium.lib" `
			-DSODIUM_INCLUDE_DIRS="$root/build/$configuration/include" `
			-DPYTHON_LIBRARY="$root/src-stage3/staged_install/$configuration/gr-python27/libs/python27.lib" `
			-DPYTHON_LIBRARY_DEBUG="$root/src-stage3/staged_install/$configuration/gr-python27/libs/python27_d.lib" `
			-DPYTHON_EXECUTABLE="$root/src-stage3/staged_install/$configuration/gr-python27/$pythonexe" `
			-DPYTHON_INCLUDE_DIR="$root/src-stage3/staged_install/$configuration/gr-python27/include" `
			-DSWIG_EXECUTABLE="$root/bin/swig.exe" `
			-DCMAKE_CXX_FLAGS="/D_USE_MATH_DEFINES /D_TIMESPEC_DEFINED /EHsc  /DNOMINMAX  /Zi $arch $runtime " `
			-DCMAKE_C_FLAGS="/D_USE_MATH_DEFINES /D_TIMESPEC_DEFINED /DNOMINMAX /Zi $arch $runtime " `
			-Wno-dev *>> $Log
		$env:Path = $oldPath
		Write-Host -NoNewline "building gr-nacl..."
		msbuild .\gr-nacl.sln /m /p:"configuration=$buildconfig;platform=x64" *>> $Log
		Write-Host -NoNewline "installing..."
		msbuild .\INSTALL.vcxproj /m /p:"configuration=$buildconfig;platform=x64;BuildProjectReferences=false" *>> $Log
		# copy the examples across
		New-Item -Force -ItemType Directory $root/src-stage3/staged_install/$configuration/share/gnuradio/examples/gr-nacl *>> $Log
		cp -Recurse -Force $root/src-stage3/oot_code/gr-nacl/examples/*.grc $root/src-stage3/staged_install/$configuration/share/gnuradio/examples/gr-nacl *>> $Log
		cp -Recurse -Force $root/src-stage3/oot_code/gr-nacl/examples/*.file $root/src-stage3/staged_install/$configuration/share/gnuradio/examples/gr-nacl *>> $Log
		$env:_CL_ = ""
		$env:_LINK_ = ""
		Validate "$root/src-stage3/staged_install/$configuration/bin/gnuradio-nacl.dll" "$root\src-stage3\staged_install\$configuration\lib\site-packages\nacl\_nacl_swig.pyd"
	}

	# ____________________________________________________________________________________________________________
	#
	# gr-eventstream
	#
	#
	if ($mm -eq "3.8") {
		Write-Host "gr-eventstream not gr3.8 compatible"
	} else {
		SetLog "gr-eventstream $configuration"
		Write-Host -NoNewline "configuring $configuration gr-eventstream..."
		New-Item -Force -ItemType Directory $root/src-stage3/oot_code/gr-eventstream/build/$configuration *>> $Log
		cd $root/src-stage3/oot_code/gr-eventstream/build/$configuration
		$env:_CL_ = ""
		$env:_LINK_ = ""
		$linkflags = " /DEBUG /DEFAULTLIB:$root\src-stage3\build\$configuration\gnuradio-runtime\swig\$buildconfig\_runtime_swig.lib " 
		$ErrorActionPreference = "Continue"
		$env:Path= ""
		& cmake ../../ `
			-G "Visual Studio 14 2015 Win64" `
			-DCMAKE_PREFIX_PATH="$root\build\$configuration" `
			-DCMAKE_INSTALL_PREFIX="$root/src-stage3/staged_install/$configuration" `
			-DCMAKE_LIBRARY_PATH="$root/build/$configuration/lib" `
			-DGNURADIO_RUNTIME_LIBRARIES="$root/src-stage3/staged_install/$configuration/lib/gnuradio-runtime.lib" `
			-DGNURADIO_RUNTIME_INCLUDE_DIRS="$root/src-stage3/staged_install/$configuration/include" `
			-DBOOST_LIBRARYDIR="$root/build/$configuration/lib" `
			-DBOOST_INCLUDEDIR="$root/build/$configuration/include" `
			-DBOOST_INCLUDE_DIRS="$root/build/$configuration/include" `
			-DBOOST_ROOT="$root/build/$configuration/" `
			-DPYTHON_LIBRARY="$root/src-stage3/staged_install/$configuration/gr-python27/libs/python27.lib" `
			-DPYTHON_LIBRARY_DEBUG="$root/src-stage3/staged_install/$configuration/gr-python27/libs/python27_d.lib" `
			-DPYTHON_EXECUTABLE="$root/src-stage3/staged_install/$configuration/gr-python27/$pythonexe" `
			-DPYTHON_INCLUDE_DIR="$root/src-stage3/staged_install/$configuration/gr-python27/include" `
			-DSWIG_EXECUTABLE="$root/bin/swig.exe" `
			-DCMAKE_CXX_FLAGS=" /D_USE_MATH_DEFINES /D_TIMESPEC_DEFINED /EHsc  /DNOMINMAX  /Zi /D_ENABLE_ATOMIC_ALIGNMENT_FIX $arch $runtime  " `
			-DCMAKE_C_FLAGS=" /D_USE_MATH_DEFINES /D_TIMESPEC_DEFINED /DNOMINMAX /Zi /D_ENABLE_ATOMIC_ALIGNMENT_FIX $arch $runtime " `
			-DCMAKE_SHARED_LINKER_FLAGS=" $linkflags " `
			-DCMAKE_EXE_LINKER_FLAGS=" $linkflags " `
			-DCMAKE_STATIC_LINKER_FLAGS=" $linkflags " `
			-DCMAKE_MODULE_LINKER_FLAGS=" $linkflags  " `
			-DENABLE_STATIC_LIBS="True" `
			-Wno-dev *>> $Log
		$env:Path = $oldPath
		Write-Host -NoNewline "building gr-eventstream..."
		# test_eventstream build will fail because dependency is set incorrectly
		msbuild .\lib\eventstream_static.vcxproj /m /p:"configuration=$buildconfig;platform=x64"  *>> $Log
		msbuild .\eventstream.sln /m /p:"configuration=$buildconfig;platform=x64" *>> $Log
		Write-Host -NoNewline "installing..."
		msbuild .\INSTALL.vcxproj /m /p:"configuration=$buildconfig;platform=x64;BuildProjectReferences=false" *>> $Log
		# copy the examples across
		New-Item -Force -ItemType Directory $root/src-stage3/staged_install/$configuration/share/gnuradio/examples/gr-eventstream *>> $Log
		cp -Recurse -Force $root/src-stage3/oot_code/gr-eventstream/examples/*.grc $root/src-stage3/staged_install/$configuration/share/gnuradio/examples/gr-eventstream *>> $Log
		cp -Recurse -Force $root/src-stage3/oot_code/gr-eventstream/apps/*.grc $root/src-stage3/staged_install/$configuration/share/gnuradio/examples/gr-eventstream *>> $Log
		cp -Recurse -Force $root/src-stage3/oot_code/gr-eventstream/apps/*.py $root/src-stage3/staged_install/$configuration/share/gnuradio/examples/gr-eventstream *>> $Log
		$env:_CL_ = ""
		$env:_LINK_ = ""
		Validate "$root/src-stage3/staged_install/$configuration/bin/eventstream.dll" "$root\src-stage3\staged_install\$configuration\lib\site-packages\es\_es_swig.pyd"
	}

	# ____________________________________________________________________________________________________________
	#
	# gr-burst
	#
	#
	SetLog "gr-burst $configuration"
	Write-Host -NoNewline "configuring $configuration gr-burst..."
	New-Item -Force -ItemType Directory $root/src-stage3/oot_code/gr-burst/build/$configuration *>> $Log
	cd $root/src-stage3/oot_code/gr-burst/build/$configuration
	$env:_CL_ = " $arch ";
	$env:_LINK_= " /DEBUG:FULL $root/src-stage3/staged_install/$configuration/lib/gnuradio-pmt.lib $root/src-stage3/staged_install/$configuration/lib/gnuradio-fft.lib "
	$ErrorActionPreference = "Continue"
	$env:Path="" 
	& cmake ../../ `
		-G "Visual Studio 14 2015 Win64" `
		-DCMAKE_PREFIX_PATH="$root\build\$configuration" `
		-DCMAKE_INSTALL_PREFIX="$root/src-stage3/staged_install/$configuration" `
		-DGNURADIO_RUNTIME_LIBRARIES="$root/src-stage3/staged_install/$configuration/lib/gnuradio-runtime.lib" `
		-DGNURADIO_RUNTIME_INCLUDE_DIRS="$root/src-stage3/staged_install/$configuration/include" `
		-DBOOST_LIBRARYDIR="$root/build/$configuration/lib" `
		-DBOOST_INCLUDEDIR="$root/build/$configuration/include" `
		-DBOOST_ROOT="$root/build/$configuration/" `
		-DPYTHON_LIBRARY="$root/src-stage3/staged_install/$configuration/gr-python27/libs/python27.lib" `
		-DPYTHON_LIBRARY_DEBUG="$root/src-stage3/staged_install/$configuration/gr-python27/libs/python27_d.lib" `
		-DPYTHON_EXECUTABLE="$root/src-stage3/staged_install/$configuration/gr-python27/$pythonexe" `
		-DPYTHON_INCLUDE_DIR="$root/src-stage3/staged_install/$configuration/gr-python27/include" `
		-DSWIG_EXECUTABLE="$root/bin/swig.exe" `
		-DCMAKE_CXX_FLAGS="/D_USE_MATH_DEFINES /D_TIMESPEC_DEFINED /EHsc  /DNOMINMAX  /Zi $arch $runtime " `
		-DCMAKE_C_FLAGS="/D_USE_MATH_DEFINES /D_TIMESPEC_DEFINED /DNOMINMAX /Zi $arch $runtime " `
		-Wno-dev *>> $Log
	$env:Path = $oldPath
	Write-Host -NoNewline "building gr-burst..."
	msbuild .\gr-burst.sln /m /p:"configuration=$buildconfig;platform=x64" *>> $Log
	Write-Host -NoNewline "installing..."
	msbuild .\INSTALL.vcxproj /m /p:"configuration=$buildconfig;platform=x64;BuildProjectReferences=false" *>> $Log
	# copy the examples across
	New-Item -Force -ItemType Directory $root/src-stage3/staged_install/$configuration/share/gnuradio/examples/gr-burst *>> $Log
	cp -Recurse -Force $root/src-stage3/oot_code/gr-burst/examples/*.grc $root/src-stage3/staged_install/$configuration/share/gnuradio/examples/gr-burst *>> $Log
	$env:_CL_ = ""
	$env:_LINK_ = ""
	Validate "$root/src-stage3/staged_install/$configuration/bin/gnuradio-burst.dll" "$root\src-stage3\staged_install\$configuration\lib\site-packages\burst\_burst_swig.pyd"

	# ____________________________________________________________________________________________________________
	#
	# gr-lte
	#
	#
	if ($mm -eq "3.8") {
		Write-Host "gr-lte not gr3.8 compatible"
	} else {
		SetLog "gr-lte $configuration"
		$ErrorActionPreference = "Continue"
		Write-Host -NoNewline "configuring $configuration gr-lte..."
		New-Item -ItemType Directory -Force -Path $root/src-stage3/oot_code/gr-lte/build/$configuration  *>> $Log
		cd $root/src-stage3/oot_code/gr-lte/build/$configuration 
		$env:_LINK_= " $root/src-stage3/staged_install/$configuration/lib/gnuradio-pmt.lib $root/src-stage3/staged_install/$configuration/lib/volk.lib /DEBUG /NODEFAULTLIB:m.lib "
		$env:_CL_ = " $arch -D_USE_MATH_DEFINES -I""$root/src-stage3/staged_install/$configuration/include""  -I""$root/src-stage3/staged_install/$configuration/include/swig"" "
		$env:Path="" 
		cmake ../../ `
			-G "Visual Studio 14 2015 Win64" `
			-DGNURADIO_RUNTIME_LIBRARIES="$root/src-stage3/staged_install/$configuration/lib/gnuradio-runtime.lib" `
			-DGNURADIO_RUNTIME_INCLUDE_DIRS="$root/src-stage3/staged_install/$configuration/include" `
			-DCMAKE_CXX_FLAGS="/D_USE_MATH_DEFINES /D_TIMESPEC_DEFINED /EHsc /DNOMINMAX $arch $runtime  /DWIN32 /D_WINDOWS /W3 /I""$root/src-stage3/staged_install/$configuration"" " `
			-DCMAKE_C_FLAGS="/D_USE_MATH_DEFINES /D_TIMESPEC_DEFINED /DNOMINMAX $arch $runtime  /DWIN32 /D_WINDOWS /W3 /I""$root/src-stage3/staged_install/$configuration"" " `
			-DPYTHON_EXECUTABLE="$root/src-stage3/staged_install/$configuration/gr-python27/$pythonexe" `
			-DCMAKE_INSTALL_PREFIX="$root/src-stage3/staged_install/$configuration" `
			-DBOOST_LIBRARYDIR=" $root/build/$configuration/lib" `
			-DBOOST_INCLUDEDIR="$root/build/$configuration/include" `
			-DBOOST_ROOT="$root/build/$configuration/" `
			-DPYTHON_LIBRARY="$root/src-stage3/staged_install/$configuration/gr-python27/libs/python27.lib" `
			-DPYTHON_LIBRARY_DEBUG="$root/src-stage3/staged_install/$configuration/gr-python27/libs/python27_d.lib" `
			-DPYTHON_INCLUDE_DIR="$root/src-stage3/staged_install/$configuration/gr-python27/include" `
			-DFFTW3F_LIBRARIES="$root/build/Release/lib/libfftw3f.lib" `
			-DFFTW3F_INCLUDE_DIRS="$root/build/Release/include/" `
			-DCPPUNIT_LIBRARIES="$root/build/$configuration/lib/cppunit.lib" `
			-DCPPUNIT_INCLUDE_DIRS="$root/build/$configuration/include" `
			-DSWIG_EXECUTABLE="$root/bin/swig.exe" `
			-Wno-dev *>> $Log
		$env:Path = $oldPath
		Write-Host -NoNewline "building gr-lte..."
		msbuild .\gr-lte.sln /m /p:"configuration=$buildconfig;platform=x64" *>> $Log
		Write-Host -NoNewline "installing..."
		msbuild .\INSTALL.vcxproj /m /p:"configuration=$buildconfig;platform=x64;BuildProjectReferences=false" *>> $Log
		# copy the examples across
		New-Item -Force -ItemType Directory $root/src-stage3/staged_install/$configuration/share/gnuradio/examples/gr-lte *>> $Log
		cp -Recurse -Force $root/src-stage3/oot_code/gr-lte/examples/*.grc $root/src-stage3/staged_install/$configuration/share/gnuradio/examples/gr-lte *>> $Log
		cp -Recurse -Force $root/src-stage3/oot_code/gr-lte/examples/*.py $root/src-stage3/staged_install/$configuration/share/gnuradio/examples/gr-lte *>> $Log
		cp -Recurse -Force $root/src-stage3/oot_code/gr-lte/examples/hier_blocks $root/src-stage3/staged_install/$configuration/share/gnuradio/examples/gr-lte *>> $Log
		# TODO we could call the routine in the examples folder to automatically build the hier blocks.
		$env:_CL_ = ""
		$env:_LINK_ = ""
		$ErrorActionPreference = "Stop"
		Validate "$root/src-stage3/staged_install/$configuration/bin/gnuradio-lte.dll" "$root\src-stage3\staged_install\$configuration\lib\site-packages\lte\_lte_swig.pyd"
	}

	# ____________________________________________________________________________________________________________
	#
	# gr-gsm
	#
	SetLog "gr-gsm $configuration"
	$ErrorActionPreference = "Continue"
	Write-Host -NoNewline "configuring $configuration gr-gsm..."
	New-Item -ItemType Directory -Force -Path $root/src-stage3/oot_code/gr-gsm/build/$configuration  *>> $Log
	cd $root/src-stage3/oot_code/gr-gsm/build/$configuration 
	$env:_CL_ = " $arch "
	$env:_LINK_= " $root/src-stage3/staged_install/$configuration/lib/gnuradio-pmt.lib /DEBUG /NODEFAULTLIB:m.lib "
	$env:_CL_ = " -D_USE_MATH_DEFINES -I""$root/src-stage3/staged_install/$configuration/include""  -I""$root/src-stage3/staged_install/$configuration/include/swig"" "
	$env:Path = ""
	cmake ../../ `
		-G "Visual Studio 14 2015 Win64" `
		-DGNURADIO_RUNTIME_LIBRARIES="$root/src-stage3/staged_install/$configuration/lib/gnuradio-runtime.lib" `
		-DGNURADIO_RUNTIME_INCLUDE_DIRS="$root/src-stage3/staged_install/$configuration/include" `
		-DCPPUNIT_LIBRARIES="$root/build/$configuration/lib/cppunit.lib" `
		-DCPPUNIT_INCLUDE_DIRS="$root/build/$configuration/include" `
		-DCMAKE_CXX_FLAGS="/D_USE_MATH_DEFINES /D_TIMESPEC_DEFINED /EHsc  /DNOMINMAX  /Zi $arch $runtime  " `
		-DCMAKE_C_FLAGS="/D_USE_MATH_DEFINES /D_TIMESPEC_DEFINED $arch $runtime  /DWIN32 /D_WINDOWS /W3 /I""$root/src-stage3/staged_install/$configuration"" " `
		-DPYTHON_LIBRARY="$root/src-stage3/staged_install/$configuration/gr-python27/libs/python27.lib" `
		-DPYTHON_LIBRARY_DEBUG="$root/src-stage3/staged_install/$configuration/gr-python27/libs/python27_d.lib" `
		-DPYTHON_EXECUTABLE="$root/src-stage3/staged_install/$configuration/gr-python27/$pythonexe" `
		-DPYTHON_INCLUDE_DIR="$root/src-stage3/staged_install/$configuration/gr-python27/include" `
		-DBOOST_LIBRARYDIR=" $root/build/$configuration/lib" `
		-DBOOST_INCLUDEDIR="$root/build/$configuration/include" `
		-DBOOST_ROOT="$root/build/$configuration/" `
		-DSWIG_EXECUTABLE="$root/bin/swig.exe" `
		-DCMAKE_INSTALL_PREFIX="$root/src-stage3/staged_install/$configuration" `
		-Wno-dev *>> $Log
	$env:Path = $oldPath
	Write-Host -NoNewline "building gr-gsm..."
	msbuild .\gr-gsm.sln /m /p:"configuration=$buildconfig;platform=x64" *>> $Log
	Write-Host -NoNewline "installing..."
	msbuild .\INSTALL.vcxproj /m /p:"configuration=$buildconfig;platform=x64;BuildProjectReferences=false" *>> $Log
	$env:_CL_ = ""
	$env:_LINK_ = ""
	$ErrorActionPreference = "Stop"
	"complete"


	# ___________________________________STILL IN WORK____________________________________________________________
	# ____________________________________________________________________________________________________________
	# ____________________________________________________________________________________________________________
	

	#
	# gflags
	#
	# Required by GNSS-SDR / glog
	# note use of non-standard build_folder location because repo already has a file named "BUILD"
	#
	SetLog "gflags $configuration"
	$ErrorActionPreference = "Continue"
	Write-Host -NoNewline "configuring $configuration gflags..."
	New-Item -ItemType Directory -Force -Path $root/src-stage3/oot_code/gflags/build_folder/$configuration  *>> $Log
	cd $root/src-stage3/oot_code/gflags/build_folder/$configuration 
	$env:_CL_ = $arch + " -D_USE_MATH_DEFINES -I""$root/src-stage3/staged_install/$configuration/include""  -I""$root/src-stage3/staged_install/$configuration/include/swig"" "
	$env:_LINK_= " $root/src-stage3/staged_install/$configuration/lib/gnuradio-pmt.lib /DEBUG /NODEFAULTLIB:m.lib "
	cmake ../../ `
		-G "Visual Studio 14 2015 Win64" `
		-DCMAKE_PREFIX_PATH="$root\build\$configuration" `
		-DCMAKE_INSTALL_PREFIX="$root\build\$configuration" `
		-DCMAKE_SYSTEM_LIBRARY_PATH="$root\build\$configuration\lib" `
		-DCMAKE_C_FLAGS="/D_USE_MATH_DEFINES /D_TIMESPEC_DEFINED $arch $runtime  /DWIN32 /D_WINDOWS /W3 /I""$root/src-stage3/staged_install/$configuration"" " `
		-Wno-dev *>> $Log
	Write-Host -NoNewline "building gflags..."
	msbuild .\gflags.sln /m /p:"configuration=$buildconfig;platform=x64" *>> $Log
	Write-Host -NoNewline "installing..."
	msbuild .\INSTALL.vcxproj /m /p:"configuration=$buildconfig;platform=x64;BuildProjectReferences=false" *>> $Log
	$env:_CL_ = ""
	$env:_LINK_ = ""
	$ErrorActionPreference = "Stop"
	"complete"

	# ____________________________________________________________________________________________________________
	#
	# glog (Google logging)
	#
	# Required by GNSS-SDR
	#
	SetLog "glog $configuration"
	$ErrorActionPreference = "Continue"
	Write-Host -NoNewline "configuring $configuration glog..."
	New-Item -ItemType Directory -Force -Path $root/src-stage3/oot_code/glog/build/$configuration  *>> $Log
	cd $root/src-stage3/oot_code/glog/build/$configuration 
	$env:_CL_ = " $arch "
	$env:_LINK_= " $root/src-stage3/staged_install/$configuration/lib/gnuradio-pmt.lib /DEBUG /NODEFAULTLIB:m.lib "
	$env:_CL_ = $env:_CL_ + " -D_USE_MATH_DEFINES -I""$root/src-stage3/staged_install/$configuration/include""  -I""$root/src-stage3/staged_install/$configuration/include/swig"" "
	cmake ../../ `
		-G "Visual Studio 14 2015 Win64" `
		-DCMAKE_PREFIX_PATH="$root\build\$configuration" `
		-DCMAKE_INSTALL_PREFIX="$root\build\$configuration" `
		-DCMAKE_SYSTEM_LIBRARY_PATH="$root\build\$configuration\lib" `
		-DCMAKE_C_FLAGS="/D_USE_MATH_DEFINES /D_TIMESPEC_DEFINED $arch $runtime  /DWIN32 /D_WINDOWS /W3 /I""$root/src-stage3/staged_install/$configuration"" " `
		-Wno-dev *>> $Log
	Write-Host -NoNewline "building glog..."
	msbuild .\google-glog.sln /m /p:"configuration=$buildconfig;platform=x64" *>> $Log
	Write-Host -NoNewline "installing..."
	msbuild .\INSTALL.vcxproj /m /p:"configuration=$buildconfig;platform=x64;BuildProjectReferences=false" *>> $Log
	$env:_CL_ = ""
	$env:_LINK_ = ""
	$ErrorActionPreference = "Stop"
	"complete"


	# the below are OOT modules that I would like to include but for various reasons are not able to run in windows
	# There is hope for all of them though and they are at vary levels of maturity.
	# Some will configure, some will build/install.  But none are currently working 100% so we'll exclude them from the .msi
	# but keep this code here so tinkerers have a place to start.
	if ($false) 
	{

		# ____________________________________________________________________________________________________________
		#
		# OpenLTE
		#
		# RENAME pthreadVC2 to pthread
		#
		SetLog "OpenLTE $configuration"
		Write-Host -NoNewline "configuring $configuration OpenLTE..."
		New-Item -Force -ItemType Directory $root/src-stage3/oot_code/OpenLTE_v$openLTE_version/build/$configuration *>> $Log
		cd $root/src-stage3/oot_code/OpenLTE_v$openLTE_version/build/$configuration
		$env:_CL_ = " $arch ";
		$env:_LINK_= " /DEBUG:FULL $root/src-stage3/staged_install/$configuration/lib/gnuradio-pmt.lib "
		$ErrorActionPreference = "Continue"
		$env:Path = ""
		& cmake ../../ `
			-G "Visual Studio 14 2015 Win64" `
			-DCMAKE_PREFIX_PATH="$root\build\$configuration" `
			-DCMAKE_INSTALL_PREFIX="$root/src-stage3/staged_install/$configuration" `
			-DGNURADIO_RUNTIME_LIBRARIES="$root/src-stage3/staged_install/$configuration/lib/gnuradio-runtime.lib" `
			-DGNURADIO_RUNTIME_INCLUDE_DIRS="$root/src-stage3/staged_install/$configuration/include" `
			-DBOOST_LIBRARYDIR="$root/build/$configuration/lib" `
			-DBOOST_INCLUDEDIR="$root/build/$configuration/include" `
			-DBOOST_ROOT="$root/build/$configuration/" `
			-DPYTHON_LIBRARY="$root/src-stage3/staged_install/$configuration/gr-python27/libs/python27.lib" `
			-DPYTHON_LIBRARY_DEBUG="$root/src-stage3/staged_install/$configuration/gr-python27/libs/python27_d.lib" `
			-DPYTHON_EXECUTABLE="$root/src-stage3/staged_install/$configuration/gr-python27/$pythonexe" `
			-DPYTHON_INCLUDE_DIR="$root/src-stage3/staged_install/$configuration/gr-python27/include" `
			-DSWIG_EXECUTABLE="$root/bin/swig.exe" `
			-DCMAKE_CXX_FLAGS="/D_USE_MATH_DEFINES /D_TIMESPEC_DEFINED /EHsc  /DNOMINMAX  /Zi $arch $runtime  " `
			-DCMAKE_C_FLAGS="/D_USE_MATH_DEFINES /D_TIMESPEC_DEFINED /DNOMINMAX /Zi $arch $runtime  " `
			-DFFTW3F_LIBRARIES="$root/build/$configuration/lib/libfftw3f.lib" `
			-DFFTW3F_INCLUDE_DIRS="$root/build/$configuration/include/" `
			-Wno-dev *>> $Log
		$env:Path = $oldPath
		Write-Host -NoNewline "building OpenLTE..."
		msbuild .\openLTE.sln /m /p:"configuration=$buildconfig;platform=x64" *>> $Log
		Write-Host -NoNewline "installing..."
		msbuild .\INSTALL.vcxproj /m /p:"configuration=$buildconfig;platform=x64;BuildProjectReferences=false" *>> $Log
		# copy the examples across
		New-Item -Force -ItemType Directory $root/src-stage3/staged_install/$configuration/share/gnuradio/examples/gr-nacl *>> $Log
		cp -Recurse -Force $root/src-stage3/oot_code/gr-nacl/examples/*.grc $root/src-stage3/staged_install/$configuration/share/gnuradio/examples/gr-nacl *>> $Log
		cp -Recurse -Force $root/src-stage3/oot_code/gr-nacl/examples/*.file $root/src-stage3/staged_install/$configuration/share/gnuradio/examples/gr-nacl *>> $Log
		$env:_CL_ = ""
		$env:_LINK_ = ""
		$env:FFTW3_DIR = ""
	
	    # ____________________________________________________________________________________________________________
	    #
	    # GNSS-SDR
	    #
	    # NOT WORKING
	    #
	    # This is going to take significant recoding to get it to be cross-platform compatible
	    #
	    SetLog "gnss-sdr $configuration"
	    Write-Host -NoNewline "configuring $configuration gnss-sdr..."
	    New-Item -Force -ItemType Directory $root/src-stage3/oot_code/gnss-sdr/build/$configuration *>> $Log
	    cd $root/src-stage3/oot_code/gnss-sdr/build/$configuration
	    $ErrorActionPreference = "Continue"
		$env:_CL_ = " -DGLOG_NO_ABBREVIATED_SEVERITIES "
	    & cmake ../../ `
		    -G "Visual Studio 14 2015 Win64" `
		    -DCMAKE_PREFIX_PATH="$root\build\$configuration" `
		    -DCMAKE_INSTALL_PREFIX="$root/src-stage3/staged_install/$configuration" `
			-DGNURADIO_INSTALL_PREFIX="$root/src-stage3/staged_install/$configuration" `
		    -DGNUTLS_LIBRARY="../../../gnutls/lib/libgnutls.la" `
		    -DGNUTLS_INCLUDE_DIR="../../../gnutls/include" `
		    -DGNUTLS_OPENSSL_LIBRARY="../../../gnutls/lib/libgnutls.la" `
		    -DBOOST_LIBRARYDIR="$root/build/$configuration/lib" `
		    -DBOOST_INCLUDEDIR="$root/build/$configuration/include" `
		    -DBOOST_ROOT="$root/build/$configuration/" `
		    -DENABLE_OSMOSDR="ON" `
			-DGFlags_ROOT="$root/build/$configuration/" `
			-DGLOG_ROOT="$root/build/$configuration/" `
			-DCMAKE_CXX_FLAGS=" /DGLOG_NO_ABBREVIATED_SEVERITIES /DNOMINMAX" `
		    -DLAPACK="ON" `
			-DPYTHON_EXECUTABLE="$root/src-stage3/staged_install/$configuration/gr-python27/$pythonexe" `
			-Wno-dev *>> $Log
	    Write-Host -NoNewline "building..."
	    msbuild .\gnss-sdr.sln /m /p:"configuration=$buildconfig;platform=x64" *>> $Log
	    Write-Host -NoNewline "installing..."
	    msbuild .\INSTALL.vcxproj /m /p:"configuration=$buildconfig;platform=x64;BuildProjectReferences=false" *>> $Log
		$env:_CL_ = ""
	    "complete"
    }

	#the swig libraries aren't properly named for the debug build, so do it here
	if ($configuration -match "Debug") {
		pushd $root/src-stage3/staged_install/$configuration
		Get-ChildItem -Filter "*_swig.pyd" -Recurse | Move-Item -Force -Destination {$_.FullName -replace "_swig","_swig_d" } 
		Get-ChildItem -Filter "*_swig0.pyd" -Recurse | Move-Item -Force -Destination {$_.FullName -replace "_swig0","_swig0_d" } 
		Get-ChildItem -Filter "*_swig1.pyd" -Recurse | Move-Item -Force -Destination {$_.FullName -replace "_swig1","_swig1_d" } 
		Get-ChildItem -Filter "*_swig2.pyd" -Recurse | Move-Item -Force -Destination {$_.FullName -replace "_swig2","_swig2_d" } 
		Get-ChildItem -Filter "*_swig3.pyd" -Recurse | Move-Item -Force -Destination {$_.FullName -replace "_swig3","_swig3_d" } 
		Get-ChildItem -Filter "*_swig4.pyd" -Recurse | Move-Item -Force -Destination {$_.FullName -replace "_swig4","_swig4_d" } 
		Get-ChildItem -Filter "*_swig5.pyd" -Recurse | Move-Item -Force -Destination {$_.FullName -replace "_swig5","_swig5_d" } 
		popd
	}
}

# build options
if ($configmode -eq "1" -or $configmode -eq "all") {BuildDrivers "Release"; BuildOOTModules "Release"}
if ($configmode -eq "2" -or $configmode -eq "all") {BuildDrivers "Release-AVX2"; BuildOOTModules "Release-AVX2"}
if ($configmode -eq "3" -or $configmode -eq "all") {BuildDrivers "Debug"; BuildOOTModules "Debug"}

cd $root/scripts 

""
"COMPLETED STEP 8: Selected OOT modules have been built from source and installed on top of the GNURadio installation(s)"
""

if ($false) 
{
	# debug shortcuts below

	$configuration = "Debug"
	$configuration = "Release"
	$configuration = "Release-AVX2"

	$root = "Z:/gr-build"

	ResetLog
}
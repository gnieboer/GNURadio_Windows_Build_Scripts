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
New-Item -ItemType Directory -Force -Path $root/build *>> $log

Function Consolidate {
	$configuration = $args[0]
	New-Item -ItemType Directory -Force -Path $root/build/$configuration *>> $log

	Write-Host ""
    Write-Host "Starting Consolidation for $configuration"
	# set up various variables we'll need
	if ($configuration -match "AVX2") {$platform = "avx2"} else {$platform = "x64"}
	if ($configuration -match "Debug") {$baseconfig = "Debug"} else {$baseconfig = "Release"}
	if ($configuration -match "AVX2") {$configDLL = "ReleaseDLL-AVX2"} else {$configDLL = $configuration + "DLL"}
	if ($configuration -match "Debug") {$d4 = "d4"} else {$d4 = "4"}
	if ($configuration -match "Debug") {$d5 = "d5"} else {$d5 = "5"}
	if ($configuration -match "Debug") {$d6 = "d6"} else {$d6 = "6"}
	if ($configuration -match "Debug") {$q5d = "d"} else {$q5d = ""}

	# move boost
	Write-Host -NoNewline "Consolidating Boost..."
	$boostbase = $boost_version_.substring(0,$boost_version_.length-2)
	if ($configuration -match "AVX2") {$platform = "avx2"} else {$platform = "x64"}
	if ($configuration -match "Debug") {$baseconfig = "Debug"} else {$baseconfig = "Release"}
	New-Item -ItemType Directory -Force -Path $root/build/$configuration/lib/ *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/boost/build/$platform/$baseconfig/lib/boost*.dll $root/build/$configuration/lib/ *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/boost/build/$platform/$baseconfig/lib/boost*.lib $root/build/$configuration/lib/ *>> $log
	# GNURadio uses shared libraries, but some OOT modules use static linking so we need both
	cp -Recurse -Force $root/src-stage1-dependencies/boost/build/$platform/$baseconfig/lib/libboost*.lib $root/build/$configuration/lib/ *>> $log
	robocopy "$root/src-stage1-dependencies/boost/build/$platform/$baseconfig/include/boost-$boostbase/" "$root/build/$configuration/include/" /e *>> $log
	# repeat for gqrx (or else we WILL get include directory conflicts with Qt4 headers)
	robocopy "$root/src-stage1-dependencies/boost/build/$platform/$baseconfig/include/boost-$boostbase/" "$root/build/$configuration/gqrx/include/" /e *>> $log
	"complete"

	# move Qt
	Write-Host -NoNewline "Consolidating Qt5..."
	New-Item -ItemType Directory -Force -Path $root/build/$configuration/src/corelib/global/ *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/Qt5Stage/build/$configDLL/bin $root/build/$configuration/ *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/Qt5Stage/build/$configDLL/lib/cmake $root/build/$configuration/lib/ *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/Qt5Stage/build/$configDLL/mkspecs $root/build/$configuration/ *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/Qt5Stage/build/$configDLL/plugins $root/build/$configuration/plugins/ *>> $log
	robocopy "$root/src-stage1-dependencies/Qt5Stage/build/$configDLL/qtbase/src/" "$root/build/$configuration/src/" "*.h" /s /xd ".moc" ".tracegen" *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/Qt5Stage/build/$configDLL/bin/Qt5Core$q5d.dll $root/build/$configuration/bin/ *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/Qt5Stage/build/$configDLL/bin/Qt5Gui$q5d.dll $root/build/$configuration/bin/ *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/Qt5Stage/build/$configDLL/bin/Qt5OpenGL$q5d.dll $root/build/$configuration/bin/ *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/Qt5Stage/build/$configDLL/bin/Qt5Svg$q5d.dll $root/build/$configuration/bin/ *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/Qt5Stage/build/$configDLL/bin/Qt5Network$q5d.dll $root/build/$configuration/bin/ *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/Qt5Stage/build/$configDLL/bin/Qt5Widgets$q5d.dll $root/build/$configuration/bin/ *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/Qt5Stage/build/$configDLL/lib/Qt5Core$q5d.lib $root/build/$configuration/lib/ *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/Qt5Stage/build/$configDLL/lib/Qt5Gui$q5d.lib $root/build/$configuration/lib/ *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/Qt5Stage/build/$configDLL/lib/Qt5OpenGL$q5d.lib $root/build/$configuration/lib/ *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/Qt5Stage/build/$configDLL/lib/Qt5Svg$q5d.lib $root/build/$configuration/lib/ *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/Qt5Stage/build/$configDLL/lib/Qt5Network$q5d.lib $root/build/$configuration/lib/ *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/Qt5Stage/build/$configDLL/lib/Qt5Widgets$q5d.lib $root/build/$configuration/lib/ *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/Qt5Stage/build/$configDLL/include/QtOpenGL* $root/build/$configuration/include/ *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/Qt5Stage/build/$configDLL/include/QtCore* $root/build/$configuration/include/ *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/Qt5Stage/build/$configDLL/include/QtGui* $root/build/$configuration/include/ *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/Qt5Stage/build/$configDLL/include/QtNetwork* $root/build/$configuration/include/ *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/Qt5Stage/build/$configDLL/include/QtSvg* $root/build/$configuration/include/ *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/Qt5Stage/build/$configDLL/include/QtWidgets* $root/build/$configuration/include/ *>> $log
	#needed by gqrx but not gnuradio itself 
	cp -Recurse -Force $root/src-stage1-dependencies/Qt5Build/build/$configDLL/qtbase/lib/qtmain$q5d.lib $root/build/$configuration/lib/ *>> $log
	# Fix a hardcoded mkspec file location
	((Get-Content -path $root/build/$configuration/lib/cmake/Qt5Core/Qt5CoreConfigExtrasMkspecDir.cmake -Raw) -Replace '\${_qt5Core_install_prefix}/../../../qtbase//mkspecs/win32-msvc',"$root/build/$configuration/mkspecs/win32-msvc") | % {$_ -Replace "\\", "/"} | Set-Content -Path $root/build/$configuration/lib/cmake/Qt5Core/Qt5CoreConfigExtrasMkspecDir.cmake
	# this will override the hardcoded install paths in qmake.exe and allow CMake to find it all when not building all deps from source
	"[Paths]" | out-file -FilePath $root/build/$configuration/bin/qt.conf -encoding ASCII
	"Prefix = $root/build/$configuration" | out-file -FilePath $root/build/$configuration/bin/qt.conf -encoding ASCII -append 
	"complete"
	

	# move Qwt 6
	# for now, move both sets of headers and if in case of conflict, use the qwt 6 ones
	# just move the shared DLLs, not the static libs
	Write-Host -NoNewline "Consolidating Qwt..."
	if ($configuration -match "AVX2") {$qwtdir = "Release-AVX2"} else {$qwtdir = "Debug-Release"}
	New-Item -ItemType Directory -Force -Path $root/build/$configuration/include/qwt6 *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/qwt-${qwt6_version}/build/x64/$configDLL/lib/qwt$d6.* $root/build/$configuration/lib/ *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/qwt-${qwt6_version}/build/x64/$configDLL/include/* $root/build/$configuration/include/qwt6/ *>> $log
	"complete"

	# move qwtplot3d
	Write-Host -NoNewline "Consolidating QwtPlot3D..."
	New-Item -ItemType Directory -Force -Path $root/build/$configuration/include/qwt3d *>> $log
	#cp -Recurse -Force $root/src-stage1-dependencies/Qwtplot3d/build/$configuration/qwtplot3d.lib $root/build/$configuration/lib/ *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/Qwtplot3d/build/$configuration/qwtplot3d.dll $root/build/$configuration/lib/ *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/Qwtplot3d/include/* $root/build/$configuration/include/qwt3d *>> $log
	"complete"

	# move SDL
	Write-Host -NoNewline "Consolidating SDL..."
	New-Item -ItemType Directory -Force -Path $root/build/$configuration/include/sdl *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/SDL-$sdl_version/VisualC/x64/$configuration/SDL.dll $root/build/$configuration/lib/ *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/SDL-$sdl_version/VisualC/x64/$configuration/SDL.lib $root/build/$configuration/lib/ *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/SDL-$sdl_version/VisualC/x64/$configuration/SDL.exp $root/build/$configuration/lib/ *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/SDL-$sdl_version/VisualC/x64/$configuration/SDL.pdb $root/build/$configuration/lib/ *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/SDL-$sdl_version/include/*.h $root/build/$configuration/include/sdl/ *>> $log
	"complete"

	# cppunit
	Write-Host -NoNewline "Consolidating cppunit..."
	cp -Recurse -Force $root/src-stage1-dependencies/cppunit-$cppunit_version/src/x64/$baseconfig/lib/cppunit.* $root/build/$configuration/lib/ *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/cppunit-$cppunit_version/include/cppunit $root/build/$configuration/include/ *>> $log
	"complete"

	# log4cpp
	Write-Host -NoNewline "Consolidating log4cpp..."
	New-Item -ItemType Directory -Force -Path $root/build/$configuration/include/log4cpp/threading *>> $log
	cp -Recurse -Force $root\src-stage1-dependencies\log4cpp\msvc14\x64\$baseconfig\log4cpp.dll $root/build/$configuration/lib/ *>> $log
	cp -Recurse -Force $root\src-stage1-dependencies\log4cpp\msvc14\x64\$baseconfig\log4cpp.lib $root/build/$configuration/lib/ *>> $log
	cp -Recurse -Force $root\src-stage1-dependencies\log4cpp\include\log4cpp\*.hh $root/build/$configuration/include/log4cpp/ *>> $log
	cp -Recurse -Force $root\src-stage1-dependencies\log4cpp\include\log4cpp\*.h $root/build/$configuration/include/log4cpp/ *>> $log
	cp -Recurse -Force $root\src-stage1-dependencies\log4cpp\include\log4cpp\threading\*.hh $root/build/$configuration/include/log4cpp/threading/ *>> $log
	"complete"

	# gsl
	Write-Host -NoNewline "Consolidating gsl..."
	New-Item -ItemType Directory -Force -Path $root/build/$configuration/include/gsl *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/gsl-$gsl_version/build.vc14/x64/$configuration/dll/* $root/build/$configuration/lib/ *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/gsl-$gsl_version/gsl/*.h $root/build/$configuration/include/gsl/ *>> $log
	"complete"

	# fftw3f
	Write-Host -NoNewline "Consolidating fftw3..."
	cp -Recurse -Force $root/src-stage1-dependencies/fftw-$fftw_version/msvc/x64/$configuration/libfftwf-3.3.lib $root/build/$configuration/lib/libfftw3f.lib *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/fftw-$fftw_version/api/fftw3.h $root/build/$configuration/include/ *>> $log
	"complete"

	# libsodium
	Write-Host -NoNewline "Consolidating libsodium..."
	New-Item -ItemType Directory -Force -Path $root/build/$configuration/include/sodium *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/libsodium/bin/x64/$baseconfig/v140/dynamic/* $root/build/$configuration/lib/ *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/libsodium/src/libsodium/include/sodium.h $root/build/$configuration/include/ *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/libsodium/src/libsodium/include/sodium/*.h $root/build/$configuration/include/sodium *>> $log
	"complete"

	# libzmq
	Write-Host -NoNewline "Consolidating libzmq..."
	if ((Test-Path $root/src-stage1-dependencies/libzmq/bin/$baseconfig) -eq $true) {
		#paths depend on whether the cmake version was used to build or not
		$libzmquv = $libzmq_version -Replace '\.','_'
		if ($baseconfig -eq "Debug") {
			cp -Recurse -Force $root/src-stage1-dependencies/libzmq/bin/$baseconfig/bin/libzmq-v140-mt-gd-$libzmquv.dll $root/build/$configuration/lib/ *>> $log	
			cp -Recurse -Force $root/src-stage1-dependencies/libzmq/bin/$baseconfig/lib/libzmq-v140-mt-gd-$libzmquv.lib $root/build/$configuration/lib/ *>> $log	
		} else {
			cp -Recurse -Force $root/src-stage1-dependencies/libzmq/bin/$baseconfig/bin/libzmq-v140-mt-$libzmquv.dll $root/build/$configuration/lib/ *>> $log	
			cp -Recurse -Force $root/src-stage1-dependencies/libzmq/bin/$baseconfig/lib/libzmq-v140-mt-$libzmquv.lib $root/build/$configuration/lib/ *>> $log			
		}
		cp -Recurse -Force $root/src-stage1-dependencies/libzmq/bin/$baseconfig/include/*.h $root/build/$configuration/include/ *>> $log
		cp -Recurse -Force $root/src-stage1-dependencies/cppzmq/*.hpp $root/build/$configuration/include/ *>> $log
	} else {
		cp -Recurse -Force $root/src-stage1-dependencies/libzmq/bin/x64/$baseconfig/v140/dynamic/libzmq.* $root/build/$configuration/lib/ *>> $log
		cp -Recurse -Force $root/src-stage1-dependencies/libzmq/include/*.h $root/build/$configuration/include/ *>> $log
		cp -Recurse -Force $root/src-stage1-dependencies/cppzmq/*.hpp $root/build/$configuration/include/ *>> $log
	}
	"complete"

	# uhd
	Write-Host -NoNewline "Consolidating UHD..."
	cp -Recurse -Force $root\src-stage1-dependencies\uhd/dist/$configuration/bin/uhd.dll $root/build/$configuration/lib/ *>> $log
	cp -Recurse -Force $root\src-stage1-dependencies\uhd/dist/$configuration/lib/uhd.lib $root/build/$configuration/lib/ *>> $log
	cp -Recurse -Force $root\src-stage1-dependencies\uhd/dist/$configuration/include/* $root/build/$configuration/include/ *>> $log
	robocopy "$root/src-stage1-dependencies/uhd/dist/$configuration" "$root/build/$configuration/uhd" /e *>> $log
	"complete"

	# portaudio
	Write-Host -NoNewline "Consolidating portaudio..."
	if ($configuration -match "AVX2") {$paconfig = "Release-Static-AVX2"} else ` {
	if ($configuration -match "Debug") {$paconfig = "Debug-Static"} else {$paconfig = "Release-Static"}}
	cp -Recurse -Force $root/src-stage1-dependencies/portaudio/build/msvc/x64/$paconfig/portaudio.* $root/build/$configuration/lib/ *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/portaudio/include/portaudio.h $root/build/$configuration/include/ *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/portaudio/include/pa_win_*.h $root/build/$configuration/include/ *>> $log
	"complete"

	# libusb
	Write-Host -NoNewline "Consolidating libusb..."
	New-Item -ItemType Directory -Path $root/build/$configuration/MS64/dll/  -Force  *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/libusb/x64/$configuration/dll/libusb-1.0.dll $root/build/$configuration/MS64/dll/ *>> $log # purely so bladeRF will build as is
	cp -Recurse -Force $root/src-stage1-dependencies/libusb/x64/$configuration/dll/libusb-1.0.lib $root/build/$configuration/lib/ *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/libusb/x64/$configuration/dll/libusb-1.0.dll $root/build/$configuration/lib/ *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/libusb/libusb/libusb.h $root/build/$configuration/include/ *>> $log
	"complete"

	# pthreads
	Write-Host -NoNewline "Consolidating pthreads..."
	New-Item -ItemType Directory -Path $root/build/$configuration/dll/x64/  -Force  *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/pthreads/pthreads.2/x64/$configDLL/pthreadVC2.dll $root/build/$configuration/dll/x64/ *>> $log # purely so bladeRF will build as is
	cp -Recurse -Force $root/src-stage1-dependencies/pthreads/pthreads.2/x64/$configuration/pthreadVC2.lib $root/build/$configuration/lib/ *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/pthreads/pthreads.2/COPYING.lib $root/build/$configuration/ *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/pthreads/pthreads.2/pthread.h $root/build/$configuration/include/ *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/pthreads/pthreads.2/semaphore.h $root/build/$configuration/include/ *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/pthreads/pthreads.2/sched.h $root/build/$configuration/include/ *>> $log
	"complete"

	# gtk
	Write-Host -NoNewline "Consolidating gtk..."
	cp -Recurse -Force $root/src-stage1-dependencies/x64/bin/gsettings.exe $root/build/$configuration/bin/ *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/x64/bin/gtk-3-3.0.dll $root/build/$configuration/lib/ *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/x64/bin/gdk-3-3.0.dll $root/build/$configuration/lib/ *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/x64/bin/pangocairo-1.0-0.dll $root/build/$configuration/lib/ *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/x64/bin/pangowin32-1.0-0.dll $root/build/$configuration/lib/ *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/x64/bin/pangoft2-1.0-0.dll $root/build/$configuration/lib/ *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/x64/bin/pango-1.0-0.dll $root/build/$configuration/lib/ *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/x64/bin/fribidi-0.dll $root/build/$configuration/lib/ *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/x64/bin/freetype.dll $root/build/$configuration/lib/ *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/x64/bin/girepository-1.0-1.dll $root/build/$configuration/lib/ *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/x64/bin/gdk_pixbuf-2.0-0.dll $root/build/$configuration/lib/ *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/x64/bin/cairo.dll $root/build/$configuration/lib/ *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/x64/bin/cairo-gobject.dll $root/build/$configuration/lib/ *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/x64/bin/epoxy-0.dll $root/build/$configuration/lib/ *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/x64/bin/atk-1.0-0.dll $root/build/$configuration/lib/ *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/x64/lib/harfbuzz.lib $root/build/$configuration/lib/ *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/x64/bin/gio-2.0-0.dll $root/build/$configuration/lib/ *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/x64/bin/gobject-2.0-0.dll $root/build/$configuration/lib/ *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/x64/bin/gmodule-2.0-0.dll $root/build/$configuration/lib/ *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/x64/bin/gthread-2.0-0.dll $root/build/$configuration/lib/ *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/x64/bin/glib-2.0-0.dll $root/build/$configuration/lib/ *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/x64/bin/intl.dll $root/build/$configuration/lib/ *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/x64/bin/fontconfig.dll $root/build/$configuration/lib/ *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/x64/lib/pixman-1.lib $root/build/$configuration/lib/ *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/x64/bin/libxml2.dll $root/build/$configuration/lib/ *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/x64/bin/libpng16.dll $root/build/$configuration/lib/ *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/x64/bin/iconv.dll $root/build/$configuration/lib/ *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/x64/bin/zlib1.dll $root/build/$configuration/lib/ *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/x64/bin/ffi-7.dll $root/build/$configuration/lib/ *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/x64/lib/freetype.lib $root/build/$configuration/lib/ *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/x64/include/freetype2/freetype $root/build/$configuration/include/ *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/x64/include/freetype2/ft2build.h $root/build/$configuration/include/  *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/x64/share/glib-2.0 $root/build/$configuration/share/ *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/x64/share/gir-1.0 $root/build/$configuration/share/ *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/x64/lib/gdk-pixbuf-2.0 $root/build/$configuration/lib/ *>> $log 
	cp -Recurse -Force $root/src-stage1-dependencies/x64/lib/girepository-1.0 $root/build/$configuration/lib/ *>> $log
	cp -Recurse -Force $root/src-stage1-dependencies/x64/lib/gobject-introspection $root/build/$configuration/lib/ *>> $log
	"complete"

	#polarssl / mbedTLS
	Write-Host -NoNewline "Consolidating polarSSL..."
	cp -Recurse -Force $root/src-stage1-dependencies/mbedTLS-mbedtls-$mbedTLS_version/dist/$configuration/lib/*.lib $root/build/$configuration/lib/ *>> $log
	cp -Recurse -Force $root\src-stage1-dependencies\mbedTLS-mbedtls-$mbedTLS_version/dist/$configuration/include/* $root/build/$configuration/include/ *>> $log
	"complete"
	
	#lapack / openblas
    if ($hasIFORT) {
	    Write-Host -NoNewline "Consolidating openBLAS + LAPACK..."
	    cp -Recurse -Force $root/src-stage1-dependencies/lapack/dist/$configuration/lib/*.lib $root/build/$configuration/lib/ *>> $log
	    if ($BuildNumpyWithMKL)
	    {
		    # gr-specest and Armadillo use blas and lapack and could link to MKL, but for the moment they only link to OpenBLAS so we need this.
		    cp -Recurse -Force $root/src-stage1-dependencies/OpenBLAS-$openblas_version/build/$configuration/lib/libopenblas_static.lib $root/build/$configuration/lib/ *>> $log
	    } else {
		    cp -Recurse -Force $root/src-stage1-dependencies/OpenBLAS-$openblas_version/build/$configuration/lib/libopenblas_static.lib $root/build/$configuration/lib/ *>> $log
	    }
	    "complete"
    }
	
	# MPIR
	#
	# GNURadio will want to link statically
	#
	Write-Host -NoNewline "Consolidating MPIR..."
	cp -Recurse -Force $root\src-stage1-dependencies\MPIR\lib\x64\$baseconfig\mpirxx.lib $root/build/$configuration/lib/ *>> $log
	cp -Recurse -Force $root\src-stage1-dependencies\MPIR\lib\x64\$baseconfig\mpir.lib $root/build/$configuration/lib/ *>> $log
	cp -Recurse -Force $root\src-stage1-dependencies\MPIR\lib\x64\$baseconfig\mpir.h $root/build/$configuration/include/ *>> $log
	cp -Recurse -Force $root\src-stage1-dependencies\MPIR\lib\x64\$baseconfig\mpirxx.h $root/build/$configuration/include/ *>> $log
	cp -Recurse -Force $root\src-stage1-dependencies\MPIR\lib\x64\$baseconfig\gmpxx.h $root/build/$configuration/include/ *>> $log
	cp -Recurse -Force $root\src-stage1-dependencies\MPIR\lib\x64\$baseconfig\gmp.h $root/build/$configuration/include/ *>> $log
	"complete"
	
	CheckNoAVX "$root/build/$configuration"

	"complete"
}

Consolidate "Release"

popd

""
"COMPLETED STEP 5: Libraries have been consolidated for easy CMake referencing to build GNURadio and OOT modules"
""

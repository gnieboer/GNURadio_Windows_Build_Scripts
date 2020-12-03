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

$mm = GetMajorMinor($gnuradio_version)

# Retrieve packages needed for Stage 1
cd $root/src-stage1-dependencies
SetLog "GetPackages"

# libzmq
getPackage https://github.com/zeromq/libzmq.git -branch "v$libzmq_version"
getPackage https://github.com/zeromq/cppzmq.git -branch "v$cppzmq_version"

# libpng
getPackage ftp://ftp.simplesystems.org/pub/libpng/png/src/libpng16/libpng-$png_version.tar.xz libpng
getPatch libpng-1.6.21-vs2015.7z libpng\projects\vstudio-vs2015

# gettext
GetPackage https://github.com/gnieboer/gettext-msvc.git
GetPackage http://ftp.gnu.org/gnu/gettext/gettext-0.19.4.tar.gz
GetPackage http://ftp.gnu.org/gnu/libiconv/libiconv-1.14.tar.gz
cd $root/src-stage1-dependencies
cp gettext-0.19.4\* .\gettext-msvc\gettext-0.19.4 -Force -Recurse
cp libiconv-1.14\* .\gettext-msvc\libiconv-1.14 -Force -Recurse
del .\libiconv-1.14 -Force -Recurse
del .\gettext-0.19.4 -Force -Recurse

# libxml2 
GetPackage https://github.com/GNOME/libxml2.git -branch "v$libxml2_version"

# GTK 3
GetPackage http://www.gcndevelopment.com/gnuradio/downloads/sources/gtk3-x64.7z
GetPatch pkgconfig.7z x64/lib/pkgconfig

# pygobject
GetPackage https://gitlab.gnome.org/GNOME/pygobject/-/archive/$pygobject3_version/pygobject-$pygobject3_version.zip

# SDL
getPackage  https://libsdl.org/release/SDL-$sdl_version.zip
getPatch sdl-$sdl_version-vs2015.7z SDL-$sdl_version\VisualC

# portaudio v19
GetPackage http://portaudio.com/archives/pa_stable_v19_20140130.tgz
GetPatch portaudio_vs2015.7z portaudio/build/msvc
# asio SDK for portaudio
GetPatch asiosdk2.3.7z portaudio/src/hostapi/asio

# cppunit 
GetPackage http://www.gcndevelopment.com/gnuradio/downloads/sources/cppunit-$cppunit_version.7z

# fftw
GetPackage http://www.gcndevelopment.com/gnuradio/downloads/sources/fftw-$fftw_version.7z

# python
GetPackage https://www.python.org/ftp/python/$python_version/python-$python_version-embed-amd64.zip python-$python_version -AddFolderName
GetPackage https://www.python.org/ftp/python/$python_version/python-$python_version-amd64.exe 

# zlib
# note: libpng is expecting zlib to be in a folder with the -1.2.8 version of the name
GetPackage https://github.com/gnieboer/zlib.git zlib-1.2.8

# libsodium
GetPackage https://github.com/gnieboer/libsodium.git 

# GSL
GetPackage http://www.gcndevelopment.com/gnuradio/downloads/sources/gsl-$gsl_version.7z
GetPatch gsl-$gsl_version.build.vc14.zip gsl-$gsl_version

# openssl
GetPackage ftp://ftp.openssl.org/source/old/1.0.2/openssl-$openssl_version.tar.gz openssl
GetPatch openssl-vs14.zip openssl
mkdir $root\src-stage1-dependencies\openssl\build\intermediate\x64\Debug -Force >> $Log 
mkdir $root\src-stage1-dependencies\openssl\build\intermediate\x64\Release -Force >> $Log 
mkdir $root\src-stage1-dependencies\openssl\build\intermediate\x64\DebugDLL -Force >> $Log 
mkdir $root\src-stage1-dependencies\openssl\build\intermediate\x64\ReleaseDLL -Force >> $Log 
mkdir $root\src-stage1-dependencies\openssl\build\intermediate\x64\Release-AVX2 -Force >> $Log 
mkdir $root\src-stage1-dependencies\openssl\build\intermediate\x64\ReleaseDLL-AVX2 -Force >> $Log 

# Qt
GetPackage https://github.com/qt/qt5.git -branch "$qt5_version" 

# Boost
GetPackage http://downloads.sourceforge.net/project/boost/boost/$boost_version/boost_$boost_version_.zip boost

# Qwt6
GetPackage http://downloads.sourceforge.net/project/qwt/qwt/$qwt6_version/qwt-$qwt6_version.zip
GetPatch qwt6_patch.7z qwt-$qwt6_version

# sip
GetPackage https://www.riverbankcomputing.com/static/Downloads/sip/$sip_version/sip-$sip_version.zip

# libusb
# patch enables AVX2 optimizations
GetPackage https://github.com/libusb/libusb/releases/download/v$libusb_version/libusb-$libusb_version.tar.bz2 libusb
GetPatch libusb_VS2015.7z libusb

# UHD
GetPackage https://github.com/EttusResearch/uhd.git -branch v$UHD_Version 

# libxslt
GetPackage https://github.com/GNOME/libxslt/archive/v$libxslt_version.tar.gz libxslt 

# lxml
GetPackage https://github.com/lxml/lxml/archive/lxml-$lxml_version.tar.gz 

# pthreads
GetPackage http://www.gcndevelopment.com/gnuradio/downloads/sources/pthreads-w32-$pthreads_version-release.7z pthreads
GetPatch pthreads.2.7z pthreads/pthreads.2

# openblas
if (!$BuildNumpyWithMKL) {
	GetPackage https://github.com/xianyi/OpenBLAS/archive/v$openBLAS_version.tar.gz 
	GetPatch openblas_patch.7z  openblas-$openblas_version
}

# lapack reference build
if (!$BuildNumpyWithMKL) {
	GetPackage http://www.netlib.org/lapack/lapack-$lapack_version.tar.gz lapack
}

# QwtPlot3D
GetPackage http://www.gcndevelopment.com/gnuradio/downloads/sources/qwtplot3d.7z

# PIL (python imaging library)
GetPackage http://effbot.org/downloads/Imaging-$PIL_version.tar.gz
GetPatch Imaging_patch.7z Imaging-$PIL_version

# mbed-tls (polarssl)
#
# Required by OpenLTE
#
GetPackage https://github.com/ARMmbed/mbedtls/archive/mbedtls-$mbedtls_version.tar.gz mbedtls
	
# log4cpp
$lmm = GetMajorMinor($log4cpp_version)
GetPackage https://downloads.sourceforge.net/project/log4cpp/log4cpp-$lmm.x%20%28new%29/log4cpp-$lmm/log4cpp-$log4cpp_version.tar.gz 
GetPatch log4cpp_msvc14.7z log4cpp

# MPIR
GetPackage http://mpir.org/mpir-$MPIR_version.zip mpir

# pkgconfig
GetPackage https://pypi.python.org/packages/source/p/pkgconfig/pkgconfig-$pkgconfig_version.tar.gz
GetPackage http://downloads.sourceforge.net/project/pkgconfiglite/0.28-1/pkg-config-lite-0.28-1_bin-win32.zip

# cleanup
""
"COMPLETED STEP 2: Source code needed to build core win32 dependencies and python dependencies have been downloaded"
""
# return to original directory
cd $root/scripts
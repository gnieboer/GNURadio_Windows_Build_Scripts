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

# pyzmq
getPackage https://github.com/zeromq/pyzmq/archive/v$pyzmq_version.zip 

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
GetPackage https://github.com/GNOME/libxml2.git

if ($Config.BuildGTKFromSource) {

	# libepoxy
	GetPackage https://github.com/anholt/libepoxy/archive/v1.3.1.tar.gz libepoxy

	# freetype
	GetPackage http://download.savannah.gnu.org/releases/freetype/freetype-2.6.3.tar.gz freetype
	GetPatch freetype-vc2015.7z freetype/builds/windows

	# Cairo
	GetPackage http://cairographics.org/releases/cairo-1.14.6.tar.xz cairo
	GetPatch cairo-vs2015.7z cairo/build

	# pixman
	GetPackage http://cairographics.org/releases/pixman-0.34.0.tar.gz pixman
	GetPatch pixman_vs2015.7z pixman/build

	# libffi
	GetPackage https://github.com/winlibs/libffi.git

	# JasPer 1900
	GetPackage http://www.ece.uvic.ca/~frodo/jasper/software/jasper-1.900.1.zip
	GetPatch jasper_vs2015.7z .\jasper-1.900.1\src

	# glib
	GetPackage http://ftp.gnome.org/pub/GNOME/sources/glib/2.47/glib-2.47.6.tar.xz glib

	# atk
	GetPackage http://ftp.gnome.org/pub/GNOME/sources/atk/2.19/atk-2.19.90.tar.xz atk

	# pango
	GetPackage http://ftp.gnome.org/pub/GNOME/sources/pango/1.39/pango-1.39.0.tar.xz pango

	# gdk-pixbuf
	GetPackage http://ftp.gnome.org/pub/GNOME/sources/gdk-pixbuf/2.33/gdk-pixbuf-2.33.2.tar.xz gdk-pixbuf

} else {
	"NOT building GTK from source, retrieving GTK VS2015 binaries"
	# These where built by the hexchat project, but they no longer host them
	# so we are pulling a mirror from our own website.
	GetPackage http://www.gcndevelopment.com/gnuradio/downloads/sources/gtk-x64.7z
	# need to add a bunch of pkgconfig files so we can build pyGTK later
	GetPatch pkgconfig.7z x64/lib/pkgconfig
}
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
GetPackage http://www.gcndevelopment.com/gnuradio/downloads/sources/python2710-x64-Source.7z
GetPatch python-pcbuild.vc14.zip python27/Python-2.7.10
# patch distutils because it doesn't correctly detect MSVC 14.0 / 2015
GetPatch python27_msvccompiler.7z python27\Python-2.7.10\Lib\distutils
GetPackage https://pypi.python.org/packages/source/s/setuptools/setuptools-20.1.1.zip
GetPackage https://pypi.python.org/packages/source/p/pip/pip-8.0.2.tar.gz
GetPackage https://pypi.python.org/packages/source/p/pip/pip-9.0.1.tar.gz
GetPackage https://pypi.python.org/packages/source/w/wheel/wheel-0.29.0.tar.gz
#GetPackage https://www.python.org/ftp/python/2.7.11/Python-2.7.11.tar.xz
#GetPatch python27_msvccompiler.7z Python-2.7.11\Lib\distutils

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
GetPackage http://download.qt.io/archive/qt/4.8/4.8.7/qt-everywhere-opensource-src-4.8.7.tar.gz Qt4
GetPackage https://github.com/qt/qt5.git -branch "v$qt5_version"

# Boost
GetPackage http://downloads.sourceforge.net/project/boost/boost/$boost_version/boost_$boost_version_.zip boost

# Qwt
GetPackage http://downloads.sourceforge.net/project/qwt/qwt/$qwt_version/qwt-$qwt_version.zip
GetPatch qwtconfig.7z qwt-$qwt_version

# Qwt6
GetPackage http://downloads.sourceforge.net/project/qwt/qwt/$qwt6_version/qwt-$qwt6_version.zip
GetPatch qwt6_patch.7z qwt-$qwt6_version

# sip
GetPackage http://sourceforge.net/projects/pyqt/files/sip/sip-$sip_version/sip-$sip_version.zip

# PyQt
GetPackage http://downloads.sourceforge.net/project/pyqt/PyQt4/PyQt-$PyQt_version/PyQt-win-gpl-$PyQt_version.zip PyQt4

# PyQwt
GetPackage https://github.com/PyQwt/PyQwt5/archive/master.zip
GetPatch pyqwt5_patch.7z PyQwt5-master/configure

# Cython
GetPackage https://github.com/cython/cython/archive/$cython_version.zip

# numpy
GetPackage https://github.com/numpy/numpy/archive/v$numpy_version.tar.gz

# scipy 
GetPackage https://github.com/scipy/scipy/releases/download/v$scipy_version/scipy-$scipy_version.tar.gz scipy

# pyopengl 
GetPackage https://pypi.python.org/packages/source/P/PyOpenGL/PyOpenGL-$pyopengl_version.tar.gz

# pyopengl-accelerate 
GetPackage https://pypi.python.org/packages/source/P/PyOpenGL-accelerate/PyOpenGL-accelerate-$pyopengl_version.tar.gz

# pygobject
if ($mm -eq "3.7") {
	$pygmm = GetMajorMinor($pygobject_version)
	GetPackage http://ftp.gnome.org/pub/GNOME/sources/pygobject/$pygmm/pygobject-$pygobject_version.tar.xz
	GetPatch gtk-pkgconfig.7z x64/lib
	GetPatch runtests-windows.7z pygobject-$pygobject_version\tests
	GetPatch pygobject_gio-types.7z pygobject-$pygobject_version\gio
} else {
	GetPackage https://gitlab.gnome.org/GNOME/pygobject/-/archive/$pygobject3_version/pygobject-$pygobject3_version.zip
}

# PyGTK
# GetPackage http://ftp.gnome.org/pub/GNOME/sources/pygtk/$pygtk_version/pygtk-$pygtk_version.0.tar.gz
GetPackage https://gitlab.gnome.org/Archive/pygtk/-/archive/windows/pygtk-windows.zip pygtk-$pygtk_version.0

# py2cairo
GetPackage https://github.com/pygobject/pycairo/archive/v$py2cairo_version.zip
#GetPatch py2cairo-$py2cairo_version.7z py2cairo-$py2cairo_version

# pyyaml
GetPackage http://pyyaml.org/download/pyyaml/PyYAML-$pyyaml_version.zip pyyaml

# pkgconfig
GetPackage https://pypi.python.org/packages/source/p/pkgconfig/pkgconfig-$pkgconfig_version.tar.gz
GetPackage http://downloads.sourceforge.net/project/pkgconfiglite/0.28-1/pkg-config-lite-0.28-1_bin-win32.zip

# wxpython
GetPackage http://downloads.sourceforge.net/wxpython/wxPython-src-$wxpython_version.tar.bz2 wxpython
GetPatch wxpython_vs2015_patch.7z wxpython

# cheetah 2.4.4
GetPackage https://pypi.python.org/packages/source/C/Cheetah/Cheetah-$cheetah_version.tar.gz

# libusb 1.0.21
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

# tensorflow
#
# contains patches to work with python 2.7 and cmake 3.3
#
GetPackage https://github.com/gnieboer/tensorflow.git -branch "msvc_fixes2"

# QwtPlot3D
GetPackage http://www.gcndevelopment.com/gnuradio/downloads/sources/qwtplot3d.7z

# MatPlotLib
GetPackage https://pypi.python.org/packages/79/a9/db688816150a6ef91fd9ce284c828467f7271c7dd5982753a73a8e1aaafa/matplotlib-$matplotlib_version.tar.gz
GetPatch matplotlib_patch.7z matplotlib-$matplotlib_version

# PIL (python imaging library)
GetPackage http://effbot.org/downloads/Imaging-$PIL_version.tar.gz
GetPatch Imaging_patch.7z Imaging-$PIL_version

# bitarray
GetPackage https://pypi.python.org/packages/0a/da/9f61d28a20c42b4963334efacfd257c85150ede96d0cd2509b37da69da47/bitarray-$bitarray_version.tar.gz

# mbed-tls (polarssl)
#
# Required by OpenLTE
#
GetPackage https://github.com/ARMmbed/mbedtls/archive/mbedtls-$mbedtls_version.tar.gz mbedtls
	
# get GNURadio 3.8+ dependencies
if ($mm -eq "3.8") {
	# log4cpp
	$lmm = GetMajorMinor($log4cpp_version)
	GetPackage https://downloads.sourceforge.net/project/log4cpp/log4cpp-$lmm.x%20%28new%29/log4cpp-$lmm/log4cpp-$log4cpp_version.tar.gz log4cpp
	GetPatch log4cpp_msvc14.7z log4cpp

	# PyQt5
	GetPackage http://downloads.sourceforge.net/project/pyqt/PyQt5/PyQt-$PyQt5_version/PyQt5_gpl-$PyQt5_version.tar.gz PyQt5
	
	# MPIR
	GetPackage http://mpir.org/mpir-$MPIR_version.zip mpir
}

# cleanup
""
"COMPLETED STEP 2: Source code needed to build core win32 dependencies and python dependencies have been downloaded"
""
# return to original directory
cd $root/scripts
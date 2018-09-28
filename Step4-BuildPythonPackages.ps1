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

$pythonexe = "python.exe"
$pythondebugexe = "python_d.exe"
$env:PYTHONPATH=""

#__________________________________________________________________________________________
# sip
#
# TODO static builds are not working, not vital as not truly needed to continue.
#
$ErrorActionPreference = "Continue"
SetLog "sip"
Write-Host "building sip..."
cd $root\src-stage1-dependencies\sip-$sip_version
# reset these in case previous run was stopped in mid-build
$env:_LINK_ = ""
$env:_CL_ = ""

Function MakeSip
{
	$type = $args[0]
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
		& $pythonroot\python$debugext.exe configure.py $dflag $kflag --platform win32-msvc2015 2>&1 >> $Log
		Write-Host -NoNewline "building..."
		nmake clean 2>&1 >> $Log
		nmake 2>&1 >> $Log
		New-Item -ItemType Directory -Force -Path ./build/x64/$type 2>&1 >> $Log
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
    		nmake install 2>&1 >> $Log
			Validate "$pythonroot/sip.exe" "$pythonroot/include/sip.h" "$pythonroot/lib/site-packages/sip$debugext.pyd" 
		}
		nmake clean 2>&1 >> $Log
		$env:_CL_ = ""
	} else {
		Write-Host "already built"
	}

}

$pythonroot = "$root\src-stage2-python\gr-python27-debug"
#MakeSip "Debug"
MakeSip "DebugDLL"
$pythonroot = "$root\src-stage2-python\gr-python27"
#MakeSip "Release"
MakeSip "ReleaseDLL"
$pythonroot = "$root\src-stage2-python\gr-python27-avx2"
#MakeSip "Release-AVX2"
MakeSip "ReleaseDLL-AVX2"
$ErrorActionPreference = "Stop"

#__________________________________________________________________________________________
# PyQt
#
# building libraries separate from the actual install into Python
#
$ErrorActionPreference = "Continue"
SetLog "PyQt"
cd $root\src-stage1-dependencies\PyQt4
$env:QMAKESPEC = "win32-msvc2015"
Write-Host -NoNewline "building PyQT..."

function MakePyQt 
{

	$type = $args[0]
	Write-Host -NoNewline "$type"
	$debugext = if ($type -match "Debug") {"_d"} else {""}
	if ((TryValidate "$root/src-stage1-dependencies/PyQt4/build/x64/$type/package/PyQt4/Qt$debugext.pyd" "$root/src-stage1-dependencies/PyQt4/build/x64/$type/package/PyQt4/QtCore$debugext.pyd" "$root/src-stage1-dependencies/PyQt4/build/x64/$type/package/PyQt4/QtGui$debugext.pyd" "$root/src-stage1-dependencies/PyQt4/build/x64/$type/package/PyQt4/QtOpenGL$debugext.pyd" "$root/src-stage1-dependencies/PyQt4/build/x64/$type/package/PyQt4/QtSvg$debugext.pyd") -eq $false) {
		if ($type -match "Debug") {$thispython = $pythondebugexe} else {$thispython = $pythonexe}
		$flags = if ($type -match "Debug") {"-u"} else {""}
		$flags += if ($type -match "Dll") {""} else {" -k"}
		if ($type -match "AVX2") {$env:_CL_ = "/Ox /arch:AVX2 /wd4577 /MP " } else {$env:_CL_ = "/wd4577 /MP "}
		$env:_LINK_= ""
		$env:Path = "$root\src-stage1-dependencies\Qt4\build\$type\bin;" + $oldpath

		& $pythonroot\$thispython configure.py $flags --destdir "build\x64\$type" --confirm-license --verbose --no-designer-plugin --enable QtOpenGL --enable QtGui --enable QtSvg -b build/x64/$type/bin -d build/x64/$type/package -p build/x64/$type/plugins --sipdir build/x64/$type/sip 2>&1 >> $log

		# BUG FIX
		"all: ;" > .\pylupdate\Makefile
		"install : ;" >> .\pylupdate\Makefile
		"clean : ;" >> .\pylupdate\Makefile

		nmake 2>&1 >> $log
		nmake install 2>&1 >> $log
		nmake clean 2>&1 >> $log
		$env:_CL_ = ""
		$env:_LINK_ = ""
		Write-Host -NoNewline "-done..."
	} else {
		Write-Host -NoNewline "...already built..."
	}
}

$pythonroot = "$root\src-stage2-python\gr-python27-debug"
MakePyQt "DebugDLL"
#MakePyQt "Debug"
$pythonroot = "$root\src-stage2-python\gr-python27"
MakePyQt "ReleaseDLL"
#MakePyQt "Release"
$pythonroot = "$root\src-stage2-python\gr-python27-avx2"
MakePyQt "ReleaseDLL-AVX2"
#MakePyQt "Release-AVX2"
$ErrorActionPreference = "Stop"
"complete"

$mm = GetMajorMinor($gnuradio_version)
if ($mm -eq "3.8") {
	#__________________________________________________________________________________________
	# PyQt5
	#
	# building libraries separate from the actual install into Python
	#
	$ErrorActionPreference = "Continue"
	SetLog "PyQt5"
	cd $root\src-stage1-dependencies\PyQt5
	$env:QMAKESPEC = "win32-msvc2015"
	Write-Host -NoNewline "building PyQT5..."

	function MakePyQt5
	{
		$type = $args[0]
		Write-Host -NoNewline "$type"
		if ($type -match "Debug") {$thispython = $pythondebugexe} else {$thispython = $pythonexe}
		$debugext = if ($type -match "Debug") {"_d"} else {""}
		if ((TryValidate "$root/src-stage1-dependencies/PyQt5/build/x64/$type/package/PyQt5/Qt$debugext.pyd"  "$root/src-stage1-dependencies/PyQt5/build/x64/$type/package/PyQt5/QtGui$debugext.pyd" "$root/src-stage1-dependencies/PyQt5/build/x64/$type/package/PyQt5/QtOpenGL$debugext.pyd" "$root/src-stage1-dependencies/PyQt5/build/x64/$type/package/PyQt5/QtWidgets$debugext.pyd" "$root/src-stage1-dependencies/PyQt5/build/x64/$type/package/PyQt5/QtSvg$debugext.pyd") -eq $false) {
			$flags = if ($type -match "Debug") {"-u"} else {""}
			$flags += if ($type -match "Dll") {""} else {" -k"}
			if ($type -match "AVX2") {$env:_CL_ = "/Ox /arch:AVX2 /wd4577 /MP "} else {$env:_CL_ = "/wd4577 /MP " }
			$env:_LINK_= ""
			$env:Path = "$root\src-stage1-dependencies\Qt5\build\$type\bin;" + $oldpath

			& $pythonroot\$thispython configure.py $flags --destdir "build\x64\$type" --confirm-license --verbose --no-designer-plugin --enable QtOpenGL --enable QtGui --enable QtWidgets  --enable QtSvg --spec win32-msvc2015 -b build/x64/$type/bin -d build/x64/$type/package  --sipdir build/x64/$type/sip --sip $pythonroot/sip.exe 2>&1 >> $log

			# BUG FIX
			"all: ;" > .\pylupdate\Makefile
			"install : ;" >> .\pylupdate\Makefile
			"clean : ;" >> .\pylupdate\Makefile

			nmake 2>&1 >> $log
			nmake install 2>&1 >> $log
			nmake clean 2>&1 >> $log
			$env:_CL_ = ""
			$env:_LINK_ = ""
			Write-Host -NoNewline "-done..."
		} else {
			Write-Host -NoNewline "...already built..."
		}
	}

	$pythonroot = "$root\src-stage2-python\gr-python27-debug"
	MakePyQt5 "DebugDLL"
	#MakePyQt5 "Debug"
	$pythonroot = "$root\src-stage2-python\gr-python27"
	#MakePyQt5 "Release"
	MakePyQt5 "ReleaseDLL"
	$pythonroot = "$root\src-stage2-python\gr-python27-avx2"
	#MakePyQt5 "Release-AVX2"
	MakePyQt5 "ReleaseDLL-AVX2"
	$ErrorActionPreference = "Stop"
	"complete"
}

#__________________________________________________________________________________________
# setup python

Function SetupPython
{
	$configuration = $args[0]
	""
	"installing python packages for $configuration"
	if ($configuration -match "Debug") { 
		$d = "d" 
		$debugext = "_d"
		$debug = "--debug"
		$pythonexe = "python_d.exe"
	} else {
		$d = ""
		$debugext = ""
		$debug = ""
		$pythonexe = "python.exe"
	}

	#__________________________________________________________________________________________
	# PyQt4
	#
	SetLog "$configuration PyQt4"
	if ((TryValidate "$pythonroot/lib/site-packages/PyQt4/Qt$debugext.pyd" "$pythonroot/lib/site-packages/PyQt4/QtCore$debugext.pyd" "$pythonroot/lib/site-packages/PyQt4/QtGui$debugext.pyd" "$pythonroot/lib/site-packages/PyQt4/QtOpenGL$debugext.pyd" "$pythonroot/lib/site-packages/PyQt4/QtSvg$debugext.pyd") -eq $false) {
		Write-Host -NoNewline "configuring PyQt4..."
		$ErrorActionPreference = "Continue"
		cd $root\src-stage1-dependencies\PyQt4
		$flags = if ($configuration -match "Debug") {"-u"} else {""}
		if ($type -match "AVX2") {$env:_CL_ = "/Ox /arch:AVX2 /wd4577 /MP "} else {$env:_CL_ = "/wd4577 /MP " }
		$env:Path = "$root\src-stage1-dependencies\Qt4\build\$configuration\bin;" + $oldpath
		$env:QMAKESPEC = "win32-msvc2015"
		$env:_LINK_= ""

		& $pythonroot\$pythonexe configure.py $flags --confirm-license --verbose --no-designer-plugin --enable QtOpenGL --enable QtGui --enable QtSvg  2>&1 >> $log
	
		# BUG FIX
		"all: ;" > .\pylupdate\Makefile
		"install : ;" >> .\pylupdate\Makefile
		"clean : ;" >> .\pylupdate\Makefile 

		Write-Host -NoNewline "building..."
		Exec {nmake} 2>&1 >> $log
		Write-Host -NoNewline "installing..."
		Exec {nmake install} 2>&1 >> $log
		$env:Path = $oldpath
		$env:_CL_ = ""
		$env:_LINK_ = ""
		$ErrorActionPreference = "Stop"
		Validate "$pythonroot/lib/site-packages/PyQt4/Qt$debugext.pyd" "$pythonroot/lib/site-packages/PyQt4/QtCore$debugext.pyd" "$pythonroot/lib/site-packages/PyQt4/QtGui$debugext.pyd" "$pythonroot/lib/site-packages/PyQt4/QtOpenGL$debugext.pyd" "$pythonroot/lib/site-packages/PyQt4/QtSvg$debugext.pyd"
	} else {
		Write-Host "PyQt4 already built..."
	}
	
	if ($mm -eq "3.8") {
		#__________________________________________________________________________________________
		# PyQt5
		#
		SetLog "$configuration PyQt5"
		if ((TryValidate "$pythonroot/lib/site-packages/PyQt5/Qt$debugext.pyd" "$pythonroot/lib/site-packages/PyQt5/QtGui$debugext.pyd" "$pythonroot/lib/site-packages/PyQt5/QtOpenGL$debugext.pyd" "$pythonroot/lib/site-packages/PyQt5/QtSvg$debugext.pyd" "$pythonroot/lib/site-packages/PyQt5/QtWidgets$debugext.pyd") -eq $false) {
			Write-Host -NoNewline "configuring PyQt5..."
			$ErrorActionPreference = "Continue"
			cd $root\src-stage1-dependencies\PyQt5
			$flags = if ($configuration -match "Debug") {"-u"} else {""}
			if ($type -match "AVX2") {$env:_CL_ = "/Ox /arch:AVX2 /wd4577 /MP "} else {$env:_CL_ = "/wd4577 /MP " }
			$env:Path = "$root\src-stage1-dependencies\Qt5\build\$configuration\bin;" + $oldpath
			$env:QMAKESPEC = "win32-msvc2015"
			$env:_LINK_= ""

			& $pythonroot\$pythonexe configure.py $flags --confirm-license --verbose --no-designer-plugin --enable QtOpenGL --enable QtGui --enable QtSvg --enable QtWidgets --spec win32-msvc2015 --sip $pythonroot/sip.exe 2>&1 >> $log

	
			Write-Host -NoNewline "building..."
			Exec {nmake} 2>&1 >> $log
			Write-Host -NoNewline "installing..."
			Exec {nmake install} 2>&1 >> $log
			$env:Path = $oldpath
			$env:_CL_ = ""
			$env:_LINK_ = ""
			$ErrorActionPreference = "Stop"
			Validate "$pythonroot/lib/site-packages/PyQt5/Qt$debugext.pyd" "$pythonroot/lib/site-packages/PyQt5/QtGui$debugext.pyd" "$pythonroot/lib/site-packages/PyQt5/QtOpenGL$debugext.pyd" "$pythonroot/lib/site-packages/PyQt5/QtSvg$debugext.pyd"  "$pythonroot/lib/site-packages/PyQt5/QtWidgets$debugext.pyd"
		} else {
			Write-Host "PyQt5 already built..."
		}					
	}
	
	#__________________________________________________________________________________________
	# Cython
	#
	# TODO This is not working properly on the debug build... essentially it is linking against
	#      python27 instead of python27_d
	SetLog "$configuration Cython"
	$ErrorActionPreference = "Continue"
	cd $root\src-stage1-dependencies\Cython-$cython_version
	if ((TryValidate "dist/Cython-$cython_version-cp27-cp27${d}m-win_amd64.$configuration.whl" "$pythonroot/lib/site-packages/Cython-$cython_version-py2.7-win-amd64.egg/cython.py" "$pythonroot/lib/site-packages/Cython-$cython_version-py2.7-win-amd64.egg/Cython/Compiler/Code$debugext.pyd" "$pythonroot/lib/site-packages/Cython-$cython_version-py2.7-win-amd64.egg/Cython/Distutils/build_ext.py") -eq $false) {
		Write-Host -NoNewline "installing Cython..."
		if ($configuration -match "Debug") { $env:_LINK_ = " /LIB:python27_d.lib " } else { $env:_LINK_="" }
		& $pythonroot/$pythonexe setup.py build $debug install 2>&1 >> $log
		Write-Host -NoNewline "creating wheel..."
		& $pythonroot/$pythonexe setup.py bdist_wheel   2>&1 >> $log
		$env:_LINK_ = ""
		move dist/Cython-$cython_version-cp27-cp27${d}m-win_amd64.whl dist/Cython-$cython_version-cp27-cp27${d}m-win_amd64.$configuration.whl -Force
		$ErrorActionPreference = "Stop"
		Validate "dist/Cython-$cython_version-cp27-cp27${d}m-win_amd64.$configuration.whl" "$pythonroot/lib/site-packages/Cython-$cython_version-py2.7-win-amd64.egg/cython.py" "$pythonroot/lib/site-packages/Cython-$cython_version-py2.7-win-amd64.egg/Cython/Compiler/Code$debugext.pyd" "$pythonroot/lib/site-packages/Cython-$cython_version-py2.7-win-amd64.egg/Cython/Distutils/build_ext.py"
	} else {
		Write-Host "Cython already built..."
	}

	#__________________________________________________________________________________________
	# Nose
	# Nose is a python-only package can be installed automatically
	# used for testing numpy/scipy etc only, not in gnuradio directly
	#
	SetLog "$configuration Nose"
	if ((TryValidate "$pythonroot/lib/site-packages/nose/core.py" "$pythonroot/lib/site-packages/nose/__main__.py") -eq $false) {
		Write-Host -NoNewline "installing Nose using pip..."
		$ErrorActionPreference = "Continue" # pip will "error" on debug
		& $pythonroot/Scripts/pip.exe --disable-pip-version-check  install nose -U -t $pythonroot\lib\site-packages 2>&1 >> $log
		$ErrorActionPreference = "Stop"
		Validate "$pythonroot/lib/site-packages/nose/core.py" "$pythonroot/lib/site-packages/nose/__main__.py"
	} else {
		Write-Host "Nose already installed..."
	}

	#__________________________________________________________________________________________
	# numpy
	# mkl_libs site.cfg lines generated with the assistance of:
	# https://software.intel.com/en-us/articles/intel-mkl-link-line-advisor
	#
	# TODO numpy Debug OpenBLAS crashes during numpy.test('full')
	#
	SetLog "$configuration numpy"
	cd $root\src-stage1-dependencies\numpy-$numpy_version
	if ((TryValidate "$pythonroot/lib/site-packages/numpy-$numpy_version-py2.7-win-amd64.egg/numpy/core/multiarray.pyd" "dist/numpy-$numpy_version-cp27-cp27${d}m-win_amd64.$configuration.whl") -eq $false) {
		Write-Host -NoNewline "configuring numpy..."
		$ErrorActionPreference = "Continue"
		# $static indicates if the MKL/OpenBLAS libraries will be linked statically into numpy/scipy or not.  numpy/scipy themselves will be built as DLLs/pyd's always
		# openblas lapack is always static
		$static = $true
		$staticconfig = ($configuration -replace "DLL", "") 
		if ($static -eq $true) {$staticlib = "_static"} else {$staticlib = ""}
		if ($BuildNumpyWithMKL) {
			# Build with MKL
			Write-Host -NoNewline "MKL..."
			if ($static -eq $false) {
				"[mkl]" | Out-File -filepath site.cfg -Encoding ascii
				"search_static_first=false" | Out-File -filepath site.cfg -Encoding ascii -Append
				"include_dirs = ${env:ProgramFiles(x86)}\IntelSWTools\compilers_and_libraries\windows\mkl\include" | Out-File -filepath site.cfg -Encoding ascii -Append
				"library_dirs = ${env:ProgramFiles(x86)}\IntelSWTools\compilers_and_libraries\windows\mkl\lib\intel64_win" | Out-File -filepath site.cfg -Encoding ascii -Append 
				"mkl_libs = mkl_rt" | Out-File -filepath site.cfg -Encoding ascii -Append
				"lapack_libs = " | Out-File -filepath site.cfg -Encoding ascii -Append
				if ($configuration -match "AVX2") {
					"extra_compile_args=/MD /Zi /Oy /Ox /Oi /arch:AVX2" | Out-File -filepath site.cfg -Encoding ascii -Append
				} elseif ($configuration -match "Debug") {
					"extra_compile_args=/MDd /Zi" | Out-File -filepath site.cfg -Encoding ascii -Append
				} else {
					"extra_compile_args=/MD /Zi /Oy /Ox /Oi" | Out-File -filepath site.cfg -Encoding ascii -Append
				}
			} else {
				"[mkl]" | Out-File -filepath site.cfg -Encoding ascii
				"search_static_first=true" | Out-File -filepath site.cfg -Encoding ascii -Append
				"include_dirs = ${env:ProgramFiles(x86)}\IntelSWTools\compilers_and_libraries\windows\mkl\include" | Out-File -filepath site.cfg -Encoding ascii -Append
				"library_dirs = ${env:ProgramFiles(x86)}\IntelSWTools\compilers_and_libraries\windows\mkl\lib\intel64_win" | Out-File -filepath site.cfg -Encoding ascii -Append 
				"mkl_libs = mkl_intel_lp64, mkl_core, mkl_intel_thread, libiomp5md" | Out-File -filepath site.cfg -Encoding ascii -Append
				"lapack_libs = " | Out-File -filepath site.cfg -Encoding ascii -Append
				if ($configuration -match "AVX2") {
					"extra_compile_args=/MD /Zi /Oy /Ox /Oi /arch:AVX2" | Out-File -filepath site.cfg -Encoding ascii -Append
				} elseif ($configuration -match "Debug") {
					"extra_compile_args=/MDd /Zi" | Out-File -filepath site.cfg -Encoding ascii -Append
				} else {
					"extra_compile_args=/MD /Zi /Oy /Ox /Oi" | Out-File -filepath site.cfg -Encoding ascii -Append
				}
			}
		} else {
			# Build with OpenBLAS
			Write-Host -NoNewline "OpenBLAS..."
			"[default]" | Out-File -filepath site.cfg -Encoding ascii
			"libraries = libopenblas$staticlib, lapack" | Out-File -filepath site.cfg -Encoding ascii -Append
			"library_dirs = $root/src-stage1-dependencies/openblas/build/$staticconfig/lib;$root/src-stage1-dependencies/lapack/dist/$staticconfig/lib" | Out-File -filepath site.cfg -Encoding ascii -Append
			"include_dirs = $root/src-stage1-dependencies\OpenBLAS\lapack-netlib\CBLAS\include" | Out-File -filepath site.cfg -Encoding ascii -Append
			"lapack_libs = libopenblas$staticlib, lapack" | Out-File -filepath site.cfg -Encoding ascii -Append
			if ($configuration -match "AVX2") {
				"extra_compile_args=/MD /Zi /Oy /Ox /Oi /arch:AVX2" | Out-File -filepath site.cfg -Encoding ascii -Append
			} elseif ($configuration -match "Debug") {
				"extra_compile_args=/MDd /Zi" | Out-File -filepath site.cfg -Encoding ascii -Append
			} else {
				"extra_compile_args=/MD /Zi /Oy /Ox /Oi" | Out-File -filepath site.cfg -Encoding ascii -Append
			}
			"[openblas]" | Out-File -filepath site.cfg -Encoding ascii -Append 
			"libraries = libopenblas$staticlib,lapack" | Out-File -filepath site.cfg -Encoding ascii -Append
			"library_dirs = $root/src-stage1-dependencies/openblas/build/$staticconfig/lib;$root/src-stage1-dependencies/lapack/dist/$staticconfig/lib" | Out-File -filepath site.cfg -Encoding ascii -Append
			"include_dirs = $root/src-stage1-dependencies\OpenBLAS\lapack-netlib\CBLAS\include/" | Out-File -filepath site.cfg -Encoding ascii -Append
			"lapack_libs = lapack" | Out-File -filepath site.cfg -Encoding ascii -Append
			if ($static -eq $false) {"runtime_library_dirs = $root/src-stage1-dependencies/openblas/build/lib/$staticconfig" | Out-File -filepath site.cfg -Encoding ascii -Append }
			"[lapack]" | Out-File -filepath site.cfg -Encoding ascii -Append
			"lapack_libs = libopenblas$staticlib, lapack" | Out-File -filepath site.cfg -Encoding ascii -Append
			"library_dirs = $root/src-stage1-dependencies/lapack/dist/$staticconfig/lib/" | Out-File -filepath site.cfg -Encoding ascii -Append
			"[blas]" | Out-File -filepath site.cfg -Encoding ascii -Append
			"libraries = libopenblas$staticlib, lapack" | Out-File -filepath site.cfg -Encoding ascii -Append
			"library_dirs = $root/src-stage1-dependencies/openblas/build/$staticconfig/lib;$root/src-stage1-dependencies/lapack/dist/$staticconfig/lib" | Out-File -filepath site.cfg -Encoding ascii -Append
			"include_dirs = $root/src-stage1-dependencies/OpenBLAS/lapack-netlib/CBLAS/include" | Out-File -filepath site.cfg -Encoding ascii -Append		
		}
		$env:VS90COMNTOOLS = $env:VS140COMNTOOLS
		# clean doesn't really get it all...
		del build/*.* -Recurse 2>&1 >> $log
		& $pythonroot/$pythonexe setup.py clean  2>&1 >> $log
		& $pythonroot/$pythonexe setup.py config --compiler=msvc2015 --fcompiler=intelvem  2>&1 >> $log
		Write-Host -NoNewline "building..."
		$env:_LINK_=" /NODEFAULTLIB:""LIBCMT.lib"" /NODEFAULTLIB:""LIBMMT.lib"" "
		& $pythonroot/$pythonexe setup.py build $debug 2>&1 >> $log
		Write-Host -NoNewline "installing..."
		& $pythonroot/$pythonexe setup.py install 2>&1 >> $log
		# TODO This is a hack to move the openblas library into the right place.  We should either link statically or figure a better so install moves this for us
		if (!($BuildNumpyWithMKL) -and ($static = $false)) { cp $root/src-stage1-dependencies/openblas/build/lib/$staticconfig/libopenblas.dll $pythonroot\lib\site-packages\numpy-$numpy_version-py2.7-win-amd64.egg\numpy\core }
		Write-Host -NoNewline "creating wheel..."
		& $pythonroot/$pythonexe setup.py bdist_wheel 2>&1 >> $log
		move dist/numpy-$numpy_version-cp27-cp27${d}m-win_amd64.whl dist/numpy-$numpy_version-cp27-cp27${d}m-win_amd64.$configuration.whl -Force 
		$ErrorActionPreference = "Stop"
		$env:_LINK_= ""
		Validate "$pythonroot/lib/site-packages/numpy-$numpy_version-py2.7-win-amd64.egg/numpy/core/multiarray.pyd" "dist/numpy-$numpy_version-cp27-cp27${d}m-win_amd64.$configuration.whl"
	} else {
		Write-Host "numpy already built..."
	}

	#__________________________________________________________________________________________
	# scipy
	#
	SetLog "$configuration scipy"
	cd $root\src-stage1-dependencies\scipy
	if ($hasIFORT) {
		if ((TryValidate "dist/scipy-$scipy_version-cp27-cp27${d}m-win_amd64.$configuration.whl" "$pythonroot/lib/site-packages/scipy-$scipy_version-py2.7-win-amd64.egg/scipy/linalg/_flapack.pyd"  "$pythonroot/lib/site-packages/scipy-$scipy_version-py2.7-win-amd64.egg/scipy/linalg/cython_lapack.pyd"  "$pythonroot/lib/site-packages/scipy-$scipy_version-py2.7-win-amd64.egg/scipy/sparse/_sparsetools.pyd") -eq $false) {
			Write-Host -NoNewline "configuring scipy..."
			$ErrorActionPreference = "Continue"
			$env:Path = "${MY_IFORT}bin\intel64;" + $oldPath 
			$env:LIB = "${MY_IFORT}compiler\lib\intel64_win;" + $oldLib
			# $static indicates if the MKL/OpenBLAS libraries will be linked statically into numpy/scipy or not.  numpy/scipy themselves will be built as DLLs/pyd's always
			# openblas lapack is always static$static = $true
			$staticconfig = ($configuration -replace "DLL", "") 
			if ($static -eq $true) {$staticlib = "_static"} else {$staticlib = ""} 
			if ($BuildNumpyWithMKL) {
				# Build with MKL
				Write-Host -NoNewline "MKL..."
				if ($static -eq $false) {
					"[mkl]" | Out-File -filepath site.cfg -Encoding ascii
					"search_static_first=false" | Out-File -filepath site.cfg -Encoding ascii -Append
					"include_dirs = ${MY_IFORT}mkl\include" | Out-File -filepath site.cfg -Encoding ascii -Append
					"library_dirs = ${MY_IFORT}compiler\lib\intel64_win;${MY_IFORT}mkl\lib\intel64_win" | Out-File -filepath site.cfg -Encoding ascii -Append 
					"mkl_libs = mkl_rt" | Out-File -filepath site.cfg -Encoding ascii -Append
					"lapack_libs = mkl_rt, mkl_lapack95_lp64,mkl_blas95_lp64" | Out-File -filepath site.cfg -Encoding ascii -Append
				if ($configuration -match "AVX2") {
						"extra_compile_args=/MD /Zi /Oy /Ox /Oi /arch:AVX2" | Out-File -filepath site.cfg -Encoding ascii -Append
					} elseif ($configuration -match "Debug") {
						"extra_compile_args=/MD /Zi" | Out-File -filepath site.cfg -Encoding ascii -Append
					} else {
						"extra_compile_args=/MD /Zi /Oy /Ox /Oi" | Out-File -filepath site.cfg -Encoding ascii -Append
					}
				} else {
					"[mkl]" | Out-File -filepath site.cfg -Encoding ascii
					"search_static_first=true" | Out-File -filepath site.cfg -Encoding ascii -Append
					"include_dirs = ${MY_IFORT}mkl\include" | Out-File -filepath site.cfg -Encoding ascii -Append
					"library_dirs = ${MY_IFORT}compiler\lib\intel64_win;${MY_IFORT}mkl\lib\intel64_win" | Out-File -filepath site.cfg -Encoding ascii -Append 
					"mkl_libs = mkl_lapack95_lp64,mkl_blas95_lp64,mkl_intel_lp64,mkl_sequential,mkl_core" | Out-File -filepath site.cfg -Encoding ascii -Append
					"lapack_libs = mkl_lapack95_lp64,mkl_blas95_lp64,mkl_intel_lp64,mkl_sequential,mkl_core" | Out-File -filepath site.cfg -Encoding ascii -Append
					if ($configuration -match "AVX2") {
						"extra_compile_args=/MD /Zi /Oy /Ox /Oi /arch:AVX2" | Out-File -filepath site.cfg -Encoding ascii -Append
					} elseif ($configuration -match "Debug") {
						"extra_compile_args=/MDd /Zi" | Out-File -filepath site.cfg -Encoding ascii -Append
					} else {
						"extra_compile_args=/MD /Zi /Oy /Ox /Oi" | Out-File -filepath site.cfg -Encoding ascii -Append
					}
				}
			} else {
				# Build scipy with OpenBLAS
				Write-Host -NoNewline "OpenBLAS..."
				"[default]" | Out-File -filepath site.cfg -Encoding ascii
				"libraries = libopenblas$staticlib, lapack" | Out-File -filepath site.cfg -Encoding ascii -Append
				"library_dirs = ${MY_IFORT}compiler\lib\intel64_win;$root/src-stage1-dependencies/openblas/build/$staticconfig/lib;$root/src-stage1-dependencies/lapack/dist/$staticconfig/lib" | Out-File -filepath site.cfg -Encoding ascii -Append
				"include_dirs = $root/src-stage1-dependencies\OpenBLAS\lapack-netlib\CBLAS\include" | Out-File -filepath site.cfg -Encoding ascii -Append
				"lapack_libs = libopenblas$staticlib, lapack" | Out-File -filepath site.cfg -Encoding ascii -Append
				if ($configuration -match "AVX2") {
					"extra_compile_args=/MD /Zi /Oy /Ox /Oi /arch:AVX2" | Out-File -filepath site.cfg -Encoding ascii -Append
				} elseif ($configuration -match "Debug") {
					"extra_compile_args=/MDd /Zi" | Out-File -filepath site.cfg -Encoding ascii -Append
				} else {
					"extra_compile_args=/MD /Zi /Oy /Ox /Oi" | Out-File -filepath site.cfg -Encoding ascii -Append
				}
				"[openblas]" | Out-File -filepath site.cfg -Encoding ascii -Append
				"libraries = libopenblas$staticlib, lapack" | Out-File -filepath site.cfg -Encoding ascii -Append
				"library_dirs = $root/src-stage1-dependencies/openblas/build/$staticconfig/lib;$root/src-stage1-dependencies/lapack/dist/$staticconfig/lib" | Out-File -filepath site.cfg -Encoding ascii -Append
				"include_dirs = $root/src-stage1-dependencies/OpenBLAS/lapack-netlib/CBLAS/include" | Out-File -filepath site.cfg -Encoding ascii -Append
				"runtime_library_dirs = " | Out-File -filepath site.cfg -Encoding ascii -Append
				"[lapack]" | Out-File -filepath site.cfg -Encoding ascii -Append
				"lapack_libs = lapack" | Out-File -filepath site.cfg -Encoding ascii -Append
				"libraries = lapack"  | Out-File -filepath site.cfg -Encoding ascii -Append
				"library_dirs = $root/src-stage1-dependencies/lapack/dist/$staticconfig/lib" | Out-File -filepath site.cfg -Encoding ascii -Append
				"[blas]" | Out-File -filepath site.cfg -Encoding ascii -Append
				"libraries = libopenblas$staticlib, lapack" | Out-File -filepath site.cfg -Encoding ascii -Append
				"library_dirs = $root/src-stage1-dependencies/openblas/build/$staticconfig/lib;$root/src-stage1-dependencies/lapack/dist/$staticconfig/lib" | Out-File -filepath site.cfg -Encoding ascii -Append
				"include_dirs = $root/src-stage1-dependencies/OpenBLAS/lapack-netlib/CBLAS/include" | Out-File -filepath site.cfg -Encoding ascii -Append		
			}
			$env:VS90COMNTOOLS = $env:VS140COMNTOOLS
			# clean doesn't really get it all...
			del build/*.* -Recurse 2>&1 >> $log
			& $pythonroot/$pythonexe setup.py clean  2>&1 >> $log
			& $pythonroot/$pythonexe setup.py config --fcompiler=intelvem --compiler=msvc  2>&1 >> $log
			Write-Host -NoNewline "building..."
			$env:_LINK_=" /NODEFAULTLIB:""LIBCMT.lib""  /NODEFAULTLIB:""LIBIFCOREMD.lib"" /DEFAULTLIB:""LIBIFCOREMT.lib"" /NODEFAULTLIB:""SVML_DISPMD.lib"" /DEFAULTLIB:""SVML_DISPMT.lib""  /NODEFAULTLIB:""LIBMMD.lib"" /DEFAULTLIB:""LIBMMDS.lib"" /DEFAULTLIB:""LIBMMT.lib"" /DEFAULTLIB:""libifport.lib"" /DEFAULTLIB:""legacy_stdio_definitions.lib"" /DEFAULTLIB:""libipgo.lib"" /DEFAULTLIB:""LIBIRC.lib""  "
			# setup.py doesn't handle debug flag correctly for windows ifort, it adds a -g flag which is ambiguous so we'll do our best to emulate it manually
			if ($configuration -match "Debug") {$env:__INTEL_POST_FFLAGS = " /debug:all "} else {$env:__INTEL_POST_FFLAGS = ""}
			& $pythonroot/$pythonexe setup.py build --compiler=msvc --fcompiler=intelvem 2>&1 >> $log
			Write-Host -NoNewline "installing..."
			& $pythonroot/$pythonexe setup.py install  2>&1 >> $log
			Write-Host -NoNewline "creating wheel..."
			& $pythonroot/$pythonexe setup.py bdist_wheel 2>&1 >> $log
			move dist/scipy-$scipy_version-cp27-cp27${d}m-win_amd64.whl dist/scipy-$scipy_version-cp27-cp27${d}m-win_amd64.$configuration.whl -Force
			$env:_LINK_=""
			$env:__INTEL_POST_FFLAGS = ""
			$ErrorActionPreference = "Stop"
			Validate "dist/scipy-$scipy_version-cp27-cp27${d}m-win_amd64.$configuration.whl" "$pythonroot/lib/site-packages/scipy-$scipy_version-py2.7-win-amd64.egg/scipy/linalg/_flapack.pyd"  "$pythonroot/lib/site-packages/scipy-$scipy_version-py2.7-win-amd64.egg/scipy/linalg/cython_lapack.pyd"  "$pythonroot/lib/site-packages/scipy-$scipy_version-py2.7-win-amd64.egg/scipy/sparse/_sparsetools.pyd"
		} else {
			Write-Host "scipy already built..."
		}
	} else {
		# Can't compile scipy without a fortran compiler, and gfortran won't work here
		# because we can't mix MSVC and gfortran libraries
		# So if we get here, we need to use the binary .whl instead
		# Note that these are specifically built VS 2015 x64 versions for python 2.7.
		if ((TryValidate "$pythonroot/lib/site-packages/scipy/linalg/_flapack.pyd"  "$pythonroot/lib/site-packages/scipy/linalg/cython_lapack.pyd"  "$pythonroot/lib/site-packages/scipy/sparse/_sparsetools.pyd") -eq $false) {
			$ErrorActionPreference = "Continue"
			if ($BuildNumpyWithMKL) {
				Write-Host -NoNewline "installing MKL scipy from wheel..."
				Write-Host -NoNewline "Compatible Fortran compiler not available, installing scipy from custom binary wheel..."
				& $pythonroot/Scripts/pip.exe --disable-pip-version-check  install http://www.gcndevelopment.com/gnuradio/downloads/libraries/scipy/mkl/scipy-$scipy_version-cp27-cp27${d}m-win_amd64.$configuration.whl -U -t $pythonroot\lib\site-packages  2>&1 >> $log
			} else {
				Write-Host -NoNewline "installing OpenBLAS scipy from wheel..."
				& $pythonroot/Scripts/pip.exe --disable-pip-version-check  install http://www.gcndevelopment.com/gnuradio/downloads/libraries/scipy/openBLAS/scipy-$scipy_version-cp27-cp27${d}m-win_amd64.$configuration.whl -U -t $pythonroot\lib\site-packages  2>&1 >> $log
			}
			$ErrorActionPreference = "Stop"
			Validate "$pythonroot/lib/site-packages/scipy/linalg/_flapack.pyd"  "$pythonroot/lib/site-packages/scipy/linalg/cython_lapack.pyd"  "$pythonroot/lib/site-packages/scipy/sparse/_sparsetools.pyd"
		} else {
			Write-Host "scipy already built..."
		}
	}
	

	#__________________________________________________________________________________________
	# PyQwt5
	# requires Python, Qwt, Qt, PyQt, and Numpy
	#
	SetLog "$configuration PyQwt5"
	cd $root\src-stage1-dependencies\PyQwt5-master
	if ((TryValidate "dist/PyQwt-5.2.1.win-amd64.$configuration.exe" "$pythonroot/lib/site-packages/PyQt4/Qwt5/Qwt$debugext.pyd" "$pythonroot/lib/site-packages/PyQt4/Qwt5/_iqt.pyd" "$pythonroot/lib/site-packages/PyQt4/Qwt5/qplt.py") -eq $false) {
		Write-Host -NoNewline "configuring PyQwt5..."
		$ErrorActionPreference = "Continue" 
		# qwt_version_info will look for QtCore4.dll, never Qt4Core4d.dll so point it to the ReleaseDLL regardless of the desired config
		if ($configuration -eq "DebugDLL") {$QtVersion = "ReleaseDLL"} else {$QtVersion = $configuration}
		$env:Path = "$root\src-stage1-dependencies\Qt4\build\$QtVersion\bin;$root\src-stage1-dependencies\Qwt-$qwt_version\build\x64\Debug-Release\lib;" + $oldpath
		$envLib = $oldlib
		if ($type -match "AVX2") {$env:_CL_ = "/Ox /arch:AVX2 /wd4577 " } else {$env:_CL_ = "/wd4577 " }
		cd configure
		# CALL "../../%1/Release/Python27/python.exe" configure.py %DEBUG% --extra-cflags=%FLAGS% %DEBUG% -I %~dp0..\qwt-5.2.3\build\include -L %~dp0..\Qt-4.8.7\lib -L %~dp0..\qwt-5.2.3\build\lib -l%QWT_LIB%
		if ($configuration -eq "DebugDLL") {
			$env:_LINK_ = " /FORCE /LIBPATH:""$root/src-stage1-dependencies/Qt4/build/ReleaseDLL/lib"" /LIBPATH:""$root/src-stage1-dependencies/Qt4/build/Release-AVX2/lib"" /DEFAULTLIB:user32  /DEFAULTLIB:advapi32  /DEFAULTLIB:ole32  /DEFAULTLIB:ws2_32  /DEFAULTLIB:qtcored4 " 
			& $pythonroot/$pythonexe configure.py --debug --extra-cflags="-Zi -wd4577"                -I $root\src-stage1-dependencies\Qwt-$qwt_version\build\x64\Debug-Release\include -L $root\src-stage1-dependencies\Qt4\build\$QtVersion\lib   -l qtcored4     -L $root\src-stage1-dependencies\Qwt-$qwt_version\build\x64\Debug-Release\lib -l"$root\src-stage1-dependencies\Qwt-$qwt_version\build\x64\Debug-Release\lib\qwtd" -j4 --sip-include-dirs ..\..\sip-$sip_version\build\x64\Debug --sip-include-dirs ..\..\PyQt4\sip 2>&1 >> $log
		} elseif ($configuration -eq "ReleaseDLL") {
			& $pythonroot/$pythonexe configure.py         --extra-cflags="-Zi -wd4577"                -I $root\src-stage1-dependencies\Qwt-$qwt_version\build\x64\Debug-Release\include -L $root\src-stage1-dependencies\Qt4\build\ReleaseDLL\lib -l qtcore4       -L $root\src-stage1-dependencies\Qwt-$qwt_version\build\x64\Debug-Release\lib -l"$root\src-stage1-dependencies\Qwt-$qwt_version\build\x64\Debug-Release\lib\qwt"  -j4 --sip-include-dirs ..\..\sip-$sip_version\build\x64\Release 2>&1 >> $log
		} else {
			& $pythonroot/$pythonexe configure.py         --extra-cflags="-Zi -Ox -arch:AVX2 -wd4577" -I $root\src-stage1-dependencies\Qwt-$qwt_version\build\x64\Release-AVX2\include  -L $root\src-stage1-dependencies\Qt4\build\ReleaseDLL-AVX2\lib -l qtcore4  -L $root\src-stage1-dependencies\Qwt-$qwt_version\build\x64\Release-AVX2\lib  -l"$root\src-stage1-dependencies\Qwt-$qwt_version\build\x64\Release-AVX2\lib\qwt"   -j4 --sip-include-dirs ..\..\sip-$sip_version\build\x64\Release-AVX2 2>&1 >> $log
		}
		nmake clean 2>&1 >> $log
		Write-Host -NoNewline "building..."
		Exec {nmake} 2>&1 >> $log
		Write-Host -NoNewline "installing..."
		Exec {nmake install} 2>&1 >> $log
		#& $pythonroot/$pythonexe setup.py build 2>&1 >> $log
		#Write-Host -NoNewline "installing..."
		#& $pythonroot/$pythonexe setup.py install 2>&1 >> $log
		Write-Host -NoNewline "creating winstaller..."
		cd ..
		& $pythonroot/$pythonexe setup.py bdist_wininst   2>&1 >> $log
		move dist/PyQwt-5.2.1.win-amd64.exe dist/PyQwt-5.2.1.win-amd64.$configuration.exe -Force
		# TODO these move fail for lack of a wheel-compatible setup
		# & $pythonroot/$pythonexe setup.py bdist_wheel   2>&1 >> $log
		# cd dist
		# & $pythonroot/Scripts/wheel.exe convert PyQwt-5.2.1.win-amd64.DebugDLL.exe
		$env:Path = $oldpath
		$env:_CL_ = ""
		$env:_LINK_ = ""
		$ErrorActionPreference = "Stop"
		Validate "dist/PyQwt-5.2.1.win-amd64.$configuration.exe" "$pythonroot/lib/site-packages/PyQt4/Qwt5/Qwt$debugext.pyd" "$pythonroot/lib/site-packages/PyQt4/Qwt5/_iqt.pyd" "$pythonroot/lib/site-packages/PyQt4/Qwt5/qplt.py"
	} else {
		Write-Host "PyQwt5 already built..."
	}

	#__________________________________________________________________________________________
	# PyOpenGL
	# requires Python
	# python-only package so no need to rename the wheels since there is only one
	#
	SetLog "$configuration PyOpenGL"
	cd $root\src-stage1-dependencies\PyOpenGL-$pyopengl_version
	if ((TryValidate "$pythonroot/lib/site-packages/OpenGL/version.py" "dist/PyOpenGL-$pyopengl_version-py2-none-any.whl") -eq $false ) {
		Write-Host -NoNewline "installing PyOpenGL..."
		$ErrorActionPreference = "Continue"
		& $pythonroot/$pythonexe setup.py install --single-version-externally-managed --root=/ 2>&1 >> $log
		Write-Host -NoNewline "crafting wheel..."
		& $pythonroot/$pythonexe setup.py bdist_wheel 2>&1 >> $log
		$ErrorActionPreference = "Stop"
		Validate "$pythonroot/lib/site-packages/OpenGL/version.py" "dist/PyOpenGL-$pyopengl_version-py2-none-any.whl"
	} else {
		Write-Host "PyOpenGL already built..."
	}

	#__________________________________________________________________________________________
	# PyOpenGL-accelerate
	# requires Python, PyOpenGL
	#
	cd $root\src-stage1-dependencies\PyOpenGL-accelerate-$pyopengl_version
	if ((TryValidate "$pythonroot/lib/site-packages/OpenGL_accelerate/wrapper$debugext.pyd" "dist/PyOpenGL_accelerate-$pyopengl_version-cp27-cp27${d}m-win_amd64.$configuration.whl") -eq $false) {
		Write-Host -NoNewline "installing PyOpenGL-accelerate..."
		$ErrorActionPreference = "Continue"
		& $pythonroot/$pythonexe setup.py clean 2>&1 >> $log
		if ($configuration -match "Debug") {$env:_LINK_=" /LIBPATH:""$root\src-stage1-dependencies\Qt4\build\$configuration\lib"" "}
		& $pythonroot/$pythonexe setup.py build $debug install --single-version-externally-managed --root=/ 2>&1 >> $log
		Write-Host -NoNewline "crafting wheel..."
		& $pythonroot/$pythonexe setup.py bdist_wheel 2>&1 >> $log
		move dist/PyOpenGL_accelerate-$pyopengl_version-cp27-cp27${d}m-win_amd64.whl dist/PyOpenGL_accelerate-$pyopengl_version-cp27-cp27${d}m-win_amd64.$configuration.whl -Force
		$env:_LINK_ = ""
		$ErrorActionPreference = "Stop"
		Validate "$pythonroot/lib/site-packages/OpenGL_accelerate/wrapper$debugext.pyd" "dist/PyOpenGL_accelerate-$pyopengl_version-cp27-cp27${d}m-win_amd64.$configuration.whl"
	} else {
		Write-Host "PyOpenGL-accelerate already built..."
	}

	#__________________________________________________________________________________________
	# pkg-config
	# both the binary (using pkg-config-lite to avoid dependency issues) and the python wrapper
	#
	SetLog "$configuration pkg-config"
	cd $root\src-stage1-dependencies\pkgconfig-$pkgconfig_version
	if ((TryValidate "$root\bin\pkg-config.exe" "dist/pkgconfig-$pkgconfig_version-py2-none-any.whl" "$pythonroot/lib/site-packages/pkgconfig/pkgconfig.py") -eq $false) {
		Write-Host -NoNewline "building pkg-config..."
		$ErrorActionPreference = "Continue"
		& $pythonroot/$pythonexe setup.py build  $debug 2>&1 >> $log
		Write-Host -NoNewline "installing..."
		& $pythonroot/$pythonexe setup.py install --single-version-externally-managed --root=/ 2>&1 >> $log
		Write-Host -NoNewline "crafting wheel..."
		& $pythonroot/$pythonexe setup.py bdist_wheel 2>&1 >> $log
		# yes, this copies the same file three times, but since it's conceptually linked to 
		# the python wrapper, I kept this here for ease of maintenance
		cp $root\src-stage1-dependencies\pkg-config-lite-0.28-1\bin\pkg-config.exe $root\bin -Force  2>&1 >> $log
		New-Item -ItemType Directory -Force $pythonroot\lib\pkgconfig 2>&1 >> $log
		$ErrorActionPreference = "Stop"
		Validate "$root\bin\pkg-config.exe" "dist/pkgconfig-$pkgconfig_version-py2-none-any.whl" "$pythonroot/lib/site-packages/pkgconfig/pkgconfig.py"
	} else {
		Write-Host "pkg-config already built..."
	}

	#__________________________________________________________________________________________
	# py2cairo
	# requires pkg-config
	# uses wierd setup python script called WAF which has an archive embedded in it which
	# creates files that then fail to work.  So we need to extract them and then patch them
	# and run again.
	SetLog "$configuration pycairo"
	cd $root\src-stage1-dependencies\pycairo-$py2cairo_version
	if ((TryValidate "$pythonroot\lib\site-packages\pycairo-$py2cairo_version-py2.7-win-amd64.egg\cairo\_cairo.pyd") -eq $false) {
		Write-Host -NoNewline "configuring py2cairo..."
		$ErrorActionPreference = "Continue" 
		$env:PATH = "$root/bin;$root/src-stage1-dependencies/x64/bin;$root/src-stage1-dependencies/x64/lib;" + $oldpath
		$env:PKG_CONFIG_PATH = "$root/bin;$root/src-stage1-dependencies/x64/lib/pkgconfig;$pythonroot/lib/pkgconfig"
		if ($configuration -match "AVX2") {$env:_CL_ = "/arch:AVX2"} else {$env:_CL_ = $null}
		if ($configuration -match "Debug") {$env:_CL_ = $env:_CL_ + " /Zi /D_DEBUG  "; $env:_LINK_ = " /DEBUG:FULL"}
		Write-Host -NoNewline "building..."
		$env:INCLUDE = "$root/src-stage1-dependencies/x64/include;$root/src-stage1-dependencies/x64/include/cairo;" + $oldInclude 
		$env:LIB = "$root/src-stage1-dependencies/cairo/build/x64/Release;$root/src-stage1-dependencies/cairo/build/x64/ReleaseDLL;$pythonroot/libs;" + $oldlib 
		$env:_CL_ = "/MD$d /I$root/src-stage1-dependencies/x64/include /I$root/src-stage1-dependencies/x64/include/cairo /DCAIRO_WIN32_STATIC_BUILD" 
		$env:_LINK_ = "/DEFAULTLIB:cairo /DEFAULTLIB:pixman-1 /DEFAULTLIB:freetype /LIBPATH:$root/src-stage1-dependencies/x64/lib /LIBPATH:$pythonroot/libs"
		& $pythonroot/$pythonexe setup.py build $debug --compiler=msvc  2>&1 >> $Log
		Write-Host -NoNewline "installing..."
		& $pythonroot/$pythonexe setup.py install --single-version-externally-managed  --root=/ 2>&1 >> $Log
		Write-Host -NoNewline "creating wheel..."
		& $pythonroot/$pythonexe setup.py bdist_wheel 2>&1 >> $Log
		$env:_LINK_ = ""
		$env:_CL_ = ""
		$env:LIB = $oldLib
		$env:INCLUDE = $oldInclude 
		cp -Recurse -Force build/x64/$configuration/lib/python2.7/site-packages/cairo $pythonroot\lib\site-packages 2>&1 >> $log
		if ($configuration -match "Debug") {
			cp -Force "$pythonroot\lib\site-packages\cairo\_cairo.pyd" "$pythonroot\lib\site-packages\cairo\_cairo_d.pyd"
		}
		Validate "$pythonroot\lib\site-packages\pycairo-$py2cairo_version-py2.7-win-amd64.egg\cairo\_cairo.pyd"
	} else {
		Write-Host "py2cairo already built..."
	}

	#__________________________________________________________________________________________
	# Pygobject
	# requires Python
	#
	# 2.X VERSION WARNING: higher than 2.28 does not have setup.py so do not try to use )
	#
	SetLog "$configuration pygobject"
	if ($mm -eq "3.8") {
		cd $root\src-stage1-dependencies\Pygobject-$pygobject3_version
		if ((TryValidate "dist/gtk-3.0/pygobject-$pygobject3_version-cp27-cp27${d}m-win_amd64.$configuration.whl" "$pythonroot\lib\site-packages\gi\_gi.pyd") -eq $false) {
			Write-Host -NoNewline "building Pygobject 3..."
			$ErrorActionPreference = "Continue" 
			$env:INCLUDE = "$root/src-stage1-dependencies/x64/include;$root/src-stage1-dependencies/x64/include/glib-2.0;$root/src-stage1-dependencies/x64/include;$root/src-stage1-dependencies/x64/include/cairo;$root/src-stage1-dependencies/x64/include;$root/src-stage1-dependencies/x64/lib/glib-2.0/include;$root/src-stage1-dependencies/x64/include/gobject-introspection-1.0;$root/src-stage1-dependencies/x64/include/gtk-3.0" + $oldInclude 
			$env:PATH = "$root/bin;$root/src-stage1-dependencies/x64/bin;$root/src-stage1-dependencies/x64/lib;" + $oldpath
			$env:PKG_CONFIG_PATH = "$root/bin;$root/src-stage1-dependencies/x64/lib/pkgconfig;$pythonroot/lib/pkgconfig"
			$env:LIB = "$root/src-stage1-dependencies/x64/lib;" + $oldlib
			if ($configuration -match "AVX2") {$env:_CL_ = "/arch:AVX2"} else {$env:_CL_ = $null}
			if ($configuration -match "Debug") {$env:_CL_ = $env:_CL_ + " /Zi /D_DEBUG  "; $env:_LINK_ = " /DEBUG:FULL"}
			& $pythonroot/$pythonexe setup.py build $debug --compiler=msvc  2>&1 >> $Log
			Write-Host -NoNewline "installing..."
			& $pythonroot/$pythonexe setup.py install --single-version-externally-managed  --root=/ 2>&1 >> $Log
			Write-Host -NoNewline "creating exe..."
			& $pythonroot/$pythonexe setup.py bdist_wininst 2>&1 >> $Log
			Write-Host -NoNewline "crafting wheel"
			& $pythonroot/$pythonexe setup.py bdist_wheel 2>&1 >> $Log
			New-Item -ItemType Directory -Force -Path .\dist\gtk-3.0 2>&1 >> $Log
			cd dist
			move ./pygobject-$pygobject3_version-cp27-cp27${d}m-win_amd64.whl gtk-3.0/pygobject-$pygobject3_version-cp27-cp27${d}m-win_amd64.$configuration.whl -Force
			cd ..
			$env:_CL_ = ""
			$env:LIB = $oldLIB 
			$env:PATH = $oldPath
			$env:PKG_CONFIG_PATH = ""
			$ErrorActionPreference = "Stop" 
			Validate "dist/gtk-3.0/pygobject-$pygobject3_version-cp27-cp27${d}m-win_amd64.$configuration.whl" "$pythonroot\lib\site-packages\gi\_gi.pyd"
		} else {
			Write-Host "pygobject3 already built..."
		}
	} else {
		cd $root\src-stage1-dependencies\Pygobject-$pygobject_version
		if ((TryValidate "dist/gtk-2.0/pygobject-cp27-none-win_amd64.$configuration.whl" "$pythonroot\lib\site-packages\gtk-2.0\gobject\_gobject.pyd") -eq $false) {
			Write-Host -NoNewline "building Pygobject..."
			$ErrorActionPreference = "Continue" 
			$env:PATH = "$root/bin;$root/src-stage1-dependencies/x64/bin;$root/src-stage1-dependencies/x64/lib;" + $oldpath
			$env:PKG_CONFIG_PATH = "$root/bin;$root/src-stage1-dependencies/x64/lib/pkgconfig;$pythonroot/lib/pkgconfig"
			if ($configuration -match "AVX2") {$env:_CL_ = "/arch:AVX2"} else {$env:_CL_ = $null}
			if ($configuration -match "Debug") {$env:_CL_ = $env:_CL_ + " /Zi /D_DEBUG  "; $env:_LINK_ = " /DEBUG:FULL"}
			& $pythonroot/$pythonexe setup.py build $debug --compiler=msvc --enable-threading  2>&1 >> $Log
			Write-Host -NoNewline "installing..."
			& $pythonroot/$pythonexe setup.py install  2>&1 >> $Log
			Write-Host -NoNewline "creating exe..."
			& $pythonroot/$pythonexe setup.py bdist_wininst 2>&1 >> $Log
			Write-Host -NoNewline "crafting wheel from exe..."
			New-Item -ItemType Directory -Force -Path .\dist\gtk-2.0 2>&1 >> $Log
			cd dist
			& $pythonroot/Scripts/wheel.exe convert pygobject-$pygobject_version.win-amd64-py2.7.exe 2>&1 >> $Log
			move gtk-2.0/pygobject-cp27-none-win_amd64.whl gtk-2.0/pygobject-cp27-none-win_amd64.$configuration.whl -Force
			cd ..
			$env:_CL_ = ""
			$env:PATH = $oldPath
			$env:PKG_CONFIG_PATH = ""
			$ErrorActionPreference = "Stop" 
			Validate "dist/gtk-2.0/pygobject-cp27-none-win_amd64.$configuration.whl" "$pythonroot\lib\site-packages\gtk-2.0\gobject\_gobject.pyd"
		} else {
			Write-Host "pygobject already built..."
		}
	}

	#__________________________________________________________________________________________
	# PyGTK
	# requires Python, Pygobject
	#
	SetLog "$configuration pygtk"
	cd $root\src-stage1-dependencies\pygtk-$pygtk_version.0
	if ((TryValidate "dist/gtk-2.0/pygtk-cp27-none-win_amd64.$configuration.whl" "$pythonroot\lib\site-packages\gtk-2.0\gtk\_gtk.pyd") -eq $false) {
		Write-Host -NoNewline "building PyGTK..."
		if ($configuration -match "AVX2") {$env:_CL_ = "/arch:AVX2"} else {$env:_CL_ = $null}
		$env:PATH = "$root/bin;$root/src-stage1-dependencies/x64/bin;$root/src-stage1-dependencies/x64/lib;$pythonroot/Scripts;$pythonroot;" + $oldpath
		$env:_CL_ = "/I$root/src-stage1-dependencies/x64/lib/gtk-2.0/include /I$root/src-stage1-dependencies/py2cairo-$py2cairo_version/src " + $env:_CL_
		if ($configuration -match "Debug") {$env:_CL_ = $env:_CL_ + " /Zi /D_DEBUG  "; $env:_LINK_ = " /DEBUG:FULL"}
		$env:PKG_CONFIG_PATH = "$root/bin;$root/src-stage1-dependencies/x64/lib/pkgconfig;$pythonroot/lib/pkgconfig"
		$ErrorActionPreference = "Continue" 
		& $pythonroot/$pythonexe setup.py clean 2>&1 >> $Log
		& $pythonroot/$pythonexe setup.py build $debug --compiler=msvc --enable-threading 2>&1 >> $log
		Write-Host -NoNewline "installing..."
		& $pythonroot/$pythonexe setup.py install 2>&1 >> $Log
		Write-Host -NoNewline "building exe..."
		& $pythonroot/$pythonexe setup.py bdist_wininst 2>&1 >> $Log
		New-Item -ItemType Directory -Force -Path .\dist\gtk-2.0 2>&1 >> $Log
		cd dist
		Write-Host -NoNewline "crafting wheel from exe..."
		& $pythonroot/Scripts/wheel.exe convert pygtk-$pygtk_version.0.win-amd64-py2.7.exe 2>&1 >> $Log
		move gtk-2.0/pygtk-cp27-none-win_amd64.whl gtk-2.0/pygtk-cp27-none-win_amd64.$configuration.whl -Force 2>&1 >> $Log
		cd ..
		$env:_CL_ = ""
		$env:_LINK_ = ""
		$env:PATH = $oldPath
		$env:PKG_CONFIG_PATH = ""
		$ErrorActionPreference = "Stop" 
		Validate "dist/gtk-2.0/pygtk-cp27-none-win_amd64.$configuration.whl" "$pythonroot\lib\site-packages\gtk-2.0\gtk\_gtk.pyd"
	} else {
		Write-Host "pyGTK already built..."
	}

	#__________________________________________________________________________________________
	# Pyyaml
	# requires Python
	#
	SetLog "$configuration pyyaml"
	if ($mm -eq "3.8") {
		cd $root\src-stage1-dependencies\pyyaml
		if ((TryValidate "dist/pyyaml-$pyyaml_version-cp27-cp27${d}m-win_amd64.$configuration.whl" "$pythonroot/lib/site-packages/yaml/__init__.py") -eq $false) {
			Write-Host -NoNewline "building pyyaml..."
			$ErrorActionPreference = "Continue" 
			if ($configuration -match "AVX2") {$env:_CL_ = "/arch:AVX2"} else {$env:_CL_ = $null}
			if ($configuration -match "Debug") {$env:_CL_ = $env:_CL_ + " /Zi /D_DEBUG  "; $env:_LINK_ = " /DEBUG:FULL"}
			& $pythonroot/$pythonexe setup.py build $debug --compiler=msvc  2>&1 >> $Log
			Write-Host -NoNewline "installing..."
			& $pythonroot/$pythonexe setup.py install 2>&1 >> $Log
			Write-Host -NoNewline "creating exe..."
			& $pythonroot/$pythonexe setup.py bdist_wininst 2>&1 >> $Log
			Write-Host -NoNewline "crafting wheel..."
			& $pythonroot/$pythonexe setup.py bdist_wheel 2>&1 >> $Log
			cd dist
			move ./pyyaml-$pyyaml_version-cp27-cp27${d}m-win_amd64.whl pyyaml-$pyyaml_version-cp27-cp27${d}m-win_amd64.$configuration.whl -Force
			cd ..
			$ErrorActionPreference = "Stop" 
			Validate "dist/pyyaml-$pyyaml_version-cp27-cp27${d}m-win_amd64.$configuration.whl" "$pythonroot/lib/site-packages/yaml/__init__.py"
		} else {
			Write-Host "pyyaml already built..."
		}
	}
	
	#__________________________________________________________________________________________
	# wxpython
	#
	# v3.0.2 is not VC140 compatible, so the patch fixes those things
	# TODO submit changes to source tree
	#
	# TODO so the debug build is not working because of it's looking for the wrong file to link to
	# (debug vs non-debug).  So the workaround is to build wx in release even when python is
	# being built in debug.
	#
	SetLog "$configuration wxpython"
	cd $root\src-stage1-dependencies\wxpython\wxPython
	if ((TryValidate "$pythonroot\lib\site-packages\wx-3.0-msw\wx\_core_.pyd" "dist\wx-3.0-cp27-none-win_amd64.$configuration.whl") -eq $false) {
		Write-Host -NoNewline "prepping wxpython..."
		$canbuildwxdebug = $true
		$wxdebug = ($canbuildwxdebug -and $d -eq "d")
		$wxdebugstring = ""
		$env:WXWIN="$root\src-stage1-dependencies\wxpython"
		$env:PATH = "$root/src-stage1-dependencies/x64/bin;$root/src-stage1-dependencies/x64/lib;$pythonroot/Scripts;$pythonroot" + $oldpath
		$env:_CL_ = "/I$root/src-stage1-dependencies/wxpython/include/msvc /I$root/src-stage1-dependencies/wxpython/lib/vc140_dll/mswu  /DWXWIN=.. /DMSLU /D_UNICODE /DUNICODE /DwxMSVC_VERSION_AUTO "
		if ($configuration -match "AVX2") {$env:_CL_ = $env:_CL_ +  " /arch:AVX2 "}
		$ErrorActionPreference = "Continue"
		if (Test-Path .\build) {del -recurse .\build\*.* 2>&1 >> $Log}
		& $pythonroot\$pythonexe build-wxpython.py --clean 2>&1 >> $Log
		if ($wxdebug) {
			Write-Host -NoNewline "building release..."
			$env:_CL_ = " /D__WXMSW__  /MDd " + $env:_CL_ 
			& $pythonroot\$pythonexe build-wxpython.py --build_dir=../build  --force_config  2>&1 >> $Log
			$env:_CL_ = " /I$root/src-stage1-dependencies/wxpython/lib/vc140_dll/mswud /D__WXDEBUG__ /D_DEBUG " + $env:_CL_ 
			$wxdebugstring = "--debug"
			Write-Host -NoNewline "building & installing..."
		    & $pythonroot\$pythonexe build-wxpython.py --build_dir=../build  --force_config --install $wxdebugstring 2>&1 >> $Log
		} else {
			Write-Host -NoNewline "building & installing..."
			& $pythonroot\$pythonexe build-wxpython.py --build_dir=../build  --force_config --install 2>&1 >> $Log
		}
		# the above assumes the core WX dll's will be installed to the system someplace on the PATH.
		# That's not what we want to do, so since these are gr-python-only DLLs, we'll put then in the site packages dir
		cp "$root/src-stage1-dependencies/wxpython/lib/vc140_dll/wx*.dll" "$pythonroot/Lib/site-packages/wx-3.0-msw/wx"
		#Write-Host -NoNewline "configing..."
		#& $pythonroot\$pythonexe setup.py clean 2>&1 >> $Log
		#& $pythonroot\$pythonexe setup.py config MONOLITHIC=1 2>&1 >> $Log
		#Write-Host -NoNewline "building..."
		#& $pythonroot\$pythonexe setup.py build $wxdebugstring MONOLITHIC=1 2>&1 >> $Log
		#Write-Host -NoNewline "installing..."
		#& $pythonroot\$pythonexe setup.py install 2>&1 >> $Log
		Write-Host -NoNewline "crafting wheel..."
		& $pythonroot\$pythonexe setup.py bdist_wininst UNICODE=1 BUILD_BASE=build 2>&1 >> $Log
		cd dist
		& $pythonroot/Scripts/wheel.exe convert wxpython-$wxpython_version.win-amd64-py2.7.exe 2>&1 >> $Log
		del wxpython-$wxpython_version.win-amd64-py2.7.exe
		move wx-3.0-cp27-none-win_amd64.whl wx-3.0-cp27-none-win_amd64.$configuration.whl -Force 2>&1 >> $Log
		move .\wxPython-common-$wxpython_version.win-amd64.exe .\wxPython-common-$wxpython_version.win-amd64.$configuration.exe -Force 2>&1 >> $Log
		$ErrorActionPreference = "Stop" 
		$env:_CL_ = ""
		$env:PATH = $oldPath
		Validate "$pythonroot\lib\site-packages\wx-3.0-msw\wx\_core_.pyd" "wx-3.0-cp27-none-win_amd64.$configuration.whl"
	} else {
		Write-Host "wxpython already built..."
	}

	#__________________________________________________________________________________________
	# cheetah
	#
	# will download and install Markdown automatically
	SetLog "$configuration cheetah"
	cd $root\src-stage1-dependencies\Cheetah-$cheetah_version
	if ((TryValidate "dist/Cheetah-$cheetah_version-cp27-cp27${d}m-win_amd64.$configuration.whl" "$pythonroot/lib/site-packages/Cheetah-$cheetah_version-py2.7-win-amd64.egg/Cheetah/_namemapper.pyd" "$pythonroot/lib/site-packages/Cheetah-$cheetah_version-py2.7-win-amd64.egg/Cheetah/Compiler.py") -eq $false) {
		Write-Host -NoNewline "building cheetah..."
		$ErrorActionPreference = "Continue"
		& $pythonroot/$pythonexe setup.py build  $debug 2>&1 >> $log
		Write-Host -NoNewline "installing..."
		& $pythonroot/$pythonexe setup.py install 2>&1 >> $log
		Write-Host -NoNewline "crafting wheel..."
		& $pythonroot/$pythonexe setup.py bdist_wheel 2>&1 >> $log
		move dist/Cheetah-$cheetah_version-cp27-cp27${d}m-win_amd64.whl dist/Cheetah-$cheetah_version-cp27-cp27${d}m-win_amd64.$configuration.whl -Force 2>&1 >> $log
		$ErrorActionPreference = "Stop"
		Validate "dist/Cheetah-$cheetah_version-cp27-cp27${d}m-win_amd64.$configuration.whl" "$pythonroot/lib/site-packages/Cheetah-$cheetah_version-py2.7-win-amd64.egg/Cheetah/_namemapper.pyd" "$pythonroot/lib/site-packages/Cheetah-$cheetah_version-py2.7-win-amd64.egg/Cheetah/Compiler.py"
	} else {
		Write-Host "cheetah already built..."
	}

	#__________________________________________________________________________________________
	# sphinx
	#
	# will also download/install a large number of dependencies
	# pytz, babel, colorama, snowballstemmer, sphinx-rtd-theme, six, Pygments, docutils, Jinja2, alabaster, sphinx
	# all are python only packages
	SetLog "$configuration sphinx"
	if ((TryValidate "$pythonroot/lib/site-packages/sphinx/__main__.py") -eq $false) {
		Write-Host -NoNewline "installing sphinx using pip..."
		$ErrorActionPreference = "Continue" # pip will "error" on debug
		& $pythonroot/Scripts/pip.exe --disable-pip-version-check  install -U sphinx -t $pythonroot\lib\site-packages 2>&1 >> $log
		$ErrorActionPreference = "Stop"
		Validate "$pythonroot/lib/site-packages/sphinx/__main__.py"
	} else {
		Write-Host "sphinx already installed..."
	}

	#__________________________________________________________________________________________
	# lxml
	#
	# this was a royal pain to get to statically link the dependent libraries
	# but now there are no dependencies, just install the wheel
	SetLog "$configuration lxml"
	cd $root\src-stage1-dependencies\lxml-lxml-$lxml_version
	$xsltconfig = ($configuration -replace "DLL", "")
	if ((TryValidate "dist/lxml-$lxml_version-cp27-cp27${d}m-win_amd64.$xsltconfig.whl" "$pythonroot/lib/site-packages/lxml-$lxml_version-py2.7-win-amd64.egg/lxml/etree.pyd") -eq $false) {
		Write-Host -NoNewline "configuring lxml..."
		$ErrorActionPreference = "Continue"
		New-Item -ItemType Directory -Force $root/src-stage1-dependencies/lxml-lxml-$lxml_version/libs/$xsltconfig 2>&1 >> $Log
		if ($type -match "AVX2") {$env:_CL_ = "/Ox /arch:AVX2 "} else {$env:_CL_ = ""}
		$env:_CL_ = $env:_CL_ + " /I$root/src-stage1-dependencies/libxml2/build/x64/$xsltconfig/include/libxml2 /I$root/src-stage1-dependencies/gettext-msvc/libiconv-1.14 /I$root/src-stage1-dependencies/libxslt-$libxslt_version/build/$xsltconfig/include "
		$env:_LINK_ = "/LIBPATH:$root/src-stage1-dependencies/libxslt-$libxslt_version/build/$xsltconfig/lib /LIBPATH:$root/src-stage1-dependencies/zlib-1.2.8/contrib/vstudio/vc14/x64/ZlibStat$xsltconfig /LIBPATH:$root/src-stage1-dependencies/libxml2/build/x64/$xsltconfig/lib /LIBPATH:$root/src-stage1-dependencies/gettext-msvc/x64/$xsltconfig"
		$env:LIBRARY = "$root/src-stage1-dependencies/lxml-lxml-$lxml_version/libs/$xsltconfig;$root/src-stage1-dependencies/libxslt-$libxslt_version/build/$xsltconfig/lib;$root/src-stage1-dependencies/zlib-1.2.8/contrib/vstudio/vc14/x64/ZlibStat$xsltconfig;$root/src-stage1-dependencies/libxml2/build/x64/$xsltconfig/lib;$root/src-stage1-dependencies/gettext-msvc/x64/$xsltconfig"
		$env:INCLUDE = "$root/src-stage1-dependencies/libxml2/build/x64/$xsltconfig/include/libxml2;$root/src-stage1-dependencies/gettext-msvc/libiconv-1.14;$root/src-stage1-dependencies/libxslt-$libxslt_version/build/$xsltconfig/include;$root/src-stage1-dependencies/lxml/src/lxml/includes"
		cp -Force $root/src-stage1-dependencies/libxml2/build/x64/$xsltconfig/lib/libxml2_a.lib $root/src-stage1-dependencies/lxml-lxml-$lxml_version/libs/$xsltconfig/libxml2_a.lib
		cp -Force $root/src-stage1-dependencies/gettext-msvc/x64/$xsltconfig/libiconv.lib $root/src-stage1-dependencies/lxml-lxml-$lxml_version/libs/$xsltconfig/iconv_a.lib
		& $pythonroot/$pythonexe setup.py clean 2>&1 >> $log
		if (Test-Path build) {del -Recurse -Force build}
		Write-Host -NoNewline "building..."
		& $pythonroot/$pythonexe setup.py build --static $debug 2>&1 >> $log
		Write-Host -NoNewline "installing..."
		& $pythonroot/$pythonexe setup.py install --static 2>&1 >> $log
		Write-Host -NoNewline "crafting wheel..."
		& $pythonroot/$pythonexe setup.py bdist_wheel --static 2>&1 >> $log
		move dist/lxml-$lxml_version-cp27-cp27${d}m-win_amd64.whl dist/lxml-$lxml_version-cp27-cp27${d}m-win_amd64.$xsltconfig.whl -Force 2>&1 >> $log
		$env:_CL_ = ""
		$env:_LINK_ = ""
		$env:LIBRARY = $oldlibrary
		$env:INCLUDE = $oldinclude
		$ErrorActionPreference = "Stop"
		Validate "dist/lxml-$lxml_version-cp27-cp27${d}m-win_amd64.$xsltconfig.whl" "$pythonroot/lib/site-packages/lxml-$lxml_version-py2.7-win-amd64.egg/lxml/etree.pyd"
	} else {
		Write-Host "lxml already built..."
	}

	#__________________________________________________________________________________________
	# pyzmq
	#
	SetLog "$configuration pyzmq"
	cd $root\src-stage1-dependencies\pyzmq-$pyzmq_version
	if ((TryValidate "wheels/pyzmq-$pyzmq_version-cp27-cp27${d}m-win_amd64.$configuration.whl" "$pythonroot/lib/site-packages/zmq/libzmq-v140-mt$flag-4_3_1.dll" "$pythonroot/lib/site-packages/zmq/devices/monitoredqueue.pyd" "$pythonroot/lib/site-packages/zmq/error.py") -eq $false) {
		Write-Host -NoNewline "configuring pyzmq..."
		if ($configuration -match "Debug") {$baseconfig="Debug"; $flag="-gd"} else {$baseconfig="Release"; $flag=""}
		$ErrorActionPreference = "Continue"
		# this stdint.h file prevents the import of the real stdint file and causes the build to fail
		# TODO submit upstream patch
		if (!(Test-Path wheels)) {mkdir wheels 2>&1 >> $log}
		if (Test-Path buildutils/include_win32/stdint.h) 
		{
			if (Test-Path buildutils/include_win32/stdint.old.h) {del buildutils/include_win32/stdint.old.h}
			Rename-Item -Force buildutils/include_win32/stdint.h stdint.old.h
		}
		New-Item -ItemType Directory -Force libzmq 2>&1 >> $log
		New-Item -ItemType Directory -Force libzmq/$configuration 2>&1 >> $log
		New-Item -ItemType Directory -Force libzmq/$configuration/lib 2>&1 >> $log
		New-Item -ItemType Directory -Force libzmq/$configuration/include 2>&1 >> $log
		Copy-Item ..\libzmq\include/*.h libzmq/$configuration/include/ 2>&1 >> $log
		Copy-Item ..\libzmq\bin\$baseconfig\bin\libzmq-v140-mt$flag-4_3_1.dll libzmq/$configuration/lib/ 2>&1 >> $log
		Copy-Item ..\libzmq\bin\$baseconfig\lib\libzmq-v140-mt$flag-4_3_1.lib libzmq/$configuration/lib/ 2>&1 >> $log
		if ($configuration -match "AVX2") {$env:_CL_ = " /arch:AVX2 "} else {$env:_CL_ = ""}
		$env:_LINK_ = " /MANIFEST /LIBPATH:libzmq/$configuration/lib "
		$env:INCLUDE = $oldinclude + ";$root/libzmq/include"
		$env:LINK = $oldlink
		# don't run clean because it wipes out /dist folder as well
		& $pythonroot/$pythonexe setup.py clean 2>&1 >> $log
		cp ..\libzmq\bin\$baseconfig\bin\libzmq-v140-mt$flag-4_3_1.dll .\zmq\libzmq.dll 
		if ($configuration -match "Debug") {
			cp ..\libzmq\bin\$baseconfig\bin\libzmq-v140-mt$flag-4_3_1.pdb .\zmq\libzmq.pdb 
		}
		& $pythonroot/$pythonexe setup.py configure $debug --zmq=./libzmq/$configuration --libzmq=libzmq-v140-mt$flag-4_3_1 2>&1 >> $log
		Write-Host -NoNewline "building..."
		& $pythonroot/$pythonexe setup.py build_ext $debug --inplace --zmq=./libzmq/$configuration --libzmq=libzmq-v140-mt$flag-4_3_1 2>&1 >> $log
		# TODO a pyzmq socket test is failing which then prompts user to debug so disable for now so we don't slow down the build process
		# Write-Host -NoNewline "testing..."
		# & $pythonroot/$pythonexe setup.py test 2>&1 >> $log
		Write-Host -NoNewline "installing..."
		& $pythonroot/$pythonexe setup.py install  --zmq=./libzmq/$configuration --libzmq=libzmq-v140-mt$flag-4_3_1 2>&1 >> $log
		Write-Host -NoNewline "crafting wheel..."
		& $pythonroot/$pythonexe setup.py bdist_wheel --zmq=./libzmq/$configuration 2>&1 >> $log
		# these can't be in dist because clean wipes out dist completely
		move dist/pyzmq-$pyzmq_version-cp27-cp27${d}m-win_amd64.whl wheels/pyzmq-$pyzmq_version-cp27-cp27${d}m-win_amd64.$configuration.whl -Force 2>&1 >> $log
		$env:_LINK_ = ""
		$env:_CL_ = ""
		$env:INCLUDE = $oldinclude
		$ErrorActionPreference = "Stop"
		Validate "wheels/pyzmq-$pyzmq_version-cp27-cp27${d}m-win_amd64.$configuration.whl" "$pythonroot/lib/site-packages/zmq/libzmq.dll" "$pythonroot/lib/site-packages/zmq/devices/monitoredqueue.pyd" "$pythonroot/lib/site-packages/zmq/error.py"
	} else {
		Write-Host "pyzmq already built..."
	}

	
	# ____________________________________________________________________________________________________________
	# tensorflow
	#
	# requires numpy
	#
	# Tensorflow won't build in debug mode because the cmake config assumes zlibstatic, not zlibstaticd, so even for debug builds we'll make the Release version.  Also RelWithDebInfo fails as well.
	# 3 files need to be change.:
	# farmhash.cmake to only have a single include dir (no /util)
	# Cmakelists.txt to allow cmake 3.3 and allow python 2.7 uniquely for us (since 2.7 should be compiled w/ 2008 but we don't)
	# zlib.cmake to change filename
	# need to add hacked create_def_file.py for py2.7
	#
	# need to also change dependencies for tf_core_kernels to wait for farmhash_copy_header project
	#
	# Finally, farmhash doesn't seem to change configurations well, and building in debug then release will leave /MDd libraries in release build.  So we need to add a clean.
	#
	SetLog "$configuration tensorflow"
	if ($configuration -match "Debug") {
		Write-Host "tensorflow skipped in debug..."
	} else {
		if ((TryValidate "$pythonroot/lib/site-packages/tensorflow/python/_pywrap_tensorflow_internal.pyd") -eq $false) {
			Write-Host -NoNewline "configuring $configuration tensorflow..."
			# We need to truncate the builddir or else we end up with a handful of files with paths that exceed max size and it fails.
			if ($configuration -match "AVX2") {$env:_CL_ = " /D__SSE__ /D__SSE2__ /D__SSE3__ /D__SSE4_1__ /D__SSE4_2__ /D__FMA__ /arch:AVX2 "; $builddir = "RelAVX2"} else {$env:_CL_ = " /D__SSE__ /D__SSE2__ "; $builddir=$configuration}
			if ($configuration -match "Release") {$buildconfig="Release"; $tfpythonexe = $pythonexe;$linkflags = "";$tests="ON"} else { $buildconfig="Debug"; $tfpythonexe = "python_d.exe";$linkflags = " /INCREMENTAL:NO /OPT:REF ";$tests="OFF"}
			New-Item -ItemType Directory -Force $root\src-stage1-dependencies\tensorflow\tensorflow\contrib\cmake\build\$builddir 2>&1 >> $Log
			cd $root\src-stage1-dependencies\tensorflow\tensorflow\contrib\cmake\build\$builddir
			$env:Path = "$pythonroot;$pythonroot\bin;$pythonroot\scripts;"+ $oldPath
			& cmake ..\.. `
				-G "Visual Studio 14 2015 Win64" `
				-DPYTHON_EXECUTABLE="$pythonroot\$tfpythonexe" `
				-DPYTHON_INCLUDE_DIR="$pythonroot\include" `
				-DNUMPY_INCLUDE_DIR="$pythonroot\lib\site-packages\numpy-$numpy_version-py2.7-win-amd64.egg\numpy\core\include" `
				-DPython_ADDITIONAL_VERSIONS="2.7" `
				-DPYTHON_LIBRARIES="$pythonroot\libs\python27.lib" `
				-DPYTHON_LIBRARY="$pythonroot\libs\python27.lib" `
				-DSWIG_EXECUTABLE="$root/bin/swig.exe" `
				-DCMAKE_BUILD_TYPE="$buildconfig" `
				-DCMAKE_INSTALL_PREFIX="$root\src-stage1-dependencies\tensorflow\tensorflow\contrib\cmake\dist\$configuration" `
				-Dtensorflow_BUILD_CC_TESTS=$tests `
				-Dtensorflow_BUILD_PYTHON_TESTS=$tests `
				-DCMAKE_SHARED_LINKER_FLAGS=" $linkflags " `
				-DCMAKE_EXE_LINKER_FLAGS=" $linkflags " `
				-DCMAKE_STATIC_LINKER_FLAGS=" $linkflags " `
				-DCMAKE_MODULE_LINKER_FLAGS=" $linkflags  " `
				-DCMAKE_CXX_FLAGS="$env:_CL_" 2>&1 >> $Log 
			Write-Host -NoNewline "building..."
			# some specific re-ordering of projects and renaming of files is required because of flaws in the cmakelists
			msbuild  zlib_copy_headers_to_destination.vcxproj /m /p:"configuration=$buildconfig;platform=x64;PreferredToolArchitecture=x64" 2>&1 >> $Log 
			if ($configuration -match "Debug") {
				Copy-Item -Force "zlib/install/lib/zlibstaticd.lib" "zlib/install/lib/zlibstatic.lib"
			}
			msbuild  png_copy_headers_to_destination.vcxproj /m /p:"configuration=$buildconfig;platform=x64;PreferredToolArchitecture=x64" 2>&1 >> $Log 
			if ($configuration -match "Debug") {
				Copy-Item -Force "png/install/lib/libpng12_staticd.lib" "png/install/lib/libpng12_static.lib"
			}
			msbuild  protobuf.vcxproj /m /p:"configuration=$buildconfig;platform=x64;PreferredToolArchitecture=x64" 2>&1 >> $Log 
			if ($configuration -match "Debug") {
				Copy-Item -Force "protobuf/src/protobuf/Debug/libprotobufd.lib" "protobuf/src/protobuf/Debug/libprotobuf.lib"
				Copy-Item -Force "protobuf/src/protobuf/Debug/libprotocd.lib" "protobuf/src/protobuf/Debug/libprotoc.lib"
			}
			msbuild  farmhash.vcxproj /t:Clean /p:"configuration=$buildconfig;platform=x64;PreferredToolArchitecture=x64" 2>&1 >> $Log 
			msbuild  farmhash_copy_headers_to_destination.vcxproj /m /p:"configuration=$buildconfig;platform=x64;PreferredToolArchitecture=x64" 2>&1 >> $Log 
			msbuild  tf_python_build_pip_package.vcxproj /m /p:"configuration=$buildconfig;platform=x64;PreferredToolArchitecture=x64" 2>&1 >> $Log 
			Write-Host -NoNewline "installing..."
			& $pythonroot\$pythonexe -m pip install .\tf_python\dist\tensorflow-1.1.0-cp27-cp27${d}m-win_amd64.whl --disable-pip-version-check 2>&1 >> $Log
			# TODO this step is just for troubleshooting
			# & $root\src-stage3\staged_install\Release-AVX2\gr-python27\$pythonexe -m pip install .\tf_python\dist\tensorflow-1.1.0rc0-cp27-cp27m-win_amd64.whl --disable-pip-version-check  --upgrade --no-deps --force-reinstall
			# msbuild  ALL_BUILD.vcxproj /m /p:"configuration=$buildconfig;platform=x64;PreferredToolArchitecture=x64"
			# & ctest -C Release
			# end troubleshooting
			Validate "$pythonroot/lib/site-packages/tensorflow/python/_pywrap_tensorflow_internal.pyd"
			$env:_CL_ = ""
		} else {
			Write-Host "tensorflow already built..."
		}
	}
	
	# ____________________________________________________________________________________________________________
	# matplotlib
	#
	# required by gr-radar
	#
	# Most important part is to set up the paths correctly so it finds all the possible back ends it can use.  The code for the checks is all in buildext.py
	# And since we haven't consolidated the libraries yet (that's step 5) we need to do add a bunch of different paths to the environment vars.
	#
	SetLog "$configuration matplotlib"
	cd $root\src-stage1-dependencies\matplotlib-$matplotlib_version
	if ((TryValidate "dist/matplotlib-$matplotlib_version-cp27-cp27${d}m-win_amd64.$configuration.whl" "$pythonroot/lib/site-packages/matplotlib-$matplotlib_version-py2.7-win-amd64.egg/pylab.py" "$pythonroot/lib/site-packages/matplotlib-$matplotlib_version-py2.7-win-amd64.egg/matplotlib/_path$debugext.pyd" ) -eq $false) {
		$ErrorActionPreference = "Continue"
		Write-Host -NoNewline "configuring $configuration matplotlib..."
		if ($configuration -match "Release") {$buildlibdir = "Release"} else {$buildlibdir = "Debug"}
		if ($configuration -match "AVX2") {$env:_CL_ = " /arch:AVX2 /EHsc "; $buildlibdir = "Release-AVX2"} else {$env:_CL_ = " /EHsc "}
		$env:INCLUDE = "$pythonroot\Include\pygtk-2.0;$root/src-stage1-dependencies/x64/include;$root/src-stage1-dependencies/x64/include/cairo;$root/src-stage1-dependencies/x64/lib/gtk-2.0/include;" + $oldInclude
		$env:Path = "$root/build/$buildlibdir/lib;$pythonroot;$pythonroot/Dlls;$pythonroot\scripts;$root/src-stage1-dependencies/x64/include;$pythonroot\Include\pygtk-2.0\;$pythonroot/include;$pythonroot/Lib/site-packages/wx-3.0-msw;$root\src-stage1-dependencies\x64\bin;$root\src-stage1-dependencies\Qt5\build\$configuration\bin;$root\src-stage1-dependencies\Qt4\build\$configuration\bin;"+ $oldPath
		$env:PYTHONPATH="$pythonroot/Lib/site-packages/wx-3.0-msw;$pythonroot/Lib/site-packages;$pythonroot/Lib/site-packages/gtk-2.0;$pythonroot\Include\pygtk-2.0\"
		$env:_LINK_ = " /DEBUG "
		Write-Host -NoNewline "building and installing..."
		& $pythonroot/$pythonexe setup.py build $debug install 2>&1 >> $log
		Write-Host -NoNewline "creating wheel..."
		& $pythonroot/$pythonexe setup.py bdist_wheel   2>&1 >> $log
		$env:_LINK_ = ""
		move dist/matplotlib-$matplotlib_version-cp27-cp27${d}m-win_amd64.whl dist/matplotlib-$matplotlib_version-cp27-cp27${d}m-win_amd64.$configuration.whl -Force
		$ErrorActionPreference = "Stop"
		Validate "dist/matplotlib-$matplotlib_version-cp27-cp27${d}m-win_amd64.$configuration.whl" "$pythonroot/lib/site-packages/matplotlib-$matplotlib_version-py2.7-win-amd64.egg/pylab.py" "$pythonroot/lib/site-packages/matplotlib-$matplotlib_version-py2.7-win-amd64.egg/matplotlib/_path$debugext.pyd" 
		$env:INCLUDE = $oldinclude
		$env:_CL_ = ""
		$env:Path = $oldPath
		$env:PYTHONPATH = ""
	} else {
		Write-Host "matplotlib already built..."
	}


	# ____________________________________________________________________________________________________________
	# Python Imaging Library (PIL)
	#
	# required by gr-paint
	#
	SetLog "$configuration Python Imaging Library"
	cd $root\src-stage1-dependencies\Imaging-$PIL_version
	if ((TryValidate "dist/PIL-$PIL_version-cp27-none-win_amd64.$configuration.whl" "$pythonroot/lib/site-packages/PIL/_imaging$debugext.pyd") -eq $false) {
		Write-Host -NoNewline "configuring $configuration PIL..."
		if ($configuration -match "AVX2") {$env:_CL_ = " /arch:AVX2 "} else {$env:_CL_ = ""}
		$env:Path = "$pythonroot;$pythonroot/Dlls;$pythonroot\scripts;$root/src-stage1-dependencies/x64/include;$pythonroot/include;$pythonroot/Lib/site-packages/wx-3.0-msw;"+ $oldPath
		$env:PYTHONPATH="$pythonroot/Lib/site-packages/wx-3.0-msw;$pythonroot/Lib/site-packages;$pythonroot/Lib/site-packages/gtk-2.0"
		Write-Host -NoNewline "building and installing..."
		$ErrorActionPreference = "Continue"
		& $pythonroot/$pythonexe setup.py build $debug install 2>&1 >> $log
		Write-Host -NoNewline "creating wheel..."
		& $pythonroot/$pythonexe setup.py bdist_wininst   2>&1 >> $log
		cd dist
		& $pythonroot/Scripts/wheel.exe convert PIL-$PIL_version.win-amd64-py2.7.exe 2>&1 >> $log
		$env:_LINK_ = ""
		move PIL-$PIL_version-cp27-none-win_amd64.whl PIL-$PIL_version-cp27-none-win_amd64.$configuration.whl -Force 2>&1 >> $log
		$ErrorActionPreference = "Stop"
		Validate "PIL-$PIL_version-cp27-none-win_amd64.$configuration.whl" "$pythonroot/lib/site-packages/PIL/_imaging$debugext.pyd"
		$env:_CL_ = ""
		$env:Path = $oldPath
		$env:PYTHONPATH = ""
		$ErrorActionPreference = "Stop"
	} else {
		Write-Host "PIL already built..."
	}

	# ____________________________________________________________________________________________________________
	# bitarray
	#
	# required by gr-burst
	#
	SetLog "$configuration bitarray"
	cd $root\src-stage1-dependencies\bitarray-$bitarray_version
	if ((TryValidate "dist/bitarray-$bitarray_version-cp27-cp27${d}m-win_amd64.$configuration.whl" "$pythonroot/lib/site-packages/bitarray-$bitarray_version-py2.7-win-amd64.egg/bitarray/_bitarray$debugext.pyd") -eq $false) {
		Write-Host -NoNewline "configuring $configuration bitarray..."
		if ($configuration -match "AVX2") {$env:_CL_ = " /arch:AVX2 "} else {$env:_CL_ = ""}
		$env:Path = "$pythonroot;$pythonroot/Dlls;$pythonroot\scripts;$root/src-stage1-dependencies/x64/include;$pythonroot/include;$pythonroot/Lib/site-packages/wx-3.0-msw;"+ $oldPath
		$env:PYTHONPATH="$pythonroot/Lib/site-packages/wx-3.0-msw;$pythonroot/Lib/site-packages;$pythonroot/Lib/site-packages/gtk-2.0"
		Write-Host -NoNewline "building and installing..."
		$ErrorActionPreference = "Continue"
		& $pythonroot/$pythonexe setup.py build $debug install 2>&1 >> $log
		Write-Host -NoNewline "creating wheel..."
		& $pythonroot/$pythonexe setup.py bdist_wheel   2>&1 >> $log
		cd dist
		$env:_LINK_ = ""
		move bitarray-$bitarray_version-cp27-cp27${d}m-win_amd64.whl bitarray-$bitarray_version-cp27-cp27${d}m-win_amd64.$configuration.whl -Force 2>&1 >> $log
		$ErrorActionPreference = "Stop"
		Validate "bitarray-$bitarray_version-cp27-cp27${d}m-win_amd64.$configuration.whl" "$pythonroot/lib/site-packages/bitarray-$bitarray_version-py2.7-win-amd64.egg/bitarray/_bitarray$debugext.pyd"
		$env:_CL_ = ""
		$env:Path = $oldPath
		$env:PYTHONPATH = ""
		$ErrorActionPreference = "Stop"
	} else {
		Write-Host "bitarray already built..."
	}

	"finished installing python packages for $configuration"
}

$pythonexe = "python.exe"
SetLog("Setting up Python")
$pythonroot = "$root\src-stage2-python\gr-python27"
SetupPython "ReleaseDLL"
SetLog("Setting up AVX2 Python")
$pythonroot = "$root\src-stage2-python\gr-python27-avx2"
SetupPython "ReleaseDLL-AVX2"
SetLog("Setting up debug Python")
$pythonexe = "python_d.exe"
$pythonroot = "$root\src-stage2-python\gr-python27-debug"
SetupPython "DebugDLL"

cd $root/scripts 

""
"COMPLETED STEP 4: Python dependencies / packages have been built and installed"
""


if ($false)
{
	# these are just here for quick debugging
	$root="Z:\gr-build"
	ResetLog

	$configuration = "ReleaseDLL"
	$pythonroot = "$root\src-stage2-python\gr-python27"
	$pythonexe = "python.exe"
	$d = ""
	$debug = ""

	$configuration = "ReleaseDLL-AVX2"
	$pythonroot = "$root\src-stage2-python\gr-python27-avx2"
	$pythonexe = "python.exe"
	$d = ""
	$debug = ""

	$configuration = "DebugDLL"
	$pythonroot = "$root\src-stage2-python\gr-python27-debug"
	$pythonexe = "python_d.exe"
	$d = "d"
	$debug = "--debug"
}
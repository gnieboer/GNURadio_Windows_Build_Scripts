#
# Step7BuildGNURadio.ps1
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

# prep for cmake
if (!(Test-Path $root/src-stage3/build)) {
	cd $root/src-stage3
	mkdir build >> $null
} 

if (!(Test-Path $root/src-stage3/staged_install)) {
	cd $root/src-stage3
	mkdir staged_install >> $null
} 

function BuildGNURadio {
	$configuration = $args[0]
	if ($configuration -match "Release") {$runtime = "/MD"; $buildtype = "relwithDebInfo"; $d=""} else {$runtime = "/MDd"; $buildtype = "DEBUG"; $d="d"}
	if ($configuration -match "AVX") {$DLLconfig="ReleaseDLL-AVX2"; $archflag="/arch:AVX2 /Ox /GS- /EHsc"} else {$DLLconfig = $configuration + "DLL"; $archflag="/EHsc"}

	# prep for cmake
	SetLog "Build GNURadio $configuration"
	if (!(Test-Path $root/src-stage3/staged_install/$configuration)) {
		cd $root/src-stage3/staged_install
		mkdir $configuration
	} 
	if (!(Test-Path $root/src-stage3/build/$configuration)) {
		cd $root/src-stage3/build
		mkdir $configuration
	} 
	cd $root/src-stage3/build/$configuration
	if (Test-Path CMakeCache.txt) {Remove-Item -Force CMakeCache.txt} # Don't keep the old cache because if the user is fixing a config problem it may not re-check the fix

	$env:PATH = "$root/build/$configuration/lib;$pythonroot;$pythonroot/Dlls" + $oldPath
	$env:PYTHONPATH="$pythonroot/Lib/site-packages"

	# set PYTHONPATH=%~dp0..\gr-python$pyver\Lib\site-packages; %~dp0..\gr-python$pyver\dlls;%~dp0..\gr-python$pyver\libs;%~dp0..\gr-python$pyver\lib;%~dp0..\lib\site-packages;%~dp0..\gr-python$pyver\Lib\site-packages\pkgconfig;%~dp0..\gr-python$pyver\Lib\site-packages\gtk-2.0\glib;%~dp0..\gr-python$pyver\Lib\site-packages\gtk-2.0;%~dp0..\gr-python$pyver\Lib\site-packages\wx-3.0-msw;%~dp0..\gr-python$pyver\Lib\site-packages\sphinx;%~dp0..\gr-python$pyver\Lib\site-packages\lxml-3.4.4-py2.7-win.amd64.egg;%~dp0..\lib\site-packages\gnuradio\gr;%~dp0..\lib\site-packages\pmt;%~dp0..\lib\site-packages\gnuradio\blocks;%~dp0..\lib\site-packages\gnuradio\fec;%~dp0..\lib\site-packages\gnuradio\fft;%~dp0..\lib\site-packages\gnuradio\qtgui;%~dp0..\lib\site-packages\gnuradio\trellis;%~dp0..\lib\site-packages\gnuradio\vocoder;%~dp0..\lib\site-packages\gnuradio\audio;%~dp0..\lib\site-packages\gnuradio\channels;%~dp0..\lib\site-packages\gnuradio\ctrlport;%~dp0..\lib\site-packages\gnuradio\digital;%~dp0..\lib\site-packages\gnuradio\grc;%~dp0..\lib\site-packages\gnuradio\filter;%~dp0..\lib\site-packages\gnuradio\analog;%~dp0..\lib\site-packages\gnuradio\wxgui;%~dp0..\lib\site-packages\gnuradio\zeromq;%~dp0..\lib\site-packages\gnuradio\pager;%~dp0..\lib\site-packages\gnuradio\fcd;%~dp0..\lib\site-packages\gnuradio\video_sdl;%~dp0..\lib\site-packages\gnuradio\wavelet;%~dp0..\lib\site-packages\gnuradio\noaa;%~dp0..\lib\site-packages\gnuradio\dtv;%~dp0..\lib\site-packages\gnuradio\atsc;%~dp0..\lib\site-packages\gnuradio\pmt
	# test notes... the following qa batch files must have the pythonpath prepended instead of appended:
	# qa_tag_utils_test.bat requires this pythonpath: Z:/gr-build/src-stage3/src/gnuradio/gnuradio-runtime/python;Z:\gr-build\src-stage3\build\Release\gnuradio-runtime\swig\RelWithDebInfo;Z:\gr-build\src-stage3\build\Release\gnuradio-runtime\python;;Z:\gr-build\src-stage3\build\Release\gnuradio-runtime\swig
	# qa_socket_pdu_test.bat
	# qa_burst_shaper_test.bat
	#
	# There are a couple pulls requests pending to fix several test failures, at those a couple are left
	# qa_agc will also fail for legit reasons still unknown, even after alignment gets fixed.  agc3 isn't converging as fast as it should
	# qa_tcp_server_sink will fail because it in TCP source/sink is incompatible with windows
	# qa_file_source_sink will fail because of the way the locking/opening of temp files varies in python between windows and linux


	$env:_CL_ = ""
	$env:_LINK_ = ""
	$ErrorActionPreference = "Continue"
	$libzmquv = $libzmq_version -Replace '\.','_'
	if ($configuration -match "Debug") { $libzmquv = "gd-" + $libzmquv}
	# Always use the DLL version of Qt to avoid errors about parent being on a different thread.
	cmake ../../src/gnuradio `
		-G $cmakeGenerator -A x64 `
		-DPYTHON_EXECUTABLE="$pythonroot\$pythonexe" `
		-DQA_PYTHON_EXECUTABLE="$pythonroot\$pythonexe" `
		-DPYTHON_LIBRARY="$pythonroot\Libs\python$pyver.lib" `
		-DPYTHON_INCLUDE_DIR="$pythonroot\include"  `
		-DBoost_NO_SYSTEM_PATHS=ON `
		-DQT_QMAKE_EXECUTABLE="$root/build/$configuration/bin/qmake.exe" `
		-DQT_UIC_EXECUTABLE="$root/build/$configuration/bin/uic.exe" `
		-DQT_MOC_EXECUTABLE="$root/build/$configuration/bin/moc.exe" `
		-DQT_RCC_EXECUTABLE="$root/build/$configuration/bin/rcc.exe" `
		-DQWT_INCLUDE_DIRS="$root/build/$configuration/include/qwt6" `
		-DQWT_LIBRARIES="$root/build/$configuration/lib/qwt6.lib" `
		-DSWIG_EXECUTABLE="$root/bin/swig.exe" `
		-DZEROMQ_LIBRARY_NAME="libzmq-v140-mt-$libzmquv" `
		-DCMAKE_PREFIX_PATH="$root/build/$configuration" `
		-DCMAKE_INSTALL_PREFIX="$root/src-stage3/staged_install/$configuration/" `
		-DCMAKE_CXX_FLAGS="$archflag $runtime /W1 /DGSL_DLL /DBOOST_BIND_GLOBAL_PLACEHOLDERS " `
		-DCMAKE_C_FLAGS="$archflag $runtime /W1 /DGSL_DLL " `
		-DCMAKE_SHARED_LINKER_FLAGS=" /DEBUG /opt:ref,icf " `
		-DSPHINX_EXECUTABLE="$pythonroot/Scripts/sphinx-build.exe" `
		-DCMAKE_BUILD_TYPE="$buildtype" `
		-Wno-dev
	$ErrorActionPreference = "Stop"
	
	# before we build we need to trim from SWIG cmd.exe lines in the VS projects, as cmd.exe has a 8192 character limit, and some of the swig commands will likely be > 9000
	# the good news is that the includes are very repetitive so we can use a swizzy regex to get rid to them
	# These directories may not exist in GR 3.8
	Write-Host -NoNewline "Fixing swig > 8192 char includes..."
	Function FixSwigIncludes
	{
		$filename = $args[0]
		(Get-Content -Path "$filename") `
			-replace '(-I[^ \n]+)[ ](?=.+?[ ]\1[ ])(?<=.+swig\.exe.+)', '' | Out-File -Encoding utf8 "$filename.temp" 
		Copy-Item -Force "$filename.temp" "$filename"
		Remove-Item "$filename.temp"	
	}
	if (Test-Path -Path "$root\src-stage3\build\$configuration\gr-blocks\swig\blocks_swig5_gr_blocks_swig_a6e57.vcxproj") { FixSwigIncludes "$root\src-stage3\build\$configuration\gr-blocks\swig\blocks_swig5_gr_blocks_swig_a6e57.vcxproj"}
	if (Test-Path -Path "$root\src-stage3\build\$configuration\gr-blocks\swig\blocks_swig4_gr_blocks_swig_a6e57.vcxproj") { FixSwigIncludes "$root\src-stage3\build\$configuration\gr-blocks\swig\blocks_swig4_gr_blocks_swig_a6e57.vcxproj"}
	"complete"

	# NOW we build gnuradio finally
	Write-Host -NoNewline "Build GNURadio $configuration..."
	Write-Host -NoNewline "building..." 
	msbuild .\gnuradio.sln /m /p:"configuration=$buildtype;platform=x64" *>> $Log 
	Write-Host -NoNewline "staging install..."
	msbuild INSTALL.vcxproj  /m  /p:"configuration=$buildtype;platform=x64;BuildProjectReferences=false" *>> $Log 

	# Then combine it into a useable staged install with the dependencies it will need
	Write-Host -NoNewline "moving add'l libraries..."
	cp -Recurse -Force $root/build/$configuration/lib/*.dll $root\src-stage3\staged_install\$configuration\bin\  *>> $Log 
	# It appears pip install PyQt5 will handle all our Qt5 needs
	#cp -Recurse -Force $root/build/$configuration/bin/Qt5Svg.dll $root\src-stage3\staged_install\$configuration\bin\  *>> $Log 
	#cp -Recurse -Force $root/build/$configuration/bin/Qt5OpenGL.dll $root\src-stage3\staged_install\$configuration\bin\  *>> $Log 
	#cp -Recurse -Force $root/build/$configuration/bin/Qt5Widgets.dll $root\src-stage3\staged_install\$configuration\bin\  *>> $Log 
	#cp -Recurse -Force $root/build/$configuration/bin/Qt5Gui.dll $root\src-stage3\staged_install\$configuration\bin\  *>> $Log 
	#cp -Recurse -Force $root/build/$configuration/bin/Qt5Core.dll $root\src-stage3\staged_install\$configuration\bin\  *>> $Log 
	#cp -Recurse -Force $root/build/$configuration/bin/plugins $root\src-stage3\staged_install\$configuration\bin\  *>> $Log 
	cp -Recurse -Force $root/build/$configuration/lib/gobject-introspection $root\src-stage3\staged_install\$configuration\lib\  *>> $Log 
	cp -Recurse -Force $root/build/$configuration/lib/girepository-1.0 $root\src-stage3\staged_install\$configuration\lib\  *>> $Log 
	cp -Recurse -Force $root/build/$configuration/lib/gdk-pixbuf-2.0 $root\src-stage3\staged_install\$configuration\lib\  *>> $Log 
	cp -Recurse -Force $root/build/$configuration/bin/gsettings.exe $root\src-stage3\staged_install\$configuration\bin\  *>> $Log 
	cp -Recurse -Force $root/build/$configuration/share/glib-2.0 $root\src-stage3\staged_install\$configuration\share\  *>> $Log 
	cp -Recurse -Force $root/build/$configuration/share/gir-1.0 $root\src-stage3\staged_install\$configuration\share\  *>> $Log 
	"complete"

	Write-Host -NoNewline "moving python..."
	Copy-Item -Force -Recurse -Path $pythonroot $root/src-stage3/staged_install/$configuration  *>> $Log
	if ((Test-Path $root/src-stage3/staged_install/$configuration/gr-python$pyver) -and (($pythonroot -match "avx2") -or ($pythonroot -match "debug"))) 
	{
		del -Recurse -Force $root/src-stage3/staged_install/$configuration/gr-python$pyver
	}
	if ($pythonroot -match "avx2") {Rename-Item $root/src-stage3/staged_install/$configuration/gr-python$pyver-avx2 $root/src-stage3/staged_install/$configuration/gr-python$pyver}
	if ($pythonroot -match "debug") {Rename-Item $root/src-stage3/staged_install/$configuration/gr-python$pyver-debug $root/src-stage3/staged_install/$configuration/gr-python$pyver}
	if ($configuration -match "debug") {
		# calls python_d.exe instead
		Copy-Item -Force -Path $root\src-stage3\src\run_gr_d.bat $root/src-stage3/staged_install/$configuration/bin/run_gr.bat  *>> $Log
	} else {
		Copy-Item -Force -Path $root\src-stage3\src\run_gr.bat $root/src-stage3/staged_install/$configuration/bin  *>> $Log
	}
	Copy-Item -Force -Path $root\src-stage3\src\run_GRC.bat $root/src-stage3/staged_install/$configuration/bin  *>> $Log
	Copy-Item -Force -Path $root\src-stage3\src\run_gqrx.bat $root/src-stage3/staged_install/$configuration/bin  *>> $Log
	Copy-Item -Force -Path $root\src-stage3\src\gr_filter_design.bat $root/src-stage3/staged_install/$configuration/bin  *>> $Log
	Copy-Item -Force -Recurse -Path $root\src-stage3\icons $root/src-stage3/staged_install/$configuration/share  *>> $Log

	# ensure the GR build went well by checking for newmod package, and if found then build
	Validate  $root/src-stage3/staged_install/$configuration/share/gnuradio/modtool/templates/gr-newmod/CMakeLists.txt
	New-Item -Force -ItemType Directory $root/src-stage3/staged_install/$configuration/share/gnuradio/modtool/templates/gr-newmod/build 
	cd $root/src-stage3/staged_install/$configuration/share/gnuradio/modtool/templates/gr-newmod/build

	$ErrorActionPreference = "Continue"
	cmake ../ `
		-G $cmakeGenerator -A x64 `
		-DPYTHON_EXECUTABLE="$pythonroot\$pythonexe" `
		-DQA_PYTHON_EXECUTABLE="$pythonroot\$pythonexe" `
		-DCMAKE_PREFIX_PATH="$root\build\$configuration" `
		-DCMAKE_INSTALL_PREFIX="$root/src-stage3/staged_install/$configuration/" `
		-Wno-dev
	$ErrorActionPreference = "Stop"
	msbuild .\gr-howto.sln /m /p:"configuration=$buildtype;platform=x64" *>> $Log
	msbuild INSTALL.vcxproj  /m  /p:"configuration=$buildtype;platform=x64;BuildProjectReferences=false" *>> $Log
	$env:_CL_ = ""
	$env:_LINK_ = ""
	
	Write-Host -NoNewline "confirming AVX configuration..."
	CheckNoAVX "$root/src-stage3/staged_install/$configuration"

	"complete"
}

# Release build
if ($configmode -eq "1" -or $configmode -eq "all") {
	BuildGNURadio "Release"
}


""
"COMPLETED STEP 7: Core GNURadio has been built from source"
""


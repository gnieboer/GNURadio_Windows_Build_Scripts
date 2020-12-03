# GNURadio Windows Build System
# Geof Nieboer
#
Write-Host "Welcome to GNURadio windows build and installation script."
Write-Host ""
Write-Host "This script can build GNURadio and every dependency needed using Visual Studio 2017+"
Write-Host "to ensure version and binary compatibility."
Write-Host ""
Write-Host "This build script also includes a number of OOT packages in the final installer"
Write-Host "This version currently builds and includes:"
Write-Host "- UHD drivers"
Write-Host "- airspy drivers"
Write-Host "- bladeRF drivers"
Write-Host "- RTL-SDR drivers"
Write-Host "- HackRF drivers"
Write-Host "- gr-osmocomsdr"
Write-Host "- gr-iqimbalance"
Write-Host "- gr-benchmark"
Write-Host "- gr-fosphor"
Write-Host "- gr-adsb"
Write-Host "- gr-acars2"
Write-Host ""
Write-Host "The only GNURadio component not currently built is gr-comedi."
Write-Host ""
Write-Host "You must be connected to the internet to run this script."
Write-Host "Downloaded packages will be cached in the packages subdir."
Write-Host ""
Write-Host "This script can build GNURadio in two different ways:"
Write-Host "1- Compile every dependency from source right now [LONGEST]"
Write-Host "2- Download all dependencies, including custom python, as binaries and build GNURadio"
Write-Host "   only from source"
Write-Host ""

$buildoption = Read-Host "Please choose an option (1,2)<2>"
if (!$buildoption) {$buildoption = "2"}
if ($buildoption -ne "1" -and $buildoption -ne "2" ) 
{
    Write-Host "'$buildoption' was not a valid choice.  Exiting script."
    return
}
Write-Host ""

if ($script:MyInvocation.MyCommand.Path -eq $null) {
    $mypath = "."
} else {
    $mypath =  Split-Path $script:MyInvocation.MyCommand.Path
}
. $mypath\Setup.ps1 -Force
SetLog "Initial Configuration"

Write-Host "Dependencies checked passed: VS 2017+, git, perl, cmake, 7-zip, & doxygen are installed."
if ($hasIFORT -and $buildoption -eq "1") 
{
    Write-Host "Intel Fortran compiler has been detected.  Numpy/Scipy will be built from source"
} elseif ($buildoption -eq "1") {
    Write-Host "Intel Fortran compiler not installed.  Numpy/Scipy will be installed from wheels"
}
Write-Host ""
$defaultroot = Split-Path (Split-Path -Parent $script:MyInvocation.MyCommand.Path)
$Global:root = Read-Host "Please choose an absolute root directory for this build <$defaultroot>"
if (!$root) {$root = $defaultroot}
if (!(Test-Path -isValid -LiteralPath $root)) {
    Write-Host "'$root' is not a valid path.  Exiting script."
    return
}
if (![System.IO.Path]::IsPathRooted($root)) {
    Write-Host "'$root' is not an absolute path.  Exiting script."
    return
}
# need this fixed for the qt.conf file in Step5/5a
$root = $root -replace "\\", "/"

if ( $buildoption -eq "1")
{
	Write-Host ""
	Write-Host "By default, GNURadio uses only open source libraries.  However, if you have Intel MKL installed"
	Write-Host "the script can find it and use it to build numpy and scipy, which are significantly faster than"
	Write-Host "the MSVC version of OpenBLAS.  However, the resulting products CANNOT be distributed as it"
	Write-Host "would violate the GPL."
	Write-Host ""
	$useMKLstr = Read-Host "Use MKL libraries if available? <N>"
}
if ($useMKLstr -match "y") {$Global:BuildNumpyWithMKL = $true} else {$Global:BuildNumpyWithMKL = $false}

if ( $buildoption -eq "2")
{
	Write-Host ""
	Write-Host "This script can build 3 different configurations of GNURadio:"
	Write-Host "1- Release"
	Write-Host "2- Release, optimized for AVX2 cpu's only.  Fastest, but will crash on non-AVX2 processors!"
	Write-Host "3- Debug"
	Write-Host "Or, the script can build all three versions so all the dependencies are available to you."
	Write-Host ""
	$Global:configmode = Read-Host "What configuration do you want to build? (1,2,3,all)<1>"
}
if (!$configmode) {$configmode = "all"}
if (($configmode -ne "1" -and $configmode -ne "2" -and $configmode -ne "3" -and $configmode -ne "all")) {
    Write-Host "That was not a valid choice.  Exiting script"
    return
}

if ($buildoption -eq "1") {$numberof = 2}
if ($buildoption -eq "2") {$numberof = .3}
if ($configmode -eq "all") {$numberof = $numberof * 3}

Write-Host ""
Write-Host "Thank you.  Package download will occur first, then compilation and build will begin."
Write-Host "Building will take about $numberof hours on a Intel i7-5930X machine"
Write-Host "After downloads are complete.  Logs can be found in $root/Logs if the build fails."
Write-Host ""

# RUN

if ($buildoption -eq "1") 
{
	& $root\scripts\Step2-GetStage1Packages.ps1
	& $root\scripts\Step3-BuildStage1Packages.ps1 
	& $root\scripts\Step4-BuildPythonPackages.ps1 
	& $root\scripts\Step5-ConsolidateLibs.ps1 
} else {
    & $root\scripts\Step5a-DownloadDependencies.ps1 
}

& $root\scripts\Step6-GetStage3Packages.ps1
& $root\scripts\Step7-BuildGNURadio.ps1 $configmode
& $root\scripts\Step8-BuildOOTModules.ps1 $configmode
& $root\scripts\Step9-BuildMSI.ps1 $configmode 
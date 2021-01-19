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
Write-Host "- gr-osmosdr"
Write-Host "- gr-benchmark"
Write-Host "- gr-fosphor"
Write-Host "- gr-adsb"
Write-Host "- gr-acars2"
Write-Host ""
Write-Host "You must be connected to the internet to run this script."
Write-Host ""

# Deprecated settings
$buildoption = 1 # build all
$Global:configmode = 1 # Release only

if ($script:MyInvocation.MyCommand.Path -eq $null) {
    $mypath = "."
} else {
    $mypath =  Split-Path $script:MyInvocation.MyCommand.Path
}
. $mypath\Setup.ps1 -Force
SetLog "Initial Configuration"

Write-Host "Dependencies checked passed: VS 2017+, git, perl, cmake, 7-zip, & doxygen are installed."
if ($hasIFORT) 
{
    Write-Host "Intel Fortran compiler has been detected.  gr-specest will be built from source"
} else {
    Write-Host "Intel Fortran compiler not installed.  gr-specest will be installed from wheels"
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

Write-Host ""
Write-Host "Thank you."
Write-Host "Download and build will take about 6 hours on a Intel i7-5930X machine depending on your internet connection speed"
Write-Host "Logs can be found in $root/Logs if the build fails."
Write-Host ""

# RUN
& $root\scripts\Step2-GetStage1Packages.ps1
& $root\scripts\Step3a-BuildStage1Packages.ps1 
& $root\scripts\Step4-BuildPythonPackages.ps1 
& $root\scripts\Step5-ConsolidateLibs.ps1 
& $root\scripts\Step6-GetStage3Packages.ps1
& $root\scripts\Step7-BuildGNURadio.ps1 $configmode
& $root\scripts\Step8-BuildOOTModules.ps1 $configmode
& $root\scripts\Step9-BuildMSI.ps1 $configmode 
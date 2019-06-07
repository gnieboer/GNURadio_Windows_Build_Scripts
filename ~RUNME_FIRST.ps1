# GNURadio Windows Build System
# Geof Nieboer
#
# RUNME_FIRST.ps1
#
$ErrorActionPreference = "Stop"

$Global:root = Read-Host "Please choose an absolute root directory for this build. <Z:\gr-build>"
if (!$root) {$root = "Z:\gr-build"}
if (!(Test-Path -isValid -LiteralPath $root)) {
    Write-Host "'$root' is not a valid path.  Exiting script."
    return
}
if (![System.IO.Path]::IsPathRooted($root)) {
    Write-Host "'$root' is not an absolute path.  Exiting script."
    return
}
if ($root.length -gt 11)
{
    Write-Host "'$root' cannot be longer than 11 chars due to filename length errors that would occur during build, please choose a different root.  Exiting script."
	# These errors will manifest themselves in a couple places, but tensorflow is currently the most sensitive to this problem.
    return
}

# setup
"Performing initial setup"
Write-Host "Setting up directories and checking dependencies..." 

# set up enough to import setup.ps1 and start logging
New-Item -ItemType Directory -Force -Path $root > $null
New-Item -ItemType Directory -Force -Path "$root\logs" > $null

if ($script:MyInvocation.MyCommand.Path -eq $null) {
    $mypath = "."
} else {
    $mypath =  Split-Path $script:MyInvocation.MyCommand.Path
}
. $mypath\Setup.ps1 -Force
ResetLog
SetLog "Initial Configuration"

# build basic directories

New-Item -ItemType Directory -Force -Path "$root\bin" >> $Log
New-Item -ItemType Directory -Force -Path "$root\build" >> $Log
New-Item -ItemType Directory -Force -Path "$root\include" >> $Log
New-Item -ItemType Directory -Force -Path "$root\packages" >> $Log
New-Item -ItemType Directory -Force -Path "$root\src-stage1-dependencies" >> $Log
New-Item -ItemType Directory -Force -Path "$root\src-stage2-python" >> $Log
New-Item -ItemType Directory -Force -Path "$root\src-stage3" >> $Log
New-Item -ItemType Directory -Force -Path "$root\src-stage3\src" >> $Log
New-Item -ItemType Directory -Force -Path "$root\src-stage3\oot_code" >> $Log
New-Item -ItemType Directory -Force -Path "$root\src-stage4-installer" >> $Log
New-Item -ItemType Directory -Force -Path "$root\scripts" >> $Log
robocopy $mypath/bin $root/bin /e >> $Log
Copy-Item $mypath/wix/*.* $root/src-stage4-installer -Recurse -Force >> $Log
Copy-Item $mypath/run/*.bat $root\src-stage3\src -Force
Copy-Item $mypath/*.ps1 $root/scripts -Force >> $Log
Copy-Item $mypath/*.psd1 $root/scripts -Force >> $Log
Copy-Item $mypath/icons $root\src-stage3 -Recurse -Force >> $Log 
Copy-Item $mypath/AVX2.props $root/src-stage1-dependencies -Force >> $Log
Remove-Item $root/scripts/~RUNME_FIRST.ps1 >> $Log  # Don't need this file in the build tree after everything is there
cd $root/scripts

& .\Step1-UserPreferences.ps1
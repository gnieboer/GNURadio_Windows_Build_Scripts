# GNURadio Windows Build System
# Geof Nieboer
# Step9_BuildMSI.ps1
#

# script setup
$ErrorActionPreference = "Stop"

# setup helper functions
$mypath =  Split-Path $script:MyInvocation.MyCommand.Path
if (Test-Path $mypath\Setup.ps1) {
	. $mypath\Setup.ps1 -Force
} else {
	. $root\scripts\Setup.ps1 -Force
}

$configmode = $args[0]
if ($configmode -eq $null) {$configmode = "all"}

SetLog "MSI Creation"
cd $root\src-stage4-installer
New-Item -ItemType Directory -Force build *>> $Log 
Write-Host "Building MSI packages"

Function BuildMSI {

	$configuration = $args[0]

	Write-Host -NoNewline "Building $configuration package..."

	CheckNoAVX "$root/src-stage3/staged_install/$configuration"

	cd $root\src-stage4-installer

	New-Item -ItemType Directory -Force build\$configuration *>> $Log 

	msbuild gnuradio-winstaller.wixproj /m /p:"configuration=$configuration;root=$root;platform=x64"  *>> $Log 

	Validate "$root/src-stage4-installer/dist/$configuration/gnuradio_win64.msi"
	
	if ($configuration -match "AVX2") {
		Move-Item -Force -Path $root/src-stage4-installer/dist/$configuration/gnuradio_win64.msi $root/src-stage4-installer/dist/$configuration/gnuradio_$gnuradio_version`_win64_avx2.msi
	} else	{
		Move-Item -Force -Path $root/src-stage4-installer/dist/$configuration/gnuradio_win64.msi $root/src-stage4-installer/dist/$configuration/gnuradio_$gnuradio_version`_win64.msi
	}
}

Function ConsolidatePDBs {
	$configuration = $args[0]
	New-Item -ItemType Directory -Force $root\src-stage4-installer\symbols\$configuration *>> $Log
	pushd $root\src-stage1-dependencies
	Get-ChildItem -Recurse -Filter "$configuration" -Directory | Get-ChildItem -Recurse -Directory | Get-ChildItem -Filter "*.pdb" | Copy-Item -Destination ..\src-stage4-installer\symbols\$configuration -Force
	Get-ChildItem -Recurse -Filter "${configuration}DLL" -Directory | Get-ChildItem -Recurse -Directory | Get-ChildItem -Filter "*.pdb" | Copy-Item -Destination ..\src-stage4-installer\symbols\$configuration -Force
	Get-ChildItem -Recurse -Filter "$configuration" -Directory | Get-ChildItem -Filter "*.pdb" | Copy-Item -Destination ..\src-stage4-installer\symbols\$configuration -Force
	Get-ChildItem -Recurse -Filter "${configuration}DLL" -Directory | Get-ChildItem -Filter "*.pdb" | Copy-Item -Destination ..\src-stage4-installer\symbols\$configuration -Force
	popd
	pushd $root\src-stage3 
	Get-ChildItem -Recurse -Filter "$configuration" -Directory | Get-ChildItem -Recurse -Directory | Get-ChildItem -Filter "*.pdb" | Copy-Item -Destination ..\src-stage4-installer\symbols\$configuration -Force
	Get-ChildItem -Recurse -Filter "${configuration}DLL" -Directory | Get-ChildItem -Recurse -Directory | Get-ChildItem -Filter "*.pdb" | Copy-Item -Destination ..\src-stage4-installer\symbols\$configuration -Force
	popd
}

if ($configmode -eq "1" -or $configmode -eq "all") {BuildMSI "Release"; ConsolidatePDBs "Release"}
if ($configmode -eq "2" -or $configmode -eq "all") {BuildMSI "Release-AVX2"}
if ($configmode -eq "3" -or $configmode -eq "all") {BuildMSI "Debug"; ConsolidatePDBs "Debug"}

""
"COMPLETED STEP 9: .msi files have been created and can be found in $root/src-stage4-installer/dist/(configuration)/gnuradio_$gnuradio_version_win64.msi"
""
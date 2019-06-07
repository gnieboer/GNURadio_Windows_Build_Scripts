GNURadio Windows Build Scripts v1.5
=====================================

A series of Powershell scripts to automatically download,  build from source, and install GNURadio and -all- it's dependencies as 64-bit native binaries then package as an .msi using Visual Studio 2015.

For more details on this effort, please see the support [website](http://www.gcndevelopment.com/gnuradio)

IF YOU JUST WANT TO USE GNURADIO ON WINDOWS, DON'T USE THESE SCRIPTS... use the binaries that are posted at the above site.  The Linux way is to build from source, this is usually not helpful on Windows, so use the installers unless you just want to tinker, in which case enjoy!

The finished MSI includes:

Device Support: UHD, RTL-SDR, hackrf, airspy, BladeRF, osmoSDR, FCD

GNURadio modules: 3.7.13.4 with all but gr-comedi modules built and included

OOT modules: gr-iqbal, gr-fosphor, gr-osmosdr, gr-acars, gr-adsb, gr-modtool, gr-air-modes, gr-ais, gr-ax25, gr-burst (incl. bitarray), gr-cdma, gr-display (incl. matplotlib), gr-eventstream, gr-inspector (incl. tensorflow), gr-lte, gr-mapper, gr-nacl, gr-paint (incl. PIL), gr-radar, gr-rds, gr-specest, OpenLTE, gr-gsm

Other Applications: gqrx

<h2>PREREQUISITES</h2>
Windows 10 64-bit (though binaries will run on Win 7)

The following tools must be installed:  
- MS Visual Studio 2015 
- Git For Windows  
- CMake 3.13
- Doxygen  
- ActiveState Perl  
- Wix toolset for VS 2015  

Please note that Visual Studio 2017 is not yet supported.

Also, the complete build requires no less than **120 GB** of free disk space.

<h2>INSTALLATION & BUILD</h2>

Run the below from an **elevated** command prompt (the only command that requires elevation is the Set-ExecutionPolicy.  If desired, the rest can be run from a user-privilege account)

```powershell
git clone http://www.github.com/gnieboer/GNURadio_Windows_Build_Scripts
cd GNURadio_Windows_Build_Scripts
powershell 
Set-ExecutionPolicy Unrestricted
./~RUNME_FIRST.ps1
```

Build logs can be found in the $root/logs directory.  The scripts will validate key parts of each step, but are not 100% guaranteed to detect a partial build failure.  Use the logs to further diagnose issues.

Once complete, msi files can be found in the [root]/src-stage4-installer/dist subdirectories.  The build can be tested after Step 7 by running run_grc.bat in the src-stage3/staged_install/[config]/bin subdirectory to 

<h2>ISSUES</h2>

1- Ensure your anti-virus is off during installation... even Windows Defender.  PyQt4 may fail to create manifest files as a result.

2- Right-click your powershell window, go to "Properties" and ensure QuickEdit and Insert Mode are NOT checked.  Otherwise when you click on the window, execution may pause without any indication as to why, leading you to believe the build has hung.

3- This has been tested with a B200 UHD, a hackRF, and an RTL-SDR.  Other device drivers have not been phyiscally verified to work.  If you own one, please let me know if you had success.

4- In the event of issues, I highly recommend [Dependency Walker](https://www.dependencywalker.com/) to troubleshoot what libraries are linked to what.

5- If your connection is spotty, you may get partially downloaded packages which cause build failures.  To correct, DELETE the suspect package from the /packages directory so it will retry the download.

6- The following devices are NOT currently supported: FCD Pro+, RFSPACE, MiriSDR, SoapySDR, SDRPlay

7- CMake 3.13 is the only version currently supported, though versions after 3.5 may be successful; older versions have been reported to have issues detecting the custom python install when at the BuildGNURadio step. 

8- Zadig must be manually added to the /bin directory prior to MSI creation

<h2>LICENSE</h2>
The scripts themselves are released under the GPLv3.  The resulting MSI's are also GPLv3 compatible, see www.gcndevelopment.com/gnuradio for details and access to all modifications to original source code.  All patches are released under the same license as the original package it applies to.
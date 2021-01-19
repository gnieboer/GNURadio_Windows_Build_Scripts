@echo off
echo setting gnuradio environment

REM --- Set Basic GR Environment ---
set GR_VERSION=3.8
set GR_PREFIX=%~dp0\..
set SYSCONFDIR=%~dp0\..\etc
set GR_PREFSDIR=%~dp0\..\etc\gnuradio\conf.d

REM --- Set Python environment ---
set PYTHONHOME=%~dp0..\tools\python3
set PYTHONPATH=%~dp0..\tools\python3\Lib\site-packages;%~dp0..\tools\python3\dlls;%~dp0..\tools\python3\libs;%~dp0..\tools\python3\lib;%~dp0..\lib\site-packages;%~dp0..\tools\python3\Lib\site-packages\pkgconfig;%~dp0..\tools\python3\Lib\site-packages\gtk-2.0\glib;%~dp0..\tools\python3\Lib\site-packages\gtk-2.0;%~dp0..\tools\python3\Lib\site-packages\lxml-3.4.4-py2.7-win.amd64.egg
set PATH=%~dp0;%~dp0..\tools\python3\dlls;%~dp0..\tools\python3;%PATH%

REM --- Set GRC environment ---
REM set GRC_BLOCKS_PATH=%~dp0..\share\gnuradio\grc\blocks
set GRC_BLOCKS_PATH=

REM --- Set UHD environment ---
set UHD_PKG_DATA_PATH=%~dp0..\share\uhd;%~dp0..\share\uhd\images
set UHD_IMAGES_DIR=%~dp0..\share\uhd\images
set UHD_RFNOC_DIR=%~dp0..\share\uhd\rfnoc\

REM --- Set QT environment ---
set QT_QPA_PLATFORM_PLUGIN_PATH=%~dp0plugins\platforms
set QT_PLUGIN_PATH=%~dp0plugins

CALL gqrx.exe %1 %2 %3 %4
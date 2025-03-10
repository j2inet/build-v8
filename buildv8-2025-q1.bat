ECHO OFF
CLS
SETLOCAL ENABLEEXTENSIONS
setlocal EnableDelayedExpansion
ECHO Building V8

IF ERRORLEVEL 1 ECHO Unable to enable extensions
REM Make sure that Visual Studio (Community Edition) has the components that is needs.
pushd "C:\Program Files (x86)\Microsoft Visual Studio\Installer\"
vs_installer.exe install --productid Microsoft.VisualStudio.Product.Community --ChannelId VisualStudio.17.Release --add Microsoft.VisualStudio.Workload.NativeDesktop  --add Microsoft.VisualStudio.Component.VC.ATLMFC  --add Microsoft.VisualStudio.Component.VC.Tools.ARM64 --add Microsoft.VisualStudio.Component.VC.MFC.ARM64 --add Microsoft.VisualStudio.Component.Windows10SDK.20348  --add Microsoft.VisualStudio.Component.VC.Llvm.Clang --add Microsoft.VisualStudio.Component.VC.Llvm.ClangToolset --add Microsoft.VisualStudio.ComponentGroup.NativeDesktop.Llvm.Clang	 --includeRecommended
popd


ECHO Setting project path
SET drive=c:
SET ProjectRoot=%drive%\shares\projects
SET TempFolder=%ProjectRoot%\google\temp
SET DepotFolder=%ProjectRoot%\google\depot_tools
pushd %drive%

mkdir %ProjectRoot%
mkdir %TempFolder%

REM Create some folders in which the results of this effort will go.
REM mkdir c:\shares
REM mkdir c:\shares\projects
REM mkdir c:\shares\projects\google

SET DEPOT_TOOLS_WIN_TOOLCHAIN=0
ECHO Setting VS 2022 Build Variable
ECHO %vs2022_install%
ECHO.
ECHO.
IF DEFINED vs2022_install (ECHO VS Variable already set) ELSE (	set vs2022_install=C:\Program Files\Microsoft Visual Studio\2022\Community)

if "!path:%DepotFolder%=!" equ %path% (
   set PATH=%DepotFolder%;%PATH%
)


REM Install the DEPOT Tools
SET depot_tools_source=https://storage.googleapis.com/chrome-infra/depot_tools.zip
SET depot_tools_download_folder=%ProjectRoot%\google\temp\
SET depot_tools_download_path=%depot_tools_download_folder%depot_tools.zip
SET depot_tools_path=%ProjectRoot%\google\depot_tools\
SET windows_ddk_path=%ProjectRoot%\google\temp\windowsddk.exe
SET chromium_checkout_path=%ProjectRoot%\google\chromium
SET v8_checkout_path=%ProjectRoot%\google\

mkdir %depot_tools_download_folder%
mkdir %depot_tools_path%
mkdir %chromium_checkout_path%
mkdir %v8_checkout_path%

ECHO checking for build tools

ECHO "Checking for windows ddk"
if not exist "%windows_ddk_path%" (
	ECHO Downloading Windows Driver Development Kit
	powershell Invoke-WebRequest -Uri "https://go.microsoft.com/fwlink/?linkid=2305205" -OutFile %windows_ddk_path%
	%windows_ddk_path%
)

ECHO expanding build tools
REM powershell Expand-Archive -LiteralPath %depot_tools_download_path% -DestinationPath %depot_tools_path% -Force

cd %v8_checkout_path%
ECHO ___________________________________________________
ECHO %DepotFolder%
if not exist "%DepotFolder%" (
	ECHO Downloading build files
	REM git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
	powershell Invoke-WebRequest -Uri %depot_tools_source% -OutFile %depot_tools_download_path%
)
ECHO ___________________________________________________


call gclient.bat update
call gclient.bat sync

cd %v8_checkout_path%
call fetch --nohistory v8
cd v8
call git fetch --tags
call git checkout 11.9.99


ECHO.>SuggestedBuildOptions.txt
ECHO is_debug = true>>SuggestedBuildOptions.txt
ECHO target_cpu = "x64">>SuggestedBuildOptions.txt
ECHO v8_enable_backtrace = true>>SuggestedBuildOptions.txt
ECHO v8_enable_slow_dchecks = false>>SuggestedBuildOptions.txt
ECHO v8_optimized_debug = false>>SuggestedBuildOptions.txt
ECHO v8_monolithic = true>>SuggestedBuildOptions.txt
ECHO v8_use_external_startup_data = false>>SuggestedBuildOptions.txt
ECHO is_component_build = false>>SuggestedBuildOptions.txt
ECHO is_clang = false>>SuggestedBuildOptions.txt

CLS
ECHO.
ECHO To build v8 x64 for release, run the following command
ECHO. 
ECHO python3 tools\dev\gm.py x64.release
ECHO.
ECHO.
ECHO Press [CTRL]+[C] to stop script. Do nothing, and release build will start
ECHO.
REM notepad tools\dev\gm.py
TIMEOUT 60
REM notepad tools\dev\gm.py
ECHO Performing x64 (Intel Architecture) builds
call python3 tools\dev\gm.py x64.release
call python3 tools\dev\gm.py x64.debug

ECHO Performing ARM64 builds
call python3 tools\dev\gm.py arm64.release
call python3 tools\dev\gm.py arm64.debug
popd

ECHO I hoped this helped you with building V8 on your computer. 
ECHO more information on this script can be found on my blog at
ECHO https://blog.j2i.net. This script was originally written in
ECHO March 2025. With time, as V8 and the build process change, 
ECHO these instructions may become less valid. 
 [32mLater![0m 

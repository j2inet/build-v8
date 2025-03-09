ECHO OFF
CLS
SETLOCAL ENABLEEXTENSIONS
setlocal EnableDelayedExpansion

IF ERRORLEVEL 1 ECHO Unable to enable extensions
REM Make sure that Visual Studio (Community Edition) has the components that is needs.
pushd "C:\Program Files (x86)\Microsoft Visual Studio\Installer\"
vs_installer.exe install --productid Microsoft.VisualStudio.Product.Community --ChannelId VisualStudio.17.Release --add Microsoft.VisualStudio.Workload.NativeDesktop  --add Microsoft.VisualStudio.Component.VC.ATLMFC  --add Microsoft.VisualStudio.Component.VC.Tools.ARM64 --add Microsoft.VisualStudio.Component.VC.MFC.ARM64 --add Microsoft.VisualStudio.Component.Windows10SDK.20348 --includeRecommended
popd

REM Create some folders in which the results of this effort will go.
REM mkdir c:\shares
REM mkdir c:\shares\projects
REM mkdir c:\shares\projects\google
mkdir c:\shares\projects\google\temp

SET DEPOT_TOOLS_WIN_TOOLCHAIN=0
ECHO Setting VS 2022 Build Variable
ECHO %vs2022_install%
ECHO.
ECHO.
IF DEFINED vs2022_install (ECHO VS Variable already set) ELSE (	set vs2022_install=C:\Program Files\Microsoft Visual Studio\2022\Community)

SET path_to_insert=c:\shares\projects\google\depot_tools\
if "!path:%path_to_insert%=!" equ %path% (
   set PATH=%path_to_inseret%;%PATH%
)

ECHO Setting project path
SET drive=c:
SET ProjectRoot=%drive%\shares\projects
pushd %drive%

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
if not exist "%depot_tools_download_path%" (
	ECHO Downloading build files
	powershell Invoke-WebRequest -Uri %depot_tools_source% -OutFile %depot_tools_download_path%
)
ECHO "Checking for windows ddk"
if not exist "%windows_ddk_path%" (
	ECHO Downloading Windows Driver Development Kit
	powershell Invoke-WebRequest -Uri "https://go.microsoft.com/fwlink/?linkid=2305205" -OutFile %windows_ddk_path%
	%windows_ddk_path%
)

ECHO expanding build tools
REM powershell Expand-Archive -LiteralPath %depot_tools_download_path% -DestinationPath %depot_tools_path% -Force

cd %v8_checkout_path%
git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git

call gclient.bat update
call gclient.bat config
call gclient.bat sync

cd %v8_checkout_path%
call fetch --nohistory v8
cd v8
call git fetch --tags
call git checkout 13.6.9

CLS
ECHO.
ECHO Setup complete. Build will begin shortly.
ECHO.
ECHO.
ECHO Press [CTRL]+[C] to stop script. Do nothing, and release build will start
ECHO.
TIMEOUT 60
notepad tools\dev\gm.py
call python3 tools\dev\gm.py x64.release
call python3 tools\dev\gm.py x64.debug
call python3 tools\dev\gm.py arm64.release
call python3 tools\dev\gm.py arm64.debug
popd

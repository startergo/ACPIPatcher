@echo off
REM Simple build script for ACPIPatcher using traditional EDK2

echo ===============================================
echo Building ACPIPatcher with Traditional EDK2
echo ===============================================

set ARCH=%1
set BUILD_TYPE=%2

if "%ARCH%"=="" set ARCH=X64
if "%BUILD_TYPE%"=="" set BUILD_TYPE=RELEASE

echo Architecture: %ARCH%
echo Build Type: %BUILD_TYPE%

REM Clone EDK2 if not present
if not exist edk2 (
    echo Cloning EDK2...
    git clone --depth 1 https://github.com/tianocore/edk2.git edk2
    if errorlevel 1 (
        echo Failed to clone EDK2
        exit /b 1
    )
)

cd edk2

REM Initialize essential submodules
echo Initializing EDK2 submodules...
git submodule update --init --depth 1 MdePkg/Library/MipiSysTLib
git submodule update --init --depth 1 BaseTools/Source/C/BrotliCompress
git submodule update --init --depth 1 CryptoPkg/Library/OpensslLib/openssl

REM Build BaseTools
echo Building EDK2 BaseTools...
call edksetup.bat ForceRebuild
if errorlevel 1 (
    echo Failed to build BaseTools
    exit /b 1
)

REM Re-setup environment to ensure BaseTools are in PATH
echo Setting up EDK2 environment...
call edksetup.bat

REM Verify GenFw is available
echo Checking for GenFw tool...
where GenFw >nul 2>&1
if errorlevel 1 (
    echo WARNING: GenFw not found in PATH
    echo Attempting to add BaseTools/Bin to PATH...
    set "PATH=%CD%\BaseTools\Bin\Win32;%PATH%"
    where GenFw >nul 2>&1
    if errorlevel 1 (
        echo ERROR: GenFw still not found after PATH update
        exit /b 1
    )
)

echo GenFw found: 
where GenFw

REM Build ACPIPatcher
echo Building ACPIPatcher...
set "PACKAGES_PATH=%CD%;%CD%\.."
build -p ..\ACPIPatcherPkg\ACPIPatcherPkg.dsc -a %ARCH% -t VS2022 -b %BUILD_TYPE%
if errorlevel 1 (
    echo Build failed
    exit /b 1
)

echo ===============================================
echo Build completed successfully!
echo ===============================================

REM Copy artifacts to root
set "BUILD_DIR=Build\ACPIPatcher\%BUILD_TYPE%_VS2022\%ARCH%"
if exist "%BUILD_DIR%\ACPIPatcher.efi" (
    copy "%BUILD_DIR%\ACPIPatcher.efi" ..
    echo Copied ACPIPatcher.efi
)
if exist "%BUILD_DIR%\ACPIPatcherDxe.efi" (
    copy "%BUILD_DIR%\ACPIPatcherDxe.efi" ..
    echo Copied ACPIPatcherDxe.efi
)

cd ..
echo Build script completed successfully

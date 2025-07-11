@echo off
REM EDK2 Comprehensive Setup Script (Batch Version) for ACPIPatcher
REM This script sets up the complete EDK2 environment and builds ACPIPatcher
REM Usage: setup_and_build.bat [ARCH] [BUILD_TYPE]
REM   ARCH: X64, IA32 (default: X64)
REM   BUILD_TYPE: RELEASE, DEBUG (default: RELEASE)
REM Examples:
REM   setup_and_build.bat X64 RELEASE
REM   setup_and_build.bat IA32 DEBUG

setlocal enabledelayedexpansion

REM Parse command line arguments
set "TARGET_ARCH=%~1"
set "BUILD_TYPE=%~2"

REM Set defaults if not provided
if "%TARGET_ARCH%"=="" set "TARGET_ARCH=X64"
if "%BUILD_TYPE%"=="" set "BUILD_TYPE=RELEASE"

REM Validate architecture
if /i not "%TARGET_ARCH%"=="X64" if /i not "%TARGET_ARCH%"=="IA32" (
    echo ERROR: Invalid architecture '%TARGET_ARCH%'. Supported: X64, IA32
    exit /b 1
)

REM Validate build type
if /i not "%BUILD_TYPE%"=="RELEASE" if /i not "%BUILD_TYPE%"=="DEBUG" (
    echo ERROR: Invalid build type '%BUILD_TYPE%'. Supported: RELEASE, DEBUG
    exit /b 1
)

echo === EDK2 Comprehensive Setup Script for ACPIPatcher ===
echo Target Architecture: %TARGET_ARCH%
echo Build Type: %BUILD_TYPE%
echo Starting EDK2 environment setup and ACPIPatcher build...

REM Check if running in CI environment
if "%CI%"=="true" (
    echo Running in CI environment - unattended mode
    set "CI_MODE=1"
    REM Configure Git to use GitHub token for CI
    if not "%GITHUB_TOKEN%"=="" (
        echo Configuring Git with GitHub token for CI authentication...
        git config --global credential.helper store
        echo https://x-access-token:%GITHUB_TOKEN%@github.com > %USERPROFILE%\.git-credentials
    )
) else (
    set "CI_MODE=0"
)

REM Get script directory (EDK2 root will be set later)
set "ACPI_PATCHER_ROOT=%~dp0"
set "ACPI_PATCHER_ROOT=%ACPI_PATCHER_ROOT:~0,-1%"

echo ACPIPatcher Root: %ACPI_PATCHER_ROOT%

REM Function to check if NASM exists
:check_nasm
echo.
echo === Step 1: NASM Setup ===
set "NASM_FOUND=0"

REM Check common NASM locations
if exist "%SystemDrive%\NASM\nasm.exe" (
    set "NASM_DIR=%SystemDrive%\NASM"
    set "NASM_FOUND=1"
    echo Found NASM at: %SystemDrive%\NASM
    goto nasm_found
)

if exist "%ProgramFiles%\NASM\nasm.exe" (
    set "NASM_DIR=%ProgramFiles%\NASM"
    set "NASM_FOUND=1"
    echo Found NASM at: %ProgramFiles%\NASM
    goto nasm_found
)

if exist "%ProgramFiles(x86)%\NASM\nasm.exe" (
    set "NASM_DIR=%ProgramFiles(x86)%\NASM"
    set "NASM_FOUND=1"
    echo Found NASM at: %ProgramFiles(x86)%\NASM
    goto nasm_found
)

REM Check if NASM is in PATH
nasm -v >nul 2>&1
if !errorlevel! equ 0 (
    for %%i in (nasm.exe) do set "NASM_DIR=%%~dpi"
    set "NASM_DIR=!NASM_DIR:~0,-1!"
    set "NASM_FOUND=1"
    echo Found NASM in PATH: !NASM_DIR!
    goto nasm_found
)

REM No automatic NASM installation - user must install manually
:nasm_manual
echo WARNING: NASM not found. Please install NASM manually and place it in %SystemDrive%\NASM
echo Download from: https://www.nasm.us/pub/nasm/releasebuilds/
echo.
if %CI_MODE%==0 pause
if %CI_MODE%==1 exit /b 1
goto check_vs

:nasm_found
REM Set NASM environment variables
echo Setting NASM_PREFIX environment variable...
setx NASM_PREFIX "%NASM_DIR%\" /M >nul 2>&1
set "NASM_PREFIX=%NASM_DIR%\"

REM Add NASM to PATH if not already there
echo %PATH% | find /i "%NASM_DIR%" >nul
if !errorlevel! neq 0 (
    echo Adding NASM to system PATH...
    for /f "tokens=2*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v PATH') do set "CURRENT_PATH=%%b"
    setx PATH "%CURRENT_PATH%;%NASM_DIR%" /M >nul 2>&1
)

echo NASM setup complete!

:check_vs
echo.
echo === Step 2: Visual Studio Setup ===

REM Check for Visual Studio 2019/2022
set "VS_FOUND=0"

REM Check for Visual Studio 2022 first
if exist "%ProgramFiles%\Microsoft Visual Studio\2022\Enterprise\Common7\IDE\devenv.exe" (
    set "VS_PATH=%ProgramFiles%\Microsoft Visual Studio\2022\Enterprise"
    set "VS_FOUND=1"
    set "VS_VERSION=2022"
    echo Found Visual Studio 2022 Enterprise
    goto vs_found
)

if exist "%ProgramFiles%\Microsoft Visual Studio\2022\Professional\Common7\IDE\devenv.exe" (
    set "VS_PATH=%ProgramFiles%\Microsoft Visual Studio\2022\Professional"
    set "VS_FOUND=1"
    set "VS_VERSION=2022"
    echo Found Visual Studio 2022 Professional
    goto vs_found
)

if exist "%ProgramFiles%\Microsoft Visual Studio\2022\Community\Common7\IDE\devenv.exe" (
    set "VS_PATH=%ProgramFiles%\Microsoft Visual Studio\2022\Community"
    set "VS_FOUND=1"
    set "VS_VERSION=2022"
    echo Found Visual Studio 2022 Community
    goto vs_found
)

REM Check for Visual Studio 2019
if exist "%ProgramFiles(x86)%\Microsoft Visual Studio\2019\Enterprise\Common7\IDE\devenv.exe" (
    set "VS_PATH=%ProgramFiles(x86)%\Microsoft Visual Studio\2019\Enterprise"
    set "VS_FOUND=1"
    set "VS_VERSION=2019"
    echo Found Visual Studio 2019 Enterprise
    goto vs_found
)

if exist "%ProgramFiles(x86)%\Microsoft Visual Studio\2019\Professional\Common7\IDE\devenv.exe" (
    set "VS_PATH=%ProgramFiles(x86)%\Microsoft Visual Studio\2019\Professional"
    set "VS_FOUND=1"
    set "VS_VERSION=2019"
    echo Found Visual Studio 2019 Professional
    goto vs_found
)

if exist "%ProgramFiles(x86)%\Microsoft Visual Studio\2019\Community\Common7\IDE\devenv.exe" (
    set "VS_PATH=%ProgramFiles(x86)%\Microsoft Visual Studio\2019\Community"
    set "VS_FOUND=1"
    set "VS_VERSION=2019"
    echo Found Visual Studio 2019 Community
    goto vs_found
)

REM Try using vswhere for any Visual Studio version
if exist "%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" (
    REM Try VS2022 first
    for /f "tokens=*" %%i in ('"%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" -version "[17.0,18.0)" -property installationPath') do (
        if exist "%%i\Common7\IDE\devenv.exe" (
            set "VS_PATH=%%i"
            set "VS_FOUND=1"
            set "VS_VERSION=2022"
            echo Found Visual Studio 2022 using vswhere: %%i
            goto vs_found
        )
    )
    REM Fall back to VS2019
    for /f "tokens=*" %%i in ('"%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" -version "[16.0,17.0)" -property installationPath') do (
        if exist "%%i\Common7\IDE\devenv.exe" (
            set "VS_PATH=%%i"
            set "VS_FOUND=1"
            set "VS_VERSION=2019"
            echo Found Visual Studio 2019 using vswhere: %%i
            goto vs_found
        )
    )
)

REM Check for Cygwin as alternative
echo Visual Studio not found. Checking for Cygwin...

REM Check common Cygwin locations
for %%D in ("%SystemDrive%\cygwin64" "%SystemDrive%\cygwin" "%ProgramFiles%\cygwin64" "%ProgramFiles%\cygwin") do (
    if exist "%%~D\bin\gcc.exe" (
        echo [OK] Found Cygwin GCC at %%~D\
        set "BASETOOLS_CYGWIN_BUILD=TRUE"
        set "BASETOOLS_CYGWIN_PATH=%%~D"
        set "PATH=%%~D\bin;!PATH!"
        echo   - Configured for Cygwin build
        goto compiler_found
    )
)

echo WARNING: Neither Visual Studio 2019/2022 nor Cygwin found!
echo Please install one of the following:
echo - Visual Studio 2019 or 2022 with C++ development tools
echo - Cygwin with gcc and make packages
echo.
if %CI_MODE%==0 pause
if %CI_MODE%==1 exit /b 1
goto set_edk2_vars

:vs_found
echo Visual Studio %VS_VERSION% setup complete!
goto set_edk2_vars

:compiler_found
echo Compiler setup complete!

:set_edk2_vars
echo.
echo === Step 3: Python and Git Prerequisites ===

REM Check Python
python --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Python not found. Please install Python 3.10+ and add to PATH.
    if %CI_MODE%==0 pause
    exit /b 1
) else (
    echo [OK] Python found
)

REM Check Git and configure for EDK2
git --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Git not found. Please install Git and add to PATH.
    if %CI_MODE%==0 pause
    exit /b 1
) else (
    echo [OK] Git found. Configuring Git for optimal EDK2 experience...
    git config --global credential.helper store >nul 2>&1
    git config --global core.autocrlf false >nul 2>&1
    git config --global core.longpaths true >nul 2>&1
    git config --global url."https://github.com/".insteadOf "git@github.com:" >nul 2>&1
    git config --global url."https://".insteadOf "git://" >nul 2>&1
    git config --global credential.https://github.com.useHttpPath true >nul 2>&1
    echo   - Credential store configured for seamless authentication
    echo   - Line ending handling optimized for EDK2
    echo   - Long path support enabled for deep directory structures
    echo   - Force HTTPS for all Git operations to avoid SSH auth issues
)

echo.
echo === Step 4: EDK2 Workspace Setup ===

REM Set up EDK2 workspace
echo Setting up EDK2 workspace...

REM Check for existing EDK2 installations
set "EDK2_PATH="

REM Check multiple common EDK2 locations
for %%D in ("%USERPROFILE%\Downloads\edk2" "temp_edk2" "%SystemDrive%\edk2" "%USERPROFILE%\edk2" "%USERPROFILE%\Desktop\edk2" "%CD%\edk2") do (
    if exist "%%~D" (
        echo [OK] Found existing EDK2 at %%~D
        set "EDK2_PATH=%%~D"
        goto edk2_found
    )
)

REM If no existing EDK2 found, clone fresh copy
echo No existing EDK2 found. Cloning fresh copy...
echo This may take a while for the first time...
git clone --depth 1 --single-branch https://github.com/tianocore/edk2.git temp_edk2
if errorlevel 1 (
    echo ERROR: Failed to clone EDK2 repository.
    if %CI_MODE%==0 pause
    exit /b 1
)
set "EDK2_PATH=%CD%\temp_edk2"

:edk2_found

echo Using EDK2 at: !EDK2_PATH!
set "EDK2_ROOT=!EDK2_PATH!"

REM Set EDK2 environment variables
echo Setting EDK2 environment variables...
setx WORKSPACE "%EDK2_ROOT%" /M >nul 2>&1
setx EDK_TOOLS_PATH "%EDK2_ROOT%\BaseTools" /M >nul 2>&1
setx BASE_TOOLS_PATH "%EDK2_ROOT%\BaseTools" /M >nul 2>&1

REM Set Python command
python --version >nul 2>&1
if !errorlevel! equ 0 (
    setx PYTHON_COMMAND "python" /M >nul 2>&1
    echo Set PYTHON_COMMAND=python
) else (
    py -3 --version >nul 2>&1
    if !errorlevel! equ 0 (
        setx PYTHON_COMMAND "py -3" /M >nul 2>&1
        echo Set PYTHON_COMMAND=py -3
    ) else (
        echo WARNING: Python not found in PATH
    )
)

echo EDK2 environment variables set!

cd /d "!EDK2_ROOT!"

REM Configure Git for submodule authentication and initialize submodules
echo.
echo === Step 5: EDK2 Submodules Setup ===

REM Configure Git for submodule authentication (only if in git repo)
echo Configuring Git for submodule access...
echo [DEBUG] Quick git repository check with timeout...

REM Use a simple file-based check instead of git status to avoid hangs
if exist ".git" (
    echo [DEBUG] .git directory found - proceeding with git configuration...
    echo [DEBUG] Setting up git credential helper...
    git config --local credential.helper store >nul 2>&1
    echo [DEBUG] Setting up GitHub URL rewriting...
    git config --local url."https://github.com/".insteadOf "git@github.com:" >nul 2>&1
    git config --local url."https://".insteadOf "git://" >nul 2>&1
    echo [DEBUG] Setting up GitHub credential path...
    git config --local credential.https://github.com.useHttpPath true >nul 2>&1
    echo [DEBUG] Git configuration completed successfully.
) else (
    echo [INFO] No .git directory found - skipping git configuration
)

REM Check if essential submodules exist
echo Checking EDK2 submodules...
set "SUBMODULES_OK=1"
if not exist "BaseTools\Source\C\BrotliCompress\brotli\c" set "SUBMODULES_OK=0"
if not exist "CryptoPkg\Library\OpensslLib\openssl\include" set "SUBMODULES_OK=0"
if not exist "MdeModulePkg\Library\BrotliCustomDecompressLib\brotli\c" set "SUBMODULES_OK=0"
if not exist "MdePkg\Library\MipiSysTLib\mipisyst\library\include" set "SUBMODULES_OK=0"

if !SUBMODULES_OK!==1 (
    echo [OK] Essential submodules already available.
) else (
    echo Initializing required EDK2 submodules...
    echo Note: Using anonymous access with timeout protection
    echo [DEBUG] Starting submodule initialization...
    git -c credential.helper= -c http.lowSpeedLimit=1000 -c http.lowSpeedTime=60 submodule update --init --recursive --depth 1 --jobs 1
    if errorlevel 1 (
        echo WARNING: Submodule initialization timed out or failed. Trying essential ones only...
        echo Initializing critical submodules for BaseTools...
        echo [DEBUG] Initializing BrotliCompress...
        git -c credential.helper= -c http.lowSpeedLimit=1000 -c http.lowSpeedTime=30 submodule update --init BaseTools/Source/C/BrotliCompress/brotli
        echo [DEBUG] Initializing OpensslLib...
        git -c credential.helper= -c http.lowSpeedLimit=1000 -c http.lowSpeedTime=30 submodule update --init CryptoPkg/Library/OpensslLib/openssl
        echo [DEBUG] Initializing BrotliCustomDecompressLib...
        git -c credential.helper= -c http.lowSpeedLimit=1000 -c http.lowSpeedTime=30 submodule update --init MdeModulePkg/Library/BrotliCustomDecompressLib/brotli
        echo [DEBUG] Initializing MipiSysTLib...
        git -c credential.helper= -c http.lowSpeedLimit=1000 -c http.lowSpeedTime=30 submodule update --init MdePkg/Library/MipiSysTLib
        echo Continuing with available submodules...
    ) else (
        echo [OK] All submodules initialized successfully.
    )
    
    REM Verify critical submodules after initialization
    echo [DEBUG] Verifying submodule status after initialization...
    if exist "BaseTools\Source\C\BrotliCompress\brotli\c" (
        echo [OK] BrotliCompress submodule verified
    ) else (
        echo [WARNING] BrotliCompress submodule missing
    )
    if exist "CryptoPkg\Library\OpensslLib\openssl\include" (
        echo [OK] OpensslLib submodule verified
    ) else (
        echo [WARNING] OpensslLib submodule missing
    )
    if exist "MdeModulePkg\Library\BrotliCustomDecompressLib\brotli\c" (
        echo [OK] BrotliCustomDecompressLib submodule verified
    ) else (
        echo [WARNING] BrotliCustomDecompressLib submodule missing
    )
    if exist "MdePkg\Library\MipiSysTLib\mipisyst\library\include" (
        echo [OK] MipiSysTLib submodule verified
    ) else (
        echo [ERROR] MipiSysTLib submodule missing - this will cause build failures
        echo [DEBUG] Attempting direct MipiSysTLib initialization...
        git submodule update --init --recursive MdePkg/Library/MipiSysTLib
        if exist "MdePkg\Library\MipiSysTLib\mipisyst\library\include" (
            echo [OK] MipiSysTLib submodule now verified after direct init
        ) else (
            echo [ERROR] MipiSysTLib submodule still missing after direct init
        )
    )
)

:build_basetools
echo.
echo === Step 6: Building BaseTools ===

cd /d "%EDK2_ROOT%"

echo Running EDK2 setup...
call edksetup.bat

if !errorlevel! neq 0 (
    echo ERROR: EDK2 setup failed! Attempting recovery...
    
    REM Try to set up basic environment manually
    set "WORKSPACE=%EDK2_ROOT%"
    set "EDK_TOOLS_PATH=%EDK2_ROOT%\BaseTools"
    set "CONF_PATH=%EDK2_ROOT%\Conf"
    
    REM Create Conf directory if it doesn't exist
    if not exist "Conf" mkdir "Conf"
    
    echo [WARNING] Using minimal EDK2 environment setup
)

REM Now build BaseTools explicitly
echo Building BaseTools C utilities...
pushd BaseTools

REM Build using toolsetup.bat which handles the VS environment setup
echo Building BaseTools using toolsetup.bat...
call toolsetup.bat

if errorlevel 1 (
    echo ERROR: BaseTools build via toolsetup.bat failed!
    echo Attempting recovery by rebuilding BaseTools manually...
    
    echo [DEBUG] Cleaning BaseTools build environment...
    if exist "Source\C\bin" rmdir /s /q "Source\C\bin" 2>nul
    if exist "Bin" rmdir /s /q "Bin" 2>nul
    
    echo [DEBUG] Rebuilding BaseTools using nmake...
    if exist "Source\C\Makefile" (
        pushd Source\C
        nmake clean >nul 2>&1
        nmake
        popd
    ) else (
        echo [DEBUG] Trying toolsetup.bat again...
        call toolsetup.bat
    )
    
    if errorlevel 1 (
        echo ERROR: All BaseTools build attempts failed!
        popd
        if %CI_MODE%==0 pause
        exit /b 1
    )
)

popd

REM Verify BaseTools were created
set "BASETOOLS_PATH=%EDK2_ROOT%\BaseTools"
set "BASETOOLS_BIN=%BASETOOLS_PATH%\Bin\Win32"
set "REQUIRED_TOOLS=GenFv.exe GenFfs.exe GenFw.exe GenSec.exe VfrCompile.exe"

echo Verifying BaseTools...
for %%T in (%REQUIRED_TOOLS%) do (
    if not exist "%BASETOOLS_BIN%\%%T" (
        echo WARNING: Required tool not found: %%T in %BASETOOLS_BIN%
        REM Check alternative locations
        if exist "%BASETOOLS_PATH%\Bin\Win64\%%T" (
            echo Found %%T in Win64 directory
        ) else if exist "%BASETOOLS_PATH%\Source\C\bin\%%T" (
            echo Found %%T in Source\C\bin directory
        ) else (
            echo ERROR: %%T not found in any expected location
        )
    ) else (
        echo [OK] %%T verified in %BASETOOLS_BIN%
    )
)

REM Add BaseTools to PATH immediately after verification
echo [DEBUG] Adding BaseTools to PATH after build...
set "PATH=%BASETOOLS_PATH%\Source\C\bin;%BASETOOLS_PATH%\Bin\Win32;%BASETOOLS_PATH%\Bin\Win64;%PATH%"

echo BaseTools build completed!

:integrate_acpipatcher
echo.
echo === Step 7: Integrating ACPIPatcher Package ===

REM Copy our package to EDK2
echo Integrating ACPIPatcher package...
if not exist "ACPIPatcherPkg" (
    echo Copying ACPIPatcherPkg from !ACPI_PATCHER_ROOT!\ACPIPatcherPkg to !EDK2_ROOT!\ACPIPatcherPkg
    xcopy /E /I /Y "!ACPI_PATCHER_ROOT!\ACPIPatcherPkg" "ACPIPatcherPkg"
) else (
    echo [OK] ACPIPatcherPkg already integrated.
)

:setup_edk2_environment
echo.
echo === Step 8: Setting up EDK2 Build Environment ===

REM Configure Python for EDK2
for /f "tokens=*" %%i in ('python -c "import sys; print(sys.executable)" 2^>nul') do set "PYTHON_COMMAND=%%i"
if "%PYTHON_COMMAND%"=="" (
    for /f "tokens=*" %%i in ('py -c "import sys; print(sys.executable)" 2^>nul') do set "PYTHON_COMMAND=%%i"
)
if "%PYTHON_COMMAND%"=="" (
    set "PYTHON_COMMAND=python"
)

echo [DEBUG] Using Python: %PYTHON_COMMAND%

REM Set PYTHONPATH to include BaseTools Python modules
set "PYTHONPATH=%EDK2_ROOT%\BaseTools\Source\Python;%PYTHONPATH%"
echo [DEBUG] PYTHONPATH set to include BaseTools Python modules

REM Set EDK_TOOLS_PATH and other required environment variables
set "EDK_TOOLS_PATH=%EDK2_ROOT%\BaseTools"
set "HOST_ARCH=X64"
REM Note: TARGET_ARCH is preserved from command line arguments
echo [DEBUG] EDK_TOOLS_PATH set to: %EDK_TOOLS_PATH%
echo [DEBUG] HOST_ARCH set to: %HOST_ARCH%
echo [DEBUG] TARGET_ARCH preserved as: %TARGET_ARCH%

REM Ensure BaseTools are in PATH
set "PATH=%EDK_TOOLS_PATH%\Source\C\bin;%EDK_TOOLS_PATH%\Bin\Win32;%EDK_TOOLS_PATH%\Bin\Win64;%PATH%"

REM For Cygwin builds, ensure Cygwin tools are at the front of PATH
if defined BASETOOLS_CYGWIN_BUILD (
    set "PATH=%BASETOOLS_CYGWIN_PATH%\bin;%PATH%"
    echo [DEBUG] Cygwin tools added to front of PATH for consistent access
)

REM Set EDK_TOOLS_BIN for Win64 build
if exist "%EDK_TOOLS_PATH%\Bin\Win64" (
    set "EDK_TOOLS_BIN=%EDK_TOOLS_PATH%\Bin\Win64"
    echo [DEBUG] EDK_TOOLS_BIN set to: %EDK_TOOLS_BIN%
) else if exist "%EDK_TOOLS_PATH%\Bin\Win32" (
    set "EDK_TOOLS_BIN=%EDK_TOOLS_PATH%\Bin\Win32"
    echo [DEBUG] EDK_TOOLS_BIN set to: %EDK_TOOLS_BIN%
) else (
    set "EDK_TOOLS_BIN=%EDK_TOOLS_PATH%\Source\C\bin"
    echo [DEBUG] EDK_TOOLS_BIN set to: %EDK_TOOLS_BIN%
)

call edksetup.bat
if errorlevel 1 (
    echo ERROR: Failed to set up EDK2 environment.
    echo Attempting recovery with minimal setup...
    
    REM Try to set up basic environment manually
    set "WORKSPACE=%EDK2_ROOT%"
    set "EDK_TOOLS_PATH=%EDK2_ROOT%\BaseTools"
    set "CONF_PATH=%EDK2_ROOT%\Conf"
    
    REM Create Conf directory if it doesn't exist
    if not exist "Conf" mkdir "Conf"
    
    echo [WARNING] Using minimal EDK2 environment setup
    echo Continuing with build attempt...
)

:create_convenience_script
echo.
echo === Step 9: Creating Convenience Scripts ===

REM Create a convenience script for future builds
set "BUILD_SCRIPT=%EDK2_ROOT%\build-edk2.bat"

echo @echo off > "%BUILD_SCRIPT%"
echo REM EDK2 Build Environment Setup >> "%BUILD_SCRIPT%"
echo cd /d "%EDK2_ROOT%" >> "%BUILD_SCRIPT%"
echo call edksetup.bat >> "%BUILD_SCRIPT%"
echo echo. >> "%BUILD_SCRIPT%"
echo echo EDK2 environment is ready! >> "%BUILD_SCRIPT%"
echo echo Example build commands: >> "%BUILD_SCRIPT%"
echo echo   build -a X64 -t VS2019 -b RELEASE -p ACPIPatcherPkg/ACPIPatcherPkg.dsc >> "%BUILD_SCRIPT%"
echo echo   build -a X64 -t VS2022 -b DEBUG -p ACPIPatcherPkg/ACPIPatcherPkg.dsc >> "%BUILD_SCRIPT%"
echo echo   build -a IA32 -t GCC5 -b RELEASE -p ACPIPatcherPkg/ACPIPatcherPkg.dsc >> "%BUILD_SCRIPT%"
echo echo. >> "%BUILD_SCRIPT%"
echo cmd /k >> "%BUILD_SCRIPT%"

echo Created convenience script: %BUILD_SCRIPT%

:configure_build
echo.
echo === Step 10: Configuring Build Settings ===

echo Using build configuration:
echo   Architecture: %TARGET_ARCH%
echo   Build Type: %BUILD_TYPE%

REM Detect toolchain
if defined BASETOOLS_CYGWIN_BUILD (
    REM Use GCC5 for Cygwin compatibility
    set "TOOL_CHAIN_TAG=GCC5"
    echo Using GCC5 toolchain for Cygwin build
    
    REM Set additional GCC-specific environment variables for compatibility
    set "GCC5_BIN=%BASETOOLS_CYGWIN_PATH%\bin\"
    echo [DEBUG] GCC5_BIN set to: %GCC5_BIN%
    
    REM Ensure Cygwin make is available as 'make' for EDK2 build system
    echo [DEBUG] Current PATH includes Cygwin: %BASETOOLS_CYGWIN_PATH%\bin
) else (
    where cl >nul 2>&1
    if errorlevel 1 (
        set "TOOL_CHAIN_TAG=GCC5"
        echo Using GCC5 toolchain
    ) else (
        if defined VS_VERSION (
            set "TOOL_CHAIN_TAG=VS%VS_VERSION%"
            echo Using VS%VS_VERSION% toolchain
        ) else (
            set "TOOL_CHAIN_TAG=VS2019"
            echo Using VS2019 toolchain (default)
        )
    )
)

:build_acpipatcher
echo.
echo ================================================================
echo Building ACPIPatcher Package
echo ================================================================
echo Target: !TARGET_ARCH! !BUILD_TYPE! (!TOOL_CHAIN_TAG!)
echo.

REM Ensure BaseTools are in PATH for build process
echo [DEBUG] Ensuring BaseTools are in PATH for build...
set "PATH=%EDK_TOOLS_PATH%\Source\C\bin;%EDK_TOOLS_PATH%\Bin\Win32;%EDK_TOOLS_PATH%\Bin\Win64;%PATH%"

REM Verify GenFw is accessible before build
where GenFw >nul 2>&1
if errorlevel 1 (
    echo [ERROR] GenFw not found in PATH. Checking BaseTools locations...
    if exist "%EDK_TOOLS_PATH%\Source\C\bin\GenFw.exe" (
        echo [OK] Found GenFw at %EDK_TOOLS_PATH%\Source\C\bin\GenFw.exe
        set "PATH=%EDK_TOOLS_PATH%\Source\C\bin;%PATH%"
    ) else if exist "%EDK_TOOLS_PATH%\Bin\Win32\GenFw.exe" (
        echo [OK] Found GenFw at %EDK_TOOLS_PATH%\Bin\Win32\GenFw.exe
        set "PATH=%EDK_TOOLS_PATH%\Bin\Win32;%PATH%"
    ) else if exist "%EDK_TOOLS_PATH%\Bin\Win64\GenFw.exe" (
        echo [OK] Found GenFw at %EDK_TOOLS_PATH%\Bin\Win64\GenFw.exe
        set "PATH=%EDK_TOOLS_PATH%\Bin\Win64;%PATH%"
    ) else (
        echo [ERROR] GenFw not found in any BaseTools location!
        echo This will cause build failure.
    )
) else (
    echo [OK] GenFw found in PATH
)

build -p ACPIPatcherPkg\ACPIPatcherPkg.dsc -a !TARGET_ARCH! -t !TOOL_CHAIN_TAG! -b !BUILD_TYPE!
if errorlevel 1 (
    echo.
    echo ERROR: Standard build failed. Trying with explicit BaseTools setup...
    
    REM Try again with explicit PATH and environment setup
    echo [DEBUG] Setting up complete EDK2 environment for retry...
    
    REM Ensure all EDK2 environment variables are properly set
    set "WORKSPACE=%EDK2_ROOT%"
    set "EDK_TOOLS_PATH=%EDK2_ROOT%\BaseTools"
    set "CONF_PATH=%EDK2_ROOT%\Conf"
    set "PYTHON_COMMAND=python"
    
    REM Add BaseTools to PATH with highest priority
    set "PATH=%EDK_TOOLS_PATH%\Source\C\bin;%EDK_TOOLS_PATH%\Bin\Win32;%EDK_TOOLS_PATH%\Bin\Win64;%PATH%"
    
    REM Call edksetup again to refresh environment
    call edksetup.bat
    
    REM Retry build with fresh environment
    build -p ACPIPatcherPkg\ACPIPatcherPkg.dsc -a !TARGET_ARCH! -t !TOOL_CHAIN_TAG! -b !BUILD_TYPE!
    if errorlevel 1 (
        echo.
        echo ERROR: Build failed even with explicit environment setup.
        echo Checking if BaseTools were built correctly...
        
        if exist "%EDK_TOOLS_PATH%\Source\C\bin\GenFw.exe" (
            echo GenFw exists at: %EDK_TOOLS_PATH%\Source\C\bin\GenFw.exe
        ) else (
            echo ERROR: GenFw.exe not found in expected location
        )
        
        echo Build diagnostics complete.
        if %CI_MODE%==0 pause
        exit /b 1
    )
)

echo.
echo ================================================================
echo Build completed successfully!
echo ================================================================

REM Copy built files back to main directory
echo.
echo Copying build artifacts...

set "BUILD_DIR=Build\ACPIPatcher\!BUILD_TYPE!_!TOOL_CHAIN_TAG!\!TARGET_ARCH!"

REM Check for ACPIPatcher.efi in multiple possible locations
set "ACPIPATCHER_FOUND=0"
if exist "!BUILD_DIR!\ACPIPatcher.efi" (
    copy "!BUILD_DIR!\ACPIPatcher.efi" "%ACPI_PATCHER_ROOT%\ACPIPatcher.efi"
    set "ACPIPATCHER_FOUND=1"
    echo [OK] ACPIPatcher.efi copied from !BUILD_DIR!
) else if exist "!BUILD_DIR!\ACPIPatcherPkg\ACPIPatcher\ACPIPatcher\OUTPUT\ACPIPatcher.efi" (
    copy "!BUILD_DIR!\ACPIPatcherPkg\ACPIPatcher\ACPIPatcher\OUTPUT\ACPIPatcher.efi" "%ACPI_PATCHER_ROOT%\ACPIPatcher.efi"
    set "ACPIPATCHER_FOUND=1"
    echo [OK] ACPIPatcher.efi copied from OUTPUT directory
) else (
    echo WARNING: ACPIPatcher.efi not found in expected build output locations
    echo Checked: !BUILD_DIR!\ACPIPatcher.efi
    echo Checked: !BUILD_DIR!\ACPIPatcherPkg\ACPIPatcher\ACPIPatcher\OUTPUT\ACPIPatcher.efi
)

REM Check for ACPIPatcherDxe.efi in multiple possible locations
set "ACPIPATCHERDXE_FOUND=0"
if exist "!BUILD_DIR!\ACPIPatcherDxe.efi" (
    copy "!BUILD_DIR!\ACPIPatcherDxe.efi" "%ACPI_PATCHER_ROOT%\ACPIPatcherDxe.efi"
    set "ACPIPATCHERDXE_FOUND=1"
    echo [OK] ACPIPatcherDxe.efi copied from !BUILD_DIR!
) else if exist "!BUILD_DIR!\ACPIPatcherPkg\ACPIPatcher\ACPIPatcherDxe\OUTPUT\ACPIPatcherDxe.efi" (
    copy "!BUILD_DIR!\ACPIPatcherPkg\ACPIPatcher\ACPIPatcherDxe\OUTPUT\ACPIPatcherDxe.efi" "%ACPI_PATCHER_ROOT%\ACPIPatcherDxe.efi"
    set "ACPIPATCHERDXE_FOUND=1"
    echo [OK] ACPIPatcherDxe.efi copied from OUTPUT directory
) else (
    echo WARNING: ACPIPatcherDxe.efi not found in expected build output locations
    echo Checked: !BUILD_DIR!\ACPIPatcherDxe.efi
    echo Checked: !BUILD_DIR!\ACPIPatcherPkg\ACPIPatcher\ACPIPatcherDxe\OUTPUT\ACPIPatcherDxe.efi
)

REM Display final status
if !ACPIPATCHER_FOUND!==1 if !ACPIPATCHERDXE_FOUND!==1 (
    echo [SUCCESS] Both ACPIPatcher.efi and ACPIPatcherDxe.efi copied successfully!
) else (
    echo [WARNING] Some build artifacts may not have been copied. Check the build output above.
)

cd /d "%ACPI_PATCHER_ROOT%"

echo.
echo === EDK2 Setup Complete! ===
echo.
echo Environment variables set:
echo   WORKSPACE = %EDK2_ROOT%
echo   EDK_TOOLS_PATH = %EDK2_ROOT%\BaseTools
if defined NASM_PREFIX echo   NASM_PREFIX = %NASM_PREFIX%
echo.
echo To use EDK2 in new sessions, run: %BUILD_SCRIPT%
echo Or manually run: cd %EDK2_ROOT% ^&^& edksetup.bat
echo.
echo ================================================================
echo ACPIPatcher build process completed!
echo ================================================================
echo Build Configuration:
echo   Architecture: %TARGET_ARCH%
echo   Build Type: %BUILD_TYPE%
echo   Toolchain: !TOOL_CHAIN_TAG!
echo.
echo Built files should be available in the current directory.
echo You can now use the .efi files for UEFI firmware integration.
echo.
echo Usage examples for different configurations:
echo   setup_and_build.bat X64 RELEASE
echo   setup_and_build.bat X64 DEBUG  
echo   setup_and_build.bat IA32 RELEASE
echo   setup_and_build.bat IA32 DEBUG
echo.
if %CI_MODE%==0 (
    echo Press any key to exit...
    pause >nul
)

:end
endlocal

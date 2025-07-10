# MSYS2 MinGW Build Support Update

## Changes Made

### 1. Updated Build Matrix
Added proper MSYS2 system configurations for GCC5 builds:
- **X64 builds**: `msys: mingw64`, `msys_env: x86_64`
- **IA32 builds**: `msys: mingw32`, `msys_env: i686`

### 2. Replaced MinGW Setup Action
Changed from `egor-tensin/setup-mingw@v2` to `msys2/setup-msys2@v2`:
- Proper MSYS2 environment setup
- Automatic installation of GCC toolchain and Python
- Better integration with GitHub Actions

### 3. Conditional Build Steps
Split steps into toolchain-specific versions:
- **VS Toolchain**: Uses PowerShell (`pwsh`) shell
- **GCC5 Toolchain**: Uses MSYS2 shell (`msys2 {0}`)

### 4. Python Virtual Environment Setup
- **VS builds**: Use `py -m venv .venv` and `.venv\Scripts\Activate.ps1`
- **GCC5 builds**: Use `python3 -m venv .venv` and `source .venv/bin/activate`

### 5. Stuart Commands
- **VS builds**: Run in PowerShell with Windows-style paths
- **GCC5 builds**: Run in MSYS2 shell with Unix-style paths

### 6. BaseTools Build
- Runs only for GCC5 builds using `msys2 {0}` shell
- Uses `python3 BaseTools/Edk2ToolsBuild.py -t GCC5`
- Proper error handling with Unix-style exit codes

## Benefits

### Proper MSYS2 Integration
- Native MSYS2 environment for GCC5 builds
- Automatic toolchain installation
- Better compatibility with EDK2 build system

### Toolchain Isolation
- VS builds use native Windows environment
- GCC5 builds use MSYS2 MinGW environment
- No interference between different toolchain setups

### Enhanced Reliability
- Proper shell environment for each toolchain
- Correct path handling and command execution
- Better error reporting and handling

## Build Matrix Coverage

The workflow now supports:
- **VS2022**: X64/IA32, RELEASE/DEBUG/NOOPT
- **GCC5**: X64/IA32, RELEASE/DEBUG with proper MSYS2 setup
- **Unit Tests**: NOOPT builds with VS2022

## Technical Details

### MSYS2 Package Installation
```yaml
install: >-
  git
  python3
  python3-pip
  mingw-w64-${{ matrix.msys_env }}-gcc
  mingw-w64-${{ matrix.msys_env }}-python
  mingw-w64-${{ matrix.msys_env }}-python-pip
```

### Shell Usage
- **VS builds**: `shell: pwsh`
- **GCC5 builds**: `shell: msys2 {0}`
- **BaseTools**: `shell: msys2 {0}` (GCC5 only)

### Virtual Environment Handling
- **VS**: Windows-style paths and PowerShell commands
- **GCC5**: Unix-style paths and bash commands
- **Activation**: Proper activation scripts for each environment

This update ensures that GCC5/MinGW builds work correctly with the Stuart build system while maintaining compatibility with existing VS2022 builds.

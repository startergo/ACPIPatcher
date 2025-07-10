# Workflow Dependencies Optimization

## Changes Made

Optimized the Stuart build workflow to only use the necessary actions for each toolchain, reducing setup time and eliminating unnecessary dependencies.

## Before vs After

### Before:
- All matrix jobs used all setup actions regardless of toolchain
- Unnecessary Microsoft actions ran for GCC5/MinGW builds
- Redundant Python setup for MSYS2 builds

### After:
- **VS Toolchain jobs** only use Microsoft-specific actions
- **GCC5 toolchain jobs** only use MSYS2 setup
- Each toolchain gets exactly what it needs

## Toolchain-Specific Actions

### Visual Studio (VS2022) Builds
```yaml
- name: Setup Python (VS Toolchain)
  if: startsWith(matrix.toolchain, 'VS')
  uses: actions/setup-python@v5
  with:
    python-version: '3.11'

- name: Setup Visual Studio Environment
  if: startsWith(matrix.toolchain, 'VS')
  uses: microsoft/setup-msbuild@v2

- name: Setup Windows Build Environment
  if: startsWith(matrix.toolchain, 'VS')
  uses: ilammy/msvc-dev-cmd@v1.13.0
  with:
    arch: ${{ matrix.arch == 'IA32' && 'x86' || 'x64' }}
```

### GCC5/MinGW Builds
```yaml
- name: Setup MSYS2 for MinGW
  if: matrix.toolchain == 'GCC5'
  uses: msys2/setup-msys2@v2
  with:
    msystem: ${{ matrix.msys }}
    update: true
    install: >-
      git
      python3
      python3-pip
      mingw-w64-${{ matrix.msys_env }}-gcc
      mingw-w64-${{ matrix.msys_env }}-python
      mingw-w64-${{ matrix.msys_env }}-python-pip
```

## Why This Optimization Matters

### 1. **Reduced Setup Time**
- VS builds don't wait for unnecessary MSYS2 setup
- GCC5 builds don't wait for unnecessary Microsoft toolchain setup
- Each job starts faster with only required dependencies

### 2. **Cleaner Environment**
- No conflicting toolchain installations
- Each build uses its native environment
- Reduced chance of environment conflicts

### 3. **Better Resource Usage**
- Less download time for unused tools
- Smaller action runner footprint
- More efficient CI/CD execution

### 4. **MSYS2 Advantages**
- MSYS2 provides its own Python environment
- No need for separate Python setup action
- Native MinGW toolchain integration
- Better compatibility with EDK2 GCC5 builds

## What Each Toolchain Gets

### VS2022 Builds:
- ✅ Native Windows Python (via actions/setup-python@v5)
- ✅ MSBuild environment setup
- ✅ MSVC compiler environment
- ✅ Windows-style paths and commands

### GCC5 Builds:
- ✅ MSYS2 environment with MinGW-w64 GCC
- ✅ MSYS2 Python 3 (native to the environment)
- ✅ Unix-style paths and commands
- ✅ Proper BaseTools build support

## Performance Impact

- **Faster job startup**: Each job only installs what it needs
- **Reduced complexity**: Cleaner separation of concerns
- **Better reliability**: No cross-toolchain interference
- **Optimized resource usage**: Efficient use of GitHub Actions minutes

This optimization ensures that each build configuration gets exactly the tools it needs without unnecessary overhead or potential conflicts.

# ACPIPatcher
An EFI application and driver to add SSDTs and/or patch in your own DSDT

[![Build and Test](https://github.com/startergo/ACPIPatcher/actions/workflows/build-and-test.yml/badge.svg)](https://github.com/startergo/ACPIPatcher/actions/workflows/build-and-test.yml)
[![Quick CI](https://github.com/startergo/ACPIPatcher/actions/workflows/ci.yml/badge.svg)](https://github.com/startergo/ACPIPatcher/actions/workflows/ci.yml)
[![Comprehensive Testing](https://github.com/startergo/ACPIPatcher/actions/workflows/comprehensive-test.yml/badge.svg)](https://github.com/startergo/ACPIPatcher/actions/workflows/comprehensive-test.yml)
[![GitHub release](https://img.shields.io/github/v/release/startergo/ACPIPatcher)](https://github.com/startergo/ACPIPatcher/releases)
[![License](https://img.shields.io/github/license/startergo/ACPIPatcher)](LICENSE)

> **✨ Recently Enhanced**: This project has been significantly improved with better error handling, memory management, comprehensive CI/CD automation, and extensive documentation. See [IMPROVEMENTS.md](IMPROVEMENTS.md) and [CI_CD_FIXES.md](CI_CD_FIXES.md) for details.

I made this tool because I wanted a way to use [RehabMans ACPI Debug tool](https://github.com/RehabMan/OS-X-ACPI-Debug) on my MacBook Pro without using Clover.  Although I made this with macOS in mind it will work with any OS along with any bootloader (provided your bootloader does not do its own ACPI patching).

## Features
- **DSDT Replacement**: Replace the system DSDT with a custom one
- **SSDT Addition**: Add custom SSDT tables to the system
- **Table Validation**: Validates ACPI table integrity before patching
- **Comprehensive Debugging**: Multiple debug levels for troubleshooting
- **Error Recovery**: Graceful handling of corrupted or invalid files
- **Memory Safety**: Enhanced memory management and bounds checking
- **Checksum Updates**: Automatic recalculation of table checksums

## System Requirements

### Minimum Requirements
- **UEFI Firmware**: ACPI 2.0+ compatible UEFI firmware
- **Architecture**: x64 (Intel/AMD 64-bit) or IA32 (32-bit x86)
- **Memory**: At least 2MB available EFI memory
- **Storage**: Access to EFI System Partition for file placement

### Supported Platforms
- **Intel-based systems**: Core 2 Duo and newer
- **AMD-based systems**: Athlon 64 and newer
- **UEFI firmware**: Most modern UEFI implementations (2010+)
- **Operating Systems**: Windows, macOS, Linux (OS-agnostic)

### Bootloader Compatibility
- ✅ **OpenCore**: Full support with driver integration
- ✅ **Clover**: Compatible with driver folder placement
- ✅ **rEFInd**: Works with driver directory
- ✅ **GRUB**: Compatible via EFI shell execution
- ✅ **Direct UEFI**: Native EFI shell execution
- ❌ **Legacy BIOS**: Not supported (UEFI only)

### File System Support
- **FAT32**: Primary file system for EFI System Partition
- **FAT16**: Compatible for smaller partitions
- **NTFS/ext4**: Not supported for EFI execution (use FAT32)

## How to use:

### Quick Start
1. **Download** or compile the ACPIPatcher binaries
2. **Create** an `ACPI` folder in the same directory as `ACPIPatcher.efi`
3. **Place** your `.aml` files in the `ACPI` folder
4. **Run** `ACPIPatcher.efi` from an EFI shell
5. **Reboot** to apply changes

### Detailed Usage Instructions

#### Application Mode (One-time patching)
Using this is fairly straightforward. Just place a folder titled `ACPI` in the same directory as `ACPIPatcher.efi` and it will search the folder for any `.aml` files. Any file not named `DSDT.aml` will be added to the XSDT table as SSDTs while `DSDT.aml` will completely replace the OEM DSDT.

**Steps:**
1. Boot to EFI shell (usually by pressing F2/F12 during boot or using a UEFI shell USB)
2. Navigate to your EFI partition: `fs0:` (or `fs1:`, `fs2:`, etc.)
3. Place `ACPIPatcher.efi` and `ACPI` folder in the same directory
4. Run the application: `ACPIPatcher.efi`
5. Review the output for any errors or warnings
6. Type `reset` to reboot and apply changes

#### Driver Mode (Persistent patching)
However, if you would like your patches to survive reboots you can use the driver version of this software. To do this simply place `ACPIPatcherDxe.efi` in your bootloader's driver folder along with the `ACPI` folder mentioned above.

**For OpenCore users:**
1. Place `ACPIPatcherDxe.efi` in `EFI/OC/Drivers/`
2. Place `ACPI` folder in `EFI/OC/` (same level as `Drivers` folder)
3. Add the driver to your `config.plist`:
   ```xml
   <dict>
       <key>Arguments</key>
       <string></string>
       <key>Comment</key>
       <string>ACPI Patcher Driver</string>
       <key>Enabled</key>
       <true/>
       <key>Path</key>
       <string>ACPIPatcherDxe.efi</string>
   </dict>
   ```

**For Clover users:**
1. Place `ACPIPatcherDxe.efi` in `EFI/CLOVER/drivers/UEFI/`
2. Place `ACPI` folder in `EFI/CLOVER/`

**For rEFInd users:**
1. Place `ACPIPatcherDxe.efi` in `EFI/refind/drivers_x64/`
2. Place `ACPI` folder in `EFI/refind/`

### File Organization
Your directory structure should look like this:

**Application Mode:**
```
FS0:\
├── ACPIPatcher.efi
└── ACPI\
    ├── DSDT.aml          (Optional: replaces system DSDT)
    ├── SSDT-CPU.aml      (Custom CPU management)
    ├── SSDT-GPU.aml      (Graphics patches)
    └── SSDT-USB.aml      (USB port configuration)
```

**Driver Mode (OpenCore example):**
```
EFI\
└── OC\
    ├── Drivers\
    │   └── ACPIPatcherDxe.efi
    ├── ACPI\
    │   ├── DSDT.aml
    │   ├── SSDT-CPU.aml
    │   └── SSDT-USB.aml
    └── config.plist
```

### ACPI Table Types

#### DSDT (Differentiated System Description Table)
- **Filename:** Must be named exactly `DSDT.aml`
- **Purpose:** Completely replaces the system's original DSDT
- **Use case:** Major system modifications, hardware enablement
- **Warning:** Incorrect DSDT can prevent system boot

#### SSDT (Secondary System Description Table)
- **Filename:** Any `.aml` file except `DSDT.aml`
- **Purpose:** Adds additional ACPI functionality
- **Use case:** Device patches, power management, hardware fixes
- **Safer:** Less likely to cause boot issues than DSDT replacement

### Testing and Validation

I have also provided a test SSDT in `Build/ACPI` for validation purposes.

**Before deploying custom tables:**
1. Test with the provided `SSDT-Test.aml` first
2. Enable VERBOSE debugging to monitor the patching process
3. Keep backup of working configuration
4. Test boot with new tables before making permanent

**Common issues and solutions:**
- **Boot failure:** Remove DSDT.aml and try SSDT-only approach
- **No effect:** Check file permissions and naming conventions
- **Errors:** Enable debugging and check DEBUG_GUIDE.md

## Debugging

ACPIPatcher now includes comprehensive debugging capabilities to help troubleshoot ACPI patching issues. See [DEBUG_GUIDE.md](DEBUG_GUIDE.md) for detailed information.

### Debug Levels
- **ERROR**: Only critical failures
- **WARN**: Warnings and errors  
- **INFO**: General information (default)
- **VERBOSE**: Detailed debugging with memory dumps

### Sample Debug Output
```
[INFO]  === ACPIPatcher v1.1 Starting ===
[INFO]  Found XSDT at address: 0x7FF8B000
[INFO]  Processing file: DSDT.aml (16384 bytes)
[INFO]  ACPI patching summary:
[INFO]    Files processed: 5
[INFO]    Tables added/replaced: 4
```

### Troubleshooting
If you encounter issues, increase the debug level by modifying `DEBUG_LEVEL` in the source code:
```c
#define DEBUG_LEVEL DEBUG_VERBOSE  // For maximum debugging output
```

## Documentation
- [IMPROVEMENTS.md](IMPROVEMENTS.md) - Details about code improvements and security enhancements
- [DEBUG_GUIDE.md](DEBUG_GUIDE.md) - Comprehensive debugging and troubleshooting guide

## How to Build:

### Prerequisites

#### Windows (Visual Studio)
1. **Install Visual Studio 2019/2022** with C++ development tools
2. **Install NASM:** Download from https://www.nasm.us/
3. **Install Python 3.7+** for EDK II build scripts
4. **Install Git** for repository cloning

#### macOS (Xcode)
```bash
# Install Xcode command line tools
xcode-select --install

# Install required tools via Homebrew
brew install nasm
brew install mtoc
brew install python3
```

#### Linux (GCC)
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install build-essential nasm python3 git uuid-dev

# CentOS/RHEL/Fedora
sudo dnf install gcc gcc-c++ nasm python3 git libuuid-devel
```

### EDK II Setup

#### Method 1: Quick Setup (Recommended)
```bash
# Clone EDK II repository
git clone --depth=1 -b edk2-stable202202 https://github.com/tianocore/edk2.git
cd edk2/

# Initialize submodules
git submodule update --init --recommend-shallow

# Setup build environment
source edksetup.sh  # Linux/macOS
# OR
edksetup.bat        # Windows

# Build base tools
make -C BaseTools   # Linux/macOS
# OR
build -t VS2019     # Windows (in EDK II Command Prompt)
```

#### Method 2: Manual Setup
1. Download EDK II from https://github.com/tianocore/edk2
2. Extract to a directory (e.g., `C:\edk2` or `/home/user/edk2`)
3. Follow EDK II documentation for your platform

### Building ACPIPatcher

#### Step 1: Place Source Code
```bash
# Copy ACPIPatcherPkg to your EDK II directory
cp -r ACPIPatcherPkg /path/to/edk2/
```

#### Step 2: Build Commands

**Linux/macOS:**
```bash
cd /path/to/edk2
source edksetup.sh

# Build both application and driver (Release)
build -a X64 -b RELEASE -t GCC5 -p ACPIPatcherPkg/ACPIPatcherPkg.dsc

# Build with debug symbols
build -a X64 -b DEBUG -t GCC5 -p ACPIPatcherPkg/ACPIPatcherPkg.dsc

# macOS with Xcode
build -a X64 -b RELEASE -t XCODE5 -p ACPIPatcherPkg/ACPIPatcherPkg.dsc
build -a X64 -b DEBUG -t XCODE5 -p ACPIPatcherPkg/ACPIPatcherPkg.dsc
```

**Windows:**
```cmd
cd C:\edk2
edksetup.bat

# Build with Visual Studio 2019
build -a X64 -b RELEASE -t VS2019 -p ACPIPatcherPkg\ACPIPatcherPkg.dsc

# Build with debug information
build -a X64 -b DEBUG -t VS2019 -p ACPIPatcherPkg\ACPIPatcherPkg.dsc
```

#### Step 3: Locate Built Files
After successful compilation, binaries will be located at:
```
Build/ACPIPatcherPkg/RELEASE_[TOOLCHAIN]/X64/
├── ACPIPatcher.efi        (Application version)
└── ACPIPatcherDxe.efi     (Driver version)

# Example paths:
# Linux: Build/ACPIPatcherPkg/RELEASE_GCC5/X64/
# macOS: Build/ACPIPatcherPkg/RELEASE_XCODE5/X64/
# Windows: Build\ACPIPatcherPkg\RELEASE_VS2019\X64\
```

### Build Options

#### Debug vs Release
- **DEBUG**: Includes debugging symbols and additional runtime checks
- **RELEASE**: Optimized for size and performance, recommended for production

#### Architecture Support
- **X64**: 64-bit x86 (Intel/AMD) - Primary target
- **IA32**: 32-bit x86 (legacy systems)
- **AARCH64**: ARM64 (experimental)

#### Custom Debug Level
To build with specific debug level:
```bash
# Maximum debugging output
build -a X64 -b DEBUG -t GCC5 -p ACPIPatcherPkg/ACPIPatcherPkg.dsc -D DEBUG_LEVEL=4

# Production build with minimal output
build -a X64 -b RELEASE -t GCC5 -p ACPIPatcherPkg/ACPIPatcherPkg.dsc -D DEBUG_LEVEL=1
```

### Troubleshooting Build Issues

#### Common Build Errors

**Error: "nasm not found"**
```bash
# Solution: Install NASM assembler
# Windows: Download from https://www.nasm.us/
# macOS: brew install nasm
# Linux: sudo apt install nasm
```

**Error: "BaseTools not built"**
```bash
# Solution: Build BaseTools first
cd /path/to/edk2
make -C BaseTools
```

**Error: "Python not found"**
```bash
# Solution: Install Python 3.7+
# Ensure python3 is in your PATH
which python3  # Should show python location
```

**Error: "Toolchain not found"**
```bash
# Solution: Install appropriate compiler
# Linux: sudo apt install build-essential
# macOS: xcode-select --install
# Windows: Install Visual Studio with C++ tools
```

#### Clean Build
If you encounter persistent build issues:
```bash
# Clean previous build artifacts
rm -rf Build/ACPIPatcherPkg/
rm -rf Conf/.cache/

# Rebuild BaseTools
make -C BaseTools clean
make -C BaseTools

# Try build again
build -a X64 -b RELEASE -t GCC5 -p ACPIPatcherPkg/ACPIPatcherPkg.dsc
```

### Build Automation

#### Script for Continuous Integration
```bash
#!/bin/bash
# build-acpipatcher.sh

set -e  # Exit on any error

echo "Setting up EDK II environment..."
source edksetup.sh

echo "Building BaseTools..."
make -C BaseTools

echo "Building ACPIPatcher (Release)..."
build -a X64 -b RELEASE -t GCC5 -p ACPIPatcherPkg/ACPIPatcherPkg.dsc

echo "Building ACPIPatcher (Debug)..."
build -a X64 -b DEBUG -t GCC5 -p ACPIPatcherPkg/ACPIPatcherPkg.dsc

echo "Build completed successfully!"
echo "Binaries available in Build/ACPIPatcherPkg/"
```

### Pre-built Binaries
For convenience, pre-built binaries are provided in the releases section. However, building from source is recommended for:
- Security validation
- Custom debug levels
- Platform-specific optimizations
- Development and contribution


### Completed Improvements:
This project has evolved significantly from its original form:

* ✅ **Rewrite as a driver** - Driver version available so the application does not need to be called before every boot
* ✅ **Enhanced Memory Management** - Complete overhaul with proper cleanup, bounds checking, and leak prevention
* ✅ **Robust Error Handling** - Comprehensive error checking with graceful degradation and detailed reporting
* ✅ **Security Hardening** - Input validation, buffer overflow protection, and ACPI table integrity checking
* ✅ **Debugging System** - Multi-level debugging with detailed logging and troubleshooting capabilities
* ✅ **Code Quality** - Professional-grade documentation, consistent coding standards, and maintainability improvements

### Memory Management Improvements:
- **Proper Pool Selection**: Uses appropriate memory pool types (EfiBootServicesData vs EfiBootServicesCode)
- **Comprehensive Cleanup**: All allocated memory is properly freed in both success and error paths
- **Bounds Checking**: Prevents buffer overflows when modifying XSDT and reading files
- **Null Pointer Protection**: Validates all pointers before dereferencing
- **Resource Limits**: Prevents memory exhaustion with configurable table limits
- **Leak Prevention**: Goto cleanup patterns ensure resources are always freed

### Error Handling Improvements:
- **Graceful Degradation**: Continues processing when individual files fail
- **Detailed Error Reporting**: Specific error codes with context and suggested fixes
- **Input Validation**: Comprehensive parameter checking for all functions
- **File System Resilience**: Handles missing files, access errors, and corrupted data
- **Recovery Mechanisms**: Attempts to continue operation despite non-critical failures
- **Status Propagation**: Proper EFI_STATUS codes throughout the application

## CI/CD and Automation

This project uses comprehensive GitHub Actions workflows for automated building, testing, and releasing:

### 🚀 **Automated Builds**
- **Cross-platform**: Linux (Ubuntu), macOS, Windows
- **Multi-architecture**: X64 and IA32 support
- **Multiple configurations**: Debug and Release builds
- **Automated testing**: Static analysis and code quality checks

### 📦 **Release Automation**
- **Automatic releases**: Triggered by git tags
- **Multi-platform packages**: Platform-specific artifacts
- **Comprehensive documentation**: Build info and checksums included
- **Asset verification**: Automated integrity checks

### 🔍 **Quality Assurance**
- **Static Analysis**: CPPCheck, Clang-Tidy integration
- **Security Scanning**: Vulnerability detection and code review
- **Performance Testing**: Build time and binary size monitoring
- **Compliance Checking**: Coding standards validation

### 📊 **Workflow Status**
Current build status across all platforms and configurations is shown in the badges above. For detailed information about the CI/CD pipeline, see [GITHUB_ACTIONS.md](GITHUB_ACTIONS.md).

### Future Enhancements:
* Configuration file support for advanced patching options
* ACPI table backup and restore functionality
* Integration with firmware setup utilities
* Support for ACPI 6.5+ features

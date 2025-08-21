# ACPIPatcher
An EFI application and driver to add SSDTs and/or patch in your own DSDT

[![CI Build](https://github.com/startergo/ACPIPatcher/actions/workflows/ci-new.yml/badge.svg)](https://github.com/startergo/ACPIPatcher/actions/workflows/ci-new.yml)
[![Release](https://github.com/startergo/ACPIPatcher/actions/workflows/release.yml/badge.svg)](https://github.com/startergo/ACPIPatcher/actions/workflows/release.yml)
[![GitHub release](https://img.shields.io/github/v/release/startergo/ACPIPatcher)](https://github.com/startergo/ACPIPatcher/releases)
[![License](https://img.shields.io/github/license/startergo/ACPIPatcher)](LICENSE)

> **🚀 Clean & Simple**: This project has been streamlined with a focus on reliability and ease of use. The build system now uses traditional EDK2 tools for maximum compatibility and minimal dependencies.

I made this tool because I wanted a way to use [RehabMans ACPI Debug tool](https://github.com/RehabMan/OS-X-ACPI-Debug) on my MacBook Pro without using Clover's built-in ACPI patching. Although I made this with macOS in mind, it will work with any OS along with any EFI/UEFI-compatible bootloader. This tool is particularly useful for older Mac hardware (like MacPro5,1) that uses EFI 1.x firmware.

**Important Note on Bootloader Compatibility**: While ACPIPatcher can technically run with any bootloader, **OpenCore and Clover have their own sophisticated ACPI patching systems** that are generally preferred for production use. ACPIPatcher is most useful with bootloaders like **RefindPlus** or **rEFInd** that don't provide extensive ACPI modification capabilities, or for development/debugging scenarios where you need direct control over ACPI table injection.

## Features
- **DSDT Replacement**: Replace the system DSDT with a custom one
- **SSDT Addition**: Add custom SSDT tables to the system
- **✨ Enhanced SSDT Naming**: Support for both numeric (`SSDT-1.aml`) and descriptive (`SSDT-CPU.aml`) patterns
- **🔍 Smart Directory Scanning**: Automatically discovers all SSDT-*.aml files with intelligent duplicate detection
- **📁 Flexible File Organization**: Supports both ACPI/ subdirectory and same-directory placement
- **Table Validation**: Validates ACPI table integrity before patching
- **Comprehensive Debugging**: Multiple debug levels for troubleshooting
- **Error Recovery**: Graceful handling of corrupted or invalid files
- **Memory Safety**: Enhanced memory management and bounds checking
- **Checksum Updates**: Automatic recalculation of table checksums

## System Requirements

### Minimum Requirements
- **Firmware**: ACPI 2.0+ compatible EFI or UEFI firmware
- **Architecture**: x64 (Intel/AMD 64-bit) or IA32 (32-bit x86)
- **Memory**: At least 2MB available EFI memory
- **Storage**: Access to EFI System Partition for file placement

### Supported Platforms
- **Intel-based systems**: Core 2 Duo and newer (including older EFI Macs)
- **AMD-based systems**: Athlon 64 and newer
- **Firmware Compatibility**: 
  - **Modern UEFI**: Most systems 2012+ with full UEFI 2.x support
  - **Legacy EFI**: Older Mac systems (2006-2012) with EFI 1.x firmware
  - **Note**: MacPro5,1 and similar older Macs use EFI 1.x, not UEFI 2.x
- **Operating Systems**: Windows, macOS, Linux (OS-agnostic)

### Bootloader Compatibility
- ✅ **RefindPlus**: Recommended - excellent compatibility with ACPIPatcher
- ✅ **rEFInd**: Full support with driver directory
- ⚠️ **OpenCore**: Compatible but has built-in ACPI patching (see note below)
- ⚠️ **Clover**: Compatible but has built-in ACPI patching (see note below)
- ✅ **GRUB**: Compatible via EFI shell execution
- ✅ **Direct EFI/UEFI**: Native EFI shell execution
- ❌ **Legacy BIOS**: Not supported (EFI/UEFI only)

**Note on OpenCore/Clover**: While ACPIPatcher can run alongside these bootloaders, they provide their own comprehensive ACPI patching systems through their configuration files. For production use with these bootloaders, their built-in ACPI features are generally preferred. ACPIPatcher is most useful with these bootloaders for development, debugging, or specific edge cases not covered by their built-in patching.

**Note on Older Mac Hardware**: Systems like MacPro5,1 (2010/2012) use EFI 1.x firmware rather than modern UEFI 2.x. ACPIPatcher is compatible with both EFI 1.x and UEFI 2.x firmware implementations.

### File System Support
- **FAT32**: Primary file system for EFI System Partition
- **FAT16**: Compatible for smaller partitions
- **NTFS/ext4**: Not supported for EFI execution (use FAT32)

**Special Notes for Older Mac Hardware**:
- **MacPro5,1 and similar**: These systems use EFI 1.x firmware and may require specific bootloader configurations
- **EFI Shell Access**: On older Macs, accessing EFI shell may require holding Option during boot and selecting "EFI Boot" options
- **Firmware Limitations**: Some older EFI implementations may have stricter memory or file size limitations

## How to use:

### 🔍 **ACPI File Location Logic**

ACPIPatcher uses a sophisticated file discovery system that works consistently across both Application and DXE Driver modes:

#### **Step 1: Determine Base Directory**
- **Application Mode**: Base directory = directory where you run `ACPIPatcher.efi` from
- **DXE Driver Mode**: Base directory = directory where `ACPIPatcherDxe.efi` is located

#### **Step 2: ACPI File Discovery (with Smart Fallback)**
1. **Primary**: Try to open `ACPI/` subdirectory in the base directory
2. **Fallback**: If no `ACPI/` folder exists, scan the base directory directly
3. **Discovery**: Find all `.aml` files using the enhanced naming system

#### **Step 3: File Processing**
1. **DSDT Processing**: If `DSDT.aml` exists, replace system DSDT
2. **SSDT Processing Phase 1**: Load numeric SSDTs (`SSDT-1.aml` through `SSDT-10.aml`)
3. **SSDT Processing Phase 2**: Scan for descriptive SSDTs (`SSDT-*.aml`), skipping already-loaded numeric ones
4. **Integration**: Add all tables to XSDT with checksum validation

#### **Practical Examples**
```
# Application Mode - EFI Shell
fs0:\> dir
  ACPIPatcher.efi
  ACPI\              ← ACPIPatcher looks here FIRST
    DSDT.aml
    SSDT-CPU.aml

fs0:\> ACPIPatcher.efi
[INFO] Found ACPI directory, loading from ACPI/DSDT.aml
```

```
# DXE Driver Mode - OpenCore
EFI/OC/Drivers/ACPIPatcherDxe.efi  ← Driver location = base directory
EFI/OC/Drivers/ACPI/               ← ACPIPatcher looks here FIRST
EFI/OC/Drivers/ACPI/SSDT-CPU.aml   ← Loads this file
```

### Quick Start
1. **Download** or compile the ACPIPatcher binaries
2. **Create** an `ACPI` folder in the same directory as `ACPIPatcher.efi` (or place .aml files directly alongside it)
3. **Place** your `.aml` files in the `ACPI` folder (or same directory)
4. **Run** `ACPIPatcher.efi` from an EFI shell
5. **Reboot** to apply changes

### Detailed Usage Instructions

#### Application Mode (One-time patching)
ACPIPatcher uses a smart file discovery system that supports two organizational approaches:

**Option 1: ACPI Subdirectory (Recommended)**
Place your .aml files in an `ACPI` folder next to `ACPIPatcher.efi`. This keeps files organized and is the preferred method.

**Option 2: Same Directory (Fallback)**
If no `ACPI` folder exists, ACPIPatcher will look for .aml files in the same directory as the executable.

The tool will automatically:
- Replace the system DSDT if `DSDT.aml` is found
- Add any other `.aml` files as SSDT tables
- Support both numeric patterns (`SSDT-1.aml`, `SSDT-2.aml`) and descriptive names (`SSDT-CPU.aml`, `SSDT-GPU.aml`)
- Avoid duplicate loading of the same tables

**Steps:**
1. Boot to EFI shell (usually by pressing F2/F12 during boot or using a UEFI shell USB)
2. Navigate to your EFI partition: `fs0:` (or `fs1:`, `fs2:`, etc.)
3. Place `ACPIPatcher.efi` and `ACPI` folder in the same directory
4. Run the application: `ACPIPatcher.efi`
5. Review the output for any errors or warnings
6. Type `reset` to reboot and apply changes

#### Driver Mode (Persistent patching)
However, if you would like your patches to survive reboots you can use the driver version of this software. To do this simply place `ACPIPatcherDxe.efi` in your bootloader's driver folder along with the `ACPI` folder mentioned above.

**Important**: For OpenCore and Clover users, consider using their built-in ACPI patching features first, as they provide more comprehensive and tested solutions. Use ACPIPatcher with these bootloaders only for specific development needs or edge cases not covered by their native ACPI support.

**For OpenCore users:**
1. Place `ACPIPatcherDxe.efi` in `EFI/OC/Drivers/`
2. Place `ACPI` folder in `EFI/OC/Drivers/` (same location as the DXE driver) **OR** place .aml files directly in `EFI/OC/Drivers/`
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
2. Place `ACPI` folder in `EFI/CLOVER/drivers/UEFI/` (same location as the DXE driver) **OR** place .aml files directly in `EFI/CLOVER/drivers/UEFI/`

**For RefindPlus/rEFInd users (Recommended):**
1. Place `ACPIPatcherDxe.efi` in `EFI/refind/drivers_x64/`
2. Place `ACPI` folder in `EFI/refind/drivers_x64/` (same location as the DXE driver) **OR** place .aml files directly in `EFI/refind/drivers_x64/`

### File Organization
ACPIPatcher supports flexible file organization with automatic fallback:

**✅ Method 1: ACPI Subdirectory (Recommended)**
```
FS0:\
├── ACPIPatcher.efi
└── ACPI\                     ← Preferred location
    ├── DSDT.aml              (Optional: replaces system DSDT)
    ├── SSDT-1.aml            (Numeric naming - backward compatible)
    ├── SSDT-2.aml            (Numeric naming - backward compatible)
    ├── SSDT-CPU.aml          (✨ NEW: Descriptive naming)
    ├── SSDT-GPU.aml          (✨ NEW: Graphics patches)
    ├── SSDT-USB.aml          (✨ NEW: USB port configuration)
    ├── SSDT-BATTERY.aml      (✨ NEW: Battery patches)
    └── SSDT-ETHERNET.aml     (✨ NEW: Network patches)
```

**✅ Method 2: Same Directory (Automatic Fallback)**
```
FS0:\                         ← Fallback if no ACPI folder exists
├── ACPIPatcher.efi
├── DSDT.aml                  (Optional: replaces system DSDT)
├── SSDT-1.aml                (Numeric naming)
├── SSDT-CPU.aml              (✨ NEW: Descriptive naming)
├── SSDT-GPU.aml              (✨ NEW: Graphics patches)
└── SSDT-USB.aml              (✨ NEW: USB configuration)
```

**Driver Mode Examples:**

**OpenCore (ACPI folder - Recommended):**
```
EFI\
└── OC\
    ├── Drivers\
    │   ├── ACPIPatcherDxe.efi
    │   └── ACPI\             ← ACPI folder next to the driver
    │       ├── DSDT.aml
    │       ├── SSDT-CPU.aml
    │       └── SSDT-USB.aml
    └── config.plist
```

**OpenCore (Same directory fallback):**
```
EFI\
└── OC\
    ├── Drivers\
    │   ├── ACPIPatcherDxe.efi
    │   ├── DSDT.aml          ← .aml files alongside the driver
    │   ├── SSDT-CPU.aml      ← (if no ACPI folder exists)
    │   └── SSDT-USB.aml
    └── config.plist
```

**RefindPlus/rEFInd (ACPI folder - Recommended):**
```
EFI\
└── refind\
    ├── drivers_x64\
    │   ├── ACPIPatcherDxe.efi
    │   └── ACPI\             ← ACPI folder next to the driver
    │       ├── DSDT.aml
    │       ├── SSDT-CPU.aml
    │       └── SSDT-GPU.aml
    └── refind.conf
```

**⚠️ Important Note for DXE Driver File Location:**
The ACPIPatcherDxe.efi driver looks for ACPI files **relative to its own location**, not in the bootloader root directory. This means:
- ✅ **Correct**: Place ACPI files in the same directory as `ACPIPatcherDxe.efi`
- ❌ **Incorrect**: Place ACPI files in the bootloader root while driver is in a subdirectory

**Why this matters:**
- **Application mode**: `ACPIPatcher.efi` looks relative to where you run it from
- **Driver mode**: `ACPIPatcherDxe.efi` looks relative to where the driver file is located
- **Both modes**: Support the same ACPI folder → same directory fallback mechanism

### ACPI Table Types and Naming

#### DSDT (Differentiated System Description Table)
- **Filename:** Must be named exactly `DSDT.aml`
- **Purpose:** Completely replaces the system's original DSDT
- **Use case:** Major system modifications, hardware enablement
- **Warning:** Incorrect DSDT can prevent system boot

#### SSDT (Secondary System Description Table)
ACPIPatcher now supports **unlimited SSDT files** with flexible naming patterns:

**✅ Numeric Pattern (Backward Compatible)**
- **Filenames:** `SSDT-1.aml`, `SSDT-2.aml`, `SSDT-3.aml`, ..., `SSDT-10.aml`
- **Legacy Support:** Maintains compatibility with existing workflows

**✨ Descriptive Pattern (NEW Enhanced Feature)**
- **Filenames:** Any `SSDT-*.aml` pattern with descriptive names
- **Examples:**
  - `SSDT-CPU.aml` - CPU power management patches
  - `SSDT-GPU.aml` - Graphics device patches  
  - `SSDT-USB.aml` - USB port mapping
  - `SSDT-BATTERY.aml` - Battery status patches
  - `SSDT-ETHERNET.aml` - Network device patches
  - `SSDT-WIFI.aml` - WiFi device patches
  - `SSDT-AUDIO.aml` - Audio codec patches
  - `SSDT-THERMAL.aml` - Thermal management
  - `SSDT-KEYBOARD.aml` - Keyboard and trackpad patches

**Key Benefits:**
- 🔄 **Unlimited Files**: No longer limited to 10 SSDT tables
- 📝 **Self-Documenting**: Clear purpose identification from filename
- 🏗️ **Professional**: Matches industry ACPI patching standards
- 🔒 **Backward Compatible**: Existing numeric files continue to work
- 🚀 **Smart Loading**: Avoids duplicate loading, comprehensive validation

**Loading Behavior:**
1. **Phase 1**: Loads numeric SSDTs (1-10) for backward compatibility
2. **Phase 2**: Scans directory for descriptive SSDTs, skipping already-loaded numeric ones
3. **Validation**: Each table is validated for integrity before integration
4. **Integration**: Tables are added to XSDT with proper checksum updates

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

**Older Mac Hardware (MacPro5,1, etc.):**
- **EFI Shell Access:** Use Option key during boot, look for "EFI Boot" options
- **Memory Limitations:** Keep ACPI files small (<64KB each) for EFI 1.x compatibility
- **Bootloader Requirements:** RefindPlus or rEFInd work best with older EFI firmware
- **File Path Issues:** Ensure short path names and avoid deep directory structures

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
[INFO]  === Starting Real ACPI Patching ===
[INFO]  Attempting to load: DSDT.aml
[INFO]  Found ACPI directory, loading from ACPI/DSDT.aml
[INFO]  ✓ DSDT replaced successfully
[INFO]  Scanning for SSDT-*.aml files...
[INFO]  Found ACPI directory, loading from ACPI/SSDT-1.aml
[INFO]  ✓ SSDT-1.aml added successfully
[INFO]  Found ACPI directory, loading from ACPI/SSDT-2.aml
[INFO]  ✓ SSDT-2.aml added successfully
[INFO]  Starting directory scan for additional SSDT files...
[INFO]  Scanning ACPI/ subdirectory
[INFO]  Skipping numeric SSDT: SSDT-1.aml (already processed)
[INFO]  Skipping numeric SSDT: SSDT-2.aml (already processed)
[INFO]  Found descriptive SSDT: SSDT-CPU.aml
[INFO]  ✓ SSDT-CPU.aml loaded and added successfully
[INFO]  Found descriptive SSDT: SSDT-GPU.aml
[INFO]  ✓ SSDT-GPU.aml loaded and added successfully
[INFO]  Directory scan complete: 15 files scanned, 4 SSDT files found
[INFO]  ✓ XSDT checksum recalculated: 0x42
[INFO]  ✓ RSDP updated: 0x7FF8A000 -> 0x7FF9C000
[INFO]  Status: Successfully patched 5 ACPI tables!
```

### Troubleshooting
If you encounter issues, increase the debug level by modifying `DEBUG_LEVEL` in the source code:
```c
#define DEBUG_LEVEL DEBUG_VERBOSE  // For maximum debugging output
```

## Documentation
- [IMPROVEMENTS.md](IMPROVEMENTS.md) - Details about code improvements and security enhancements
- [DEBUG_GUIDE.md](DEBUG_GUIDE.md) - Comprehensive debugging and troubleshooting guide
- [EFI_1X_COMPATIBILITY.md](EFI_1X_COMPATIBILITY.md) - Detailed guide for MacPro5,1 and other EFI 1.x systems

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
* ✅ **Enhanced SSDT Support** - ⭐ **NEW**: Unlimited SSDT files with descriptive naming (SSDT-CPU.aml, SSDT-GPU.aml, etc.)
* ✅ **Smart Directory Scanning** - ⭐ **NEW**: Intelligent file discovery with duplicate detection and comprehensive validation
* ✅ **Flexible File Organization** - ⭐ **NEW**: Support for both ACPI subdirectory and same-directory placement with automatic fallback

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

This project uses streamlined GitHub Actions workflows for automated building, testing, and releasing:

### 🚀 **Comprehensive CI Pipeline**
- **Cross-platform**: Linux (Ubuntu), macOS, Windows Server 2022
- **Multi-architecture**: X64 and IA32 support  
- **Multiple toolchains**: GCC5 (Linux), Xcode5 (macOS), VS2022 (Windows)
- **Matrix builds**: 16 different build configurations for maximum compatibility
- **Automated testing**: Build validation across all supported platforms

### 📦 **Dedicated Release Management**
- **Automatic releases**: Triggered by git tags with `release.yml` workflow
- **Multi-platform packages**: Platform-specific artifacts for all major systems
- **Comprehensive artifacts**: Both Debug and Release builds included
- **Asset verification**: Automated integrity checks and proper naming

### 🔍 **Quality Assurance**
- **Build validation**: Ensures all configurations compile successfully
- **Cross-platform testing**: Validates compatibility across operating systems
- **EDK2 integration**: Uses traditional EDK2 BaseTools for maximum reliability
- **Modern toolchains**: Visual Studio 2022, GCC5, and Xcode5 support

### 📊 **Workflow Status**
Current build status is shown in the badges above:
- **CI Build**: Comprehensive multi-platform testing with 16 build jobs
- **Release**: Automated release creation and artifact packaging

The streamlined workflow system provides robust CI/CD while maintaining simplicity and reliability.
* Configuration file support for advanced patching options
* ACPI table backup and restore functionality
* Integration with firmware setup utilities
* Support for ACPI 6.5+ features

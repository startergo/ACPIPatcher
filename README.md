# ACPIPatcher
A professional UEFI/EFI application and driver for ACPI table patching and SSDT injection

[![CI Build](https://github.com/startergo/ACPIPatcher/actions/workflows/ci-new.yml/badge.svg)](https://github.com/startergo/ACPIPatcher/actions/workflows/ci-new.yml)
[![Release](https://github.com/startergo/ACPIPatcher/actions/workflows/release.yml/badge.svg)](https://github.com/startergo/ACPIPatcher/actions/workflows/release.yml)
[![GitHub release](https://img.shields.io/github/v/release/startergo/ACPIPatcher)](https://github.com/startergo/ACPIPatcher/releases)
[![License](https://img.shields.io/github/license/startergo/ACPIPatcher)](LICENSE)

ACPIPatcher is a comprehensive UEFI/EFI tool for ACPI table modification that works with any OS and bootloader. Originally designed for macOS systems without advanced ACPI patching capabilities, it provides professional-grade ACPI table injection and modification for development, debugging, and production use.

## Quick Start
1. **Download** or compile the ACPIPatcher binaries
2. **Create** an `ACPI` folder in the same directory as `ACPIPatcher.efi` (or place .aml files directly alongside it)
3. **Place** your `.aml` files in the `ACPI` folder (or same directory)
4. **🔍 For testing/new tables:** Run from **EFI shell** to see debug messages clearly
5. **⚡ For production:** Can run directly from **bootloader menu** for convenience
6. **Important:** Application mode patches are **temporary** (lost on reboot) - use driver mode for persistence

<details>
<summary><strong>📋 Architecture & Design Details</strong></summary>

### **Dual-Mode Operation**
- **Application Mode**: Manual execution for testing and development
- **DXE Driver Mode**: Automatic execution during boot for production deployment

### **Universal Bootloader Compatibility**
- **Primary Use Cases**: RefindPlus, rEFInd, GRUB, or custom UEFI environments
- **Advanced Bootloaders**: Compatible with OpenCore and Clover but consider their built-in ACPI systems first
- **Legacy Support**: Works with EFI 1.x firmware (MacPro5,1 and older Mac hardware)

### **Intelligent File Discovery System**
- **Multi-Filesystem Search**: Scans all available storage devices automatically
- **Priority-Based Selection**: Favors co-located files and driver-specific directories
- **Resource Fork Filtering**: Ignores macOS `._filename.aml` metadata files
- **Universal AML Support**: Loads all `.aml` files regardless of naming pattern

### **Multi-Phase AML Loading**
1. **Phase 1**: DSDT replacement (`DSDT.aml`)
2. **Phase 2**: Numeric SSDT loading (`SSDT-1.aml` through `SSDT-10.aml`)
3. **Phase 3**: Descriptive SSDT loading (`SSDT-*.aml` patterns)
4. **Phase 4**: General AML loading (any other `*.aml` files)

</details>

<details>
<summary><strong>🚀 Features</strong></summary>

### Core ACPI Functionality
- **DSDT Replacement**: Replace the system DSDT with a custom implementation
- **SSDT Addition**: Add unlimited custom SSDT tables to the system
- **Universal AML Support**: Load any `.aml` file regardless of naming pattern
- **Table Validation**: Comprehensive ACPI table integrity checking before patching
- **Checksum Management**: Automatic recalculation of table checksums

### Enhanced Discovery System
- **Intelligent File Discovery**: Automatic detection across multiple filesystems and directories
- **Priority-Based Selection**: Smart directory selection favoring co-located files
- **Multi-Phase Loading**: Comprehensive four-phase system ensures no AML files are missed
- **Resource Fork Filtering**: Excludes macOS metadata files for accurate file counting

### Professional Quality & Safety
- **Memory Safety**: Professional-grade memory management with bounds checking
- **Error Recovery**: Graceful handling of corrupted or missing files
- **Cross-Platform Debugging**: Multi-level debug output for troubleshooting
- **Production Ready**: Enterprise-grade error handling with graceful degradation

</details>

<details>
<summary><strong>💻 System Requirements & Compatibility</strong></summary>

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

</details>

<details>
<summary><strong>📖 How to Use</strong></summary>

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

</details>

<details>
<summary><strong>⚡ Application Mode (One-time patching)</strong></summary>
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

**📋 Execution Methods:**

**Method 1: EFI Shell Execution (Recommended for Debugging)**
```
1. Boot to EFI shell (F2/F12 during boot or UEFI shell USB)
2. Navigate to your EFI partition: fs0: (or fs1:, fs2:, etc.)
3. Run: ACPIPatcher.efi
4. Review debug output carefully - messages stay visible
5. Type 'exit' to return to bootloader menu
6. Continue normal OS boot from rEFInd/RefindPlus
```
✅ **Advantages:**
- Debug messages remain visible for inspection
- Can exit shell and return to bootloader menu
- Full control over timing and execution
- Best for troubleshooting and validation

**Method 2: Direct Bootloader Execution (Convenient but Limited Debugging)**
Add ACPIPatcher.efi as a menu entry in rEFInd/RefindPlus configuration.
```
# Add to refind.conf
menuentry "ACPI Patcher" {
    loader /ACPIPatcher.efi
    options ""
}
```
⚠️ **Limitations:**
- Debug messages scroll very fast and disappear quickly
- Cannot inspect output before OS boot continues
- Harder to troubleshoot issues
- Best for production use when patches are verified working

**Steps:**
1. Boot to EFI shell (usually by pressing F2/F12 during boot or using a UEFI shell USB)
2. Navigate to your EFI partition: `fs0:` (or `fs1:`, `fs2:`, etc.)
3. Place `ACPIPatcher.efi` and `ACPI` folder in the same directory
4. Run the application: `ACPIPatcher.efi`
5. Review the output for any errors or warnings
6. **Important**: ACPI patches are applied **only for the current boot session**
7. For **permanent patches**, use the **Driver Mode** instead (see below)

**Note**: Application mode patches are **temporary** - they only last until the system is powered off or reboots. The ACPI tables are patched in memory during this boot session only.

</details>

<details>
<summary><strong>🔧 Driver Mode (Persistent patching)</strong></summary>
For **permanent ACPI patches** that survive reboots, use the driver version. The DXE driver loads automatically during every boot and applies patches before the operating system starts.

**Important**: For OpenCore and Clover users, consider using their built-in ACPI patching features first, as they provide more comprehensive and tested solutions. Use ACPIPatcher with these bootloaders only for specific development needs or edge cases not covered by their native ACPI support.

**How Driver Mode Works:**
1. **DXE Driver Loading**: `ACPIPatcherDxe.efi` loads automatically during the UEFI DXE phase
2. **Smart File System Detection**: The driver intelligently searches for ACPI files across all available file systems
3. **Delayed Patching**: If storage isn't ready immediately, the driver waits for file system availability
4. **Automatic Patching**: Once the file system is ready, it automatically applies ACPI patches
5. **Persistence**: Patches are applied on **every boot** without user intervention
6. **Operating System Handoff**: The patched ACPI tables are passed to the OS

**Enhanced DXE Driver Features:**
- ✅ **Multi-Filesystem Search**: Automatically searches across ALL available file systems
- ✅ **Multi-Location Discovery**: Intelligently searches multiple standard ACPI paths
- ✅ **Smart Directory Selection**: Chooses best ACPI directory based on file count
- ✅ **Storage Timing Resilience**: Handles delayed file system initialization gracefully
- ✅ **Cross-Platform Compatibility**: Works reliably across different firmware implementations
- ✅ **Driver-Relative Paths**: Finds ACPI files relative to driver location for any bootloader

**Installation Instructions:**

For **OpenCore** users:
1. Place `ACPIPatcherDxe.efi` in `EFI/OC/Drivers/`
2. Create `ACPI` folder in `EFI/OC/Drivers/` and place .aml files there
3. Add the driver to your `config.plist`:
   ```xml
   <dict>
       <key>Comment</key>
       <string>ACPI Patcher Driver</string>
       <key>Enabled</key>
       <true/>
       <key>Path</key>
       <string>ACPIPatcherDxe.efi</string>
   </dict>
   ```

For **RefindPlus/rEFInd** users (Recommended):
1. Place `ACPIPatcherDxe.efi` in `EFI/refind/drivers_x64/`
2. Create `ACPI` folder in `EFI/refind/drivers_x64/` and place .aml files there

For **Clover** users:
1. Place `ACPIPatcherDxe.efi` in `EFI/CLOVER/drivers/UEFI/`
2. Create `ACPI` folder in `EFI/CLOVER/drivers/UEFI/` and place .aml files there

</details>

<details>
<summary><strong>📁 File Organization & Naming</strong></summary>
ACPIPatcher supports flexible file organization with automatic fallback:

**✅ Method 1: ACPI Subdirectory (Recommended)**
```
FS0:\
├── ACPIPatcher.efi
└── ACPI\                     ← Preferred location
    ├── DSDT.aml              (Optional: replaces system DSDT)
    ├── SSDT-1.aml            (Numeric naming - backward compatible)
    ├── SSDT-2.aml            (Numeric naming - backward compatible)
    ├── SSDT-CPU.aml          (Descriptive naming)
    ├── SSDT-GPU.aml          (Graphics patches)
    ├── SSDT-USB.aml          (USB port configuration)
    └── SSDT-BATTERY.aml      (Battery patches)
```

**✅ Method 2: Same Directory (Automatic Fallback)**
```
FS0:\                         ← Fallback if no ACPI folder exists
├── ACPIPatcher.efi
├── DSDT.aml                  (Optional: replaces system DSDT)
├── SSDT-1.aml                (Numeric naming)
├── SSDT-CPU.aml              (Descriptive naming)
├── SSDT-GPU.aml              (Graphics patches)
└── SSDT-USB.aml              (USB configuration)
```

### ACPI Table Types and Naming

#### DSDT (Differentiated System Description Table)
- **Filename:** Must be named exactly `DSDT.aml`
- **Purpose:** Completely replaces the system's original DSDT
- **Use case:** Major system modifications, hardware enablement
- **Warning:** Incorrect DSDT can prevent system boot

#### SSDT (Secondary System Description Table)
ACPIPatcher supports **unlimited SSDT files** with flexible naming patterns:

**✅ Numeric Pattern (Backward Compatible)**
- **Filenames:** `SSDT-1.aml`, `SSDT-2.aml`, `SSDT-3.aml`, ..., `SSDT-10.aml`
- **Legacy Support:** Maintains compatibility with existing workflows

**✨ Descriptive Pattern (Enhanced Feature)**
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

**Key Benefits:**
- 🔄 **Unlimited Files**: No longer limited to 10 SSDT tables
- 📝 **Self-Documenting**: Clear purpose identification from filename
- 🏗️ **Professional**: Matches industry ACPI patching standards
- 🔒 **Backward Compatible**: Existing numeric files continue to work
- 🚀 **Smart Loading**: Avoids duplicate loading, comprehensive validation

</details>

<details>
<summary><strong>🔍 Debug Output and Testing</strong></summary>

**⚠️ Important: Debug Message Visibility Depends on Execution Method**

**📱 EFI Shell Execution (Best for Development/Troubleshooting):**
```bash
# Boot to EFI shell first, then run ACPIPatcher
fs0:\> ACPIPatcher.efi
[INFO] === ACPIPatcher v1.1 Starting ===
[INFO] Found XSDT at address: 0x7FF8B000
[INFO] Scanning for SSDT-*.aml files...
[INFO] ✓ SSDT-CPU.aml loaded and added successfully
[INFO] Status: Successfully patched 4 ACPI tables!
# Messages stay visible - you can read them carefully
fs0:\> exit
# Returns to rEFInd/RefindPlus menu - continue OS boot
```
✅ **Advantages:**
- Debug messages remain visible for inspection
- Can review output thoroughly before continuing
- Can exit shell and return to bootloader
- Perfect for development and troubleshooting

**🚀 Direct Bootloader Menu Execution (Convenient but Limited):**
- Messages scroll very fast and disappear
- No time to inspect output for errors
- Automatic transition to OS boot
- Difficult to troubleshoot issues

**🔧 Recommendation for Different Use Cases:**
- **Development/New Tables:** Always use EFI Shell execution
- **Production/Verified Tables:** Can use direct bootloader execution

### Testing and Validation

**Recommended Testing Workflow:**
1. **Start with Application Mode**: Test patches temporarily first
2. **Validate Functionality**: Boot and verify patches work correctly
3. **Deploy Driver Mode**: Only after successful application mode testing
4. **Keep Backup Configuration**: Always maintain a working fallback

**Before deploying custom tables:**
1. Test with the provided `SSDT-Test.aml` first using **Application Mode**
2. Enable VERBOSE debugging to monitor the patching process
3. Verify patches work correctly **before** switching to Driver Mode
4. Keep backup of working configuration
5. Test boot multiple times to ensure stability

**Sample Debug Output:**
```
[INFO]  === ACPIPatcher v1.1 Starting ===
[INFO]  Found XSDT at address: 0x7FF8B000
[INFO]  === Starting Real ACPI Patching ===
[INFO]  Attempting to load: DSDT.aml
[INFO]  Found ACPI directory, loading from ACPI/DSDT.aml
[INFO]  ✓ DSDT replaced successfully
[INFO]  Scanning for SSDT-*.aml files...
[INFO]  ✓ SSDT-CPU.aml loaded and added successfully
[INFO]  ✓ SSDT-GPU.aml loaded and added successfully
[INFO]  Status: Successfully patched 5 ACPI tables!
```

**Common issues and solutions:**
- **Boot failure**: Remove ACPIPatcherDxe.efi from drivers folder immediately
- **Application Mode works, Driver Mode doesn't**: Check file system access timing and paths
- **No effect**: Check file permissions, naming conventions, and bootloader driver loading
- **Intermittent issues**: Enable debugging and check logs across multiple boots

</details>

<details>
<summary><strong>🏗️ How to Build</strong></summary>

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

</details>

<details>
<summary><strong>🏆 Completed Architecture</strong></summary>

This project provides a complete, professional-grade ACPI patching solution:

* ✅ **DXE Driver Architecture** - Automatic operation with zero configuration required
* ✅ **Professional Memory Management** - Comprehensive cleanup, bounds checking, and leak prevention
* ✅ **Enterprise Error Handling** - Robust error checking with graceful degradation
* ✅ **Security Hardening** - Input validation, buffer protection, and integrity checking
* ✅ **Multi-Level Debugging** - Comprehensive logging and troubleshooting capabilities
* ✅ **Production Code Quality** - Professional documentation and maintainable architecture
* ✅ **Universal AML Support** - Loads any `.aml` file regardless of naming convention
* ✅ **Intelligent File Discovery** - Multi-filesystem search with priority-based selection
* ✅ **Flexible Organization** - ACPI subdirectory or same-directory placement with automatic fallback
* ✅ **Cross-Platform Compatibility** - Universal bootloader support with automatic detection
* ✅ **Smart Directory Selection** - Priority system favoring co-located and driver-specific paths
* ✅ **Zero-Configuration Operation** - Comprehensive path coverage requiring no manual setup
* ✅ **Resource Fork Handling** - macOS compatibility with proper metadata file filtering
* ✅ **Multi-Phase Loading System** - Four-phase system ensuring complete AML file coverage

</details>

<details>
<summary><strong>📊 Project Status</strong></summary>

ACPIPatcher is a mature, production-ready ACPI patching solution with comprehensive features:

### Core Capabilities
- **Professional Architecture**: Robust DXE driver and application modes
- **Universal Compatibility**: Works with all major bootloaders and firmware types
- **Intelligent Automation**: Zero-configuration file discovery and loading
- **Enterprise-Grade Quality**: Memory safety, error handling, and comprehensive debugging

### Current Implementation
- **Multi-Platform Build System**: EDK2-based with CI/CD automation across Windows, macOS, and Linux
- **Comprehensive File Support**: Handles DSDT replacement and unlimited SSDT injection
- **Advanced Discovery**: Multi-filesystem search with intelligent priority-based selection
- **Resource Management**: Professional memory management with automatic cleanup
- **Debug Infrastructure**: Multi-level logging system for development and troubleshooting

The project is actively maintained and suitable for both development and production environments.

</details>

<details>
<summary><strong>🚀 CI/CD and Automation</strong></summary>

This project uses streamlined GitHub Actions workflows for automated building, testing, and releasing:

### **Comprehensive CI Pipeline**
- **Cross-platform**: Linux (Ubuntu), macOS, Windows Server 2022
- **Multi-architecture**: X64 and IA32 support  
- **Multiple toolchains**: GCC5 (Linux), Xcode5 (macOS), VS2022 (Windows)
- **Matrix builds**: 16 different build configurations for maximum compatibility
- **Automated testing**: Build validation across all supported platforms

### **Dedicated Release Management**
- **Automatic releases**: Triggered by git tags with `release.yml` workflow
- **Multi-platform packages**: Platform-specific artifacts for all major systems
- **Comprehensive artifacts**: Both Debug and Release builds included
- **Asset verification**: Automated integrity checks and proper naming

### **Quality Assurance**
- **Build validation**: Ensures all configurations compile successfully
- **Cross-platform testing**: Validates compatibility across operating systems
- **EDK2 integration**: Uses traditional EDK2 BaseTools for maximum reliability
- **Modern toolchains**: Visual Studio 2022, GCC5, and Xcode5 support

### **Workflow Status**
Current build status is shown in the badges above:
- **CI Build**: Comprehensive multi-platform testing with 16 build jobs
- **Release**: Automated release creation and artifact packaging

The streamlined workflow system provides robust CI/CD while maintaining simplicity and reliability.

</details>

---

## 🔮 Future Roadmap

* Configuration file support for advanced patching options
* ACPI table backup and restore functionality  
* Integration with firmware setup utilities
* Support for ACPI 6.5+ features

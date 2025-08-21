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
4. **🔍 For testing/new tables:** Run from **EFI shell** to see debug messages clearly
5. **⚡ For production:** Can run directly from **bootloader menu** for convenience
6. **Important:** Application mode patches are **temporary** (lost on reboot) - use driver mode for persistence

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

#### Driver Mode (Persistent patching)
For **permanent ACPI patches** that survive reboots, use the driver version. The DXE driver loads automatically during every boot and applies patches before the operating system starts.

**Important**: For OpenCore and Clover users, consider using their built-in ACPI patching features first, as they provide more comprehensive and tested solutions. Use ACPIPatcher with these bootloaders only for specific development needs or edge cases not covered by their native ACPI support.

**How Driver Mode Works:**
1. **DXE Driver Loading**: `ACPIPatcherDxe.efi` loads automatically during the UEFI DXE phase
2. **Smart File System Detection**: The driver intelligently searches for ACPI files across all available file systems
3. **Delayed Patching**: If storage isn't ready immediately, the driver waits for file system availability
4. **Automatic Patching**: Once the file system is ready, it automatically applies ACPI patches
5. **Persistence**: Patches are applied on **every boot** without user intervention
6. **Operating System Handoff**: The patched ACPI tables are passed to the OS

**🔧 Enhanced DXE Driver Features (Latest Version):**
- **✅ Multi-Filesystem Search**: Automatically searches across ALL available file systems
- **✅ Multi-Location Discovery**: Intelligently searches multiple standard ACPI paths
- **✅ Smart Directory Selection**: Chooses best ACPI directory based on file count
- **✅ Storage Timing Resilience**: Handles delayed file system initialization gracefully
- **✅ Cross-Platform Compatibility**: Works reliably across different firmware implementations
- **✅ Driver-Relative Paths**: Finds ACPI files relative to driver location for any bootloader
- **✅ ESP Root Discovery**: Locates shared ACPI directories at ESP root level
- **✅ Comprehensive Debug Logging**: Detailed logs showing all search attempts and discoveries

**For OpenCore users:**
1. Place `ACPIPatcherDxe.efi` in `EFI/OC/Drivers/`
2. **Recommended**: Create `ACPI` folder in `EFI/OC/Drivers/` and place .aml files there
3. **Alternative**: Place .aml files directly in `EFI/OC/Drivers/` (same directory as the driver)
4. Add the driver to your `config.plist`:
   ```xml
   <dict>
       <key>Arguments</key>
       <string></string>
       <key>Comment</key>
       <string>ACPI Patcher Driver - Enhanced Version</string>
       <key>Enabled</key>
       <true/>
       <key>Path</key>
       <string>ACPIPatcherDxe.efi</string>
   </dict>
   ```

**For Clover users:**
1. Place `ACPIPatcherDxe.efi` in `EFI/CLOVER/drivers/UEFI/`
2. **Recommended**: Create `ACPI` folder in `EFI/CLOVER/drivers/UEFI/` and place .aml files there
3. **Alternative**: Place .aml files directly in `EFI/CLOVER/drivers/UEFI/` (same directory as the driver)

**For RefindPlus/rEFInd users (Recommended):**
1. Place `ACPIPatcherDxe.efi` in `EFI/refind/drivers_x64/`
2. **Recommended**: Create `ACPI` folder in `EFI/refind/drivers_x64/` and place .aml files there
3. **Alternative**: Place .aml files directly in `EFI/refind/drivers_x64/` (same directory as the driver)

**🔍 DXE Driver File Search Logic:**
The enhanced DXE driver now uses comprehensive multi-filesystem and multi-location search:

1. **Multi-Filesystem Discovery**: Searches across ALL available file systems
   - Finds all Simple File System Protocol handles
   - Handles USB drives, SATA, NVMe, and network storage
   - Works regardless of boot device or storage configuration

2. **Multi-Location Search per File System**: For each filesystem, checks:
   - `EFI\ACPI\` (ESP root - cross-bootloader sharing)
   - `EFI\ACPIPatcher\` (ESP root - dedicated location)
   - `drivers_x64\ACPI\` (rEFInd/RefindPlus specific)
   - `OC\Drivers\ACPI\` (OpenCore specific)
   - `CLOVER\drivers\UEFI\ACPI\` (Clover specific)
   - `ACPI\` (relative to any driver location)
   - Driver directory (fallback if contains .aml files)

3. **Smart Directory Selection**: 
   - Counts .aml files in each discovered directory
   - Selects directory with the most ACPI files
   - Prevents loading from empty or sparse directories
   - Provides detailed logging of discovery process

4. **Comprehensive Coverage**:
   - Works regardless of bootloader directory structure
   - Finds ACPI files in any reasonable location
   - Handles complex EFI partition layouts automatically
   - Adapts to user's specific configuration

**📋 Debug Output for DXE Driver:**
The enhanced DXE driver provides detailed logging to help troubleshoot file discovery:

```
[DXE] ACPIPatcher DXE Driver v1.2 loading...
[DXE] Starting comprehensive file system search...
[DXE] Found 3 file system(s), searching each for ACPI directories...
[DXE] FileSystem 0: Checking EFI\ACPI... Found! (5 .aml files)
[DXE] FileSystem 1: Checking drivers_x64\ACPI... Found! (3 .aml files)
[DXE] FileSystem 2: Checking ACPI... Not found
[DXE] Selected best directory: EFI\ACPI (most files: 5)
[DXE] SUCCESS: Found ACPI directory with 5 .aml files
[INFO] Found ACPI directory, loading from ACPI/SSDT-CPU.aml
[INFO] ✓ SSDT-CPU.aml loaded and added successfully
[INFO] ✓ SSDT-GPU.aml loaded and added successfully
[INFO] Status: Successfully patched 6 ACPI tables!
[DXE] Enhanced directory search completed successfully
```

### Application vs Driver Mode Comparison

| Feature | Application Mode | Driver Mode |
|---------|------------------|-------------|
| **Execution** | Manual execution required | Automatic on every boot |
| **Persistence** | ❌ **Temporary** - patches lost on reboot | ✅ **Permanent** - patches applied every boot |
| **File Search** | Relative to execution directory | **✨ Enhanced**: Multi-location intelligent search |
| **Storage Timing** | Assumes file system ready | **✨ Handles delayed storage initialization** |
| **Use Case** | Testing, debugging, one-time fixes | Production use, permanent patches |
| **User Interaction** | Requires EFI shell access | No user interaction needed |
| **Boot Dependency** | Must run before OS boot | Integrated into boot process |
| **Bootloader Support** | Any EFI shell environment | **✨ Enhanced**: Works with all major bootloaders |
| **Patch Timing** | After manual execution | During DXE phase (early boot) |
| **Troubleshooting** | Easy to disable (just don't run) | **✨ Enhanced debug logging** for diagnosis |
| **Configuration Flexibility** | Single execution directory | **✨ Multiple search locations** |

**Recommendation**: 
- **Use Application Mode for**: Testing new ACPI patches, debugging, temporary fixes
- **Use Driver Mode for**: Production environments, permanent patches, hands-off operation

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

**OpenCore (ESP root ACPI directory - Enhanced Search):**
```
EFI\
├── ACPI\                     ← ✨ NEW: Driver will find this automatically
│   ├── DSDT.aml
│   ├── SSDT-CPU.aml
│   └── SSDT-USB.aml
└── OC\
    ├── Drivers\
    │   └── ACPIPatcherDxe.efi ← Driver searches multiple locations
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

**RefindPlus/rEFInd (ESP root search - Enhanced):**
```
EFI\
├── ACPIPatcher\              ← ✨ NEW: Alternative global location
│   ├── DSDT.aml
│   ├── SSDT-CPU.aml
│   └── SSDT-GPU.aml
└── refind\
    ├── drivers_x64\
    │   └── ACPIPatcherDxe.efi ← Automatically finds ACPIPatcher folder
    └── refind.conf
```

**⚠️ Important Note for DXE Driver File Location:**
The enhanced ACPIPatcherDxe.efi driver now uses **comprehensive multi-filesystem and multi-location search** to find ACPI files. This provides maximum flexibility and compatibility:

**✅ Enhanced Search Capabilities:**
- **Multi-Filesystem Search**: Automatically searches ALL available file systems (not just boot device)
- **Intelligent Path Detection**: Recognizes bootloader-specific directory structures automatically
- **Smart Directory Selection**: Chooses the directory with the most .aml files (indicates main ACPI location)
- **Universal Compatibility**: Works with any bootloader configuration without manual path specification
- **Delayed Storage Handling**: Gracefully handles file systems that initialize after driver loading
- **Comprehensive Logging**: Shows exactly which paths were searched and where files were found

**🔍 Search Coverage Examples:**
- **rEFInd/RefindPlus**: Finds `drivers_x64\ACPI\`, `EFI\ACPI\`, `ACPI\` automatically
- **OpenCore**: Finds `OC\Drivers\ACPI\`, `EFI\ACPI\`, driver directory automatically
- **Clover**: Finds `CLOVER\drivers\UEFI\ACPI\`, `EFI\ACPI\` automatically
- **Generic/Multiple**: Searches all reasonable paths across all storage devices

**🚀 Benefits of Enhanced Search:**
- **Zero Configuration**: No need to specify paths - driver finds files automatically
- **Maximum Coverage**: Searches every possible reasonable location
- **Smart Selection**: Automatically picks the best ACPI directory
- **Future-Proof**: Adapts to new bootloader configurations automatically
- **Troubleshooting**: Detailed logs show exactly what was searched and found

**Backward Compatibility:**
The enhanced driver maintains full backward compatibility with existing configurations while adding comprehensive search capabilities. Existing ACPI file placements continue to work exactly as before.

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

### Debug Output and Visibility

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
```bash
# Running directly from rEFInd/RefindPlus menu entry
[INFO] === ACPIPatcher v1.1 Starting ===
[INFO] Found XSDT... [scrolls fast]
[INFO] Scanning... [scrolls fast]  
[INFO] Status... [disappears quickly]
# Boot continues automatically to OS - no time to read!
```
⚠️ **Limitations:**
- Messages scroll very fast and disappear
- No time to inspect output for errors
- Automatic transition to OS boot
- Difficult to troubleshoot issues

**🔧 Recommendation for Different Use Cases:**

**Development/New Tables:** Always use EFI Shell execution
- Need to see validation messages
- Check for errors and warnings  
- Verify proper file loading
- Debug any issues thoroughly

**Production/Verified Tables:** Can use direct bootloader execution
- Tables already tested and working
- Want convenient automatic execution
- Don't need to inspect debug output

**Driver Mode:** Messages appear during boot but may scroll quickly
- **Enhanced Debug Output**: Comprehensive logging shows file discovery process
- Debug output available but may scroll during boot sequence  
- Consider using application mode during initial development and testing
- **Example DXE Debug Output**:
  ```
  [DXE] ACPIPatcher DXE Driver v1.1 loading...
  [DXE] Found 3 file system(s), searching for ACPI files...
  [DXE] SUCCESS: Found ACPI directory at EFI\ACPI
  [INFO] ✓ SSDT-CPU.aml loaded and added successfully
  [DXE] ACPI tables have been patched - driver staying resident
  ```

### Testing and Validation

I have also provided a test SSDT in `Build/ACPI` for validation purposes.

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

**Testing Process:**
```bash
# Phase 1: Application Mode Testing (Temporary)
1. Boot to EFI shell
2. Run: ACPIPatcher.efi
3. Continue boot to OS
4. Verify patches work (check functionality, no crashes)
5. Reboot (patches are automatically cleared)

# Phase 2: Driver Mode Deployment (Permanent) 
1. If Application Mode testing succeeded:
2. Install ACPIPatcherDxe.efi in bootloader drivers
3. Reboot and verify patches persist
4. Monitor multiple boot cycles for stability
```

**Common issues and solutions:**
- **Boot failure**: Remove ACPIPatcherDxe.efi from drivers folder immediately
- **Application Mode works, Driver Mode doesn't**: Check file system access timing and paths
- **No effect**: Check file permissions, naming conventions, and bootloader driver loading
- **Intermittent issues**: Enable debugging and check logs across multiple boots

**Memory and Persistence Notes:**
- **Application Mode**: Patches exist **only in current boot session** - lost on reboot/shutdown
- **Driver Mode**: Patches are **reapplied automatically** on every boot
- **ACPI Tables**: Are always in RAM, never written to firmware/storage permanently
- **Safety**: Both modes only modify in-memory ACPI tables, never firmware

**Older Mac Hardware (MacPro5,1, etc.):**
- **EFI Shell Access:** Use Option key during boot, look for "EFI Boot" options
- **Memory Limitations:** Keep ACPI files small (<64KB each) for EFI 1.x compatibility
- **Bootloader Requirements:** RefindPlus or rEFInd work best with older EFI firmware
- **File Path Issues:** Ensure short path names and avoid deep directory structures

## DXE Driver Technical Details

### 🔧 Enhanced Multi-Filesystem Directory Search Algorithm

The ACPIPatcherDxe.efi driver implements a comprehensive three-stage file discovery system:

#### Stage 1: Complete File System Discovery
```
[DXE] Starting comprehensive file system search...
[DXE] Found 8 file system(s), searching each for ACPI directories...
```
- Enumerates ALL available Simple File System Protocol handles
- Searches every accessible storage device (boot drive, USB, network, etc.)
- Handles delayed storage initialization (waits for USB/SATA/NVMe drives)
- Gracefully handles file systems that aren't ready immediately
- Works regardless of which device contains ACPI files

#### Stage 2: Comprehensive Multi-Location Search
```
For each discovered file system, search priority:
1. EFI\ACPI\              (ESP root - cross-bootloader compatibility)
2. EFI\ACPIPatcher\       (ESP root - dedicated ACPIPatcher location)
3. drivers_x64\ACPI\      (rEFInd/RefindPlus bootloader paths)
4. OC\Drivers\ACPI\       (OpenCore bootloader paths)  
5. CLOVER\drivers\UEFI\ACPI\ (Clover bootloader paths)
6. ACPI\                  (relative to any driver location)
7. ACPIPatcher\           (alternative relative location)
8. Driver directory       (fallback - if .aml files present)
9. File system root       (last resort - if .aml files present)
```

#### Stage 3: Smart Directory Selection and File Detection
```
[DXE] Directory analysis results:
[DXE]   EFI\ACPI\: 5 .aml files found
[DXE]   drivers_x64\ACPI\: 3 .aml files found
[DXE] Selected best directory: EFI\ACPI (highest file count)
[INFO] Found ACPI directory, loading from ACPI/SSDT-CPU.aml
```
- Counts .aml files in each discovered directory
- Selects directory with the most ACPI files (indicates main ACPI location)
- Validates file accessibility before attempting to load
- Prevents loading from empty or test directories
- Provides comprehensive logging for troubleshooting

### 🚀 Storage Timing Resilience

The enhanced DXE driver handles complex boot timing scenarios:

#### Delayed File System Initialization
```c
// Pseudo-code showing the approach
if (FileSystemNotReady) {
    SetupDelayedPatching();
    RegisterFileSystemCallback();
    return EFI_SUCCESS;  // Driver stays resident
}

OnFileSystemReady() {
    PerformDelayedAcpiPatching();
    SearchMultipleLocations();
    ApplyPatchesWhenReady();
}
```

**Benefits:**
- **USB/External Storage**: Handles USB drives that initialize after DXE phase
- **SATA/NVMe Timing**: Works with storage controllers that have initialization delays
- **Multiple Storage**: Searches across all available storage devices
- **Retry Logic**: Automatically retries when storage becomes available

### 🔍 Debug and Troubleshooting Features

#### Comprehensive Logging
The DXE driver provides detailed debug output for troubleshooting:

```
[DXE] ACPIPatcher DXE Driver v1.1 loading...
[DXE] Starting ACPI patching process...
[DXE] File system not ready yet, setting up delayed patching
[DXE] File system notification set up successfully
[DXE] Driver will remain resident and patch ACPI when storage is ready
...
[DXE] File System Protocol ready notification received!
[DXE] Now attempting delayed ACPI patching with file system access...
[DXE] Searching for ACPI files directory on available file systems...
[DXE] Found 3 file system(s), searching for ACPI files...
[DXE] SUCCESS: Found ACPI directory at EFI\ACPI
[INFO] Found ACPI directory, loading from ACPI/SSDT-CPU.aml
[INFO] ✓ SSDT-CPU.aml loaded and added successfully
[DXE] SUCCESS: Delayed ACPI patching completed!
```

#### Error Handling and Recovery
```
[DXE] ERROR: No file systems found: Not Ready
[DXE] WARNING: Could not locate ACPI files directory, continuing without files
[DXE] INFO: No ACPI directory found on any file system
```

**Enhanced Error Handling:**
- **Graceful Multi-System Handling**: Continues if some file systems are inaccessible
- **Smart Directory Selection**: Automatically chooses best ACPI directory based on file count  
- **Resource Cleanup**: Properly closes handles and frees memory across all file systems
- **Comprehensive Logging**: Shows search results for every file system and directory
- **Recovery Attempts**: Retries operations when file systems become available

### 🛠 Compatibility and Platform Support

#### Bootloader Integration Matrix
| Bootloader | Compatibility | Recommended Location | Notes |
|------------|---------------|---------------------|--------|
| **RefindPlus** | ✅ **Excellent** | `EFI/refind/drivers_x64/` | Native driver support |
| **rEFInd** | ✅ **Excellent** | `EFI/refind/drivers_x64/` | Native driver support |
| **OpenCore** | ✅ **Good** | `EFI/OC/Drivers/` | Consider built-in ACPI first |
| **Clover** | ✅ **Good** | `EFI/CLOVER/drivers/UEFI/` | Consider built-in ACPI first |
| **GRUB** | ⚠️ **Limited** | Manual placement | May require additional configuration |

#### Firmware Compatibility
- **UEFI 2.x**: Full support with all enhanced features
- **EFI 1.x**: Compatible with enhanced search (MacPro5,1, etc.)
- **Legacy BIOS**: Not supported (requires EFI/UEFI environment)

#### Architecture Support
- **X64**: Primary target, fully tested
- **IA32**: Compatible, limited testing
- **AARCH64**: Experimental support

### 📊 Performance and Resource Usage

#### Memory Footprint
- **Driver Size**: ~36KB (optimized for minimal impact)
- **Runtime Memory**: <1MB during patching operation
- **Resident Memory**: ~32KB after patching complete

#### Boot Impact
- **Cold Boot**: +50-200ms (depending on storage speed)
- **Warm Boot**: +20-100ms (cached file system access)
- **No Files**: +10-20ms (quick search and exit)

#### Resource Management
- **Proper Cleanup**: All allocated memory freed after patching
- **Handle Management**: File handles properly closed
- **Event Management**: Notification events properly disposed

### 🔧 Advanced Configuration Options

#### Debug Level Control
Modify debug verbosity by rebuilding with different debug levels:
```c
// In ACPIPatcher.c - for maximum debugging
#define DXE_DEBUG_LEVEL DEBUG_VERBOSE

// For production - minimal output
#define DXE_DEBUG_LEVEL DEBUG_ERROR
```

#### Search Path Customization
The comprehensive multi-location search can be customized by modifying the search arrays:
```c
// Bootloader-specific paths - automatically detected
CHAR16* BootloaderPaths[] = {
    L"drivers_x64\\ACPI",           // rEFInd/RefindPlus
    L"OC\\Drivers\\ACPI",           // OpenCore  
    L"CLOVER\\drivers\\UEFI\\ACPI", // Clover
    L"grub\\ACPI",                  // GRUB (custom)
    NULL
};

// Standard ACPI paths - searched on all file systems  
CHAR16* StandardPaths[] = {
    L"EFI\\ACPI",                   // ESP root ACPI
    L"EFI\\ACPIPatcher",            // ESP root ACPIPatcher
    L"ACPI",                        // Relative ACPI
    L"ACPIPatcher",                 // Relative ACPIPatcher
    NULL
};
```

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
* ✅ **Multi-Filesystem Search** - ⭐ **LATEST**: Comprehensive search across ALL file systems and storage devices
* ✅ **Intelligent Directory Selection** - ⭐ **LATEST**: Smart selection of best ACPI directory based on file count analysis
* ✅ **Universal Bootloader Compatibility** - ⭐ **LATEST**: Automatic detection of bootloader-specific directory structures
* ✅ **Enhanced DXE Driver Architecture** - ⭐ **LATEST**: Zero-configuration operation with comprehensive path coverage

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

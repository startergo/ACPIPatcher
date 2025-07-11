# Complete Build Guide for ACPIPatcher

## 🎯 Quick Start - How to Compile and Build

### Current Status
✅ **Comprehensive Build Scripts**: Fully automated setup and build process  
✅ **Cross-Platform Support**: Windows, Linux, and macOS builds  
✅ **CI/CD Integration**: GitHub Actions with 18 build configurations  
✅ **Multiple Toolchains**: VS2019/2022, GCC5, Cygwin, XCODE5  
✅ **All Architectures**: X64 and IA32 support  
✅ **All Build Types**: RELEASE and DEBUG builds

## 🏗️ Build Methods

### Method 1: Automated Setup Script (Recommended)

**Windows (Batch Script):**
```batch
# Quick build with defaults (X64 RELEASE)
setup_and_build.bat

# Specific configuration
setup_and_build.bat X64 DEBUG
setup_and_build.bat IA32 RELEASE
setup_and_build.bat IA32 DEBUG
```

**Linux/macOS (Shell Script):**
```bash
# Quick build with defaults (X64 RELEASE)
chmod +x setup_and_build.sh
./setup_and_build.sh

# Specific configuration
./setup_and_build.sh X64 DEBUG
./setup_and_build.sh IA32 RELEASE
./setup_and_build.sh IA32 DEBUG
```

**Python Script (Cross-Platform):**
```bash
# Quick build with defaults
python ACPIPatcher.py --build

# Specific configuration with all options
python ACPIPatcher.py --build --arch X64 --build-type DEBUG --toolchain VS2022
python ACPIPatcher.py --build --arch IA32 --build-type RELEASE --toolchain GCC5

# Clean build artifacts
python ACPIPatcher.py --clean

# Verbose output
python ACPIPatcher.py --build --verbose
```

### Method 2: GitHub Actions CI/CD (Zero Setup)

**Trigger Automatic Builds:**
```bash
# Push any changes to trigger all 18 build configurations
git add .
git commit -m "Trigger comprehensive build matrix"
git push origin master

# Or manually trigger via GitHub web interface:
# Go to Actions → CI Build → Run workflow
```

**Available Build Matrix:**
- **Linux**: GCC5 toolchain (X64/IA32, RELEASE/DEBUG)
- **macOS**: XCODE5 toolchain (X64/IA32, RELEASE/DEBUG)  
- **Windows VS2022**: Visual Studio 2022 (X64/IA32, RELEASE/DEBUG)
- **Windows Cygwin**: GCC5 via Cygwin (X64/IA32, RELEASE/DEBUG)

## 🔧 What the Scripts Do Automatically

### Complete Environment Setup
1. **Toolchain Detection & Installation**:
   - Visual Studio 2019/2022 (Windows)
   - GCC5 (Linux/Cygwin)
   - XCODE5 (macOS)
   - Automatic NASM installation

2. **EDK2 Management**:
   - Automatic EDK2 cloning (latest stable)
   - Submodule initialization with timeout protection
   - BaseTools compilation with multiple fallback methods
   - Environment variable configuration

3. **Build Process**:
   - Package integration (ACPIPatcherPkg)
   - Multi-architecture compilation
   - Artifact collection and verification
   - Comprehensive error handling

### Windows-Specific Features
- **Visual Studio Detection**: Uses `vswhere.exe` for precise VS installation detection
- **Cygwin Support**: Full GCC5 toolchain via Cygwin for alternative compilation
- **NASM Integration**: Automatic detection in multiple common locations
- **CI Mode**: Unattended operation for GitHub Actions

### Cross-Platform Features  
- **Git Configuration**: Optimized settings for EDK2 development
- **Path Management**: Environment variables properly configured
- **Tool Verification**: Comprehensive prerequisite checking
- **Error Recovery**: Multiple fallback strategies for failed operations

## 🔧 Prerequisites

### Automatic Installation (Handled by Scripts)
The setup scripts automatically handle most prerequisites:

**Windows:**
- ✅ **Visual Studio Build Tools**: Auto-detected (2019/2022) or Cygwin GCC
- ✅ **NASM**: Auto-installed via environment variables detection
- ✅ **Python**: Validated and configured automatically
- ✅ **Git**: Configured with optimal EDK2 settings
- ✅ **EDK2**: Auto-cloned with submodule management

**Linux/macOS:**
- ✅ **GCC/Clang**: Auto-detected system compilers
- ✅ **Build Tools**: Package manager integration
- ✅ **Python**: Cross-platform compatibility
- ✅ **Git**: HTTPS configuration for authentication

### Manual Prerequisites (If Needed)

Only install manually if automatic setup fails:

**Windows - Visual Studio Build Tools:**
```powershell
# Option 1: Install VS Build Tools 2022 (Recommended)
# Download: https://visualstudio.microsoft.com/downloads/#build-tools-for-visual-studio-2022
# Select: "C++ build tools" workload

# Option 2: Install Cygwin with GCC (Alternative)
# Download: https://www.cygwin.com/
# Packages: gcc-core, gcc-g++, make, binutils
```

**Windows - NASM (Backup):**
```powershell
# Using Chocolatey
choco install nasm

# Using winget  
winget install NASM.NASM

# Manual download: https://www.nasm.us/pub/nasm/releasebuilds/
```

**Linux - Build Tools:**
```bash
# Ubuntu/Debian
sudo apt update && sudo apt install build-essential nasm python3 git uuid-dev

# CentOS/RHEL/Fedora  
sudo dnf install gcc gcc-c++ nasm python3 git libuuid-devel

# Arch Linux
sudo pacman -S base-devel nasm python git util-linux
```

**macOS - Development Tools:**
```bash
# Install Xcode Command Line Tools
xcode-select --install

# Install NASM via Homebrew
brew install nasm

# Alternative: MacPorts
sudo port install nasm
```

## 🚀 Step-by-Step Build Process

### For First-Time Users (Windows)

1. **Clone the Repository:**
```batch
git clone https://github.com/startergo/ACPIPatcher.git
cd ACPIPatcher
```

2. **Run Automated Build:**
```batch
# Default build (X64 RELEASE with auto-detected toolchain)
setup_and_build.bat

# The script will:
# - Check and install prerequisites
# - Clone EDK2 automatically  
# - Set up build environment
# - Compile ACPIPatcher
# - Copy .efi files to current directory
```

3. **Find Your Build Artifacts:**
```
ACPIPatcher/
├── ACPIPatcher.efi        # Standalone UEFI application
└── ACPIPatcherDxe.efi     # UEFI driver version
```

### For First-Time Users (Linux/macOS)

1. **Clone and Build:**
```bash
git clone https://github.com/startergo/ACPIPatcher.git
cd ACPIPatcher

# Make script executable and run
chmod +x setup_and_build.sh
./setup_and_build.sh

# For specific configuration
./setup_and_build.sh IA32 DEBUG
```

### Advanced Configuration Examples

**Windows - Multiple Configurations:**
```batch
# Test all combinations locally
setup_and_build.bat X64 RELEASE    # Standard 64-bit release
setup_and_build.bat X64 DEBUG      # 64-bit with debug symbols  
setup_and_build.bat IA32 RELEASE   # 32-bit release for older systems
setup_and_build.bat IA32 DEBUG     # 32-bit debug build

# Force Cygwin GCC toolchain (if both VS and Cygwin available)
set BASETOOLS_CYGWIN_BUILD=TRUE
setup_and_build.bat X64 RELEASE
```

**Python - Cross-Platform:**
```bash
# Development workflow
python ACPIPatcher.py --build --arch X64 --build-type DEBUG --verbose
python ACPIPatcher.py --clean
python ACPIPatcher.py --build --arch IA32 --build-type RELEASE

# CI-style build (all error checking)
CI=true python ACPIPatcher.py --build --arch X64 --build-type RELEASE
```

## 🎯 Immediate Quick Start

**Fastest way to get .efi files:**

**Option 1 - Use CI (Zero local setup):**
```bash
# Fork the repo on GitHub, then:
git clone https://github.com/YOUR_USERNAME/ACPIPatcher.git
cd ACPIPatcher
git commit --allow-empty -m "Trigger build"
git push

# Download artifacts from GitHub Actions in ~5-10 minutes
# All 18 configurations will be built automatically
```

**Option 2 - Local Windows build:**
```batch
# Clone and run (handles everything automatically)
git clone https://github.com/startergo/ACPIPatcher.git
cd ACPIPatcher
setup_and_build.bat

# Build completed in current directory:
# - ACPIPatcher.efi 
# - ACPIPatcherDxe.efi
```

**Option 3 - Local Linux/macOS build:**
```bash
git clone https://github.com/startergo/ACPIPatcher.git
cd ACPIPatcher
chmod +x setup_and_build.sh && ./setup_and_build.sh
```

## 📦 Build Outputs and Artifacts

### Local Build Results
After successful build, you'll find in your project directory:
```
ACPIPatcher/
├── ACPIPatcher.efi        # Standalone UEFI application  
├── ACPIPatcherDxe.efi     # UEFI driver version
└── temp_edk2/             # EDK2 workspace (auto-created)
    └── Build/ACPIPatcher/
        ├── RELEASE_VS2022/X64/    # VS2022 64-bit release build
        ├── DEBUG_VS2022/X64/      # VS2022 64-bit debug build  
        ├── RELEASE_GCC5/IA32/     # GCC5 32-bit release build
        └── DEBUG_GCC5/IA32/       # GCC5 32-bit debug build
```

### CI/CD Build Artifacts
GitHub Actions produces artifacts for all 18 configurations:

**Download from GitHub:**
1. Go to your repository → Actions → Latest workflow run
2. Scroll to "Artifacts" section
3. Download specific configurations:

```
ACPIPatcher-linux-X64-RELEASE-GCC5.zip
ACPIPatcher-linux-X64-DEBUG-GCC5.zip  
ACPIPatcher-linux-IA32-RELEASE-GCC5.zip
ACPIPatcher-linux-IA32-DEBUG-GCC5.zip

ACPIPatcher-macos-X64-RELEASE-XCODE5.zip
ACPIPatcher-macos-X64-DEBUG-XCODE5.zip
ACPIPatcher-macos-IA32-RELEASE-XCODE5.zip  
ACPIPatcher-macos-IA32-DEBUG-XCODE5.zip

ACPIPatcher-windows-X64-RELEASE-VS2022.zip
ACPIPatcher-windows-X64-DEBUG-VS2022.zip
ACPIPatcher-windows-IA32-RELEASE-VS2022.zip
ACPIPatcher-windows-IA32-DEBUG-VS2022.zip

ACPIPatcher-windows-cygwin-X64-RELEASE-GCC5.zip
ACPIPatcher-windows-cygwin-X64-DEBUG-GCC5.zip
ACPIPatcher-windows-cygwin-IA32-RELEASE-GCC5.zip
ACPIPatcher-windows-cygwin-IA32-DEBUG-GCC5.zip
```

### File Usage Guide

**ACPIPatcher.efi** - Standalone Application:
- Use with UEFI Shell: `fs0:\ACPIPatcher.efi`
- Bootable USB: Copy to `/EFI/BOOT/` and rename to `BOOTX64.EFI`
- GRUB integration: Add as UEFI chainloader

**ACPIPatcherDxe.efi** - UEFI Driver:
- UEFI firmware integration: Add to firmware volume
- Runtime loading: Use UEFI driver loading mechanisms
- Custom BIOS: Integrate during firmware compilation

## 🔍 Troubleshooting

### Common Issues and Solutions

**Build Script Fails to Find Tools:**
```batch
# Windows - Manually specify toolchain
set VS_VERSION=2022
setup_and_build.bat X64 RELEASE

# Force Cygwin if VS detection fails  
set BASETOOLS_CYGWIN_BUILD=TRUE
setup_and_build.bat X64 RELEASE
```

**EDK2 Submodule Issues:**
```bash
# Reset EDK2 if clone fails
rm -rf temp_edk2
git clone --depth 1 https://github.com/tianocore/edk2.git temp_edk2

# Skip submodule timeouts in CI
export CI=true
./setup_and_build.sh X64 RELEASE
```

**Cross-Compilation Issues:**
```bash
# Linux - Install cross-compilation tools for IA32
sudo apt install gcc-multilib

# macOS - Ensure Xcode supports target architecture  
xcode-select --install
```

**Permission Issues (Windows):**
```batch
# Run as Administrator if PATH modification fails
# Or use portable mode:
set "NASM_PREFIX=C:\portable\nasm\"
setup_and_build.bat X64 RELEASE
```

### Debugging Build Problems

**Verbose Output:**
```bash
# Python script detailed logging
python ACPIPatcher.py --build --verbose

# Batch script debug mode  
set "DEBUG_MODE=1"
setup_and_build.bat X64 DEBUG
```

**Manual Build Steps:**
```bash
# If automatic script fails, try manual EDK2 build:
cd temp_edk2
source edksetup.sh      # Linux/macOS
# OR
call edksetup.bat       # Windows

# Manual build command
build -a X64 -b RELEASE -t GCC5 -p ACPIPatcherPkg/ACPIPatcherPkg.dsc
```

**Clean Build Environment:**
```bash
# Remove all build artifacts and restart
python ACPIPatcher.py --clean
rm -rf temp_edk2/Build
./setup_and_build.sh X64 RELEASE
```

## 📚 Additional Resources

### EDK2 Documentation
- [TianoCore EDK2 Documentation](https://github.com/tianocore/tianocore.github.io/wiki)
- [UEFI Specification](https://uefi.org/specifications)
- [EDK2 Module Writer's Guide](https://github.com/tianocore/tianocore.github.io/wiki/EDK-II-Module-Writer's-Guide)

### Development Tools
- [UEFI Shell Commands](https://github.com/tianocore/tianocore.github.io/wiki/UEFI-Shell)
- [Visual Studio Code EDK2 Extension](https://marketplace.visualstudio.com/items?itemName=intel-corporation.edk2-vscode)
- [EDK2 Debugging Guide](https://github.com/tianocore/tianocore.github.io/wiki/How-to-debug-UEFI-applications-with-GDB)

### Project-Specific  
- [ACPIPatcher GitHub Repository](https://github.com/startergo/ACPIPatcher)
- [CI/CD Build Status](https://github.com/startergo/ACPIPatcher/actions)
- [Issue Tracker](https://github.com/startergo/ACPIPatcher/issues)

---

## 🎉 Summary

The ACPIPatcher build system now provides:

- ✅ **One-Command Builds**: Just run the setup script
- ✅ **Cross-Platform**: Windows, Linux, macOS support  
- ✅ **Multiple Toolchains**: VS2019/2022, GCC5, Cygwin, XCODE5
- ✅ **All Architectures**: X64 and IA32 builds
- ✅ **All Build Types**: RELEASE and DEBUG configurations
- ✅ **CI/CD Integration**: Automated builds for all combinations
- ✅ **Zero Configuration**: Everything handled automatically
- ✅ **Fallback Support**: Multiple build methods available

**Choose your preferred method and start building!** 🚀

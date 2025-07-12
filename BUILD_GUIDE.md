# Complete Build Guide for ACPIPatcher

## 🎯 Quick Start - How to Compile and Build

### Current Status
✅ **Streamlined Build System**: Focused on reliability and traditional EDK2 tools  
✅ **Cross-Platform Support**: Windows, Linux, and macOS builds  
✅ **CI/CD Integration**: GitHub Actions with 16 build configurations via 2 focused workflows  
✅ **Modern Toolchains**: VS2022, GCC5, XCODE5  
✅ **All Architectures**: X64 and IA32 support  
✅ **All Build Types**: RELEASE and DEBUG builds

## 🏗️ Build Methods

### Method 1: Local Development Script (Optional)

**Python Script (Cross-Platform):**
```bash
# Quick build with defaults (available for local development)
python ACPIPatcher.py --build

# Specific configuration with all options
python ACPIPatcher.py --build --arch X64 --build-type DEBUG
python ACPIPatcher.py --build --arch IA32 --build-type RELEASE

# Clean build artifacts
python ACPIPatcher.py --clean

# Verbose output
python ACPIPatcher.py --build --verbose
```

### Method 2: GitHub Actions CI/CD (Recommended - Zero Setup)

**Trigger Automatic Builds:**
```bash
# Push any changes to trigger all 16 build configurations
git add .
git commit -m "Trigger comprehensive build matrix"
git push origin master

# Or manually trigger via GitHub web interface:
# Go to Actions → CI Build → Run workflow
```

**Available Build Matrix:**
- **Linux**: GCC5 toolchain (X64/IA32, RELEASE/DEBUG) 
- **macOS**: XCODE5 toolchain (X64/IA32, RELEASE/DEBUG)
- **Windows**: Visual Studio 2022 (X64/IA32, RELEASE/DEBUG)

### Method 3: Manual EDK2 Build (Traditional)

### Method 3: Manual EDK2 Build (Traditional)

**Prerequisites:**
1. Set up EDK2 environment following [EDK2 documentation](https://github.com/tianocore/edk2)
2. Clone this repository into your EDK2 workspace
3. Use standard EDK2 build commands

**Build Commands:**
```bash
# Linux/macOS
source edksetup.sh
build -a X64 -b RELEASE -t GCC5 -p ACPIPatcherPkg/ACPIPatcherPkg.dsc

# Windows  
call edksetup.bat
build -a X64 -b RELEASE -t VS2022 -p ACPIPatcherPkg\ACPIPatcherPkg.dsc

# macOS with Xcode
build -a X64 -b RELEASE -t XCODE5 -p ACPIPatcherPkg/ACPIPatcherPkg.dsc
```

## 🔧 What the CI System Does Automatically

## 🔧 What the CI System Does Automatically

### Comprehensive Environment Setup
1. **Toolchain Installation & Configuration**:
   - Visual Studio 2022 Build Tools (Windows)
   - GCC5 (Linux)
   - Xcode5 (macOS)
   - Direct NASM installation with multiple fallback sources

2. **EDK2 Management**:
   - EDK2 repository checkout (stable release)
   - Submodule initialization 
   - BaseTools compilation with enhanced Windows support
   - Environment configuration

3. **Build Process**:
   - ACPIPatcherPkg integration
   - Multi-architecture compilation (X64/IA32)
   - Artifact collection with consistent naming
   - Build validation and error reporting

### Enhanced Windows Build Process
- **Direct NASM Installation**: Downloads and installs NASM automatically
- **BaseTools Building**: Robust compilation process with fallback methods  
- **VS2022 Integration**: Full Visual Studio 2022 Enterprise support
- **vcvars Environment**: Proper compiler environment setup

### Streamlined Workflow Architecture
- **ci-new.yml**: Comprehensive 16-job matrix build system
- **release.yml**: Dedicated release management and artifact packaging
- **Traditional EDK2**: Focus on proven, reliable build methods
- **Cross-Platform**: Consistent build process across all platforms

## 🔧 Prerequisites

### Automatic Installation (Handled by CI)
The GitHub Actions workflows automatically handle all prerequisites:

**Windows:**
- ✅ **Visual Studio 2022**: Enterprise edition with full C++ build tools
- ✅ **NASM**: Direct download and installation with multiple sources
- ✅ **Python**: Latest Python 3.x with EDK2 dependencies
- ✅ **Git**: Configured for EDK2 development
- ✅ **EDK2**: Checkout with BaseTools compilation

**Linux/macOS:**
- ✅ **GCC/Clang**: System compilers with build-essential packages
- ✅ **NASM**: Package manager installation
- ✅ **Python**: Cross-platform EDK2 tools
- ✅ **Git**: Optimized configuration for large repositories

### Manual Prerequisites (For Local Development)

For local development, you may need to install prerequisites manually:

**Windows - Visual Studio Build Tools:**
```powershell
# Install VS Build Tools 2022 (Recommended)
# Download: https://visualstudio.microsoft.com/downloads/#build-tools-for-visual-studio-2022
# Select: "C++ build tools" workload
```

**Windows - NASM:**
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

### For First-Time Users (GitHub Actions - Recommended)

1. **Fork and Clone the Repository:**
```bash
# Fork on GitHub, then:
git clone https://github.com/YOUR_USERNAME/ACPIPatcher.git
cd ACPIPatcher
```

2. **Trigger Automated Build:**
```bash
# Make any small change to trigger CI
git commit --allow-empty -m "Trigger build"
git push origin master

# Or go to GitHub → Actions → CI Build → Run workflow
```

3. **Download Build Artifacts:**
```
# Go to GitHub → Actions → Latest run → Artifacts
# Download platform-specific builds:
ACPIPatcher-linux-X64-RELEASE-GCC5.zip
ACPIPatcher-macos-X64-RELEASE-XCODE5.zip  
ACPIPatcher-windows-X64-RELEASE-VS2022.zip
```

### For Local Development (Python Script)

### Advanced Configuration Examples

**Local Python Script - Multiple Configurations:**
```bash
# Test different combinations locally
python ACPIPatcher.py --build --arch X64 --build-type RELEASE
python ACPIPatcher.py --build --arch X64 --build-type DEBUG
python ACPIPatcher.py --build --arch IA32 --build-type RELEASE  
python ACPIPatcher.py --build --arch IA32 --build-type DEBUG

# Clean and rebuild
python ACPIPatcher.py --clean
python ACPIPatcher.py --build --arch X64 --build-type RELEASE --verbose
```

**Manual EDK2 - Platform-Specific:**
```bash
# Linux with GCC5
build -a X64 -b RELEASE -t GCC5 -p ACPIPatcherPkg/ACPIPatcherPkg.dsc

# macOS with Xcode
build -a X64 -b RELEASE -t XCODE5 -p ACPIPatcherPkg/ACPIPatcherPkg.dsc

# Windows with VS2022  
build -a X64 -b RELEASE -t VS2022 -p ACPIPatcherPkg\ACPIPatcherPkg.dsc
```

## 🎯 Immediate Quick Start

**Fastest way to get .efi files:**

**Option 1 - Use GitHub Actions (Zero local setup - Recommended):**
```bash
# Fork the repo on GitHub, then:
git clone https://github.com/YOUR_USERNAME/ACPIPatcher.git
cd ACPIPatcher
git commit --allow-empty -m "Trigger build"
git push

# Download artifacts from GitHub Actions in ~5-10 minutes
# All 16 configurations will be built automatically
```

**Option 2 - Local Python build:**
```bash
# Clone and run (requires Python 3.7+)
git clone https://github.com/startergo/ACPIPatcher.git
cd ACPIPatcher
python ACPIPatcher.py --build

# Build completed in current directory:
# - ACPIPatcher.efi 
# - ACPIPatcherDxe.efi
```

**Option 3 - Manual EDK2 build:**
```bash
git clone https://github.com/startergo/ACPIPatcher.git
# Set up EDK2 environment following EDK2 documentation
# Then use standard EDK2 build commands
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
GitHub Actions produces artifacts for all 16 configurations:

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

**Python Script Issues:**
```bash
# If Python script fails to find tools
export EDK2_TOOLCHAIN=GCC5  # Linux/macOS
set EDK2_TOOLCHAIN=VS2022   # Windows

# Clean and retry
python ACPIPatcher.py --clean
python ACPIPatcher.py --build --verbose
```

**EDK2 Setup Issues:**
```bash
# Reset EDK2 if setup fails
rm -rf temp_edk2
# Then retry your build method
```

**Missing Dependencies:**
```bash
# Linux - Install build tools
sudo apt install build-essential nasm python3 git uuid-dev

# macOS - Install Xcode tools
xcode-select --install
brew install nasm

# Windows - Install VS2022 Build Tools and NASM
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

# Or for manual EDK2 builds
cd edk2
rm -rf Build/ACPIPatcherPkg
make -C BaseTools clean && make -C BaseTools
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

- ✅ **Streamlined Workflows**: 2 focused GitHub Actions workflows (ci-new.yml + release.yml)
- ✅ **Cross-Platform**: Windows, Linux, macOS support with modern toolchains
- ✅ **Multiple Build Methods**: GitHub Actions (recommended), Python script, manual EDK2
- ✅ **All Architectures**: X64 and IA32 builds
- ✅ **All Build Types**: RELEASE and DEBUG configurations  
- ✅ **CI/CD Integration**: Automated builds for 16 different combinations
- ✅ **Traditional EDK2**: Focus on proven, reliable build methods
- ✅ **Zero Configuration**: GitHub Actions requires no local setup

**Choose your preferred method and start building!** 🚀

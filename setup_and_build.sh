#!/bin/bash

# EDK2 Comprehensive Setup Script (Unix/Linux/macOS Version) for ACPIPatcher
# This script sets up the complete EDK2 environment and builds ACPIPatcher
# Usage: setup_and_build.sh [ARCH] [BUILD_TYPE]
#   ARCH: X64, IA32 (default: X64)
#   BUILD_TYPE: RELEASE, DEBUG (default: RELEASE)
# Examples:
#   setup_and_build.sh X64 RELEASE
#   setup_and_build.sh IA32 DEBUG

# Parse command line arguments
TARGET_ARCH="${1:-X64}"
BUILD_TYPE="${2:-RELEASE}"

# Validate architecture
if [[ "$TARGET_ARCH" != "X64" && "$TARGET_ARCH" != "IA32" ]]; then
    echo "ERROR: Invalid architecture '$TARGET_ARCH'. Supported: X64, IA32"
    exit 1
fi

# Validate build type
if [[ "$BUILD_TYPE" != "RELEASE" && "$BUILD_TYPE" != "DEBUG" ]]; then
    echo "ERROR: Invalid build type '$BUILD_TYPE'. Supported: RELEASE, DEBUG"
    exit 1
fi

echo "================================================================"
echo "ACPIPatcher Automated Build Setup (Unix/Linux/macOS)"
echo "================================================================"
echo "Target Architecture: $TARGET_ARCH"
echo "Build Type: $BUILD_TYPE"
echo

# Check if running in CI environment
if [ "$CI" = "true" ]; then
    echo "Running in CI environment - unattended mode"
    CI_MODE=1
    # Configure Git to use GitHub token for CI
    if [ -n "$GITHUB_TOKEN" ]; then
        echo "Configuring Git with GitHub token for CI authentication..."
        git config --global credential.helper store
        echo "https://x-access-token:$GITHUB_TOKEN@github.com" > ~/.git-credentials
    fi
else
    CI_MODE=0
fi

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
echo "Checking prerequisites..."
if ! command_exists python3; then
    echo "ERROR: Python 3 not found. Please install Python 3.10+ and add to PATH."
    exit 1
fi

if ! command_exists git; then
    echo "ERROR: Git not found. Please install Git and add to PATH."
    exit 1
else
    echo "✓ Git found. Configuring Git for optimal EDK2 experience..."
    git config --global credential.helper manager >/dev/null 2>&1 || true
    git config --global core.autocrlf false >/dev/null 2>&1
    git config --global core.longpaths true >/dev/null 2>&1
    echo "  - Credential helper configured for seamless authentication"
    echo "  - Line ending handling optimized for EDK2"
    echo "  - Long path support enabled for deep directory structures"
fi

# Check for compilers - GCC, Clang, or build tools
if command_exists gcc; then
    gcc_version=$(gcc --version | head -n1)
    echo "✓ GCC found: $gcc_version"
    
    # Check GCC version for compatibility
    gcc_major=$(gcc -dumpversion | cut -d. -f1)
    if [ "$gcc_major" -ge 5 ]; then
        echo "  - GCC version is compatible (≥5.0)"
        export TOOLCHAIN="GCC5"
    else
        echo "  - WARNING: GCC version may be too old for EDK2 (recommended ≥5.0)"
        export TOOLCHAIN="GCC5"
    fi
elif command_exists clang; then
    clang_version=$(clang --version | head -n1)
    echo "✓ Clang found: $clang_version"
    
    # Check if we're on macOS or Linux
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "  - Using Xcode toolchain for macOS"
        export TOOLCHAIN="XCODE5"
    else
        echo "  - Using Clang as GCC alternative on Linux"
        # For better EDK2 compatibility, prefer GCC5 toolchain even with clang
        export TOOLCHAIN="GCC5"
        export CC=clang
        export CXX=clang++
    fi
else
    echo "WARNING: No C compiler found (GCC or Clang)."
    echo "Please install a compiler for building:"
    echo "  Ubuntu/Debian: sudo apt install build-essential"
    echo "  CentOS/RHEL: sudo yum groupinstall 'Development Tools'"
    echo "  Fedora: sudo dnf groupinstall 'Development Tools'"
    echo "  macOS: xcode-select --install"
    echo "  Arch Linux: sudo pacman -S base-devel"
    echo "Attempting to continue..."
fi

# Check for make utility
if ! command_exists make; then
    echo "WARNING: Make utility not found."
    echo "Installing build tools may resolve this issue."
fi

if ! command_exists nasm; then
    echo "WARNING: NASM not found in PATH."
    echo "NASM is required for assembly compilation."
    echo "Installing NASM..."
    
    # Try to install NASM using package manager
    if command_exists apt-get; then
        echo "Using apt-get to install NASM..."
        sudo apt-get update && sudo apt-get install -y nasm
    elif command_exists yum; then
        echo "Using yum to install NASM..."
        sudo yum install -y nasm
    elif command_exists dnf; then
        echo "Using dnf to install NASM..."
        sudo dnf install -y nasm
    elif command_exists brew; then
        echo "Using brew to install NASM..."
        brew install nasm
    elif command_exists pacman; then
        echo "Using pacman to install NASM..."
        sudo pacman -S --noconfirm nasm
    else
        echo "WARNING: Could not install NASM automatically."
        echo "Please install NASM manually and re-run the script."
        echo "Build may fail for assembly files."
    fi
else
    echo "✓ NASM found in PATH."
fi

echo "Prerequisites check completed."
echo

# Step 1: Setup completed (no longer needed)
echo "Step 1: Prerequisites verified, proceeding to EDK2 setup..."
echo

# Step 2: Set up EDK2 workspace
echo "Step 2: Setting up EDK2 workspace..."
if [ ! -d "temp_edk2" ]; then
    echo "Cloning EDK2 repository..."
    git clone https://github.com/tianocore/edk2.git temp_edk2
    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to clone EDK2 repository."
        exit 1
    fi
    
    echo "Initializing EDK2 submodules..."
    cd temp_edk2
    
    echo "Configuring Git for this repository..."
    git config core.autocrlf false >/dev/null 2>&1
    git config core.longpaths true >/dev/null 2>&1
    
    echo "Downloading submodules (this may take a few minutes)..."
    git submodule update --init --recursive --progress
    if [ $? -ne 0 ]; then
        echo "WARNING: Some submodules failed to initialize. This is often due to authentication."
        echo "Retrying with different approach..."
        git submodule update --init --progress
        if [ $? -ne 0 ]; then
            echo "WARNING: Submodule initialization failed. Build will continue using pip-based BaseTools."
            echo "Note: This may cause some assembly optimization features to be unavailable."
        else
            echo "Submodules initialized successfully (partial)."
        fi
    else
        echo "✓ All submodules initialized successfully."
    fi
    cd ..
else
    echo "EDK2 workspace already exists."
fi

# Build BaseTools C binaries (required for GenFw)
echo "Building EDK2 BaseTools C binaries..."
cd temp_edk2

# Set up EDK2 environment 
source edksetup.sh BaseTools
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to setup EDK2 environment"
    exit 1
fi

# Build C tools manually to ensure GenFw is available
echo "Compiling BaseTools C utilities..."
make -C BaseTools/Source/C
if [ $? -ne 0 ]; then
    echo "WARNING: BaseTools C compilation had issues, trying alternative approach..."
    cd BaseTools/Source/C
    make
    cd ../../..
fi

# Verify GenFw is available
if [ -f "BaseTools/Source/C/bin/GenFw" ]; then
    echo "✓ GenFw compiled successfully"
    # Add BaseTools to PATH for build process
    export PATH="$PWD/BaseTools/Source/C/bin:$PATH"
elif [ -f "BaseTools/BinWrappers/PosixLike/GenFw" ]; then
    echo "✓ GenFw wrapper found"
    export PATH="$PWD/BaseTools/BinWrappers/PosixLike:$PATH"
else
    echo "WARNING: GenFw not found, build may fail"
fi

cd ..
echo "EDK2 workspace setup completed."
echo

# Step 3: Copy project files
echo "Step 3: Copying project files..."
if [ -d "ACPIPatcherPkg" ]; then
    if [ ! -d "temp_edk2/ACPIPatcherPkg" ]; then
        echo "Copying ACPIPatcherPkg to EDK2 workspace..."
        cp -r "ACPIPatcherPkg" "temp_edk2/"
        if [ $? -ne 0 ]; then
            echo "ERROR: Failed to copy ACPIPatcherPkg."
            exit 1
        fi
    else
        echo "ACPIPatcherPkg already exists in EDK2 workspace."
    fi
else
    echo "ERROR: ACPIPatcherPkg directory not found."
    exit 1
fi
echo "Project files copied."
echo

# Step 4: Fix DSC file
echo "Step 4: Checking DSC file..."
if ! grep -q "StackCheckLib" "temp_edk2/ACPIPatcherPkg/ACPIPatcherPkg.dsc"; then
    echo "Adding StackCheckLib to DSC file..."
    sed -i 's|RegisterFilterLib|MdePkg/Library/RegisterFilterLibNull/RegisterFilterLibNull.inf|RegisterFilterLib|MdePkg/Library/RegisterFilterLibNull/RegisterFilterLibNull.inf\n  StackCheckLib|MdePkg/Library/StackCheckLibNull/StackCheckLibNull.inf|' "temp_edk2/ACPIPatcherPkg/ACPIPatcherPkg.dsc"
    echo "DSC file updated."
else
    echo "DSC file already contains StackCheckLib."
fi
echo

# Step 5: Run build
echo "Step 5: Running build..."
echo "Running: python3 ACPIPatcher.py --build --arch ${TARGET_ARCH} --build-type ${BUILD_TYPE}"
python3 ACPIPatcher.py --build --arch "${TARGET_ARCH}" --build-type "${BUILD_TYPE}"
if [ $? -ne 0 ]; then
    echo
    echo "================================================================"
    echo "BUILD FAILED - Trying fallback approach"
    echo "================================================================"
    echo "Attempting manual EDK2 build..."
    cd temp_edk2
    
    # Auto-detect available toolchain
    TOOLCHAIN="GCC5"
    if command_exists clang; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            TOOLCHAIN="XCODE5"
        else
            # For Linux, prefer GCC5 over CLANG38 for better compatibility
            TOOLCHAIN="GCC5"
        fi
    fi
    
    echo "Using toolchain: $TOOLCHAIN"
    
    source edksetup.sh BaseTools
    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to setup EDK2 environment"
        cd ..
        exit 1
    fi
    
    # Ensure BaseTools C binaries are built and available
    echo "Ensuring BaseTools C utilities are available..."
    if [ ! -f "BaseTools/Source/C/bin/GenFw" ] && [ ! -f "BaseTools/BinWrappers/PosixLike/GenFw" ]; then
        echo "Building BaseTools C utilities..."
        make -C BaseTools/Source/C
        if [ $? -ne 0 ]; then
            echo "WARNING: BaseTools C compilation failed, trying alternative..."
            cd BaseTools/Source/C
            make
            cd ../../..
        fi
    fi
    
    # Add BaseTools to PATH
    if [ -d "BaseTools/Source/C/bin" ]; then
        export PATH="$PWD/BaseTools/Source/C/bin:$PATH"
        echo "Added BaseTools C binaries to PATH"
    elif [ -d "BaseTools/BinWrappers/PosixLike" ]; then
        export PATH="$PWD/BaseTools/BinWrappers/PosixLike:$PATH"
        echo "Added BaseTools wrappers to PATH"
    fi
    
    cp BaseTools/Conf/build_rule.template Conf/build_rule.txt >/dev/null 2>&1
    cp Conf/build_rule.txt . >/dev/null 2>&1
    
    echo "Running build with auto-detected toolchain: $TOOLCHAIN"
    echo "Configuration: $TARGET_ARCH $BUILD_TYPE ($TOOLCHAIN)"
    build -a $TARGET_ARCH -b $BUILD_TYPE -t $TOOLCHAIN -p ACPIPatcherPkg/ACPIPatcherPkg.dsc
    if [ $? -ne 0 ]; then
        echo "ERROR: Manual build also failed"
        cd ..
        exit 1
    fi
    echo "Manual build completed successfully!"
    if [ -f "Build/ACPIPatcher/${BUILD_TYPE}_${TOOLCHAIN}/${TARGET_ARCH}/ACPIPatcher.efi" ]; then
        cp "Build/ACPIPatcher/${BUILD_TYPE}_${TOOLCHAIN}/${TARGET_ARCH}/ACPIPatcher.efi" .. >/dev/null 2>&1
    fi
    if [ -f "Build/ACPIPatcher/${BUILD_TYPE}_${TOOLCHAIN}/${TARGET_ARCH}/ACPIPatcherDxe.efi" ]; then
        cp "Build/ACPIPatcher/${BUILD_TYPE}_${TOOLCHAIN}/${TARGET_ARCH}/ACPIPatcherDxe.efi" .. >/dev/null 2>&1
    fi
    cd ..
fi

echo
echo "================================================================"
echo "BUILD COMPLETED SUCCESSFULLY!"
echo "================================================================"
echo
echo "Checking for output files..."
if [ -f "ACPIPatcher.efi" ]; then
    echo "✓ ACPIPatcher.efi found"
    ls -la "ACPIPatcher.efi"
else
    echo "✗ ACPIPatcher.efi not found"
fi

if [ -f "ACPIPatcherDxe.efi" ]; then
    echo "✓ ACPIPatcherDxe.efi found"
    ls -la "ACPIPatcherDxe.efi"
else
    echo "✗ ACPIPatcherDxe.efi not found"
fi

echo
echo "Build artifacts are ready for use!"
echo

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

# Check for iasl (Intel ASL Compiler) - critical for EDK2 builds
if ! command_exists iasl; then
    echo "WARNING: Intel ASL Compiler (iasl) not found in PATH."
    echo "iasl is required for ACPI compilation in EDK2."
    echo "Installing iasl..."
    
    # Try to install iasl using package manager
    if command_exists apt-get; then
        echo "Using apt-get to install iasl..."
        sudo apt-get update && sudo apt-get install -y iasl acpica-tools
    elif command_exists yum; then
        echo "Using yum to install iasl..."
        sudo yum install -y iasl acpica-tools
    elif command_exists dnf; then
        echo "Using dnf to install iasl..."
        sudo dnf install -y iasl acpica-tools
    elif command_exists brew; then
        echo "Using brew to install iasl..."
        brew install acpica
    elif command_exists pacman; then
        echo "Using pacman to install iasl..."
        sudo pacman -S --noconfirm iasl
    else
        echo "WARNING: Could not install iasl automatically."
        echo "Please install Intel ASL Compiler (iasl) manually."
        echo "  Ubuntu/Debian: sudo apt-get install iasl acpica-tools"
        echo "  CentOS/RHEL: sudo yum install iasl acpica-tools"
        echo "  macOS: brew install acpica"
        echo "Build may fail for ACPI compilation."
    fi
else
    echo "✓ Intel ASL Compiler (iasl) found in PATH."
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
    
    # Configure Git to use HTTPS for GitHub URLs (CI compatibility)
    if [ -n "$CI" ]; then
        echo "CI environment detected, configuring HTTPS for Git operations..."
        git config url."https://github.com/".insteadOf "git@github.com:"
        git config url."https://".insteadOf "git://"
    fi
    
    echo "Downloading submodules (this may take a few minutes)..."
    git -c http.lowSpeedLimit=1000 -c http.lowSpeedTime=60 submodule update --init --recursive --progress
    if [ $? -ne 0 ]; then
        echo "WARNING: Some submodules failed to initialize. This is often due to authentication issues."
        echo "Retrying with individual critical submodules..."
        
        # Try individual critical submodules
        echo "Initializing critical submodules individually..."
        echo "  - Initializing BrotliCompress..."
        git -c http.lowSpeedLimit=1000 -c http.lowSpeedTime=30 submodule update --init --recursive BaseTools/Source/C/BrotliCompress
        
        echo "  - Initializing OpensslLib..."
        git -c http.lowSpeedLimit=1000 -c http.lowSpeedTime=30 submodule update --init --recursive CryptoPkg/Library/OpensslLib
        
        echo "  - Initializing MipiSysTLib..."
        git -c http.lowSpeedLimit=1000 -c http.lowSpeedTime=30 submodule update --init --recursive MdePkg/Library/MipiSysTLib
        
        echo "  - Initializing BrotliCustomDecompressLib..."
        git -c http.lowSpeedLimit=1000 -c http.lowSpeedTime=30 submodule update --init --recursive MdeModulePkg/Library/BrotliCustomDecompressLib
        
        echo "Individual submodule initialization completed."
    else
        echo "✓ All submodules initialized successfully."
    fi
    
    # Verify critical submodules after initialization
    echo "Verifying critical submodules..."
    SUBMODULES_MISSING=0
    
    if [ -d "BaseTools/Source/C/BrotliCompress/brotli/c" ]; then
        echo "✓ BrotliCompress submodule verified"
    else
        echo "❌ BrotliCompress submodule missing"
        SUBMODULES_MISSING=1
    fi
    
    if [ -d "CryptoPkg/Library/OpensslLib/openssl/include" ]; then
        echo "✓ OpensslLib submodule verified"
    else
        echo "❌ OpensslLib submodule missing"
        SUBMODULES_MISSING=1
    fi
    
    if [ -d "MdePkg/Library/MipiSysTLib/mipisyst/library/include" ]; then
        echo "✓ MipiSysTLib submodule verified"
    else
        echo "❌ MipiSysTLib submodule missing - attempting direct initialization..."
        git submodule update --init --recursive MdePkg/Library/MipiSysTLib
        if [ -d "MdePkg/Library/MipiSysTLib/mipisyst/library/include" ]; then
            echo "✓ MipiSysTLib submodule verified after direct init"
        else
            echo "❌ MipiSysTLib submodule still missing after direct init"
            SUBMODULES_MISSING=1
        fi
    fi
    
    if [ -d "MdeModulePkg/Library/BrotliCustomDecompressLib/brotli/c" ]; then
        echo "✓ BrotliCustomDecompressLib submodule verified"
    else
        echo "❌ BrotliCustomDecompressLib submodule missing"
        SUBMODULES_MISSING=1
    fi
    
    if [ $SUBMODULES_MISSING -eq 1 ]; then
        echo "WARNING: Some critical submodules are missing. Build may fail."
        echo "Note: This may cause some assembly optimization features to be unavailable."
    else
        echo "✓ All critical submodules verified successfully."
    fi
    cd ..
else
    echo "EDK2 workspace already exists."
fi

# Build BaseTools C binaries (required for GenFw)
echo "Building EDK2 BaseTools C binaries..."
cd temp_edk2

# Check for essential build tools first
echo "Checking essential build tools..."
missing_tools=()

for tool in make gcc nasm; do
    if ! command_exists "$tool"; then
        missing_tools+=("$tool")
    else
        echo "✓ $tool found"
    fi
done

if [ ${#missing_tools[@]} -ne 0 ]; then
    echo "ERROR: Missing essential build tools: ${missing_tools[*]}"
    echo "Please install missing tools:"
    echo "  Ubuntu/Debian: sudo apt-get install build-essential nasm"
    echo "  CentOS/RHEL: sudo yum install gcc make nasm"
    echo "  macOS: xcode-select --install && brew install nasm"
    exit 1
fi

# Build BaseTools FIRST (before setting up environment) - this is the proper EDK2 sequence
echo "Building BaseTools C utilities (following EDK2 documentation sequence)..."
echo "Step 1: Build BaseTools using make -C BaseTools"
make -C BaseTools
if [ $? -ne 0 ]; then
    echo "WARNING: 'make -C BaseTools' failed, trying alternative approach..."
    # Try the Source/C approach as fallback
    make -C BaseTools/Source/C
    # Try the Source/C approach as fallback
    make -C BaseTools/Source/C
    if [ $? -ne 0 ]; then
        echo "WARNING: BaseTools/Source/C build also failed, trying comprehensive rebuild..."
        # Try building in the C directory directly
        if [ -d "BaseTools/Source/C" ]; then
            echo "Trying direct make in BaseTools C directory..."
            cd BaseTools/Source/C
            make clean
            make
            build_result=$?
            cd ../../..
            
            if [ $build_result -ne 0 ]; then
                # Try make with specific targets
                echo "Trying to build specific BaseTools targets..."
                cd BaseTools/Source/C
                for target in GenFv GenFfs GenFw GenSec VfrCompile; do
                    echo "Building $target..."
                    make "$target"
                    if [ $? -eq 0 ]; then
                        echo "✓ $target built successfully"
                    else
                        echo "WARNING: Failed to build $target"
                    fi
                done
                cd ../../..
            fi
        fi
    fi
fi

echo "Step 2: Source edksetup.sh to set up environment"
# NOW set up EDK2 environment after BaseTools are built
source edksetup.sh
if [ $? -ne 0 ]; then
    echo "WARNING: edksetup.sh had issues, but BaseTools should already be built..."
fi

# Verify that GenFw and other critical tools are available
basetools_bin="BaseTools/Source/C/bin"
basetools_wrappers="BaseTools/BinWrappers/PosixLike"

# Check for GenFw specifically since it's needed for EFI generation
genfw_locations=(
    "$basetools_bin/GenFw"
    "$basetools_wrappers/GenFw"
    "BaseTools/Source/C/GenFw/GenFw"
)

genfw_found=false
for genfw_path in "${genfw_locations[@]}"; do
    if [ -f "$genfw_path" ] && [ -x "$genfw_path" ]; then
        echo "✓ GenFw found at $genfw_path"
        genfw_found=true
        break
    fi
done

if [ "$genfw_found" = false ]; then
    echo "ERROR: GenFw tool not found - EFI generation will fail!"
    echo "Attempting to build GenFw specifically..."
    
    # Try building GenFw from its source directory
    genfw_dir="BaseTools/Source/C/GenFw"
    if [ -d "$genfw_dir" ]; then
        echo "Building GenFw from $genfw_dir"
        cd "$genfw_dir"
        make
        if [ $? -eq 0 ]; then
            echo "✓ GenFw built successfully"
            # Check if it's now available
            if [ -f "GenFw" ]; then
                # Make sure bin directory exists and copy the executable
                mkdir -p "../bin"
                cp "GenFw" "../bin/"
                echo "✓ GenFw copied to $basetools_bin"
                genfw_found=true
            fi
        else
            echo "ERROR: Failed to build GenFw"
        fi
        cd ../../../..
    fi
    
    # If still not found, try a global make in BaseTools/Source/C
    if [ "$genfw_found" = false ]; then
        echo "Trying global BaseTools C build..."
        cd BaseTools/Source/C
        make clean
        make
        if [ $? -eq 0 ]; then
            # Check again for GenFw
            for genfw_path in "${genfw_locations[@]}"; do
                if [ -f "$genfw_path" ] && [ -x "$genfw_path" ]; then
                    echo "✓ GenFw found at $genfw_path after global build"
                    genfw_found=true
                    break
                fi
            done
        fi
        cd ../../..
    fi
fi

# Set up PATH to include BaseTools
if [ -d "$basetools_bin" ]; then
    export PATH="$PWD/$basetools_bin:$PATH"
    echo "✓ Added $basetools_bin to PATH"
fi

if [ -d "$basetools_wrappers" ]; then
    export PATH="$PWD/$basetools_wrappers:$PATH"
    echo "✓ Added $basetools_wrappers to PATH"
fi

# Final verification
required_tools=("GenFv" "GenFfs" "GenFw" "GenSec")
missing_basetools=()

for tool in "${required_tools[@]}"; do
    if ! command_exists "$tool"; then
        missing_basetools+=("$tool")
    fi
done

if [ ${#missing_basetools[@]} -ne 0 ]; then
    echo "WARNING: Some BaseTools are missing: ${missing_basetools[*]}"
    echo "Build may fail, but continuing..."
else
    echo "✓ All required BaseTools found and accessible"
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
echo "Configuration: $TARGET_ARCH $BUILD_TYPE ($TOOLCHAIN)"

# Change to EDK2 directory for build
cd temp_edk2

# Set up EDK2 environment for build (should already be done, but ensure it's set)
echo "Ensuring EDK2 environment is properly set up..."
if [ -z "$EDK_TOOLS_PATH" ]; then
    echo "EDK_TOOLS_PATH not set, sourcing edksetup.sh..."
    source edksetup.sh
else
    echo "EDK2 environment already configured"
fi

# Ensure configuration files are set up
if [ ! -f "Conf/build_rule.txt" ]; then
    cp BaseTools/Conf/build_rule.template Conf/build_rule.txt >/dev/null 2>&1
fi

echo "Running EDK2 build with toolchain: $TOOLCHAIN"
build -a $TARGET_ARCH -b $BUILD_TYPE -t $TOOLCHAIN -p ACPIPatcherPkg/ACPIPatcherPkg.dsc
build_result=$?

if [ $build_result -eq 0 ]; then
    echo "✓ Build completed successfully!"
    
    # Copy build artifacts back to main directory
    echo "Copying build artifacts..."
    BUILD_DIR="Build/ACPIPatcher/${BUILD_TYPE}_${TOOLCHAIN}/${TARGET_ARCH}"
    
    # Check for ACPIPatcher.efi in multiple possible locations
    acpipatcher_found=false
    acpipatcher_locations=(
        "$BUILD_DIR/ACPIPatcher.efi"
        "$BUILD_DIR/ACPIPatcherPkg/ACPIPatcher/ACPIPatcher/OUTPUT/ACPIPatcher.efi"
    )
    
    for location in "${acpipatcher_locations[@]}"; do
        if [ -f "$location" ]; then
            cp "$location" "../ACPIPatcher.efi"
            echo "✓ ACPIPatcher.efi copied from $location"
            acpipatcher_found=true
            break
        fi
    done
    
    if [ "$acpipatcher_found" = false ]; then
        echo "WARNING: ACPIPatcher.efi not found in expected build output locations"
    fi
    
    # Check for ACPIPatcherDxe.efi in multiple possible locations
    acpipatcherdxe_found=false
    acpipatcherdxe_locations=(
        "$BUILD_DIR/ACPIPatcherDxe.efi"
        "$BUILD_DIR/ACPIPatcherPkg/ACPIPatcher/ACPIPatcherDxe/OUTPUT/ACPIPatcherDxe.efi"
    )
    
    for location in "${acpipatcherdxe_locations[@]}"; do
        if [ -f "$location" ]; then
            cp "$location" "../ACPIPatcherDxe.efi"
            echo "✓ ACPIPatcherDxe.efi copied from $location"
            acpipatcherdxe_found=true
            break
        fi
    done
    
    if [ "$acpipatcherdxe_found" = false ]; then
        echo "WARNING: ACPIPatcherDxe.efi not found in expected build output locations"
    fi
    
    cd ..
else
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
    
    # Check for essential build tools
    missing_tools=()
    for tool in make gcc nasm; do
        if ! command_exists "$tool"; then
            missing_tools+=("$tool")
        fi
    done
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        echo "ERROR: Missing essential build tools: ${missing_tools[*]}"
        echo "Please install missing tools and re-run."
        cd ..
        exit 1
    fi
    
    # Build BaseTools if GenFw is not available (following proper EDK2 sequence)
    if [ ! -f "BaseTools/Source/C/bin/GenFw" ] && [ ! -f "BaseTools/BinWrappers/PosixLike/GenFw" ]; then
        echo "Building BaseTools using proper EDK2 sequence..."
        
        # First: make -C BaseTools (this is the recommended approach)
        echo "Step 1: Building BaseTools with 'make -C BaseTools'"
        make -C BaseTools
        if [ $? -ne 0 ]; then
            echo "WARNING: 'make -C BaseTools' failed, trying Source/C fallback..."
            # Fallback: make -C BaseTools/Source/C
            make -C BaseTools/Source/C
            if [ $? -ne 0 ]; then
                echo "WARNING: BaseTools/Source/C build also failed, trying comprehensive rebuild..."
                cd BaseTools/Source/C
                make clean
                make
                if [ $? -ne 0 ]; then
                    echo "Trying to build specific tools..."
                    for target in GenFv GenFfs GenFw GenSec VfrCompile; do
                        echo "Building $target..."
                        make "$target"
                        if [ $? -eq 0 ]; then
                            echo "✓ $target built successfully"
                        fi
                    done
                fi
                cd ../../..
            fi
        fi
        
        echo "Step 2: Setting up EDK2 environment after BaseTools build"
        source edksetup.sh
    else
        echo "BaseTools already available, just setting up environment"
        source edksetup.sh
    fi
    
    # Verify critical tools are available
    genfw_found=false
    genfw_locations=(
        "BaseTools/Source/C/bin/GenFw"
        "BaseTools/BinWrappers/PosixLike/GenFw"
        "BaseTools/Source/C/GenFw/GenFw"
    )
    
    for genfw_path in "${genfw_locations[@]}"; do
        if [ -f "$genfw_path" ] && [ -x "$genfw_path" ]; then
            echo "✓ GenFw found at $genfw_path"
            genfw_found=true
            break
        fi
    done
    
    if [ "$genfw_found" = false ]; then
        echo "ERROR: GenFw tool not found - build will likely fail"
        echo "Please ensure BaseTools build completed successfully"
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

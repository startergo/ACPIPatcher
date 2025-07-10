# Stuart Build System Documentation

## Overview
This project now includes a comprehensive Stuart-based build system using TianoCore's edk2-pytool-extensions. The Stuart build system provides modern CI/CD capabilities with enhanced dependency management and testing support.

## What is Stuart?
Stuart is TianoCore's modern build system that:
- Provides Python-based build orchestration
- Handles complex dependency management
- Supports unit testing with NOOPT builds
- Integrates with modern CI/CD pipelines
- Manages binary dependencies automatically

## Build Matrix
The Stuart workflow supports the following build configurations:

### Toolchains
- **VS2019/VS2022**: Microsoft Visual Studio builds
- **GCC5**: MinGW-based GCC builds for maximum compatibility

### Architectures
- **X64**: 64-bit builds
- **IA32**: 32-bit builds
- **IA32,X64**: Combined builds for unit testing

### Build Types
- **RELEASE**: Optimized production builds
- **DEBUG**: Debug builds with symbols
- **NOOPT**: Unoptimized builds for unit testing

## Workflow Features

### Environment Setup
1. **Python Virtual Environment**: Isolated Python environment for build dependencies
2. **Toolchain Configuration**: Automatic setup of Visual Studio or MinGW
3. **EDK2 Integration**: Clones and configures EDK2 repository

### Dependency Management
- Installs `edk2-pytool-extensions` for Stuart functionality
- Processes `pip-requirements.txt` for additional Python dependencies
- Handles regex module installation with error recovery
- Manages EDK2 submodules selectively

### Stuart Process
1. **Stuart Update**: Downloads and updates all binary dependencies
2. **Stuart CI Build**: Executes comprehensive CI build process
3. **Stuart Build**: Alternative build method as fallback

### Build Verification
- Searches for built EFI files
- Verifies ACPIPatcher binaries
- Creates distribution packages
- Generates build information

## Configuration Files

### .pytool/CISettings.py
Stuart configuration file that defines:
- Package and platform settings
- Architecture and toolchain mappings
- Build targets and dependencies
- Unit test configurations

### pip-requirements.txt
Python dependencies required for the build:
```
edk2-pytool-extensions>=0.25.0
edk2-pytool-library>=0.19.0
```

## Usage

### Local Development
```bash
# Clone and setup
git clone --depth=1 -b edk2-stable202405 https://github.com/tianocore/edk2.git
cd edk2

# Copy ACPIPatcher
cp -r ../ACPIPatcher/ACPIPatcherPkg ./
cp -r ../ACPIPatcher/.pytool ./
cp ../ACPIPatcher/pip-requirements.txt ./

# Setup Python environment
python -m venv .venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate.bat

# Install dependencies
pip install --upgrade pip setuptools wheel
pip install --upgrade edk2-pytool-extensions
pip install -r pip-requirements.txt

# Initialize submodules
git submodule update --init --recommend-shallow BaseTools/Source/C/BrotliCompress/brotli CryptoPkg/Library/OpensslLib/openssl MdeModulePkg/Library/BrotliCustomDecompressLib/brotli UnitTestFrameworkPkg/Library/CmockaLib/cmocka

# Stuart build process
stuart_update -c .pytool/CISettings.py -a X64 -t RELEASE TOOL_CHAIN_TAG=VS2019
stuart_ci_build -c .pytool/CISettings.py -p ACPIPatcherPkg -a X64 -t RELEASE TOOL_CHAIN_TAG=VS2019
```

### CI/CD Integration
The Stuart workflow runs automatically on:
- Push to master/develop branches
- Pull requests to master
- Manual workflow dispatch

## Benefits Over Traditional Build

### Modern Dependency Management
- Automatic binary dependency downloads
- Version-controlled dependency specifications
- Isolated build environments

### Enhanced Testing
- Unit test support with NOOPT builds
- Comprehensive CI validation
- Multiple toolchain verification

### Improved Reliability
- Reproducible builds across environments
- Robust error handling
- Detailed build verification

### Better Automation
- Simplified CI/CD integration
- Automatic artifact generation
- Comprehensive build reporting

## Troubleshooting

### Common Issues

1. **Python Virtual Environment**
   - Ensure Python 3.11+ is available
   - Virtual environment activation may fail on some systems
   - Use appropriate activation script for your shell

2. **Dependency Installation**
   - Network issues may affect pip installations
   - Some packages may require specific versions
   - Regex module installation is optional but recommended

3. **EDK2 Submodules**
   - Git configuration may affect submodule initialization
   - Use shallow clones to reduce download time
   - Initialize only required submodules

4. **Stuart Commands**
   - Ensure virtual environment is activated
   - Check CISettings.py configuration
   - Verify package and platform names

### Build Failures
- Check build logs for specific error messages
- Verify toolchain installation and configuration
- Ensure all dependencies are properly installed
- Try alternative build methods if CI build fails

## Migration from Traditional Build

If migrating from traditional EDK2 build:
1. Install Stuart dependencies
2. Create or update CISettings.py
3. Update CI/CD workflows
4. Test build process thoroughly

## Future Enhancements

### Planned Features
- Cross-platform build support
- Advanced testing configurations
- Custom build targets
- Enhanced artifact packaging

### Performance Optimizations
- Cached dependency downloads
- Parallel build support
- Incremental build capabilities
- Optimized submodule handling

## References
- [TianoCore Stuart Documentation](https://edk2-pytool-extensions.readthedocs.io/)
- [EDK2 Build System](https://github.com/tianocore/edk2)
- [edk2-pytool-extensions](https://github.com/tianocore/edk2-pytool-extensions)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

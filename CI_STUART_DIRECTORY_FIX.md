# Stuart Configuration Directory Fix

## Issue Identified
The Stuart build system was configured incorrectly in the CI workflows:

1. **ci.yml**: Stuart was running from `edk2` directory but looking for `.pytool\CISettings.py` there without proper copying
2. **build-and-test.yml**: Stuart was running from `acpipatcher` directory but the Python virtual environment was created in the wrong location

## Root Cause
- The `.pytool/CISettings.py` configuration file is located in the ACPIPatcher root directory
- The Python virtual environment should be in the `edk2` directory where EDK2 builds occur
- Stuart commands need to run from the directory containing both the venv and the configuration

## Fixes Applied

### ci.yml
- Added explicit copying of Stuart configuration to `edk2` directory before running Stuart commands
- Ensured Stuart runs from `edk2` directory where the virtual environment is located
- Configuration path: `.pytool\CISettings.py` (relative to edk2 directory)

### build-and-test.yml  
- **Fixed Python Virtual Environment Setup**: Changed from `cd acpipatcher` to `cd edk2`
- **Fixed Stuart Build Step**: 
  - Changed from running in `acpipatcher` to running in `edk2`
  - Added proper copying of Stuart configuration using `xcopy`
  - Added validation that configuration exists before running Stuart

### comprehensive-test.yml
- Already correctly configured (no changes needed)
- Properly runs from `edk2` directory and copies configuration

## Stuart Directory Structure
```
ACPIPatcher/              # Root project directory
├── .pytool/             # Stuart configuration (source)
│   └── CISettings.py
└── edk2/                # EDK2 build directory
    ├── .venv/           # Python virtual environment
    └── .pytool/         # Stuart configuration (copied)
        └── CISettings.py
```

## Stuart Command Execution
All Stuart commands now execute from the correct context:
1. Working directory: `edk2/`
2. Virtual environment: `edk2/.venv/`
3. Configuration file: `edk2/.pytool/CISettings.py`
4. Package location: `ACPIPatcherPkg/` (relative to edk2)

## Validation
- [x] YAML syntax validation passed for all workflows
- [x] Stuart configuration copying logic implemented
- [x] Virtual environment setup fixed
- [x] Directory structure aligned with Stuart expectations

## Expected Results
- Stuart builds should now execute successfully on Windows
- No more "configuration file not found" errors
- Proper virtual environment activation
- Correct package discovery and building

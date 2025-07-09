# Stuart Build System Command Format Fix - Complete

## Issue Identified
The Stuart build commands were using incorrect parameter format across all workflows, which would cause build failures.

## Incorrect Format (Before)
```bash
# WRONG - TOOL_CHAIN_TAG in wrong position, missing -p parameter
stuart_update -c .pytool\CISettings.py TOOL_CHAIN_TAG=VS2022 -a X64 -t RELEASE
stuart_ci_build -c .pytool\CISettings.py TOOL_CHAIN_TAG=VS2022 -a X64 -t RELEASE
```

## Correct Format (After)
```bash
# CORRECT - Following Stuart documentation format
stuart_update -c .pytool\CISettings.py -a X64 -t RELEASE TOOL_CHAIN_TAG=VS2022
stuart_ci_build -c .pytool\CISettings.py -p ACPIPatcherPkg -a X64 -t RELEASE TOOL_CHAIN_TAG=VS2022
```

## Stuart Documentation Reference
Based on the official Stuart documentation example:
```bash
stuart_ci_build -c .pytool/CISettings.py -p MdeModulePkg -a IA32,X64 TOOL_CHAIN_TAG=VS2019
```

**Key Requirements:**
1. **Configuration file**: `-c .pytool/CISettings.py` (first parameter)
2. **Package parameter**: `-p ACPIPatcherPkg` (required for stuart_ci_build)
3. **Architecture**: `-a X64` or `-a IA32`
4. **Build type**: `-t DEBUG` or `-t RELEASE`
5. **Toolchain**: `TOOL_CHAIN_TAG=VS2022` (last parameter, no dash prefix)

## Files Fixed

### ✅ `.github/workflows/ci.yml`
```yaml
# Stuart update command
stuart_update -c .pytool\CISettings.py -a ${{ matrix.arch }} -t ${{ matrix.build_type }} TOOL_CHAIN_TAG=$toolchain

# Stuart CI build command  
stuart_ci_build -c .pytool\CISettings.py -p ACPIPatcherPkg -a ${{ matrix.arch }} -t ${{ matrix.build_type }} TOOL_CHAIN_TAG=$toolchain
```

### ✅ `.github/workflows/build-and-test.yml`
```yaml
# Stuart update command
stuart_update -c .pytool\CISettings.py -a ${{ matrix.arch }} -t ${{ matrix.build_type }} TOOL_CHAIN_TAG=VS2022

# Stuart CI build command
stuart_ci_build -c .pytool\CISettings.py -p ACPIPatcherPkg -a ${{ matrix.arch }} -t ${{ matrix.build_type }} TOOL_CHAIN_TAG=VS2022
```

### ✅ `.github/workflows/comprehensive-test.yml`
```yaml
# Stuart update command
stuart_update -c .pytool\CISettings.py -a ${{ matrix.arch }} -t ${{ matrix.build_type }} TOOL_CHAIN_TAG=${{ matrix.toolchain }}

# Stuart CI build command
stuart_ci_build -c .pytool\CISettings.py -p ACPIPatcherPkg -a ${{ matrix.arch }} -t ${{ matrix.build_type }} TOOL_CHAIN_TAG=${{ matrix.toolchain }}
```

## Key Changes Made

### 1. Parameter Order Correction
- **Before**: `TOOL_CHAIN_TAG=VS2022 -a X64 -t RELEASE`
- **After**: `-a X64 -t RELEASE TOOL_CHAIN_TAG=VS2022`

### 2. Added Missing Package Parameter
- **Before**: `stuart_ci_build -c .pytool\CISettings.py ...` (missing `-p`)
- **After**: `stuart_ci_build -c .pytool\CISettings.py -p ACPIPatcherPkg ...`

### 3. Removed Duplicate Commands
- Removed duplicate `stuart_update` calls in `build-and-test.yml`

### 4. Consistent Format Across All Workflows
- All three workflows now use the same Stuart command format
- Commands follow the official Stuart documentation pattern

## Expected Results

With these fixes, Stuart build commands should now:

✅ **Parse correctly**: Parameters in the right order and format
✅ **Find the package**: `-p ACPIPatcherPkg` tells Stuart which package to build
✅ **Use correct toolchain**: `TOOL_CHAIN_TAG=VS2022` at the end as documented
✅ **Build successfully**: Proper integration with ACPIPatcher's `.pytool/CISettings.py`

## Testing Validation

The Stuart commands can be tested locally with:
```bash
# Navigate to the project root where .pytool exists
cd /path/to/ACPIPatcher

# Test Stuart update
stuart_update -c .pytool/CISettings.py -a X64 -t RELEASE TOOL_CHAIN_TAG=VS2022

# Test Stuart CI build  
stuart_ci_build -c .pytool/CISettings.py -p ACPIPatcherPkg -a X64 -t RELEASE TOOL_CHAIN_TAG=VS2022
```

## Configuration Compatibility

The commands are compatible with the existing:
- ✅ `.pytool/CISettings.py` (Stuart configuration)
- ✅ `ACPIPatcherPkg/ACPIPatcherPkg.dsc` (Package description)
- ✅ `pip-requirements.txt` (Stuart dependencies)

## Commit History
- `5025b41`: Fix Stuart command format in ci.yml and comprehensive-test.yml
- `58cc8f7`: Fix Stuart command format in build-and-test.yml

**Status**: ✅ **COMPLETE** - All Stuart commands now follow correct documentation format

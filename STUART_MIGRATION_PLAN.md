# Stuart Build Migration Plan for ACPIPatcher

## Overview
Stuart is TianoCore's modern build system that provides:
- Robust Python virtual environment management
- Automatic dependency management
- Comprehensive CI/CD integration
- Cross-platform build consistency
- Better error handling and debugging

## Current State
- EDK2 version: edk2-stable202405
- No native Stuart support in current EDK2 version
- Using traditional EDK2 build system with manual setup

## Migration Strategy

### Phase 1: Stuart-Inspired Build Process
Since our EDK2 version doesn't have native Stuart support, we'll implement Stuart principles:

1. **Python Virtual Environment**
   - Create isolated Python environment per build
   - Install required dependencies (edk2-pytool-library, edk2-pytool-extensions)
   - Ensure consistent Python environment across builds

2. **Dependency Management**
   - Use pip to install EDK2 Python tools
   - Automatic BaseTools compilation
   - Structured dependency resolution

3. **Simplified Build Commands**
   - Replace complex batch logic with Python-based tools
   - Use edk2-pytool-library for environment setup
   - Leverage edk2-pytool-extensions for build automation

### Phase 2: Full Stuart Migration (Future)
When upgrading to newer EDK2 versions:
- Use native `.pytool/CISettings.py` configuration
- Migrate to `stuart_setup`, `stuart_update`, `stuart_ci_build` commands
- Remove custom build logic

## Implementation Plan

### Windows Build Modernization
```yaml
- name: Setup Python Virtual Environment (Windows)
  if: matrix.os == 'windows'
  shell: pwsh
  run: |
    cd edk2
    python -m venv .venv
    .\.venv\Scripts\Activate.ps1
    python -m pip install --upgrade pip
    pip install edk2-pytool-library edk2-pytool-extensions

- name: Build with EDK2 Python Tools (Windows)
  if: matrix.os == 'windows'  
  shell: pwsh
  run: |
    cd edk2
    .\.venv\Scripts\Activate.ps1
    python BaseTools/BinWrappers/PosixLike/build --help
    # Use Python-based build tools instead of batch scripts
```

### Benefits
- **Reliability**: Python virtual environment eliminates dependency conflicts
- **Consistency**: Same Python toolchain across all builds
- **Debugging**: Better error messages and logging
- **Maintenance**: Simpler CI configuration
- **Future-proof**: Easy migration to full Stuart when available

### Backwards Compatibility
- Maintain existing Linux/macOS builds unchanged
- Keep fallback to traditional build system if Stuart fails
- Gradual migration with monitoring

## Files to Modify
- `.github/workflows/build-and-test.yml`
- `.github/workflows/ci.yml` 
- `.github/workflows/comprehensive-test.yml`

## Testing Strategy
1. Test Windows builds with Stuart-inspired approach
2. Verify all architectures (X64, IA32) work
3. Validate both DEBUG and RELEASE builds
4. Monitor for improved reliability
5. Document any issues and solutions

## Timeline
- Phase 1: Immediate (current sprint)
- Phase 2: When upgrading EDK2 version (future)

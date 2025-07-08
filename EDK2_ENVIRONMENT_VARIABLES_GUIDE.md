# EDK2 Environment Variables Guide for MSYS2 Migration

## Overview
This guide explains how to suppress EDK2 environment setup warnings by setting the required environment variables when using the msys2/setup-msys2 action.

## The Warnings
When running `edksetup.bat`, EDK2 displays these warnings if environment variables are not set:

```
!!! WARNING !!! NASM_PREFIX environment variable is not set
  Attempting to build modules that require NASM will fail.

!!! WARNING !!! CLANG_BIN environment variable is not set
  Found LLVM, setting CLANG_BIN environment variable to C:\Program Files\LLVM\bin\

!!! WARNING !!! No CYGWIN_HOME set, gcc build may not be used !!!
```

## Solution: Pre-set Environment Variables

Add this step **before** any EDK2 operations (like calling `edksetup.bat`) in your Windows workflows:

```yaml
- name: Set EDK2 Environment Variables for Windows
  shell: pwsh
  run: |
    # Set EDK2 environment variables to suppress warnings
    $msys2Root = "D:\a\_temp\msys64"
    if (-not (Test-Path $msys2Root)) {
      $msys2Root = "C:\msys64"
    }
    
    echo "Setting EDK2 environment variables..."
    echo "NASM_PREFIX=$msys2Root\usr\bin\" | Out-File -FilePath $env:GITHUB_ENV -Encoding utf8 -Append
    echo "CLANG_BIN=$msys2Root\mingw64\bin\" | Out-File -FilePath $env:GITHUB_ENV -Encoding utf8 -Append
    echo "CYGWIN_HOME=$msys2Root" | Out-File -FilePath $env:GITHUB_ENV -Encoding utf8 -Append
    
    echo "Environment variables set:"
    echo "NASM_PREFIX=$msys2Root\usr\bin\"
    echo "CLANG_BIN=$msys2Root\mingw64\bin\"
    echo "CYGWIN_HOME=$msys2Root"
```

## Environment Variables Explained

| Variable | Purpose | Value for MSYS2 |
|----------|---------|------------------|
| `NASM_PREFIX` | Path to NASM assembler directory | `{MSYS2_ROOT}\usr\bin\` |
| `CLANG_BIN` | Path to Clang compiler directory | `{MSYS2_ROOT}\mingw64\bin\` |
| `CYGWIN_HOME` | Path to Unix-like environment root | `{MSYS2_ROOT}` |

## Verification Step (Optional)

Add this step to verify the environment variables are set correctly:

```yaml
- name: Verify EDK2 Environment Variables
  shell: cmd
  run: |
    echo === Verifying EDK2 Environment Variables ===
    echo NASM_PREFIX=%NASM_PREFIX%
    echo CLANG_BIN=%CLANG_BIN%
    echo CYGWIN_HOME=%CYGWIN_HOME%
    echo.
    
    REM Test if the paths actually exist and contain the expected tools
    if exist "%NASM_PREFIX%nasm.exe" (
      echo ✓ NASM found at: %NASM_PREFIX%nasm.exe
    ) else (
      echo ✗ NASM not found at: %NASM_PREFIX%nasm.exe
    )
    
    if exist "%CLANG_BIN%clang.exe" (
      echo ✓ Clang found at: %CLANG_BIN%clang.exe
    ) else (
      echo ✗ Clang not found at: %CLANG_BIN%clang.exe
    )
    
    if exist "%CYGWIN_HOME%" (
      echo ✓ CYGWIN_HOME directory exists: %CYGWIN_HOME%
    ) else (
      echo ✗ CYGWIN_HOME directory not found: %CYGWIN_HOME%
    )
```

## Benefits

1. **Suppresses warnings**: No more EDK2 environment variable warnings
2. **Consistent paths**: EDK2 knows exactly where to find tools
3. **Better debugging**: Clear indication of tool locations
4. **Cross-shell compatibility**: Works from both MSYS2 and Windows batch

## Integration into Workflows

Apply this pattern to:
- `build-and-test.yml` (already migrated)
- `ci.yml` (pending migration)
- `comprehensive-test.yml` (pending migration)

Add the environment variable step immediately after the `msys2/setup-msys2` action and before any EDK2 operations.

## Testing

The `test-msys2-action.yml` workflow includes validation of this approach. Run it with `test_mode: 'full-build'` to see the environment variables in action and verify they suppress the EDK2 warnings.

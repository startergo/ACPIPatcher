# ACPIPatcher Debug Guide

## Overview
The enhanced ACPIPatcher includes comprehensive debugging capabilities to help troubleshoot ACPI patching issues. This guide explains how to use the debugging features effectively.

## Debug Levels

The application supports four debug levels that can be controlled at compile time:

### Debug Level Constants
```c
#define DEBUG_ERROR   1  // Only critical errors
#define DEBUG_WARN    2  // Warnings and errors
#define DEBUG_INFO    3  // General information (default)
#define DEBUG_VERBOSE 4  // Detailed debugging information
```

### Setting Debug Level
To change the debug level, modify the `DEBUG_LEVEL` constant in the source code:
```c
#define DEBUG_LEVEL DEBUG_VERBOSE  // For maximum debugging output
```

Or use compiler flags:
```
-DDEBUG_LEVEL=4
```

## Debug Output Categories

### 1. ERROR Level Output
- Critical failures that prevent operation
- Invalid parameters or corrupted data
- File system errors
- Memory allocation failures

Example output:
```
[ERROR] Could not find RSDP: 0x8000000000000003
[ERROR] Invalid ACPI table in file SSDT-1.aml: 0x8000000000000002
[ERROR] Failed to allocate memory for FileInfo: 0x8000000000000009
```

### 2. WARN Level Output
- Non-critical issues that may affect functionality
- Checksum validation failures
- Maximum table limits reached
- Missing optional components

Example output:
```
[WARN]  ACPI table checksum validation failed (0x42)
[WARN]  Maximum XSDT entries reached (32), skipping SSDT-Extra.aml
[WARN]  FADT not found in XSDT (scanned 15 entries)
```

### 3. INFO Level Output
- General progress information
- File processing status
- Table counts and summaries
- Major operation milestones

Example output:
```
[INFO]  === ACPIPatcher v1.1 Starting ===
[INFO]  Processing file: DSDT.aml (16384 bytes)
[INFO]  Found FADT at address: 0x7FF8A000
[INFO]  ACPI patching summary:
[INFO]    Files processed: 5
[INFO]    Tables added/replaced: 4
```

### 4. VERBOSE Level Output
- Detailed memory addresses and pointers
- Complete table information
- Step-by-step operation details
- Memory dumps for analysis

Example output:
```
[DEBUG] XSDT contains 12 entries
[DEBUG] Scanning entries starting at 0x7FF8B040
[DEBUG]   Entry 0: 0x7FF8C000 -> Signature: FACP, Length: 276
[DEBUG]   FADT length: 276 bytes
[DEBUG]   Current DSDT (64-bit): 0x7FF8D000
[DEBUG] Memory dump at 0x7FF8C000 (64 bytes):
[DEBUG] 7ff8c000: 46 41 43 50 14 01 00 00 06 9e 49 4e 54 45 4c 20  |FACP......INTEL |
```

## Troubleshooting Common Issues

### Issue: RSDP Not Found
**Symptoms:**
```
[ERROR] Could not find RSDP: 0x8000000000000003
```

**Debug Steps:**
1. Set debug level to VERBOSE
2. Check if system supports ACPI 2.0+
3. Verify UEFI boot mode (not legacy BIOS)

### Issue: Invalid ACPI Tables
**Symptoms:**
```
[ERROR] Invalid ACPI table in file DSDT.aml: 0x8000000000000002
[WARN]  ACPI table checksum validation failed (0x42)
```

**Debug Steps:**
1. Enable VERBOSE debugging to see table details
2. Check the hex dump output for table structure
3. Verify .aml file was compiled correctly
4. Ensure file is not truncated or corrupted

**Example verbose output:**
```
[DEBUG] Validating ACPI table at 0x7FF8E000, size 16384 bytes
[DEBUG]   Table signature: DSDT
[DEBUG]   Table length: 16320 bytes
[DEBUG]   Table revision: 2
[DEBUG]   OEM ID: CUSTOM
[DEBUG]   Calculated checksum: 0x42
```

### Issue: Directory Access Problems
**Symptoms:**
```
[ERROR] Could not open ACPI folder: 0x800000000000000E
[ERROR] Failed to open file DSDT.aml: 0x800000000000000E
```

**Debug Steps:**
1. Verify 'ACPI' directory exists in same location as executable
2. Check file permissions and attributes
3. Ensure .aml files are present and readable

**Example verbose output:**
```
[DEBUG] Current directory located at: 0x7FF8F000
[DEBUG] Found directory entry: DSDT.aml
[DEBUG]   File size: 16384 bytes
[DEBUG]   Attributes: 0x0000000000000020
```

### Issue: Memory Allocation Failures
**Symptoms:**
```
[ERROR] Failed to allocate memory for FileInfo: 0x8000000000000009
```

**Debug Steps:**
1. Check available memory in UEFI environment
2. Reduce number of tables being processed
3. Verify system has sufficient RAM

### Issue: XSDT Table Limit Reached
**Symptoms:**
```
[WARN]  Maximum XSDT entries reached (32), skipping SSDT-Extra.aml
```

**Debug Steps:**
1. Review current table count: `[INFO] XSDT contains 28 table entries`
2. Prioritize which tables are most important
3. Consider increasing `MAX_ADDITIONAL_TABLES` constant

## Memory Analysis

### Hex Dump Interpretation
When VERBOSE debugging is enabled, hex dumps show the raw memory content:

```
[DEBUG] Memory dump at 0x7FF8C000 (64 bytes):
[DEBUG] 7ff8c000: 46 41 43 50 14 01 00 00 06 9e 49 4e 54 45 4c 20  |FACP......INTEL |
[DEBUG] 7ff8c010: 20 20 20 20 07 04 00 00 49 4e 54 45 4c 20 20 20  |    ....INTEL   |
[DEBUG] 7ff8c020: 13 20 11 20 49 4e 54 4c 28 05 18 20 00 00 fe bf  |. . INTL(.. ....|
[DEBUG] 7ff8c030: 01 02 00 00 00 10 00 00 00 00 00 00 fd f9 00 00  |................|
```

**Format:** `address: hex_bytes | ascii_representation |`

### Key Memory Addresses
- **RSDP Address:** Root System Description Pointer location
- **XSDT Address:** Extended System Description Table location  
- **FADT Address:** Fixed ACPI Description Table location
- **Table Buffers:** Loaded .aml file locations in memory

## Performance Monitoring

### Processing Statistics
The application provides detailed statistics:

```
[INFO]  ACPI patching summary:
[INFO]    Files processed: 5
[INFO]    Files skipped: 2
[INFO]    Tables added/replaced: 4
[INFO]    Final XSDT entries: 16
```

### Memory Usage Tracking
VERBOSE mode shows memory allocations:

```
[DEBUG] Allocated FileInfo buffer: 0x7FF8A000 (1536 bytes)
[DEBUG] File read to buffer at 0x7FF8E000
[DEBUG] Cleaning up FileInfo buffer
```

## Log Analysis Tips

1. **Start with INFO level** for general troubleshooting
2. **Use VERBOSE only when needed** - generates large amounts of output
3. **Look for ERROR/WARN patterns** to identify specific issues
4. **Check memory addresses** for consistency across operations
5. **Verify table signatures and sizes** match expectations

## Debugging Configuration

### Recommended Debug Settings
For development:
```c
#define DEBUG_LEVEL DEBUG_VERBOSE
```

For production:
```c
#define DEBUG_LEVEL DEBUG_WARN
```

For silent operation:
```c
#define DEBUG_LEVEL DEBUG_ERROR
```

### Build Integration
The debug system integrates with existing UEFI build processes and requires no additional libraries beyond the standard EDK II framework.

## Common Error Codes

| Error Code | Meaning | Typical Cause |
|------------|---------|---------------|
| 0x8000000000000002 | EFI_INVALID_PARAMETER | Corrupted ACPI table |
| 0x8000000000000003 | EFI_UNSUPPORTED | ACPI not available |
| 0x8000000000000009 | EFI_OUT_OF_RESOURCES | Memory allocation failed |
| 0x800000000000000E | EFI_NOT_FOUND | File/directory not found |
| 0x8000000000000005 | EFI_BUFFER_TOO_SMALL | Insufficient buffer space |

This debugging system provides comprehensive visibility into the ACPI patching process, making it much easier to diagnose and resolve issues in various environments.

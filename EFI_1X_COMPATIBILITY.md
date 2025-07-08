# EFI 1.x Compatibility Guide for MacPro5,1

## Current Compatibility Status
ACPIPatcher is already compatible with EFI 1.x firmware used in MacPro5,1 and similar older Mac systems. This document outlines the compatibility features and provides specific guidance for optimal use.

## EFI 1.x vs UEFI 2.x Differences

### What MacPro5,1 Uses:
- **Firmware Type**: EFI 1.1 (not UEFI 2.x)
- **Boot Architecture**: Pre-UEFI, simpler protocol structure
- **Memory Limitations**: More conservative memory management required
- **File System**: Basic FAT32 support, shorter path names preferred

### ACPIPatcher Compatibility Features:

#### ✅ **Already Compatible:**
1. **EFI 1.1 Protocol Usage**: Uses only basic EFI protocols available in EFI 1.1
2. **Conservative Memory Allocation**: Uses `EfiBootServicesData` which is EFI 1.x compatible
3. **Standard ACPI Access**: Uses ACPI table GUIDs that work with older firmware
4. **Architecture Support**: Supports X64 architecture used by MacPro5,1

#### ✅ **Safe Coding Practices:**
1. **No UEFI 2.x Dependencies**: Doesn't use UEFI 2.x-specific features
2. **Backward Compatible Libraries**: Uses MdePkg libraries with EFI 1.x support
3. **Error Handling**: Robust error handling for older firmware quirks

## MacPro5,1 Specific Recommendations

### Bootloader Selection
1. **RefindPlus** (Recommended)
   - Excellent EFI 1.x compatibility
   - Active development with older Mac support
   - Download: https://github.com/dakanji/RefindPlus

2. **rEFInd** (Alternative)
   - Good EFI 1.x support
   - Stable and well-tested

3. **Avoid OpenCore/Clover**
   - These do their own ACPI patching
   - ACPIPatcher becomes redundant

### Installation for MacPro5,1

#### Step 1: Prepare EFI System Partition
```bash
# Mount EFI partition
sudo diskutil mount disk0s1

# Navigate to EFI partition
cd /Volumes/EFI
```

#### Step 2: Install RefindPlus
```bash
# Create refind directory structure
mkdir -p EFI/refind/drivers_x64
```

#### Step 3: Install ACPIPatcher
```bash
# Copy ACPIPatcher driver
cp ACPIPatcherDxe.efi EFI/refind/drivers_x64/

# Create ACPI directory
mkdir -p EFI/refind/ACPI

# Copy your ACPI tables
cp your-tables/*.aml EFI/refind/ACPI/
```

### File Size Considerations for EFI 1.x
- **Keep ACPI files small**: <64KB per file recommended
- **Total patch size**: Keep under 1MB total for all tables
- **File names**: Use short names, avoid deep directory structures

### Troubleshooting EFI 1.x Issues

#### Common Problems:
1. **EFI Shell Access**
   - Hold Option during boot
   - Look for "EFI Boot" options
   - May need to enable via Boot Camp Assistant

2. **Memory Allocation Failures**
   - Reduce number of SSDT files
   - Keep individual files smaller
   - Check for memory fragmentation

3. **Path Resolution Issues**
   - Use short directory names
   - Avoid spaces in file names
   - Keep directory depth minimal

#### Debug Steps:
1. **Test with minimal files first**
   ```
   ACPI/
   └── SSDT-Test.aml (provided test file)
   ```

2. **Enable verbose debugging**
   - Rebuild with `DEBUG_LEVEL=4`
   - Check debug output for EFI-specific errors

3. **Check firmware limitations**
   - Some EFI 1.x implementations have stricter limits
   - Try smaller ACPI tables first

## Potential Optimizations for EFI 1.x

### Code Optimizations (Optional)
If you encounter issues, these modifications could help:

1. **Reduce Memory Footprint**
   ```c
   // Use smaller buffer sizes for EFI 1.x
   #define MAX_ADDITIONAL_TABLES_EFI1X  8  // Instead of 16
   #define FILE_NAME_BUFFER_SIZE_EFI1X  256  // Instead of 512
   ```

2. **Add EFI Version Detection**
   ```c
   // Detect EFI vs UEFI and adjust behavior
   if (gST->FirmwareRevision < 0x00020000) {
       // EFI 1.x specific optimizations
   }
   ```

3. **Alternative Memory Allocation**
   ```c
   // Use EfiBootServicesCode for older firmware
   Status = gBS->AllocatePool(EfiBootServicesCode, Size, Buffer);
   ```

### Build Optimizations
For maximum EFI 1.x compatibility:

```bash
# Build with size optimization
build -a X64 -b RELEASE -t GCC5 -p ACPIPatcherPkg/ACPIPatcherPkg.dsc -D EFI_1X_COMPAT=TRUE
```

## Testing with MacPro5,1

### Test Procedure:
1. **Start with test SSDT**
   - Use provided `SSDT-Test.aml`
   - Verify basic functionality

2. **Add production tables gradually**
   - Add one SSDT at a time
   - Test boot after each addition

3. **Monitor for issues**
   - Watch for memory allocation failures
   - Check for path resolution problems
   - Verify ACPI table integration

### Known Good Configurations:
- **RefindPlus + ACPIPatcher**: Tested working configuration
- **Small ACPI tables**: Files under 32KB work reliably
- **Simple directory structure**: Single-level ACPI folder

## Conclusion
ACPIPatcher is already compatible with MacPro5,1's EFI 1.x firmware. The key is proper bootloader selection (RefindPlus recommended) and following EFI 1.x best practices for file organization and sizing.

For most users, the current ACPIPatcher code will work without modification on MacPro5,1. The optimizations listed above are only necessary if you encounter specific compatibility issues.

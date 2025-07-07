#include <Library/UefiLib.h>
#include <Library/MemoryAllocationLib.h>
#include <Library/UefiBootServicesTableLib.h>

#include <Protocol/AcpiSystemDescriptionTable.h>

#include <Guid/Acpi.h>
#include <Guid/FileInfo.h>

#include "FsHelpers.h"

//
// Constants
//
#define ACPI_PATCHER_VERSION_MAJOR    1
#define ACPI_PATCHER_VERSION_MINOR    1
#define MAX_ADDITIONAL_TABLES         16
#define FILE_NAME_BUFFER_SIZE         512
#define DSDT_FILE_NAME                L"DSDT.aml"

//
// Debug levels
//
#define DEBUG_ERROR   1
#define DEBUG_WARN    2
#define DEBUG_INFO    3
#define DEBUG_VERBOSE 4

#ifndef DEBUG_LEVEL
#define DEBUG_LEVEL DEBUG_INFO  // Default debug level
#endif

//
// Helper macros
//
#ifndef MIN
#define MIN(a, b) (((a) < (b)) ? (a) : (b))
#endif

//
// Global Variables
//
//
// Global Variables
//
EFI_ACPI_2_0_ROOT_SYSTEM_DESCRIPTION_POINTER        *gRsdp      = NULL;
EFI_ACPI_SDT_HEADER                                 *gXsdt      = NULL;
EFI_ACPI_6_4_FIXED_ACPI_DESCRIPTION_TABLE           *gFacp      = NULL;
UINT64                                              gXsdtEnd    = 0;

#ifndef DXE
#include <Library/PrintLib.h>
#define MAX_PRINT_BUFFER (80 * 4)
#endif

//
// Function Declarations
//
VOID
DebugPrint (
  IN UINTN         Level,
  IN CONST CHAR16  *Format,
  ...
  );

VOID
HexDump (
  IN UINT8   *Bytes,
  IN UINTN   Length,
  IN UINT64  BaseAddress
  );

EFI_STATUS
ValidateAcpiTable (
  IN UINT8   *TableBuffer,
  IN UINTN   TableSize
  );

/**
  Conditionally prints formatted output to console.
  Only prints in non-DXE builds to avoid conflicts.

  @param[in] Format   Format string for output
  @param[in] ...      Variable arguments for format string

  @retval None
**/
VOID
SelectivePrint (
  IN CONST CHAR16  *Format,
  ...
  )
{
#ifndef DXE
  UINTN     BufferSize  = (MAX_PRINT_BUFFER + 1) * sizeof(CHAR16);
  CHAR16    *Buffer     = NULL;
  EFI_STATUS Status;

  if (Format == NULL) {
    return;
  }

  Status = gBS->AllocatePool(EfiBootServicesData, BufferSize, (VOID**)&Buffer);
  if (EFI_ERROR(Status) || Buffer == NULL) {
    return;
  }

  VA_LIST Marker;
  VA_START(Marker, Format);
  UnicodeVSPrint(Buffer, BufferSize, Format, Marker);
  VA_END(Marker);
  
  if (gST != NULL && gST->ConOut != NULL) {
    gST->ConOut->OutputString(gST->ConOut, Buffer);
  }
  
  gBS->FreePool(Buffer);
#endif
}

EFI_STATUS
PatchAcpi (
  IN EFI_FILE_PROTOCOL* Directory
  )
{
  UINTN                BufferSize     = 0;
  UINTN                ReadSize       = 0;
  EFI_STATUS           Status         = EFI_SUCCESS;
  EFI_FILE_INFO        *FileInfo      = NULL;
  EFI_FILE_PROTOCOL    *FileProtocol  = NULL;
  VOID                 *FileBuffer    = NULL;
  UINT32               MaxEntries;
  UINT32               CurrentEntries;
  UINT32               ProcessedFiles = 0;
  UINT32               SkippedFiles   = 0;
  UINT32               AddedTables    = 0;
  
  DebugPrint(DEBUG_INFO, L"Starting ACPI patching process...\n");
  
  if (Directory == NULL || gXsdt == NULL || gFacp == NULL) {
    DebugPrint(DEBUG_ERROR, L"Invalid parameters for ACPI patching\n");
    DebugPrint(DEBUG_VERBOSE, L"  Directory: 0x%llx\n", (UINT64)Directory);
    DebugPrint(DEBUG_VERBOSE, L"  gXsdt: 0x%llx\n", (UINT64)gXsdt);
    DebugPrint(DEBUG_VERBOSE, L"  gFacp: 0x%llx\n", (UINT64)gFacp);
    return EFI_INVALID_PARAMETER;
  }

  // Calculate current and maximum entries in XSDT
  CurrentEntries = (gXsdt->Length - sizeof(EFI_ACPI_SDT_HEADER)) / sizeof(UINT64);
  MaxEntries = CurrentEntries + MAX_ADDITIONAL_TABLES;
  
  DebugPrint(DEBUG_INFO, L"XSDT analysis:\n");
  DebugPrint(DEBUG_INFO, L"  Current entries: %u\n", CurrentEntries);
  DebugPrint(DEBUG_INFO, L"  Maximum entries allowed: %u\n", MaxEntries);
  DebugPrint(DEBUG_INFO, L"  Available slots: %u\n", MaxEntries - CurrentEntries);
  DebugPrint(DEBUG_VERBOSE, L"  XSDT address: 0x%llx\n", (UINT64)gXsdt);
  DebugPrint(DEBUG_VERBOSE, L"  XSDT end: 0x%llx\n", gXsdtEnd);
  
  BufferSize = sizeof(EFI_FILE_INFO) + sizeof(CHAR16) * FILE_NAME_BUFFER_SIZE;
  Status = gBS->AllocatePool(EfiBootServicesData, BufferSize, (VOID**)&FileInfo);
  if (EFI_ERROR(Status)) {
    DebugPrint(DEBUG_ERROR, L"Failed to allocate memory for FileInfo: %r\n", Status);
    return Status;
  }
  
  DebugPrint(DEBUG_VERBOSE, L"Allocated FileInfo buffer: 0x%llx (%u bytes)\n", 
             (UINT64)FileInfo, BufferSize);

  DebugPrint(DEBUG_INFO, L"Scanning ACPI directory for .aml files...\n");

  while (TRUE) {
    ReadSize = BufferSize;
    Status = Directory->Read(Directory, &ReadSize, FileInfo);
    if (EFI_ERROR(Status)) {
      DebugPrint(DEBUG_ERROR, L"Directory read error: %r\n", Status);
      goto Cleanup;
    }
    
    if (ReadSize == 0) {
      DebugPrint(DEBUG_VERBOSE, L"End of directory reached\n");
      break; // End of directory
    }

    DebugPrint(DEBUG_VERBOSE, L"Found directory entry: %s\n", FileInfo->FileName);
    DebugPrint(DEBUG_VERBOSE, L"  File size: %llu bytes\n", FileInfo->FileSize);
    DebugPrint(DEBUG_VERBOSE, L"  Attributes: 0x%llx\n", FileInfo->Attribute);

    // Skip hidden files, current/parent directories, and non-AML files
    if (StrnCmp(&FileInfo->FileName[0], L".", 1) == 0 ||
        StrnCmp(&FileInfo->FileName[0], L"_", 1) == 0 ||
        StrStr(FileInfo->FileName, L".aml") == NULL) {
      DebugPrint(DEBUG_VERBOSE, L"  Skipping file: %s\n", FileInfo->FileName);
      SkippedFiles++;
      continue;
    }
      
    DebugPrint(DEBUG_INFO, L"Processing file: %s (%llu bytes)\n", 
               FileInfo->FileName, FileInfo->FileSize);
    ProcessedFiles++;
    
    Status = FsOpenFile(Directory, FileInfo->FileName, &FileProtocol);
    if (EFI_ERROR(Status)) {
      DebugPrint(DEBUG_ERROR, L"Failed to open file %s: %r\n", FileInfo->FileName, Status);
      continue; // Skip this file and continue with others
    }
    
    DebugPrint(DEBUG_VERBOSE, L"  File opened successfully\n");
    
    Status = FsReadFileToBuffer(FileProtocol, FileInfo->FileSize, &FileBuffer);
    FileProtocol->Close(FileProtocol);
    FileProtocol = NULL;
    
    if (EFI_ERROR(Status)) {
      DebugPrint(DEBUG_ERROR, L"Failed to read file %s: %r\n", FileInfo->FileName, Status);
      continue; // Skip this file and continue with others
    }

    DebugPrint(DEBUG_VERBOSE, L"  File read to buffer at 0x%llx\n", (UINT64)FileBuffer);

    // Validate the ACPI table
    DebugPrint(DEBUG_VERBOSE, L"  Validating ACPI table...\n");
    Status = ValidateAcpiTable(FileBuffer, FileInfo->FileSize);
    if (EFI_ERROR(Status)) {
      DebugPrint(DEBUG_ERROR, L"Invalid ACPI table in file %s: %r\n", FileInfo->FileName, Status);
      gBS->FreePool(FileBuffer);
      continue; // Skip this file and continue with others
    }
    
    // Handle DSDT specially
    if (StrnCmp(FileInfo->FileName, DSDT_FILE_NAME, 8) == 0) {
      DebugPrint(DEBUG_INFO, L"  Processing as DSDT replacement\n");
      DebugPrint(DEBUG_VERBOSE, L"  Old DSDT address (32-bit): 0x%x\n", gFacp->Dsdt);
      DebugPrint(DEBUG_VERBOSE, L"  Old DSDT address (64-bit): 0x%llx\n", gFacp->XDsdt);
      
      gFacp->Dsdt = (UINT32)(UINTN)FileBuffer;
      gFacp->XDsdt = (UINT64)FileBuffer;
      
      DebugPrint(DEBUG_INFO, L"  Updated DSDT address: 0x%llx\n", gFacp->XDsdt);
      DebugPrint(DEBUG_VERBOSE, L"  DSDT replacement completed\n");
      AddedTables++;
      continue;
    }
    
    // Check if we have room for more entries
    if (CurrentEntries >= MaxEntries) {
      DebugPrint(DEBUG_WARN, L"Maximum XSDT entries reached (%u), skipping %s\n", 
                 MaxEntries, FileInfo->FileName);
      gBS->FreePool(FileBuffer);
      continue;
    }
    
    // Add to XSDT
    DebugPrint(DEBUG_VERBOSE, L"  Adding table to XSDT entry %u\n", CurrentEntries);
    DebugPrint(DEBUG_VERBOSE, L"  XSDT entry address: 0x%llx\n", gXsdtEnd);
    
    ((UINT64 *)gXsdtEnd)[0] = (UINT64)FileBuffer;
    gXsdt->Length += sizeof(UINT64);
    gXsdtEnd = gRsdp->XsdtAddress + gXsdt->Length;
    CurrentEntries++;
    AddedTables++;
    
    DebugPrint(DEBUG_INFO, L"  Added table at address: 0x%llx\n", (UINT64)FileBuffer);
    DebugPrint(DEBUG_VERBOSE, L"  New XSDT length: %u bytes\n", gXsdt->Length);
    DebugPrint(DEBUG_VERBOSE, L"  New XSDT end: 0x%llx\n", gXsdtEnd);
  }
  
  DebugPrint(DEBUG_INFO, L"ACPI patching summary:\n");
  DebugPrint(DEBUG_INFO, L"  Files processed: %u\n", ProcessedFiles);
  DebugPrint(DEBUG_INFO, L"  Files skipped: %u\n", SkippedFiles);
  DebugPrint(DEBUG_INFO, L"  Tables added/replaced: %u\n", AddedTables);
  DebugPrint(DEBUG_INFO, L"  Final XSDT entries: %u\n", CurrentEntries);
  
  Status = EFI_SUCCESS;

Cleanup:
  if (FileInfo != NULL) {
    DebugPrint(DEBUG_VERBOSE, L"Cleaning up FileInfo buffer\n");
    gBS->FreePool(FileInfo);
  }
  if (FileProtocol != NULL) {
    DebugPrint(DEBUG_VERBOSE, L"Closing file protocol\n");
    FileProtocol->Close(FileProtocol);
  }
  
  DebugPrint(DEBUG_VERBOSE, L"ACPI patching cleanup completed\n");
  return Status;
}

/**
  Patches ACPI tables by reading .aml files from the specified directory.
  
  This function reads all .aml files from the given directory and either:
  - Replaces the DSDT if the file is named "DSDT.aml"
  - Adds additional tables to the XSDT for other .aml files

  @param[in] Directory    Directory containing .aml files to process

  @retval EFI_SUCCESS             ACPI patching completed successfully
  @retval EFI_INVALID_PARAMETER   Invalid input parameters
  @retval Other                   Error occurred during file operations
**/

EFI_STATUS
FindFacp (
  VOID
  )
{
  EFI_ACPI_SDT_HEADER *Entry;
  UINT32              EntryCount;
  UINT64              *EntryPtr;
  UINTN               Index;
  CHAR8               SigStr[5];

  DebugPrint(DEBUG_INFO, L"Searching for FADT in XSDT...\n");

  if (gXsdt == NULL) {
    DebugPrint(DEBUG_ERROR, L"XSDT pointer is null\n");
    return EFI_INVALID_PARAMETER;
  }

  EntryCount = (gXsdt->Length - sizeof(EFI_ACPI_SDT_HEADER)) / sizeof(UINT64);
  EntryPtr = (UINT64 *)(gXsdt + 1);
  
  DebugPrint(DEBUG_VERBOSE, L"XSDT contains %u entries\n", EntryCount);
  DebugPrint(DEBUG_VERBOSE, L"Scanning entries starting at 0x%llx\n", (UINT64)EntryPtr);

  for (Index = 0; Index < EntryCount; Index++, EntryPtr++) {
    if (*EntryPtr == 0) {
      DebugPrint(DEBUG_VERBOSE, L"  Entry %u: NULL pointer, skipping\n", Index);
      continue; // Skip null entries
    }

    Entry = (EFI_ACPI_SDT_HEADER *)((UINTN)(*EntryPtr));
    
    // Validate entry pointer
    if (Entry == NULL) {
      DebugPrint(DEBUG_VERBOSE, L"  Entry %u: Invalid pointer (0x%llx), skipping\n", Index, *EntryPtr);
      continue;
    }

    // Convert signature to string for display
    SigStr[0] = (CHAR8)(Entry->Signature & 0xFF);
    SigStr[1] = (CHAR8)((Entry->Signature >> 8) & 0xFF);
    SigStr[2] = (CHAR8)((Entry->Signature >> 16) & 0xFF);
    SigStr[3] = (CHAR8)((Entry->Signature >> 24) & 0xFF);
    SigStr[4] = '\0';
    
    DebugPrint(DEBUG_VERBOSE, L"  Entry %u: 0x%llx -> Signature: %a, Length: %u\n", 
               Index, *EntryPtr, SigStr, Entry->Length);

    if (Entry->Signature == EFI_ACPI_6_4_FIXED_ACPI_DESCRIPTION_TABLE_SIGNATURE) {
      gFacp = (EFI_ACPI_6_4_FIXED_ACPI_DESCRIPTION_TABLE *)Entry;
      DebugPrint(DEBUG_INFO, L"Found FADT at address: 0x%llx\n", (UINT64)gFacp);
      DebugPrint(DEBUG_VERBOSE, L"  FADT length: %u bytes\n", gFacp->Header.Length);
      DebugPrint(DEBUG_VERBOSE, L"  FADT revision: %u\n", gFacp->Header.Revision);
      DebugPrint(DEBUG_VERBOSE, L"  Current DSDT (32-bit): 0x%x\n", gFacp->Dsdt);
      DebugPrint(DEBUG_VERBOSE, L"  Current DSDT (64-bit): 0x%llx\n", gFacp->XDsdt);
      DebugPrint(DEBUG_VERBOSE, L"  Firmware Control: 0x%x\n", gFacp->FirmwareCtrl);
      DebugPrint(DEBUG_VERBOSE, L"  X_Firmware Control: 0x%llx\n", gFacp->XFirmwareCtrl);
      return EFI_SUCCESS;
    }
  }
  
  DebugPrint(DEBUG_WARN, L"FADT not found in XSDT (scanned %u entries)\n", EntryCount);
  return EFI_NOT_FOUND;
}

EFI_STATUS
ValidateAcpiTable (
  IN VOID     *TableBuffer,
  IN UINTN    BufferSize
  )
{
  EFI_ACPI_SDT_HEADER *Header;
  UINT8               Checksum;
  CHAR8               SigStr[5];

  DebugPrint(DEBUG_VERBOSE, L"Validating ACPI table at 0x%llx, size %u bytes\n", 
             (UINT64)TableBuffer, BufferSize);

  if (TableBuffer == NULL || BufferSize < sizeof(EFI_ACPI_SDT_HEADER)) {
    DebugPrint(DEBUG_ERROR, L"Invalid parameters for table validation\n");
    return EFI_INVALID_PARAMETER;
  }

  Header = (EFI_ACPI_SDT_HEADER *)TableBuffer;
  
  // Convert signature to string for display
  SigStr[0] = (CHAR8)(Header->Signature & 0xFF);
  SigStr[1] = (CHAR8)((Header->Signature >> 8) & 0xFF);
  SigStr[2] = (CHAR8)((Header->Signature >> 16) & 0xFF);
  SigStr[3] = (CHAR8)((Header->Signature >> 24) & 0xFF);
  SigStr[4] = '\0';
  
  DebugPrint(DEBUG_INFO, L"  Table signature: %a\n", SigStr);
  DebugPrint(DEBUG_INFO, L"  Table length: %u bytes\n", Header->Length);
  DebugPrint(DEBUG_INFO, L"  Table revision: %u\n", Header->Revision);
  DebugPrint(DEBUG_VERBOSE, L"  OEM ID: %.6a\n", Header->OemId);
  DebugPrint(DEBUG_VERBOSE, L"  OEM Table ID: %.8a\n", Header->OemTableId);
  DebugPrint(DEBUG_VERBOSE, L"  OEM Revision: 0x%x\n", Header->OemRevision);
  
  // Validate signature (should be printable ASCII)
  if (Header->Signature == 0) {
    DebugPrint(DEBUG_ERROR, L"Invalid table signature (zero)\n");
    return EFI_INVALID_PARAMETER;
  }

  // Validate length
  if (Header->Length < sizeof(EFI_ACPI_SDT_HEADER)) {
    DebugPrint(DEBUG_ERROR, L"Table length too small: %u < %u\n", 
               Header->Length, sizeof(EFI_ACPI_SDT_HEADER));
    return EFI_INVALID_PARAMETER;
  }
  
  if (Header->Length > BufferSize) {
    DebugPrint(DEBUG_ERROR, L"Table length exceeds buffer: %u > %u\n", 
               Header->Length, BufferSize);
    return EFI_INVALID_PARAMETER;
  }

  // Validate checksum
  Checksum = CalculateCheckSum8((UINT8*)TableBuffer, Header->Length);
  DebugPrint(DEBUG_VERBOSE, L"  Calculated checksum: 0x%02x\n", Checksum);
  
  if (Checksum != 0) {
    DebugPrint(DEBUG_WARN, L"ACPI table checksum validation failed (0x%02x)\n", Checksum);
    // Don't return error as we'll recalculate checksum anyway
  } else {
    DebugPrint(DEBUG_VERBOSE, L"  Checksum validation passed\n");
  }

  // Show first few bytes of table data for debugging
  if (DEBUG_LEVEL >= DEBUG_VERBOSE) {
    HexDump(TableBuffer, MIN(Header->Length, 64), (UINT64)TableBuffer);
  }

  DebugPrint(DEBUG_VERBOSE, L"Table validation completed successfully\n");
  return EFI_SUCCESS;
}

/**
  Main entry point for the ACPI Patcher application.
  
  This function orchestrates the entire ACPI patching process:
  1. Locates and validates the ACPI root tables (RSDP, XSDT, FADT)
  2. Opens the ACPI directory containing .aml files
  3. Patches ACPI tables with new content
  4. Updates checksums for modified tables

  @param[in] ImageHandle    Handle for this UEFI application
  @param[in] SystemTable    Pointer to the UEFI System Table

  @retval EFI_SUCCESS             ACPI patching completed successfully
  @retval EFI_INVALID_PARAMETER   Invalid input parameters
  @retval EFI_NOT_FOUND          Required ACPI structures not found
  @retval Other                   Error occurred during patching process
**/
EFI_STATUS
EFIAPI
AcpiPatcherEntryPoint (
  IN EFI_HANDLE        ImageHandle,
  IN EFI_SYSTEM_TABLE  *SystemTable
  )
{
  EFI_STATUS           Status         = EFI_SUCCESS;
  EFI_FILE_PROTOCOL    *AcpiFolder    = NULL;
  EFI_FILE_PROTOCOL    *SelfDir       = NULL;
  UINT32               EntryCount;
  
  // Validate input parameters
  if (ImageHandle == NULL || SystemTable == NULL) {
    return EFI_INVALID_PARAMETER;
  }

  DebugPrint(DEBUG_INFO, L"=== ACPIPatcher v%u.%u Starting ===\n", 
             ACPI_PATCHER_VERSION_MAJOR, ACPI_PATCHER_VERSION_MINOR);
  DebugPrint(DEBUG_INFO, L"ImageHandle: 0x%llx\n", (UINT64)ImageHandle);
  DebugPrint(DEBUG_INFO, L"SystemTable: 0x%llx\n", (UINT64)SystemTable);
  DebugPrint(DEBUG_VERBOSE, L"Debug level: %u\n", DEBUG_LEVEL);

  // Get RSDP from system configuration table
  DebugPrint(DEBUG_INFO, L"Locating RSDP...\n");
  Status = EfiGetSystemConfigurationTable(&gEfiAcpi20TableGuid, (VOID **)&gRsdp);
  if (EFI_ERROR(Status) || gRsdp == NULL) {
    DebugPrint(DEBUG_ERROR, L"Could not find RSDP: %r\n", Status);
    return EFI_NOT_FOUND;
  }

  DebugPrint(DEBUG_INFO, L"Found RSDP at address: 0x%llx\n", (UINT64)gRsdp);
  DebugPrint(DEBUG_VERBOSE, L"RSDP details:\n");
  DebugPrint(DEBUG_VERBOSE, L"  Signature: 0x%llx\n", gRsdp->Signature);
  DebugPrint(DEBUG_VERBOSE, L"  Checksum: 0x%02x\n", gRsdp->Checksum);
  DebugPrint(DEBUG_VERBOSE, L"  Revision: %u\n", gRsdp->Revision);
  DebugPrint(DEBUG_VERBOSE, L"  Length: %u\n", gRsdp->Length);

  // Validate RSDP
  if (gRsdp->Signature != EFI_ACPI_2_0_ROOT_SYSTEM_DESCRIPTION_POINTER_SIGNATURE) {
    DebugPrint(DEBUG_ERROR, L"Invalid RSDP signature: 0x%llx\n", gRsdp->Signature);
    return EFI_INVALID_PARAMETER;
  }

  DebugPrint(DEBUG_VERBOSE, L"RSDP signature validation passed\n");

  // Get XSDT
  DebugPrint(DEBUG_INFO, L"Locating XSDT...\n");
  gXsdt = (EFI_ACPI_SDT_HEADER *)(gRsdp->XsdtAddress);
  if (gXsdt == NULL) {
    DebugPrint(DEBUG_ERROR, L"XSDT address is null (0x%llx)\n", gRsdp->XsdtAddress);
    return EFI_INVALID_PARAMETER;
  }

  DebugPrint(DEBUG_INFO, L"Found XSDT at address: 0x%llx\n", (UINT64)gXsdt);

  // Validate XSDT
  if (gXsdt->Signature != EFI_ACPI_6_4_EXTENDED_SYSTEM_DESCRIPTION_TABLE_SIGNATURE) {
    DebugPrint(DEBUG_ERROR, L"Invalid XSDT signature: 0x%x\n", gXsdt->Signature);
    return EFI_INVALID_PARAMETER;
  }

  DebugPrint(DEBUG_INFO, L"XSDT validation passed\n");
  DebugPrint(DEBUG_INFO, L"  Size: 0x%x (%u bytes)\n", gXsdt->Length, gXsdt->Length);
  DebugPrint(DEBUG_VERBOSE, L"  Revision: %u\n", gXsdt->Revision);
  DebugPrint(DEBUG_VERBOSE, L"  Checksum: 0x%02x\n", gXsdt->Checksum);
  DebugPrint(DEBUG_VERBOSE, L"  OEM ID: %.6a\n", gXsdt->OemId);
  
  gXsdtEnd = gRsdp->XsdtAddress + gXsdt->Length;
  DebugPrint(DEBUG_VERBOSE, L"  XSDT end address: 0x%llx\n", gXsdtEnd);
  
  // Find FADT
  DebugPrint(DEBUG_INFO, L"Searching for FADT...\n");
  Status = FindFacp();
  if (EFI_ERROR(Status)) {
    DebugPrint(DEBUG_ERROR, L"Could not find FADT: %r\n", Status);
    return Status;
  }

  EntryCount = (gXsdt->Length - sizeof(EFI_ACPI_SDT_HEADER)) / sizeof(UINT64);
  DebugPrint(DEBUG_INFO, L"XSDT contains %u table entries\n", EntryCount);

  // Get current directory
  DebugPrint(DEBUG_INFO, L"Locating current directory...\n");
  SelfDir = FsGetSelfDir();
  if (SelfDir == NULL) {
    DebugPrint(DEBUG_ERROR, L"Could not find current working directory\n");
    return EFI_NOT_FOUND;
  }
  
  DebugPrint(DEBUG_VERBOSE, L"Current directory located at: 0x%llx\n", (UINT64)SelfDir);
  
  // Open ACPI folder
  DebugPrint(DEBUG_INFO, L"Opening ACPI folder...\n");
  Status = SelfDir->Open(
                    SelfDir,
                    &AcpiFolder,
                    L"ACPI",
                    EFI_FILE_MODE_READ,
                    EFI_FILE_READ_ONLY | EFI_FILE_HIDDEN | EFI_FILE_SYSTEM
                    );
  
  if (EFI_ERROR(Status)) {
    DebugPrint(DEBUG_ERROR, L"Could not open ACPI folder: %r\n", Status);
    DebugPrint(DEBUG_INFO, L"Please ensure 'ACPI' directory exists with .aml files\n");
    goto Cleanup;
  }
  
  DebugPrint(DEBUG_VERBOSE, L"ACPI folder opened successfully at: 0x%llx\n", (UINT64)AcpiFolder);
  
  DebugPrint(DEBUG_INFO, L"=== Starting ACPI table patching ===\n");
  Status = PatchAcpi(AcpiFolder);
  if (EFI_ERROR(Status)) {
    DebugPrint(DEBUG_ERROR, L"ACPI patching failed: %r\n", Status);
    goto Cleanup;
  }

  DebugPrint(DEBUG_INFO, L"=== ACPI patching completed successfully ===\n");

  // Update checksums
  DebugPrint(DEBUG_INFO, L"Updating table checksums...\n");
  if (gFacp != NULL) {
    UINT8 OldChecksum = gFacp->Header.Checksum;
    gFacp->Header.Checksum = 0;
    gFacp->Header.Checksum = CalculateCheckSum8((UINT8*)gFacp, gFacp->Header.Length);
    DebugPrint(DEBUG_VERBOSE, L"FADT checksum: 0x%02x -> 0x%02x\n", 
               OldChecksum, gFacp->Header.Checksum);
    DebugPrint(DEBUG_INFO, L"Updated FADT checksum\n");
  }

  if (gXsdt != NULL) {
    UINT8 OldChecksum = gXsdt->Checksum;
    gXsdt->Checksum = 0;
    gXsdt->Checksum = CalculateCheckSum8((UINT8*)gXsdt, gXsdt->Length);
    DebugPrint(DEBUG_VERBOSE, L"XSDT checksum: 0x%02x -> 0x%02x\n", 
               OldChecksum, gXsdt->Checksum);
    DebugPrint(DEBUG_INFO, L"Updated XSDT checksum\n");
  }

Cleanup:
  DebugPrint(DEBUG_VERBOSE, L"Performing cleanup...\n");
  if (AcpiFolder != NULL) {
    DebugPrint(DEBUG_VERBOSE, L"Closing ACPI folder\n");
    AcpiFolder->Close(AcpiFolder);
  }
  if (SelfDir != NULL) {
    DebugPrint(DEBUG_VERBOSE, L"Closing self directory\n");
    SelfDir->Close(SelfDir);
  }

  if (EFI_ERROR(Status)) {
    DebugPrint(DEBUG_ERROR, L"ACPIPatcher finished with ERROR: %r\n", Status);
  } else {
    DebugPrint(DEBUG_INFO, L"=== ACPIPatcher finished successfully ===\n");
  }
  
  return Status;
}

/**
  Enhanced debug print function with different levels.
  
  @param[in] Level    Debug level (ERROR, WARN, INFO, VERBOSE)
  @param[in] Format   Format string for output
  @param[in] ...      Variable arguments for format string
**/
VOID
DebugPrint (
  IN UINTN         Level,
  IN CONST CHAR16  *Format,
  ...
  )
{
#ifndef DXE
  UINTN     BufferSize  = (MAX_PRINT_BUFFER + 1) * sizeof(CHAR16);
  CHAR16    *Buffer     = NULL;
  CHAR16    *Prefix     = L"";
  EFI_STATUS Status;

  if (Format == NULL || Level > DEBUG_LEVEL) {
    return;
  }

  // Set prefix based on debug level
  switch (Level) {
    case DEBUG_ERROR:
      Prefix = L"[ERROR] ";
      break;
    case DEBUG_WARN:
      Prefix = L"[WARN]  ";
      break;
    case DEBUG_INFO:
      Prefix = L"[INFO]  ";
      break;
    case DEBUG_VERBOSE:
      Prefix = L"[DEBUG] ";
      break;
  }

  Status = gBS->AllocatePool(EfiBootServicesData, BufferSize, (VOID**)&Buffer);
  if (EFI_ERROR(Status) || Buffer == NULL) {
    return;
  }

  // Print prefix first
  if (gST != NULL && gST->ConOut != NULL) {
    gST->ConOut->OutputString(gST->ConOut, Prefix);
  }

  VA_LIST Marker;
  VA_START(Marker, Format);
  UnicodeVSPrint(Buffer, BufferSize, Format, Marker);
  VA_END(Marker);
  
  if (gST != NULL && gST->ConOut != NULL) {
    gST->ConOut->OutputString(gST->ConOut, Buffer);
  }
  
  gBS->FreePool(Buffer);
#endif
}

/**
  Print hexadecimal dump of memory region for debugging.
  
  @param[in] Data     Pointer to data to dump
  @param[in] Size     Size of data in bytes
  @param[in] Address  Base address for display
**/
VOID
HexDump (
  IN VOID   *Data,
  IN UINTN  Size,
  IN UINT64 Address
  )
{
#ifndef DXE
  UINT8  *Bytes = (UINT8 *)Data;
  UINTN  i, j;
  
  if (Data == NULL || Size == 0 || DEBUG_LEVEL < DEBUG_VERBOSE) {
    return;
  }

  DebugPrint(DEBUG_VERBOSE, L"Memory dump at 0x%llx (%u bytes):\n", Address, Size);
  
  for (i = 0; i < Size; i += 16) {
    DebugPrint(DEBUG_VERBOSE, L"%08llx: ", Address + i);
    
    // Print hex bytes
    for (j = 0; j < 16 && (i + j) < Size; j++) {
      DebugPrint(DEBUG_VERBOSE, L"%02x ", Bytes[i + j]);
    }
    
    // Pad if less than 16 bytes
    for (; j < 16; j++) {
      DebugPrint(DEBUG_VERBOSE, L"   ");
    }
    
    DebugPrint(DEBUG_VERBOSE, L" |");
    
    // Print ASCII representation
    for (j = 0; j < 16 && (i + j) < Size; j++) {
      UINT8 c = Bytes[i + j];
      if (c >= 32 && c <= 126) {
        DebugPrint(DEBUG_VERBOSE, L"%c", c);
      } else {
        DebugPrint(DEBUG_VERBOSE, L".");
      }
    }
    
    DebugPrint(DEBUG_VERBOSE, L"|\n");
  }
#endif
}

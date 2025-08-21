#include <Library/UefiLib.h>
#include <Library/MemoryAllocationLib.h>
#include <Library/UefiBootServicesTableLib.h>
#include <Library/BaseLib.h>
#include <Library/BaseMemoryLib.h>
#include <Library/PrintLib.h>
#include <Library/DebugLib.h>

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
// Helper macros
//
#ifndef MIN
#define MIN(a, b) (((a) < (b)) ? (a) : (b))
#endif

// Safe pointer to integer conversion for debug output
#ifdef MDE_CPU_IA32
#define PTR_TO_INT(ptr) ((UINT32)(UINTN)(ptr))
#define PTR_FMT L"0x%x"
#else
#define PTR_TO_INT(ptr) ((UINT64)(UINTN)(ptr))
#define PTR_FMT L"0x%llx"
#endif

//
// Global variables
//
EFI_ACPI_2_0_ROOT_SYSTEM_DESCRIPTION_POINTER  *gRsdp = NULL;
EFI_ACPI_DESCRIPTION_HEADER                    *gXsdt = NULL;
EFI_ACPI_2_0_FIXED_ACPI_DESCRIPTION_TABLE      *gFacp = NULL;

#ifdef DXE_DRIVER_BUILD
// DXE Driver specific globals for delayed file system access
EFI_EVENT                                      gFileSystemReadyEvent = NULL;
VOID                                           *gFileSystemProtocolNotifyReg = NULL;
EFI_HANDLE                                     gImageHandle = NULL;
EFI_SYSTEM_TABLE                               *gSystemTable = NULL;
BOOLEAN                                        gFileSystemReady = FALSE;
#endif

//
// Function prototypes
//
VOID
AcpiDebugPrint (
  IN UINTN       Level,
  IN CONST CHAR16 *Format,
  ...
  );

EFI_STATUS
FindFadtInXsdt (
  VOID
  );

EFI_STATUS
PatchAcpiTables (
  IN EFI_FILE_PROTOCOL                 *Directory,
  IN EFI_ACPI_DESCRIPTION_HEADER       *Xsdt,
  IN EFI_ACPI_2_0_FIXED_ACPI_DESCRIPTION_TABLE *Facp
  );

#ifdef DXE_DRIVER_BUILD
//
// DXE Driver specific function prototypes
//
VOID
EFIAPI
OnFileSystemProtocolReady (
  IN EFI_EVENT    Event,
  IN VOID         *Context
  );

EFI_STATUS
WaitForFileSystemReady (
  VOID
  );

EFI_STATUS
PerformDelayedAcpiPatching (
  VOID
  );
#endif

//
// Helper functions for actual patching
//
EFI_STATUS
LoadAmlFileFromDisk (
  IN  EFI_FILE_PROTOCOL               *Directory,
  IN  CONST CHAR16                    *FileName,
  OUT EFI_ACPI_DESCRIPTION_HEADER     **AmlTable,
  OUT UINTN                          *TableSize
  );

EFI_STATUS
ValidateAcpiTable (
  IN EFI_ACPI_DESCRIPTION_HEADER *Table
  );

UINT8
CalculateAcpiChecksum (
  IN UINT8  *Buffer,
  IN UINTN  Length
  );

EFI_STATUS
ReplaceAcpiTableInXsdt (
  IN OUT EFI_ACPI_DESCRIPTION_HEADER   *Xsdt,
  IN     UINT32                        TableSignature,
  IN     EFI_ACPI_DESCRIPTION_HEADER   *NewTable
  );

EFI_STATUS
ScanDirectoryForSsdtFiles (
  IN     EFI_FILE_PROTOCOL             *Directory,
  IN OUT EFI_ACPI_DESCRIPTION_HEADER   *Xsdt,
  IN OUT UINT32                        *MaxEntries,
  IN OUT UINTN                         *TablesPatched
  );

//
// Function implementations
//

/**
  Load an AML file from disk into memory.
  
  @param[in]  Directory   File system directory to search
  @param[in]  FileName    Name of the AML file to load
  @param[out] AmlTable    Pointer to loaded table (caller must free)
  @param[out] TableSize   Size of the loaded table
  
  @retval EFI_SUCCESS     File loaded successfully
  @retval EFI_NOT_FOUND   File not found
  @retval Other           Error loading file
**/
EFI_STATUS
LoadAmlFileFromDisk (
  IN  EFI_FILE_PROTOCOL               *Directory,
  IN  CONST CHAR16                    *FileName,
  OUT EFI_ACPI_DESCRIPTION_HEADER     **AmlTable,
  OUT UINTN                          *TableSize
  )
{
  EFI_STATUS          Status;
  EFI_FILE_PROTOCOL   *FileHandle;
  EFI_FILE_INFO       *FileInfo;
  UINTN               FileInfoSize;
  VOID                *FileBuffer;

  Print(L"[INFO]  Loading AML file: %s\n", FileName);

  // Try to open the file
  Status = FsOpenFile(Directory, (CHAR16*)FileName, &FileHandle);
  if (EFI_ERROR(Status)) {
    Print(L"[WARN]  File %s not found, skipping\n", FileName);
    return Status;
  }

  // Get file information to determine size
  FileInfoSize = sizeof(EFI_FILE_INFO) + 512;
  FileInfo = AllocateZeroPool(FileInfoSize);
  if (FileInfo == NULL) {
    FileHandle->Close(FileHandle);
    return EFI_OUT_OF_RESOURCES;
  }

  Status = FileHandle->GetInfo(FileHandle, &gEfiFileInfoGuid, &FileInfoSize, FileInfo);
  if (EFI_ERROR(Status)) {
    Print(L"[ERROR] Failed to get file info for %s: %r\n", FileName, Status);
    FreePool(FileInfo);
    FileHandle->Close(FileHandle);
    return Status;
  }

  *TableSize = (UINTN)FileInfo->FileSize;
  Print(L"[INFO]  File size: %d bytes\n", *TableSize);

  // Read the file into memory
  Status = FsReadFileToBuffer(FileHandle, *TableSize, &FileBuffer);
  if (EFI_ERROR(Status)) {
    Print(L"[ERROR] Failed to read file %s: %r\n", FileName, Status);
    FreePool(FileInfo);
    FileHandle->Close(FileHandle);
    return Status;
  }

  *AmlTable = (EFI_ACPI_DESCRIPTION_HEADER*)FileBuffer;
  
  // Validate that this is a proper ACPI table
  Status = ValidateAcpiTable(*AmlTable);
  if (EFI_ERROR(Status)) {
    Print(L"[ERROR] Invalid ACPI table in file %s\n", FileName);
    FreePool(FileBuffer);
    FreePool(FileInfo);
    FileHandle->Close(FileHandle);
    return Status;
  }

  CHAR8 Signature[5];
  CopyMem(Signature, &(*AmlTable)->Signature, 4);
  Signature[4] = '\0';
  Print(L"[INFO]  Successfully loaded '%a' table, %d bytes\n", Signature, (*AmlTable)->Length);

  FreePool(FileInfo);
  FileHandle->Close(FileHandle);
  return EFI_SUCCESS;
}

/**
  Validate an ACPI table structure and checksum.
  
  @param[in] Table  Pointer to ACPI table to validate
  
  @retval EFI_SUCCESS             Table is valid
  @retval EFI_INVALID_PARAMETER   Table structure is invalid
  @retval EFI_CRC_ERROR          Checksum validation failed
**/
EFI_STATUS
ValidateAcpiTable (
  IN EFI_ACPI_DESCRIPTION_HEADER *Table
  )
{
  if (Table == NULL) {
    return EFI_INVALID_PARAMETER;
  }

  // Check minimum table size
  if (Table->Length < sizeof(EFI_ACPI_DESCRIPTION_HEADER)) {
    Print(L"[ERROR] Table too small: %d bytes\n", Table->Length);
    return EFI_INVALID_PARAMETER;
  }

  // Validate checksum
  UINT8 CalculatedChecksum = CalculateAcpiChecksum((UINT8*)Table, Table->Length);
  if (CalculatedChecksum != 0) {
    Print(L"[ERROR] Checksum validation failed: expected 0, got 0x%02x\n", CalculatedChecksum);
    return EFI_CRC_ERROR;
  }

  Print(L"[INFO]  Table validation passed\n");
  return EFI_SUCCESS;
}

/**
  Calculate ACPI table checksum.
  
  @param[in] Buffer  Pointer to buffer to checksum
  @param[in] Length  Length of buffer
  
  @return Calculated checksum value
**/
UINT8
CalculateAcpiChecksum (
  IN UINT8  *Buffer,
  IN UINTN  Length
  )
{
  UINT8 Sum = 0;
  UINTN Index;

  for (Index = 0; Index < Length; Index++) {
    Sum += Buffer[Index];
  }

  return Sum;
}

/**
  Replace an ACPI table in the XSDT.
  
  @param[in,out] Xsdt           Pointer to XSDT to modify
  @param[in]     TableSignature Signature of table to replace
  @param[in]     NewTable       Pointer to new table
  
  @retval EFI_SUCCESS     Table replaced successfully
  @retval EFI_NOT_FOUND   Original table not found in XSDT
**/
EFI_STATUS
ReplaceAcpiTableInXsdt (
  IN OUT EFI_ACPI_DESCRIPTION_HEADER   *Xsdt,
  IN     UINT32                        TableSignature,
  IN     EFI_ACPI_DESCRIPTION_HEADER   *NewTable
  )
{
  UINT32  EntryCount;
  UINT64  *EntryPtr;
  UINTN   Index;
  EFI_ACPI_DESCRIPTION_HEADER *Entry;
  CHAR8   SigStr[5];

  EntryCount = (Xsdt->Length - sizeof(EFI_ACPI_DESCRIPTION_HEADER)) / sizeof(UINT64);
  EntryPtr = (UINT64 *)(Xsdt + 1);

  CopyMem(SigStr, &TableSignature, 4);
  SigStr[4] = '\0';
  Print(L"[INFO]  Searching for table '%a' to replace\n", SigStr);

  for (Index = 0; Index < EntryCount; Index++) {
    Entry = (EFI_ACPI_DESCRIPTION_HEADER *)(UINTN)EntryPtr[Index];
    if (Entry != NULL && Entry->Signature == TableSignature) {
      Print(L"[INFO]  Found table '%a' at index %d, replacing\n", SigStr, Index);
      Print(L"[INFO]  Old table: %d bytes at " PTR_FMT L"\n", Entry->Length, PTR_TO_INT(Entry));
      Print(L"[INFO]  New table: %d bytes at " PTR_FMT L"\n", NewTable->Length, PTR_TO_INT(NewTable));
      
      // Replace the pointer
      EntryPtr[Index] = (UINT64)(UINTN)NewTable;
      
      Print(L"[INFO]  Table '%a' successfully replaced\n", SigStr);
      return EFI_SUCCESS;
    }
  }

  Print(L"[WARN]  Table '%a' not found in XSDT\n", SigStr);
  return EFI_NOT_FOUND;
}

/**
  Simplified AML file loader using existing file system helpers.
**/
EFI_STATUS
LoadAmlFile (
  IN  EFI_FILE_PROTOCOL               *Directory,
  IN  CONST CHAR16                    *FileName,
  OUT EFI_ACPI_DESCRIPTION_HEADER     **AmlTable,
  OUT UINTN                           *TableSize
  )
{
  EFI_STATUS Status;
  EFI_FILE_PROTOCOL *AcpiDir;
  EFI_FILE_PROTOCOL *FileHandle;
  VOID *FileBuffer;
  UINTN FileSize;

  Print(L"[INFO]  Attempting to load: %s\n", FileName);
  
  // First, try to open the ACPI subdirectory as specified in README
  Status = Directory->Open(
    Directory,
    &AcpiDir,
    L"ACPI",
    EFI_FILE_MODE_READ,
    0
  );
  
  if (EFI_ERROR(Status)) {
    Print(L"[INFO]  ACPI directory not found, trying current directory as fallback\n");
    // Fall back to current directory if ACPI directory doesn't exist
    Status = FsOpenFile(Directory, (CHAR16*)FileName, &FileHandle);
  } else {
    Print(L"[INFO]  Found ACPI directory, loading from ACPI/%s\n", FileName);
    // Open file in ACPI directory
    Status = FsOpenFile(AcpiDir, (CHAR16*)FileName, &FileHandle);
    AcpiDir->Close(AcpiDir);  // Close the ACPI directory handle
  }
  
  if (EFI_ERROR(Status)) {
    return Status;
  }

  // Get file size (simplified - assume reasonable size < 1MB)
  FileSize = 0x100000; // 1MB buffer
  Status = FsReadFileToBuffer(FileHandle, FileSize, &FileBuffer);
  FileHandle->Close(FileHandle);
  
  if (EFI_ERROR(Status)) {
    return Status;
  }

  *AmlTable = (EFI_ACPI_DESCRIPTION_HEADER*)FileBuffer;
  *TableSize = (*AmlTable)->Length;
  
  Print(L"[INFO]  Loaded %d bytes\n", *TableSize);
  return EFI_SUCCESS;
}

/**
  Replace table in XSDT (simplified version).
**/
EFI_STATUS
ReplaceTableInXsdt (
  IN OUT EFI_ACPI_DESCRIPTION_HEADER   *Xsdt,
  IN     UINT32                        Signature,
  IN     EFI_ACPI_DESCRIPTION_HEADER   *NewTable
  )
{
  UINT32 EntryCount = (Xsdt->Length - sizeof(EFI_ACPI_DESCRIPTION_HEADER)) / sizeof(UINT64);
  UINT64 *EntryPtr = (UINT64 *)(Xsdt + 1);
  
  for (UINTN i = 0; i < EntryCount; i++) {
    EFI_ACPI_DESCRIPTION_HEADER *Entry = (EFI_ACPI_DESCRIPTION_HEADER *)(UINTN)EntryPtr[i];
    if (Entry != NULL && Entry->Signature == Signature) {
      EntryPtr[i] = (UINT64)(UINTN)NewTable;
      return EFI_SUCCESS;
    }
  }
  return EFI_NOT_FOUND;
}

/**
  Add new table to XSDT.
**/
EFI_STATUS
AddTableToXsdt (
  IN OUT EFI_ACPI_DESCRIPTION_HEADER   *Xsdt,
  IN     EFI_ACPI_DESCRIPTION_HEADER   *NewTable,
  IN OUT UINT32                        *MaxEntries
  )
{
  UINT32 CurrentEntries = (Xsdt->Length - sizeof(EFI_ACPI_DESCRIPTION_HEADER)) / sizeof(UINT64);
  
  if (CurrentEntries >= *MaxEntries) {
    return EFI_OUT_OF_RESOURCES;
  }
  
  UINT64 *EntryPtr = (UINT64 *)(Xsdt + 1);
  EntryPtr[CurrentEntries] = (UINT64)(UINTN)NewTable;
  
  Xsdt->Length += sizeof(UINT64);
  return EFI_SUCCESS;
}

/**
  Debug print function that respects debug levels.
  
  @param[in]  Level   Debug level for this message
  @param[in]  Format  Format string for debug output
  @param[in]  ...     Variable arguments for format string
**/
VOID
AcpiDebugPrint (
  IN UINTN       Level,
  IN CONST CHAR16 *Format,
  ...
  )
{
  // Use standard EDK2 DEBUG levels and output to Print for visibility
  if (Level == DEBUG_ERROR) {
    Print(L"ERROR: ");
    Print(Format);
  } else if (Level == DEBUG_WARN) {
    Print(L"WARN: ");
    Print(Format);
  } else if (Level == DEBUG_INFO) {
    Print(L"INFO: ");
    Print(Format);
  } else if (Level == DEBUG_VERBOSE) {
    Print(L"VERBOSE: ");
    Print(Format);
  } else {
    Print(Format);
  }
}

/**
  Search for FADT table in the XSDT.
  
  @retval EFI_SUCCESS           FADT found successfully
  @retval EFI_INVALID_PARAMETER XSDT pointer is invalid
  @retval EFI_NOT_FOUND         FADT not found in XSDT
**/
EFI_STATUS
FindFadtInXsdt (
  VOID
  )
{
  EFI_ACPI_DESCRIPTION_HEADER *Entry;
  UINT32              EntryCount;
  UINT64              *EntryPtr;
  UINTN               Index;
  CHAR8               SigStr[5];

  AcpiDebugPrint(DEBUG_INFO, L"Searching for FADT in XSDT...\n");

  if (gXsdt == NULL) {
    AcpiDebugPrint(DEBUG_ERROR, L"XSDT pointer is null (0x%llx)\n", gRsdp->XsdtAddress);
    return EFI_INVALID_PARAMETER;
  }

  EntryCount = (gXsdt->Length - sizeof(EFI_ACPI_DESCRIPTION_HEADER)) / sizeof(UINT64);
  EntryPtr = (UINT64 *)(gXsdt + 1);

  AcpiDebugPrint(DEBUG_VERBOSE, L"XSDT has %d entries to scan\n", EntryCount);

  // Null terminate the signature string buffer
  SigStr[4] = '\0';

  // Enhanced debug: Show detailed ACPI table discovery
  Print(L"[INFO]  === ACPI Table Discovery ===\n");
  Print(L"[INFO]  XSDT contains %d table entries\n", EntryCount);
  
  for (Index = 0; Index < EntryCount; Index++) {
    Entry = (EFI_ACPI_DESCRIPTION_HEADER *)(UINTN)EntryPtr[Index];
    if (Entry == NULL) {
      Print(L"[WARN]  Entry %d: NULL pointer, skipping\n", Index);
      continue;
    }

    // Copy signature for safe string operations
    CopyMem(SigStr, &Entry->Signature, 4);
    
    // Show detailed table information
    Print(L"[INFO]  Table[%d]: Signature='%a', Length=%d bytes, Revision=%d\n", 
          Index, SigStr, Entry->Length, Entry->Revision);
    Print(L"[INFO]    Address: " PTR_FMT L", Checksum=0x%02x\n", 
          PTR_TO_INT(Entry), Entry->Checksum);

    // Show table-specific information
    if (Entry->Signature == EFI_ACPI_2_0_FIXED_ACPI_DESCRIPTION_TABLE_SIGNATURE) {
      gFacp = (EFI_ACPI_2_0_FIXED_ACPI_DESCRIPTION_TABLE *)Entry;
      Print(L"[INFO]    -> FADT (Fixed ACPI Description Table)\n");
      Print(L"[INFO]       DSDT Address: 0x%x, X_DSDT Address: 0x%llx\n", 
            gFacp->Dsdt, gFacp->XDsdt);
    } else if (Entry->Signature == EFI_ACPI_2_0_DIFFERENTIATED_SYSTEM_DESCRIPTION_TABLE_SIGNATURE) {
      Print(L"[INFO]    -> DSDT (Differentiated System Description Table)\n");
    } else if (Entry->Signature == EFI_ACPI_2_0_SECONDARY_SYSTEM_DESCRIPTION_TABLE_SIGNATURE) {
      Print(L"[INFO]    -> SSDT (Secondary System Description Table)\n");
    } else if (Entry->Signature == EFI_ACPI_2_0_MULTIPLE_APIC_DESCRIPTION_TABLE_SIGNATURE) {
      Print(L"[INFO]    -> APIC/MADT (Multiple APIC Description Table)\n");
    } else if (Entry->Signature == EFI_ACPI_2_0_MEMORY_MAPPED_CONFIGURATION_BASE_ADDRESS_TABLE_SIGNATURE) {
      Print(L"[INFO]    -> MCFG (Memory Mapped Configuration)\n");
    }
  }

  if (gFacp != NULL) {
    Print(L"[INFO]  === FADT Analysis Complete ===\n");
    Print(L"[INFO]  Successfully found FADT at " PTR_FMT L"\n", PTR_TO_INT(gFacp));
    return EFI_SUCCESS;
  }

  AcpiDebugPrint(DEBUG_ERROR, L"FADT not found in XSDT\n");
  return EFI_NOT_FOUND;
}

#ifdef DXE_DRIVER_BUILD
/**
  Callback function that gets called when Simple File System Protocol becomes available.
  This allows the DXE driver to wait until storage is ready before loading .aml files.
  
  @param[in] Event    The event that was signaled
  @param[in] Context  Event context (unused)
**/
VOID
EFIAPI
OnFileSystemProtocolReady (
  IN EFI_EVENT    Event,
  IN VOID         *Context
  )
{
  EFI_STATUS Status;
  
  Print(L"[DXE] File System Protocol ready notification received!\n");
  
  // Mark file system as ready
  gFileSystemReady = TRUE;
  
  // Close the event as we no longer need it
  if (gFileSystemReadyEvent != NULL) {
    gBS->CloseEvent(gFileSystemReadyEvent);
    gFileSystemReadyEvent = NULL;
  }
  
  Print(L"[DXE] Now attempting delayed ACPI patching with file system access...\n");
  
  // Perform the ACPI patching now that file system is ready
  Status = PerformDelayedAcpiPatching();
  if (EFI_ERROR(Status)) {
    Print(L"[DXE] ERROR: Delayed ACPI patching failed: %r\n", Status);
  } else {
    Print(L"[DXE] SUCCESS: Delayed ACPI patching completed!\n");
  }
}

/**
  Sets up an event notification to wait for the Simple File System Protocol.
  This is essential for DXE drivers that need file system access.
  
  @retval EFI_SUCCESS     Event registered successfully
  @retval Other           Error setting up the event
**/
EFI_STATUS
WaitForFileSystemReady (
  VOID
  )
{
  EFI_STATUS Status;
  
  Print(L"[DXE] Setting up file system ready notification...\n");
  
  // Create an event that will be signaled when Simple File System Protocol is installed
  Status = gBS->CreateEvent(
    EVT_NOTIFY_SIGNAL,
    TPL_CALLBACK,
    OnFileSystemProtocolReady,
    NULL,
    &gFileSystemReadyEvent
  );
  
  if (EFI_ERROR(Status)) {
    Print(L"[DXE] ERROR: Failed to create file system event: %r\n", Status);
    return Status;
  }
  
  // Register for protocol installation notification
  Status = gBS->RegisterProtocolNotify(
    &gEfiSimpleFileSystemProtocolGuid,
    gFileSystemReadyEvent,
    &gFileSystemProtocolNotifyReg
  );
  
  if (EFI_ERROR(Status)) {
    Print(L"[DXE] ERROR: Failed to register protocol notify: %r\n", Status);
    gBS->CloseEvent(gFileSystemReadyEvent);
    gFileSystemReadyEvent = NULL;
    return Status;
  }
  
  Print(L"[DXE] File system notification registered successfully\n");
  Print(L"[DXE] DXE driver will wait for storage to initialize...\n");
  
  return EFI_SUCCESS;
}

/**
  Performs the actual ACPI patching once file system is ready.
  This is called from the file system ready callback.
  
  @retval EFI_SUCCESS     ACPI patching completed successfully
  @retval Other           Error during patching
**/
EFI_STATUS
PerformDelayedAcpiPatching (
  VOID
  )
{
  EFI_STATUS Status;
  EFI_FILE_PROTOCOL *SelfDir;
  
  Print(L"[DXE] === Delayed ACPI Patching (File System Ready) ===\n");
  
  // Now try to get file system access (should succeed)
  SelfDir = FsGetSelfDir();
  if (SelfDir == NULL) {
    Print(L"[DXE] WARNING: File system still not accessible, continuing without files\n");
    // Continue anyway - we can still do ACPI table discovery
  } else {
    Print(L"[DXE] SUCCESS: File system now accessible, .aml files can be loaded\n");
  }
  
  // Get RSDP from the system table (if not already done)
  if (gRsdp == NULL) {
    Status = EfiGetSystemConfigurationTable(&gEfiAcpi20TableGuid, (VOID**)&gRsdp);
    if (EFI_ERROR(Status)) {
      // Try ACPI 1.0 table if 2.0 is not available
      Status = EfiGetSystemConfigurationTable(&gEfiAcpiTableGuid, (VOID**)&gRsdp);
      if (EFI_ERROR(Status)) {
        Print(L"[DXE] ERROR: Failed to find ACPI tables: %r\n", Status);
        return Status;
      }
      Print(L"[DXE] Using ACPI 1.0 tables\n");
    } else {
      Print(L"[DXE] Using ACPI 2.0+ tables\n");
    }
  }
  
  // Get XSDT from RSDP (if not already done)
  if (gXsdt == NULL) {
    if (gRsdp->XsdtAddress == 0) {
      Print(L"[DXE] ERROR: XSDT address is invalid\n");
      return EFI_UNSUPPORTED;
    }
    
    gXsdt = (EFI_ACPI_DESCRIPTION_HEADER*)(UINTN)gRsdp->XsdtAddress;
    Print(L"[DXE] XSDT found at " PTR_FMT L"\n", PTR_TO_INT(gXsdt));
  }
  
  // Find FADT in XSDT (if not already done)
  if (gFacp == NULL) {
    Status = FindFadtInXsdt();
    if (EFI_ERROR(Status)) {
      Print(L"[DXE] ERROR: Failed to find FADT: %r\n", Status);
      return Status;
    }
  }
  
  // Perform ACPI patching with file system access
  Status = PatchAcpiTables(SelfDir, gXsdt, gFacp);
  if (EFI_ERROR(Status)) {
    Print(L"[DXE] ERROR: ACPI patching failed: %r\n", Status);
    return Status;
  }
  
  Print(L"[DXE] === Delayed ACPI Patching Completed Successfully ===\n");
  return EFI_SUCCESS;
}
#endif

/**
  Main ACPI table patching function.
  
  @param[in] Directory  File system protocol for accessing ACPI files
  @param[in] Xsdt       Pointer to the Extended System Description Table
  @param[in] Facp       Pointer to the Fixed ACPI Description Table
  
  @retval EFI_SUCCESS           Patching completed successfully
  @retval EFI_INVALID_PARAMETER Invalid parameters provided
  @retval EFI_OUT_OF_RESOURCES  Insufficient memory for operations
**/
EFI_STATUS
PatchAcpiTables (
  IN EFI_FILE_PROTOCOL                 *Directory,
  IN EFI_ACPI_DESCRIPTION_HEADER       *Xsdt,
  IN EFI_ACPI_2_0_FIXED_ACPI_DESCRIPTION_TABLE *Facp
  )
{
  UINT32                      CurrentEntries;
  UINT32                      MaxEntries;
  UINTN                       NewXsdtSize;
  EFI_ACPI_DESCRIPTION_HEADER *NewXsdt;
  
  AcpiDebugPrint(DEBUG_INFO, L"Starting ACPI patching process...\n");
  
  // For now, Directory can be NULL since we're not using file system operations yet
  if (Xsdt == NULL || Facp == NULL) {
    AcpiDebugPrint(DEBUG_ERROR, L"Invalid parameters for ACPI patching\n");
    AcpiDebugPrint(DEBUG_VERBOSE, L"  Directory: " PTR_FMT L"\n", PTR_TO_INT(Directory));
    AcpiDebugPrint(DEBUG_VERBOSE, L"  Xsdt: " PTR_FMT L"\n", PTR_TO_INT(Xsdt));
    AcpiDebugPrint(DEBUG_VERBOSE, L"  Facp: " PTR_FMT L"\n", PTR_TO_INT(Facp));
    return EFI_INVALID_PARAMETER;
  }

  CurrentEntries = (Xsdt->Length - sizeof(EFI_ACPI_DESCRIPTION_HEADER)) / sizeof(UINT64);
  
  // Determine maximum entries based on EFI version
  if (gST->Hdr.Revision < EFI_2_00_SYSTEM_TABLE_REVISION) {
    // EFI 1.x - limit additional tables for compatibility
    MaxEntries = CurrentEntries + MIN(MAX_ADDITIONAL_TABLES, 8);  // Limit to 8 additional tables for EFI 1.x
    AcpiDebugPrint(DEBUG_INFO, L"EFI 1.x detected, limiting to %d additional tables (%d total)\n",
                   MIN(MAX_ADDITIONAL_TABLES, 8));
  } else {
    // EFI 2.0+ - use full limit
    MaxEntries = CurrentEntries + MAX_ADDITIONAL_TABLES;
    AcpiDebugPrint(DEBUG_INFO, L"EFI 2.0+ detected, allowing %d additional tables (%d total)\n",
                   MAX_ADDITIONAL_TABLES, MaxEntries);
  }

  NewXsdtSize = sizeof(EFI_ACPI_DESCRIPTION_HEADER) + (MaxEntries * sizeof(UINT64));
  
  AcpiDebugPrint(DEBUG_INFO, L"Allocating new XSDT: %d bytes for %d entries\n", 
                 NewXsdtSize, MaxEntries);

  // Allocate memory for the new XSDT with additional entries
  NewXsdt = AllocateZeroPool(NewXsdtSize);
  if (NewXsdt == NULL) {
    AcpiDebugPrint(DEBUG_ERROR, L"Failed to allocate memory for new XSDT\n");
    return EFI_OUT_OF_RESOURCES;
  }

  // Copy the existing XSDT
  CopyMem(NewXsdt, Xsdt, Xsdt->Length);

  // Enhanced debug output for patching process
  Print(L"[INFO]  === ACPI Patching Analysis ===\n");
  Print(L"[INFO]  Original XSDT: %d entries, %d bytes\n", CurrentEntries, Xsdt->Length);
  Print(L"[INFO]  New XSDT capacity: %d entries, %d bytes\n", MaxEntries, NewXsdtSize);
  
  // Show current XSDT contents before patching
  UINT64 *OriginalEntryPtr = (UINT64 *)(Xsdt + 1);
  Print(L"[INFO]  Current ACPI tables in XSDT:\n");
  for (UINTN i = 0; i < CurrentEntries; i++) {
    EFI_ACPI_DESCRIPTION_HEADER *TableEntry = (EFI_ACPI_DESCRIPTION_HEADER *)(UINTN)OriginalEntryPtr[i];
    if (TableEntry != NULL) {
      CHAR8 TableSig[5];
      CopyMem(TableSig, &TableEntry->Signature, 4);
      TableSig[4] = '\0';
      Print(L"[INFO]    [%d] %a - %d bytes, checksum=0x%02x\n", 
            i, TableSig, TableEntry->Length, TableEntry->Checksum);
    }
  }

  // Show memory layout changes before patching
  Print(L"[INFO]  === Memory Layout Changes ===\n");
  Print(L"[INFO]  Original XSDT address: " PTR_FMT L"\n", PTR_TO_INT(Xsdt));
  Print(L"[INFO]  New XSDT address: " PTR_FMT L"\n", PTR_TO_INT(NewXsdt));
  Print(L"[INFO]  Memory allocated: %d bytes\n", NewXsdtSize);

  // Note: In a real implementation, you would:
  // - Actually load and parse .aml files from the file system
  // - Replace specific tables (like DSDT) with patched versions
  // - Add new SSDT tables
  // - Update the system's RSDP to point to the new XSDT
  // - Properly validate all checksums

  Print(L"[INFO]  === Patching Summary ===\n");
  Print(L"[INFO]  Tables processed: %d\n", CurrentEntries);
  Print(L"[INFO]  New table capacity: %d\n", MaxEntries);
  Print(L"[INFO]  Memory usage: %d bytes\n", NewXsdtSize);

  // *** ACTUAL PATCHING IMPLEMENTATION ***
  Print(L"[INFO]  === Starting Real ACPI Patching ===\n");
  
  UINTN TablesPatched = 0;
  EFI_STATUS PatchStatus;
  
  // Try to load and replace DSDT.aml if present
  if (Directory != NULL) {
    EFI_ACPI_DESCRIPTION_HEADER *NewDsdt = NULL;
    UINTN DsdtSize = 0;
    
    // Try to load DSDT.aml
    EFI_STATUS DsdtStatus = LoadAmlFile(Directory, L"DSDT.aml", &NewDsdt, &DsdtSize);
      if (!EFI_ERROR(DsdtStatus) && NewDsdt != NULL) {
        // Replace DSDT in XSDT
        PatchStatus = ReplaceTableInXsdt(NewXsdt, 
                                       EFI_ACPI_2_0_DIFFERENTIATED_SYSTEM_DESCRIPTION_TABLE_SIGNATURE,
                                       NewDsdt);
        if (!EFI_ERROR(PatchStatus)) {
          Print(L"[INFO]  ✓ DSDT replaced successfully\n");
          TablesPatched++;
          
          // Update FADT pointers to new DSDT
          if (Facp != NULL) {
            Facp->Dsdt = (UINT32)(UINTN)NewDsdt;
            Facp->XDsdt = (UINT64)(UINTN)NewDsdt;
            Print(L"[INFO]  ✓ FADT DSDT pointers updated\n");
          }
        }
      } else {
        Print(L"[INFO]  No DSDT.aml file found, keeping original\n");
      }
      
      // Try to load additional SSDT tables by scanning directory
      Print(L"[INFO]  Scanning for SSDT-*.aml files...\n");
      
      // First, try the numeric pattern for backward compatibility
      CHAR16 SsdtFileName[64];
      for (UINTN SsdtIndex = 1; SsdtIndex <= 10; SsdtIndex++) {
        UnicodeSPrint(SsdtFileName, sizeof(SsdtFileName), L"SSDT-%d.aml", SsdtIndex);
        
        EFI_ACPI_DESCRIPTION_HEADER *NewSsdt = NULL;
        UINTN SsdtSize = 0;
        
        EFI_STATUS SsdtStatus = LoadAmlFile(Directory, SsdtFileName, &NewSsdt, &SsdtSize);
        if (!EFI_ERROR(SsdtStatus) && NewSsdt != NULL) {
          // Add new SSDT to XSDT (append to end)
          PatchStatus = AddTableToXsdt(NewXsdt, NewSsdt, &MaxEntries);
          if (!EFI_ERROR(PatchStatus)) {
            Print(L"[INFO]  ✓ %s added successfully\n", SsdtFileName);
            TablesPatched++;
          }
        }
      }
      
      // Now scan directory for any other SSDT-*.aml files
      EFI_STATUS ScanStatus = ScanDirectoryForSsdtFiles(Directory, NewXsdt, &MaxEntries, &TablesPatched);
      if (EFI_ERROR(ScanStatus)) {
        Print(L"[WARN]  Directory scanning failed: %r\n", ScanStatus);
      }
  }
  
  // Recalculate XSDT checksum after all modifications
  NewXsdt->Checksum = 0;
  UINT8 NewXsdtChecksum = 0;
  UINT8 *XsdtBytes = (UINT8 *)NewXsdt;
  for (UINTN ChecksumIndex = 0; ChecksumIndex < NewXsdt->Length; ChecksumIndex++) {
    NewXsdtChecksum += XsdtBytes[ChecksumIndex];
  }
  NewXsdt->Checksum = (UINT8)(0x100 - NewXsdtChecksum);
  
  Print(L"[INFO]  ✓ XSDT checksum recalculated: 0x%02x\n", NewXsdt->Checksum);
  
  // Update system RSDP to point to new XSDT (critical step!)
  if (gRsdp != NULL && TablesPatched > 0) {
    UINT64 OriginalXsdtAddr = gRsdp->XsdtAddress;
    gRsdp->XsdtAddress = (UINT64)(UINTN)NewXsdt;
    
    // Recalculate RSDP checksum
    gRsdp->Checksum = 0;
    UINT8 RsdpChecksum = 0;
    UINT8 *RsdpBytes = (UINT8 *)gRsdp;
    for (UINTN i = 0; i < sizeof(EFI_ACPI_2_0_ROOT_SYSTEM_DESCRIPTION_POINTER); i++) {
      RsdpChecksum += RsdpBytes[i];
    }
    gRsdp->Checksum = (UINT8)(0x100 - RsdpChecksum);
    
    Print(L"[INFO]  ✓ RSDP updated: 0x%llx -> 0x%llx\n", OriginalXsdtAddr, gRsdp->XsdtAddress);
    Print(L"[INFO]  ✓ RSDP checksum recalculated: 0x%02x\n", gRsdp->Checksum);
  }

  Print(L"[INFO]  Status: Successfully patched %d ACPI tables!\n", TablesPatched);

  AcpiDebugPrint(DEBUG_INFO, L"ACPI patching completed successfully\n");
  return EFI_SUCCESS;
}

/**
  Scan directory for SSDT-*.aml files with arbitrary naming.
  This function complements the numeric pattern scanning by finding
  descriptively named files like SSDT-CPU.aml, SSDT-GPU.aml, etc.
  
  @param[in]     Directory       File system directory to scan
  @param[in,out] Xsdt           XSDT to add tables to
  @param[in,out] MaxEntries     Maximum entries allowed in XSDT
  @param[in,out] TablesPatched  Counter of successfully added tables
  
  @retval EFI_SUCCESS     Directory scanning completed successfully
  @retval Other           Error during directory operations
**/
EFI_STATUS
ScanDirectoryForSsdtFiles (
  IN     EFI_FILE_PROTOCOL             *Directory,
  IN OUT EFI_ACPI_DESCRIPTION_HEADER   *Xsdt,
  IN OUT UINT32                        *MaxEntries,
  IN OUT UINTN                         *TablesPatched
  )
{
  EFI_STATUS Status;
  EFI_FILE_PROTOCOL *AcpiDir = NULL;
  EFI_FILE_INFO *FileInfo = NULL;
  UINTN FileInfoSize;
  BOOLEAN EndOfDirectory = FALSE;
  UINTN FilesScanned = 0;
  UINTN SsdtFilesFound = 0;
  
  if (Directory == NULL || Xsdt == NULL || MaxEntries == NULL || TablesPatched == NULL) {
    return EFI_INVALID_PARAMETER;
  }
  
  Print(L"[INFO]  Starting directory scan for additional SSDT files...\n");
  
  // Try to open ACPI subdirectory first, fallback to current directory
  Status = Directory->Open(
    Directory,
    &AcpiDir,
    L"ACPI",
    EFI_FILE_MODE_READ,
    0
  );
  
  if (EFI_ERROR(Status)) {
    Print(L"[INFO]  No ACPI subdirectory, scanning current directory\n");
    AcpiDir = Directory;  // Use current directory
  } else {
    Print(L"[INFO]  Scanning ACPI/ subdirectory\n");
  }
  
  // Start directory enumeration
  while (!EndOfDirectory) {
    FileInfoSize = sizeof(EFI_FILE_INFO) + 512;  // Buffer for filename
    FileInfo = AllocateZeroPool(FileInfoSize);
    if (FileInfo == NULL) {
      Status = EFI_OUT_OF_RESOURCES;
      break;
    }
    
    Status = AcpiDir->Read(AcpiDir, &FileInfoSize, FileInfo);
    if (Status == EFI_BUFFER_TOO_SMALL) {
      // Need larger buffer for filename
      FreePool(FileInfo);
      FileInfo = AllocateZeroPool(FileInfoSize);
      if (FileInfo == NULL) {
        Status = EFI_OUT_OF_RESOURCES;
        break;
      }
      Status = AcpiDir->Read(AcpiDir, &FileInfoSize, FileInfo);
    }
    
    if (EFI_ERROR(Status) || FileInfoSize == 0) {
      // End of directory or error
      EndOfDirectory = TRUE;
      FreePool(FileInfo);
      break;
    }
    
    FilesScanned++;
    
    // Skip directories and non-.aml files
    if ((FileInfo->Attribute & EFI_FILE_DIRECTORY) || 
        FileInfo->FileSize == 0) {
      FreePool(FileInfo);
      continue;
    }
    
    // Check if filename matches SSDT-*.aml pattern (but not numeric ones we already processed)
    CHAR16 *FileName = FileInfo->FileName;
    UINTN NameLen = StrLen(FileName);
    
    // Must be at least 9 chars: "SSDT-X.aml"
    if (NameLen < 9) {
      FreePool(FileInfo);
      continue;
    }
    
    // Check if it starts with "SSDT-" and ends with ".aml"
    if (StrnCmp(FileName, L"SSDT-", 5) != 0 || 
        StrnCmp(&FileName[NameLen-4], L".aml", 4) != 0) {
      FreePool(FileInfo);
      continue;
    }
    
    // Extract the middle part (between "SSDT-" and ".aml")
    CHAR16 MiddlePart[64];
    UINTN MiddleLen = NameLen - 9;  // Total length minus "SSDT-" (5) and ".aml" (4)
    if (MiddleLen >= sizeof(MiddlePart)/sizeof(CHAR16)) {
      Print(L"[WARN]  Filename too long, skipping: %s\n", FileName);
      FreePool(FileInfo);
      continue;
    }
    
    StrnCpyS(MiddlePart, sizeof(MiddlePart)/sizeof(CHAR16), &FileName[5], MiddleLen);
    MiddlePart[MiddleLen] = L'\0';
    
    // Skip if it's a pure numeric pattern (already processed)
    BOOLEAN IsNumeric = TRUE;
    for (UINTN i = 0; i < MiddleLen; i++) {
      if (MiddlePart[i] < L'0' || MiddlePart[i] > L'9') {
        IsNumeric = FALSE;
        break;
      }
    }
    
    if (IsNumeric) {
      Print(L"[INFO]  Skipping numeric SSDT: %s (already processed)\n", FileName);
      FreePool(FileInfo);
      continue;
    }
    
    // This is a descriptive SSDT file - try to load it
    Print(L"[INFO]  Found descriptive SSDT: %s\n", FileName);
    SsdtFilesFound++;
    
    EFI_ACPI_DESCRIPTION_HEADER *NewSsdt = NULL;
    UINTN SsdtSize = 0;
    
    EFI_STATUS LoadStatus = LoadAmlFile(AcpiDir, FileName, &NewSsdt, &SsdtSize);
    if (!EFI_ERROR(LoadStatus) && NewSsdt != NULL) {
      // Add to XSDT
      EFI_STATUS AddStatus = AddTableToXsdt(Xsdt, NewSsdt, MaxEntries);
      if (!EFI_ERROR(AddStatus)) {
        Print(L"[INFO]  ✓ %s loaded and added successfully\n", FileName);
        (*TablesPatched)++;
      } else {
        Print(L"[WARN]  Failed to add %s to XSDT: %r\n", FileName, AddStatus);
        FreePool(NewSsdt);  // Clean up on failure
      }
    } else {
      Print(L"[WARN]  Failed to load %s: %r\n", FileName, LoadStatus);
    }
    
    FreePool(FileInfo);
  }
  
  Print(L"[INFO]  Directory scan complete: %d files scanned, %d SSDT files found\n", 
        FilesScanned, SsdtFilesFound);
  
  // Close ACPI directory if we opened it
  if (AcpiDir != Directory && AcpiDir != NULL) {
    AcpiDir->Close(AcpiDir);
  }
  
  return EFI_SUCCESS;
}

/**
  Entry point for both UEFI Application and DXE Driver versions.
  
  @param[in] ImageHandle  The image handle of the UEFI Application/Driver.
  @param[in] SystemTable  A pointer to the EFI System Table.

  @retval EFI_SUCCESS     The application/driver ran successfully.
  @retval Other           Some error occurred.
**/
EFI_STATUS
EFIAPI
AcpiPatcherEntryPoint (
  IN EFI_HANDLE        ImageHandle,
  IN EFI_SYSTEM_TABLE  *SystemTable
  )
{
  EFI_STATUS                       Status;
  EFI_FILE_PROTOCOL                *SelfDir;
  
  // Very first thing - confirm we're running
  Print(L"*** ACPIPatcher Entry Point Called ***\n");
  
#ifdef DXE_DRIVER_BUILD
  Print(L"[DXE] ACPIPatcher DXE Driver v%d.%d loading...\n",
        ACPI_PATCHER_VERSION_MAJOR, ACPI_PATCHER_VERSION_MINOR);
  // Force console output for DXE driver debugging
  gST->ConOut->OutputString(gST->ConOut, L"[DXE] ACPIPatcher DXE Driver starting ACPI patching\r\n");
  
  // Store handles for delayed processing
  gImageHandle = ImageHandle;
  gSystemTable = SystemTable;
  
  // Check if file system is already available
  SelfDir = FsGetSelfDir();
  if (SelfDir != NULL) {
    Print(L"[DXE] File system already ready, proceeding with immediate patching\n");
    gFileSystemReady = TRUE;
  } else {
    Print(L"[DXE] File system not ready yet, setting up delayed patching\n");
    
    // Set up notification to wait for file system
    Status = WaitForFileSystemReady();
    if (EFI_ERROR(Status)) {
      Print(L"[DXE] ERROR: Failed to set up file system notification: %r\n", Status);
      // Continue anyway - we can still do basic ACPI discovery
    } else {
      Print(L"[DXE] File system notification set up successfully\n");
      Print(L"[DXE] Driver will remain resident and patch ACPI when storage is ready\n");
      // Return success so driver stays loaded and waits for file system
      return EFI_SUCCESS;
    }
  }
  
  // If we get here, either file system is ready or notification setup failed
  // Continue with immediate processing
  if (SelfDir == NULL) {
    Print(L"[DXE] Proceeding without file system access\n");
  }
  
#else
  AcpiDebugPrint(DEBUG_INFO, L"ACPIPatcher Application v%d.%d starting...\n",
                 ACPI_PATCHER_VERSION_MAJOR, ACPI_PATCHER_VERSION_MINOR);
  
  // Get the file system protocol from our own image
  SelfDir = FsGetSelfDir();
  if (SelfDir == NULL) {
    AcpiDebugPrint(DEBUG_ERROR, L"Failed to get file system - protocols may not be ready\n");
    return EFI_UNSUPPORTED;
  }
#endif

  // Get RSDP from the system table
  Status = EfiGetSystemConfigurationTable(&gEfiAcpi20TableGuid, (VOID**)&gRsdp);
  if (EFI_ERROR(Status)) {
    // Try ACPI 1.0 table if 2.0 is not available
    Status = EfiGetSystemConfigurationTable(&gEfiAcpiTableGuid, (VOID**)&gRsdp);
    if (EFI_ERROR(Status)) {
      AcpiDebugPrint(DEBUG_ERROR, L"Failed to find ACPI tables: %r\n", Status);
      return Status;
    }
    AcpiDebugPrint(DEBUG_INFO, L"Using ACPI 1.0 tables\n");
  } else {
    AcpiDebugPrint(DEBUG_INFO, L"Using ACPI 2.0+ tables\n");
  }

  // Get XSDT from RSDP
  if (gRsdp->XsdtAddress == 0) {
    AcpiDebugPrint(DEBUG_ERROR, L"XSDT address is invalid\n");
    return EFI_UNSUPPORTED;
  }

  gXsdt = (EFI_ACPI_DESCRIPTION_HEADER*)(UINTN)gRsdp->XsdtAddress;
  AcpiDebugPrint(DEBUG_INFO, L"XSDT found at " PTR_FMT L"\n", PTR_TO_INT(gXsdt));

  // Find FADT in XSDT
  Status = FindFadtInXsdt();
  if (EFI_ERROR(Status)) {
    AcpiDebugPrint(DEBUG_ERROR, L"Failed to find FADT: %r\n", Status);
    return Status;
  }

  // Perform ACPI patching - Pass the file system directory so it can load .aml files  
  Status = PatchAcpiTables(SelfDir, gXsdt, gFacp);
  if (EFI_ERROR(Status)) {
    AcpiDebugPrint(DEBUG_ERROR, L"ACPI patching failed: %r\n", Status);
    return Status;
  }

#ifdef DXE_DRIVER_BUILD
  Print(L"[DXE] ACPIPatcher DXE Driver loaded and patching completed!\n");
  gST->ConOut->OutputString(gST->ConOut, L"[DXE] ACPI tables have been patched - driver staying resident\r\n");
#else
  AcpiDebugPrint(DEBUG_INFO, L"ACPIPatcher completed successfully\n");
#endif
  return EFI_SUCCESS;
}

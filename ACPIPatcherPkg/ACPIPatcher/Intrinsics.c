/** @file
  Basic intrinsic functions for IA32 builds where CompilerIntrinsicsLib
  is not available (e.g., Darwin/macOS XCODE5 toolchain).
  
  This provides minimal implementations of standard C library functions
  that the compiler may generate calls to, redirecting them to appropriate
  EDK2 BaseMemoryLib functions.
**/

#include <Uefi.h>
#include <Library/BaseMemoryLib.h>

//
// Redirect compiler-generated memcpy calls to EDK2 CopyMem
//
void *
memcpy (
  void       *Destination,
  const void *Source,
  UINTN      Length
  )
{
  return CopyMem(Destination, Source, Length);
}

//
// Redirect compiler-generated memset calls to EDK2 SetMem
//
void *
memset (
  void  *Buffer,
  int   Value,
  UINTN Length
  )
{
  SetMem(Buffer, Length, (UINT8)Value);
  return Buffer;
}

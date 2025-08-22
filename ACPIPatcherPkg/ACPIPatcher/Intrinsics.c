/** @file
  Basic intrinsic functions for IA32 builds where CompilerIntrinsicsLib
  is not available (e.g., Darwin/macOS XCODE5 toolchain).
  
  This provides minimal implementations of standard C library functions
  that the compiler may generate calls to, redirecting them to appropriate
  EDK2 BaseMemoryLib functions.
  
  NOTE: This file is primarily for non-MSVC compilers. Visual Studio provides
  its own intrinsics and may not need these implementations.
**/

#include <Uefi.h>
#include <Library/BaseMemoryLib.h>

//
// Only provide these implementations for non-MSVC compilers
//
#if !defined(_MSC_VER)

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

#else

//
// For MSVC builds, provide a dummy symbol to ensure the compilation unit is not empty
// This prevents linker warnings and build system issues with empty object files
//
static const int __dummy_intrinsics_symbol = 0;

#endif // !defined(_MSC_VER)

## @file
# EFI/PI Reference Module Package for All Architectures
#
# (C) Copyright 2014 Hewlett-Packard Development Company, L.P.<BR>
# Copyright (c) 2007 - 2019, Intel Corporation. All rights reserved.<BR>
#
#    This program and the accompanying materials
#    are licensed and made available under the terms and conditions of the BSD License
#    which accompanies this distribution. The full text of the license may be found at
#    http://opensource.org/licenses/bsd-license.php
#
#    THE PROGRAM IS DISTRIBUTED UNDER THE BSD LICENSE ON AN "AS IS" BASIS,
#    WITHOUT WARRANTIES OR REPRESENTATIONS OF ANY KIND, EITHER EXPRESS OR IMPLIED.
#
##

[Defines]
  PLATFORM_NAME                  = ACPIPatcher
  PLATFORM_GUID                  = 856fe4ce-a20c-4524-b329-e379e287d376
  PLATFORM_VERSION               = 0.1
  DSC_SPECIFICATION              = 0x00010005
  OUTPUT_DIRECTORY               = Build/ACPIPatcher
  SUPPORTED_ARCHITECTURES        = IA32|X64|EBC|ARM|AARCH64
  BUILD_TARGETS                  = DEBUG|RELEASE|NOOPT
  SKUID_IDENTIFIER               = DEFAULT

[LibraryClasses]
  BaseLib|edk2/MdePkg/Library/BaseLib/BaseLib.inf
  UefiDriverEntryPoint|edk2/MdePkg/Library/UefiDriverEntryPoint/UefiDriverEntryPoint.inf
  UefiApplicationEntryPoint|edk2/MdePkg/Library/UefiApplicationEntryPoint/UefiApplicationEntryPoint.inf
  UefiBootServicesTableLib|edk2/MdePkg/Library/UefiBootServicesTableLib/UefiBootServicesTableLib.inf
  UefiRuntimeServicesTableLib|edk2/MdePkg/Library/UefiRuntimeServicesTableLib/UefiRuntimeServicesTableLib.inf
  MemoryAllocationLib|edk2/MdePkg/Library/UefiMemoryAllocationLib/UefiMemoryAllocationLib.inf
  UefiLib|edk2/MdePkg/Library/UefiLib/UefiLib.inf
  PrintLib|edk2/MdePkg/Library/BasePrintLib/BasePrintLib.inf
  BaseMemoryLib|edk2/MdePkg/Library/BaseMemoryLib/BaseMemoryLib.inf
  PcdLib|edk2/MdePkg/Library/BasePcdLibNull/BasePcdLibNull.inf
  DevicePathLib|edk2/MdePkg/Library/UefiDevicePathLib/UefiDevicePathLib.inf
  UefiRuntimeLib|edk2/MdePkg/Library/UefiRuntimeLib/UefiRuntimeLib.inf
  DebugLib|edk2/MdePkg/Library/BaseDebugLibNull/BaseDebugLibNull.inf
  RegisterFilterLib|edk2/MdePkg/Library/RegisterFilterLibNull/RegisterFilterLibNull.inf
  StackCheckLib|edk2/MdePkg/Library/StackCheckLib/StackCheckLib.inf
  StackCheckFailureHookLib|edk2/MdePkg/Library/StackCheckFailureHookLibNull/StackCheckFailureHookLibNull.inf

[Components]
  ACPIPatcherPkg/ACPIPatcher/ACPIPatcher.inf
  ACPIPatcherPkg/ACPIPatcher/ACPIPatcherDxe.inf
## @file
# ACPIPatcher Platform Build Script for Stuart Build System
#
# This module contains the setup and build configuration for the ACPIPatcher platform
# using the edk2-pytool Stuart build system.
#
# Copyright (c) Microsoft Corporation.
# SPDX-License-Identifier: BSD-2-Clause-Patent
##

import os
import sys
import logging
from pathlib import Path

try:
    from edk2toolext.environment import shell_environment
    from edk2toolext.environment.uefi_build import UefiBuilder
    from edk2toolext.invocables.edk2_ci_build import CiBuildSettingsManager
    from edk2toolext.invocables.edk2_platform_build import BuildSettingsManager
    from edk2toolext.invocables.edk2_setup import SetupSettingsManager, RequiredSubmodule
    from edk2toolext.invocables.edk2_update import UpdateSettingsManager
    from edk2toolext.invocables.edk2_pr_eval import PrEvalSettingsManager
    from edk2toollib.utility_functions import RunCmd
except ImportError as e:
    print("Error: Missing edk2-pytool packages. Install with:")
    print("pip install edk2-pytool-library edk2-pytool-extensions")
    sys.exit(1)


class SettingsManager(UpdateSettingsManager, SetupSettingsManager, 
                      PrEvalSettingsManager, CiBuildSettingsManager, BuildSettingsManager, UefiBuilder):
    """Settings Manager for ACPIPatcher Platform - Combined Platform Configuration"""

    def GetPackagesSupported(self):
        """Return a list of packages supported by this build"""
        return ("ACPIPatcherPkg",)

    def GetArchitecturesSupported(self):
        """Return a tuple of arch strings supported by this build"""
        return ("X64", "IA32")

    def GetTargetsSupported(self):
        """Return a tuple of targets (DEBUG, RELEASE) this build supports"""
        return ("DEBUG", "RELEASE", "NOOPT")

    def GetRequiredSubmodules(self):
        """Return iterable containing RequiredSubmodule objects for all 
        required submodules. If no required submodules return an empty iterable"""
        # Return empty list since EDK2 is handled by the CI workflow, not as a submodule
        return []

    def GetWorkspaceRoot(self):
        """Return the workspace root for initializing the SDE"""
        return os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

    def GetActiveScopes(self):
        """Return tuple containing scopes that should be active for this process"""
        return ("edk2-build", "cibuild")
    
    def GetPackagesPath(self):
        """Return paths where packages are located"""
        return [
            ".",
            "edk2"
        ]
    
    def GetName(self):
        """Return the name of the platform"""
        return "ACPIPatcher"

    def GetLoggingLevel(self, loggerType):
        """Get the logging level for a given type"""
        return "INFO"

    def FilterPackagesToTest(self, changedFilesList, potentialPackagesList):
        """Filter the list of packages to test based on changed files"""
        return ("ACPIPatcherPkg",)

    def GetPlatformDscAndConfig(self) -> tuple:
        """Return tuple for platform dsc and configuration for building"""
        return ("ACPIPatcherPkg/ACPIPatcherPkg.dsc", {})

    def SetPlatformDefaultEnv(self):
        """Set default environment variables"""
        return {
            "TARGET_ARCH": "X64",
            "TARGET": "RELEASE", 
            "TOOL_CHAIN_TAG": "VS2022"
        }
    def SetPlatformEnv(self):
        """Set platform specific environment variables"""
        self.env.SetValue("ACTIVE_PLATFORM", "ACPIPatcherPkg/ACPIPatcherPkg.dsc", "Platform Hardcoded")
        self.env.SetValue("PRODUCT_NAME", "ACPIPatcher", "Platform Hardcoded")
        self.env.SetValue("BUILDREPORTING", "TRUE", "Platform Hardcoded")
        self.env.SetValue("BUILDREPORT_TYPES", "PCD DEPEX FLASH BUILD_FLAGS LIBRARY FIXED_ADDRESS HASH", "Platform Hardcoded")
        
        # Set architecture and target from command line or defaults
        if hasattr(self, 'ACTIVE_ARCHITECTURE') and self.ACTIVE_ARCHITECTURE:
            self.env.SetValue("TARGET_ARCH", " ".join(self.ACTIVE_ARCHITECTURE), "Platform Hardcoded")
        
        if hasattr(self, 'ACTIVE_TARGETS') and self.ACTIVE_TARGETS:
            self.env.SetValue("TARGET", " ".join(self.ACTIVE_TARGETS), "Platform Hardcoded")
            
        return 0

    # UefiBuilder methods
    def PlatformPreBuild(self):
        """Platform specific pre-build actions"""
        return 0

    def PlatformPostBuild(self):
        """Platform specific post-build actions"""
        return 0

    def PlatformFlashImage(self):
        """Flash the ROM image to target device"""
        return 0

    def SetArchitectures(self, list_of_requested_architectures):
        """Set the architectures to build"""
        self.ACTIVE_ARCHITECTURE = list_of_requested_architectures

    def SetPackages(self, list_of_requested_packages):
        """Set the packages to build"""
        self.ACTIVE_PACKAGES = list_of_requested_packages

    def SetTargets(self, list_of_requested_targets):
        """Set the targets to build"""
        self.ACTIVE_TARGETS = list_of_requested_targets

    def GetPluginSettings(self):
        """Return a dictionary of plugin settings to control plugin behavior"""
        return {
            "CompilerPlugin": {
                "CompilerPath": ""
            },
            "DebugMacroCheck": {
                "Enabled": False  # Disable problematic plugin
            }
        }
    
    def GetEnvironmentDescriptorFiles(self):
        """Return list of environment descriptor files"""
        return []

    def GetDscName(self):
        """Return the DSC file name for the build"""
        return "ACPIPatcherPkg/ACPIPatcherPkg.dsc"
    
    def GetFdfName(self):
        """Return the FDF file name for the build (optional)"""
        return None  # No FDF file for this simple build

    def GetConfigurationElements(self):
        """Return list of configuration elements for this platform"""
        # This method should return an empty list since we don't have custom configuration elements
        return []

    def GetBuildInfoFiles(self):
        """Return list of files that contain build information"""
        return []

    def GetGuidNameFile(self):
        """Return path to GUID name file (optional)"""
        return None


if __name__ == "__main__":
    import argparse
    import sys
    from edk2toolext import edk2_logging
    
    # Setup argument parser
    parser = argparse.ArgumentParser(description='ACPIPatcher Platform Build Script')
    parser.add_argument("--version", action="version", version="ACPIPatcher Platform Builder 1.0")
    
    args = parser.parse_args()
    
    # Setup logging
    edk2_logging.setup_txt_logger()
    
    print("ACPIPatcher Platform Stuart Configuration Loaded Successfully")

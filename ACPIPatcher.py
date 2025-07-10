#!/usr/bin/env python3
"""
ACPIPatcher Platform Build Script for Stuart

This script provides platform-specific build customization for the Stuart build system.
It extends the base Stuart functionality with ACPIPatcher-specific configurations.
"""

import os
import sys
import logging
from pathlib import Path

# Stuart imports - these will be available when edk2-pytool-extensions is installed
try:
    from edk2toolext.environment import shell_environment
    from edk2toolext.environment.uefi_build import UefiBuilder
    from edk2toolext.invocables.edk2_platform_build import BuildSettingsManager
    from edk2toolext.invocables.edk2_pr_eval import PrEvalSettingsManager
    from edk2toolext.invocables.edk2_setup import SetupSettingsManager
    from edk2toolext.invocables.edk2_update import UpdateSettingsManager
    from edk2toollib.utility_functions import RunCmd
    STUART_AVAILABLE = True
except ImportError:
    STUART_AVAILABLE = False
    logging.warning("Stuart dependencies not available - this script requires edk2-pytool-extensions")

class ACPIPatcherSettingsManager:
    """Settings manager for ACPIPatcher Stuart builds"""
    
    def __init__(self):
        if not STUART_AVAILABLE:
            raise ImportError("Stuart dependencies not available")
        
        # Mix in the required base classes
        self.__class__.__bases__ = (BuildSettingsManager, SetupSettingsManager, UpdateSettingsManager, PrEvalSettingsManager)
        
        self.workspace = Path(os.path.abspath(__file__)).parent
        self.package_name = "ACPIPatcherPkg"
        
    def GetActiveScopes(self):
        """Return active scopes for the build"""
        return ["acpipatcher", "edk2-build"]
    
    def GetWorkspaceRoot(self):
        """Return the workspace root directory"""
        return str(self.workspace)
    
    def GetPackagesPath(self):
        """Return paths to packages"""
        return [str(self.workspace)]
    
    def GetName(self):
        """Return the name of the platform"""
        return "ACPIPatcher"
    
    def GetPackagesSupported(self):
        """Return list of supported packages"""
        return [self.package_name]
    
    def GetArchitecturesSupported(self):
        """Return list of supported architectures"""
        return ["IA32", "X64"]
    
    def GetTargetsSupported(self):
        """Return list of supported build targets"""
        return ["DEBUG", "RELEASE", "NOOPT"]
    
    def GetRequiredSubmodules(self):
        """Return required submodules"""
        return [
            "BaseTools/Source/C/BrotliCompress/brotli",
            "CryptoPkg/Library/OpensslLib/openssl", 
            "MdeModulePkg/Library/BrotliCustomDecompressLib/brotli",
            "UnitTestFrameworkPkg/Library/CmockaLib/cmocka"
        ]
    
    def SetPlatformEnv(self):
        """Set platform-specific environment variables"""
        shell_environment.GetEnvironment().set_shell_var("ACTIVE_PLATFORM", f"{self.package_name}/{self.package_name}.dsc")
        shell_environment.GetEnvironment().set_shell_var("TARGET_ARCH", "IA32 X64")
        
        # Set toolchain-specific variables
        tool_chain = shell_environment.GetEnvironment().get_shell_var("TOOL_CHAIN_TAG")
        if tool_chain:
            if tool_chain.startswith("VS"):
                shell_environment.GetEnvironment().set_shell_var("TOOL_CHAIN_TAG", tool_chain)
            elif tool_chain == "GCC5":
                shell_environment.GetEnvironment().set_shell_var("TOOL_CHAIN_TAG", "GCC5")
                # Additional GCC5 setup if needed
        
        return 0
    
    def SetArchitectures(self, list_of_requested_architectures):
        """Set target architectures"""
        self.architectures = " ".join(list_of_requested_architectures)
        shell_environment.GetEnvironment().set_shell_var("TARGET_ARCH", self.architectures)
        return self.architectures.split()
    
    def GetPlatformDscAndConfig(self):
        """Return platform DSC and configuration"""
        return (f"{self.package_name}/{self.package_name}.dsc", {})
    
    def GetLoggingLevel(self, loggerType):
        """Return logging level"""
        return logging.INFO
    
    def FilterPackagesToTest(self, changedFilesList, potentialPackagesList):
        """Filter packages to test based on changed files"""
        # Always test ACPIPatcher if any files changed
        if changedFilesList:
            return [self.package_name]
        return []
    
    def GetPlatformName(self):
        """Return platform name"""
        return "ACPIPatcher"
    
    def GetCustomBuildCommands(self):
        """Return custom build commands"""
        commands = []
        
        # Add custom pre-build commands
        commands.append({
            "name": "Pre-build validation",
            "command": "python",
            "args": ["-c", "print('Starting ACPIPatcher build validation...')"],
            "working_dir": str(self.workspace)
        })
        
        return commands
    
    def GetCustomPostBuildCommands(self):
        """Return custom post-build commands"""
        commands = []
        
        # Add custom post-build commands
        commands.append({
            "name": "Post-build validation",
            "command": "python",
            "args": ["-c", "print('ACPIPatcher build completed successfully!')"],
            "working_dir": str(self.workspace)
        })
        
        return commands

class ACPIPatcherPlatformBuilder:
    """Platform-specific builder for ACPIPatcher"""
    
    def __init__(self):
        if not STUART_AVAILABLE:
            raise ImportError("Stuart dependencies not available")
        
        # Mix in the required base class
        self.__class__.__bases__ = (UefiBuilder,)
        
        self.settings = ACPIPatcherSettingsManager()
        super().__init__()
    
    def SetPlatformEnv(self):
        """Set platform environment"""
        self.settings.SetPlatformEnv()
        return 0
    
    def PlatformPreBuild(self):
        """Pre-build platform setup"""
        logging.info("ACPIPatcher Pre-build setup")
        
        # Verify required files exist
        required_files = [
            f"{self.settings.package_name}/{self.settings.package_name}.dsc",
            f"{self.settings.package_name}/ACPIPatcher/ACPIPatcher.inf"
        ]
        
        for file in required_files:
            file_path = Path(self.settings.workspace) / file
            if not file_path.exists():
                logging.error(f"Required file not found: {file}")
                return 1
        
        logging.info("All required files verified")
        return 0
    
    def PlatformPostBuild(self):
        """Post-build platform cleanup"""
        logging.info("ACPIPatcher Post-build cleanup")
        
        # Verify build outputs
        build_output_base = Path(self.settings.workspace) / "Build"
        efi_files = list(build_output_base.rglob("*.efi"))
        
        if efi_files:
            logging.info(f"Found {len(efi_files)} EFI files:")
            for efi_file in efi_files:
                logging.info(f"  - {efi_file}")
        else:
            logging.warning("No EFI files found in build output")
        
        return 0
    
    def PlatformFlashImage(self):
        """Flash image creation (not applicable for ACPIPatcher)"""
        logging.info("ACPIPatcher does not require flash image creation")
        return 0

def main():
    """Main entry point for ACPIPatcher Stuart build"""
    import argparse
    
    parser = argparse.ArgumentParser(description="ACPIPatcher Stuart Build Script")
    parser.add_argument("--build", action="store_true", help="Run build process")
    parser.add_argument("--setup", action="store_true", help="Run setup process")
    parser.add_argument("--update", action="store_true", help="Run update process")
    parser.add_argument("--clean", action="store_true", help="Clean build outputs")
    parser.add_argument("--arch", default="X64", help="Target architecture")
    parser.add_argument("--target", default="RELEASE", help="Build target")
    parser.add_argument("--toolchain", default="VS2019", help="Toolchain to use")
    
    args = parser.parse_args()
    
    # Set up logging
    logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
    
    if not STUART_AVAILABLE:
        logging.error("Stuart dependencies not available. Please install edk2-pytool-extensions.")
        return 1
    
    settings = ACPIPatcherSettingsManager()
    
    if args.setup:
        logging.info("Running ACPIPatcher Stuart setup...")
        # Setup logic would go here
        return 0
    
    if args.update:
        logging.info("Running ACPIPatcher Stuart update...")
        # Update logic would go here
        return 0
    
    if args.clean:
        logging.info("Cleaning ACPIPatcher build outputs...")
        build_dir = Path(settings.workspace) / "Build"
        if build_dir.exists():
            import shutil
            shutil.rmtree(build_dir)
            logging.info("Build directory cleaned")
        return 0
    
    if args.build:
        logging.info("Running ACPIPatcher Stuart build...")
        builder = ACPIPatcherPlatformBuilder()
        
        # Set environment variables
        os.environ["TARGET_ARCH"] = args.arch
        os.environ["TARGET"] = args.target
        os.environ["TOOL_CHAIN_TAG"] = args.toolchain
        
        # Run build
        ret = builder.Go()
        if ret != 0:
            logging.error("Build failed")
            return ret
        
        logging.info("Build completed successfully")
        return 0
    
    parser.print_help()
    return 0

if __name__ == "__main__":
    sys.exit(main())

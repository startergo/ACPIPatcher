## @file
# CI Configuration for ACPIPatcher
# This file provides the configuration for Stuart-style builds
#
# Copyright (c) 2024, ACPIPatcher Project
# SPDX-License-Identifier: BSD-2-Clause-Patent
##

import os
import sys
import logging
from pathlib import Path
from edk2toolext.environment import shell_environment
from edk2toolext.invocables.edk2_ci_build import CiBuildSettingsManager
from edk2toolext.invocables.edk2_setup import SetupSettingsManager, RequiredSubmodule
from edk2toolext.invocables.edk2_update import UpdateSettingsManager
from edk2toolext.invocables.edk2_pr_eval import PrEvalSettingsManager
from edk2toolext.invocables.edk2_platform_build import PlatformSettingsManager
from edk2toollib.utility_functions import GetHostInfo


class Settings(CiBuildSettingsManager, UpdateSettingsManager, SetupSettingsManager, PrEvalSettingsManager, PlatformSettingsManager):

    def __init__(self):
        self.ActualPackages = []
        self.ActualTargets = []
        self.ActualArchitectures = []
        self.ActualToolChainTag = ""
        self.ActualScopes = None

    # ####################################################################################### #
    #                             Traditional PI Settings                                     #
    # ####################################################################################### #

    def GetPackagesSupported(self):
        ''' return iterable of edk2 packages supported by this build.
        These should be edk2 workspace relative paths '''
        return ("ACPIPatcherPkg",)

    def GetArchitecturesSupported(self):
        ''' return iterable of edk2 architectures supported by this build '''
        return ("IA32", "X64")

    def GetTargetsSupported(self):
        ''' return iterable of edk2 target tags supported by this build '''
        return ("DEBUG", "RELEASE")

    def GetRequiredSubmodules(self):
        ''' return iterable containing RequiredSubmodule objects.
        If no RequiredSubmodules return an empty iterable
        '''
        rs = []
        return rs

    def GetWorkspaceRoot(self):
        ''' Return the workspace root relative to repo root '''
        return "."

    def GetDependencies(self):
        ''' Return Git Repository Dependencies

        Return an iterable of dictionary objects with the following fields
        {
        "Path": <required> Workspace relative path
        "Url": <required> Url of git repo
        "Commit": <optional> Commit to checkout of repo
        "Branch": <optional> Branch to checkout (will checkout most recent commit in branch)
        "Full": <optional> Boolean to do shallow or Full checkout.  (default is False)
        "ReferencePath": <optional> Workspace relative path to git repo to use as "reference"
        }
        '''
        return []

    def SetPackages(self, list_of_requested_packages):
        ''' Confirm the requested package list is valid and configure SettingsManager
        to build the requested packages.
        Raise UnsupportedException if a requested_package is not supported
        '''
        unsupported = set(list_of_requested_packages) - \
            set(self.GetPackagesSupported())
        if(len(unsupported) > 0):
            raise Exception(
                "Unsupported Package Requested: " + " ".join(unsupported))
        self.ActualPackages = list_of_requested_packages

    def SetArchitectures(self, list_of_requested_architectures):
        ''' Confirm the requests architecture list is valid and configure SettingsManager
        to run only the requested architectures.
        Raise Exception if a requested_architecture is not supported
        '''
        unsupported = set(list_of_requested_architectures) - \
            set(self.GetArchitecturesSupported())
        if(len(unsupported) > 0):
            raise Exception(
                "Unsupported Architecture Requested: " + " ".join(unsupported))
        self.ActualArchitectures = list_of_requested_architectures

    def SetTargets(self, list_of_requested_target):
        ''' Confirm the request target list is valid and configure SettingsManager
        to run only the requested targets.
        Raise UnsupportedException if a requested_target is not supported
        '''
        unsupported = set(list_of_requested_target) - \
            set(self.GetTargetsSupported())
        if(len(unsupported) > 0):
            raise Exception(
                "Unsupported Target Requested: " + " ".join(unsupported))
        self.ActualTargets = list_of_requested_target

    # ####################################################################################### #
    #                         Supported Tool Chain configurations                            #
    # ####################################################################################### #

    def GetToolChainTag(self):
        ''' get the tool chain tag '''
        return self.ActualToolChainTag

    def SetToolChainTag(self, toolchain_tag):
        ''' set the tool chain tag.  Return success code or raise exception '''
        self.ActualToolChainTag = toolchain_tag
        return 0

    # ####################################################################################### #
    #                         Documentation Configuration                                     #
    # ####################################################################################### #

    def GetName(self):
        return "ACPIPatcher"

    def GetMaintainerList(self):
        return []

    def GetEmailAddressList(self):
        return []

    def GetDefaultEnvironmentVars(self):
        ''' get environment variables for this build '''
        result = super().GetDefaultEnvironmentVars()
        result.update({
            "ACTIVE_PLATFORM": "ACPIPatcherPkg/ACPIPatcherPkg.dsc",
            "TARGET_ARCH": " ".join(self.ActualArchitectures),
            "TARGET": " ".join(self.ActualTargets),
            "TOOL_CHAIN_TAG": self.GetToolChainTag()
        })
        return result

    def GetLoggingLevel(self, loggerType):
        ''' Get the logging level for a given type
        '''
        return super().GetLoggingLevel(loggerType)

    def SetLoggingLevel(self, loggerType, loggerLevel):
        ''' Set the logging level for a given type
        '''
        return super().SetLoggingLevel(loggerType, loggerLevel)

    # ####################################################################################### #
    #                          Override for CI Build                                         #
    # ####################################################################################### #

    def GetDscName(self, packagename) -> str:
        ''' Get the DSC file name for the given package
        '''
        if packagename == "ACPIPatcherPkg":
            return "ACPIPatcherPkg.dsc"
        return super().GetDscName(packagename)

    def GetFvNameList(self, packagename):
        ''' Get FV names for package '''
        return []

    def GetCustomConfigureOptions(self, packagename):
        ''' Get package specific configure options '''
        return []

    def GetCustomBuildOptions(self, packagename):
        ''' Get package specific build options '''
        return []

    def FilterPackagesToTest(self, chglist, potentlist):
        ''' Filter potential packages to test based on changes '''
        build_these_packages = []
        change_list = set(chglist)
        
        # If any files in ACPIPatcherPkg changed, build it
        if any("ACPIPatcherPkg" in x for x in change_list):
            build_these_packages.append("ACPIPatcherPkg")
        
        # If no changes found or this is a full build, build all packages
        if not build_these_packages:
            build_these_packages = self.GetPackagesSupported()
            
        return build_these_packages

    # ####################################################################################### #
    #                          Additional Required Methods                                    #
    # ####################################################################################### #

    def GetActiveScopes(self):
        ''' Return tuple containing scopes that should be active for this process '''
        if self.ActualScopes is None:
            scopes = ("edk2-build", "cibuild")
            
            self.ActualToolChainTag = shell_environment.GetBuildVars().GetValue("TOOL_CHAIN_TAG", "")
            
            self.ActualScopes = scopes
        return self.ActualScopes

    def GetPlatformDscAndConfig(self) -> tuple:
        ''' If a platform desires to provide its DSC then Policy 4 will evaluate if
        any of the changes will be built in the dsc.

        The tuple should be (<workspace relative path to dsc file>, <input dictionary of dsc key value pairs>)
        '''
        dsc = "ACPIPatcherPkg/ACPIPatcherPkg.dsc"
        config = {}
        return (dsc, config)

    # ####################################################################################### #
    #                          Platform Build Methods (stuart_build)                         #
    # ####################################################################################### #

    def GetPlatformName(self):
        ''' Get platform name '''
        return "ACPIPatcher"

    def GetPackagesPath(self):
        ''' Return a list of paths that should be mapped as edk2 PackagesPath '''
        return []

    def GetPlatformDsc(self):
        ''' Return the platform DSC file path '''
        return os.path.join("ACPIPatcherPkg", "ACPIPatcherPkg.dsc")

    def GetOutputFolderBaseName(self):
        ''' Base name for output folder '''
        return "Build"

    def GetTargetType(self):
        ''' Get the target to pass to the build '''
        return " ".join(self.ActualTargets) if self.ActualTargets else "DEBUG"

    def GetArchitecture(self):
        ''' Get the target arch to pass to the build '''
        return " ".join(self.ActualArchitectures) if self.ActualArchitectures else "IA32 X64"

    def GetBuildEnvironmentVariables(self):
        ''' Return a dictionary of environment variables that should be set '''
        result = {}
        result["ACTIVE_PLATFORM"] = self.GetPlatformDsc()
        result["TARGET_ARCH"] = self.GetArchitecture()
        result["TARGET"] = self.GetTargetType()
        result["TOOL_CHAIN_TAG"] = self.GetToolChainTag() or "GCC5"
        return result

    def FlashRomImage(self):
        ''' Platform can choose to flash the ROM image '''
        return 0

    def PlatformPreBuild(self):
        ''' Platform specific pre-build operations '''
        return 0

    def PlatformPostBuild(self):
        ''' Platform specific post-build operations '''
        return 0

    def PlatformFlashImage(self):
        ''' Platform specific flash operations '''
        return 0

    def SetPlatformEnv(self):
        ''' Platform can customize the environment '''
        shell_environment.GetBuildVars().SetValue("ACTIVE_PLATFORM", self.GetPlatformDsc(), "Set in CISettings.py")
        shell_environment.GetBuildVars().SetValue("TARGET_ARCH", self.GetArchitecture(), "Set in CISettings.py")
        shell_environment.GetBuildVars().SetValue("TARGET", self.GetTargetType(), "Set in CISettings.py")
        shell_environment.GetBuildVars().SetValue("TOOL_CHAIN_TAG", self.GetToolChainTag() or "GCC5", "Set in CISettings.py")
        return 0

#!/usr/bin/env python3
"""
ACPIPatcher Build Script

Simple, reliable build script for ACPIPatcher UEFI application.
Uses traditional EDK2 build system without external dependencies.
"""

import os
import sys
import subprocess
import platform
import shutil
import argparse
import logging

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')

class ACPIPatcherBuilder:
    """Simple builder for ACPIPatcher using traditional EDK2 build system"""
    
    def __init__(self, arch='X64', build_type='RELEASE', toolchain=None):
        self.script_dir = os.path.dirname(os.path.abspath(__file__))
        self.workspace = self.script_dir
        self.edk2_path = os.path.join(self.workspace, "temp_edk2")
        self.package_path = os.path.join(self.workspace, "ACPIPatcherPkg")
        self.arch = arch
        self.build_type = build_type
        self.toolchain = toolchain
        self.is_ci = os.environ.get('CI', '').lower() == 'true'
        
    def detect_python(self):
        """Detect available Python executable"""
        python_candidates = ['python3', 'python', 'py']
        
        for candidate in python_candidates:
            try:
                result = subprocess.run([candidate, '--version'], 
                                      capture_output=True, text=True, timeout=10)
                if result.returncode == 0 and 'Python 3' in result.stdout:
                    logging.info(f"✓ Found Python: {candidate}")
                    return candidate
            except (subprocess.TimeoutExpired, FileNotFoundError):
                continue
                
        logging.error("No suitable Python 3 found")
        return None
        
    def detect_toolchain(self):
        """Auto-detect available toolchain"""
        # Use specified toolchain if provided
        if self.toolchain:
            logging.info(f"Using specified toolchain: {self.toolchain}")
            return self.toolchain
            
        system = platform.system()
        
        if system == "Windows":
            # Check for Visual Studio
            try:
                result = subprocess.run(['where', 'cl'], capture_output=True, text=True)
                if result.returncode == 0:
                    logging.info("✓ Visual Studio compiler detected")
                    # Try to detect VS version from environment
                    if 'VS2022' in os.environ.get('PATH', '') or 'VS170COMNTOOLS' in os.environ:
                        return 'VS2022'
                    elif 'VS2019' in os.environ.get('PATH', '') or 'VS160COMNTOOLS' in os.environ:
                        return 'VS2019'
                    else:
                        return 'VS2019'  # Default fallback
            except FileNotFoundError:
                pass
                
            # Check for Cygwin GCC
            cygwin_paths = [
                os.path.join(os.environ.get('SystemDrive', 'C:'), 'cygwin64', 'bin', 'gcc.exe'),
                os.path.join(os.environ.get('SystemDrive', 'C:'), 'cygwin', 'bin', 'gcc.exe'),
                os.path.join(os.environ.get('ProgramFiles', ''), 'cygwin64', 'bin', 'gcc.exe'),
                os.path.join(os.environ.get('ProgramFiles', ''), 'cygwin', 'bin', 'gcc.exe'),
                r'C:\tools\cygwin\bin\gcc.exe'  # GitHub Actions location
            ]
            
            for gcc_path in cygwin_paths:
                if os.path.exists(gcc_path):
                    logging.info(f"✓ Cygwin GCC found at {os.path.dirname(gcc_path)}")
                    os.environ['BASETOOLS_CYGWIN_BUILD'] = 'TRUE'
                    os.environ['BASETOOLS_CYGWIN_PATH'] = os.path.dirname(os.path.dirname(gcc_path))
                    return 'GCC5'
                    
        else:  # Linux/macOS
            # Check for GCC
            try:
                result = subprocess.run(['gcc', '--version'], capture_output=True, text=True)
                if result.returncode == 0:
                    logging.info("✓ GCC found")
                    return 'GCC5'
            except FileNotFoundError:
                pass
                
            # Check for Clang
            try:
                result = subprocess.run(['clang', '--version'], capture_output=True, text=True)
                if result.returncode == 0:
                    logging.info("✓ Clang found")
                    os.environ['CC'] = 'clang'
                    os.environ['CXX'] = 'clang++'
                    if system == "Darwin":  # macOS
                        return 'XCODE5'
                    else:
                        # For Linux, prefer GCC5 over CLANG38 as it's more reliable
                        logging.info("Preferring GCC5 over CLANG for Linux builds")
                        return 'GCC5'
            except FileNotFoundError:
                pass
                
        logging.warning("No suitable toolchain detected")
        return 'GCC5'  # Default fallback
        
    def setup_edk2_environment(self):
        """Set up EDK2 environment variables"""
        logging.info("Setting up EDK2 environment...")
        
        os.environ['WORKSPACE'] = self.edk2_path
        os.environ['EDK_TOOLS_PATH'] = os.path.join(self.edk2_path, 'BaseTools')
        os.environ['BASE_TOOLS_PATH'] = os.path.join(self.edk2_path, 'BaseTools')
        os.environ['CONF_PATH'] = os.path.join(self.edk2_path, 'Conf')
        
        # Detect and set Python
        python_cmd = self.detect_python()
        if python_cmd:
            os.environ['PYTHON_COMMAND'] = python_cmd
        
        # Set NASM if available
        nasm_locations = [
            'nasm',  # In PATH
            os.path.join(os.environ.get('ProgramFiles', ''), 'NASM', 'nasm.exe'),
            os.path.join(os.environ.get('ProgramFiles(x86)', ''), 'NASM', 'nasm.exe'),
            os.path.join(os.environ.get('SystemDrive', 'C:'), 'NASM', 'nasm.exe')
        ]
        
        nasm_found = False
        for nasm_path in nasm_locations:
            try:
                if nasm_path == 'nasm':
                    result = subprocess.run(['nasm', '-v'], capture_output=True, text=True)
                    if result.returncode == 0:
                        logging.info("✓ NASM found in PATH")
                        nasm_found = True
                        break
                elif os.path.exists(nasm_path):
                    os.environ['NASM_PREFIX'] = os.path.dirname(nasm_path) + os.sep
                    logging.info(f"✓ NASM found at {nasm_path}")
                    nasm_found = True
                    break
            except FileNotFoundError:
                continue
        
        if not nasm_found:
            logging.warning("NASM not found - assembly compilation may fail")
            logging.warning("Install NASM from https://www.nasm.us/ or via package manager")
            logging.warning("  Ubuntu/Debian: sudo apt-get install nasm")
            logging.warning("  macOS: brew install nasm")
            logging.warning("  Windows: choco install nasm")
            
    def check_edk2_workspace(self):
        """Check if EDK2 workspace is properly set up"""
        if not os.path.exists(self.edk2_path):
            logging.error(f"EDK2 workspace not found at {self.edk2_path}")
            logging.error("Please run the setup script first to clone EDK2")
            return False
            
        basetools_path = os.path.join(self.edk2_path, 'BaseTools')
        if not os.path.exists(basetools_path):
            logging.error("BaseTools not found in EDK2 workspace")
            return False
            
        package_in_edk2 = os.path.join(self.edk2_path, 'ACPIPatcherPkg')
        if not os.path.exists(package_in_edk2):
            logging.error("ACPIPatcherPkg not found in EDK2 workspace")
            logging.error("Please run the setup script first to copy the package")
            return False
            
        return True
        
    def build_basetools(self):
        """Build EDK2 BaseTools"""
        logging.info("Building BaseTools...")
        
        # Change to EDK2 directory
        original_cwd = os.getcwd()
        os.chdir(self.edk2_path)
        
        try:
            system = platform.system()
            
            if system == "Windows":
                logging.info("Building BaseTools on Windows...")
                
                # First, try to build BaseTools using the toolsetup.bat approach
                # This is more reliable than edksetup.bat for building tools
                cmd = ['cmd', '/c', 'BaseTools\\toolsetup.bat', 'forcerebuild']
                result = subprocess.run(cmd, cwd=self.edk2_path)
                
                if result.returncode != 0:
                    logging.warning("toolsetup.bat failed, trying edksetup.bat...")
                    # Fallback to edksetup.bat
                    cmd = ['cmd', '/c', 'edksetup.bat', 'ForceRebuild']
                    result = subprocess.run(cmd, cwd=self.edk2_path)
                    
                    if result.returncode != 0:
                        logging.warning("edksetup.bat also failed, trying manual nmake...")
                        # Manual build attempt
                        c_dir = os.path.join(self.edk2_path, 'BaseTools', 'Source', 'C')
                        if os.path.exists(c_dir):
                            manual_result = subprocess.run(['cmd', '/c', 'nmake'], cwd=c_dir)
                            if manual_result.returncode != 0:
                                logging.error("All BaseTools build attempts failed on Windows")
                                return False
                
                # Check if tools were built successfully
                basetools_bin = os.path.join(self.edk2_path, 'BaseTools', 'Bin', 'Win32')
                required_tools = ['GenFv.exe', 'GenFfs.exe', 'GenFw.exe', 'GenSec.exe']
                missing_tools = []
                
                for tool in required_tools:
                    tool_path = os.path.join(basetools_bin, tool)
                    if not os.path.exists(tool_path):
                        missing_tools.append(tool)
                
                if missing_tools:
                    logging.warning(f"Some BaseTools are missing: {missing_tools}")
                    logging.warning("Build may fail, but continuing...")
                else:
                    logging.info("✓ All required BaseTools found")
                
                # Add BaseTools to PATH for Windows
                basetools_wrappers = os.path.join(self.edk2_path, 'BaseTools', 'BinWrappers', 'WindowsLike')
                current_path = os.environ.get('PATH', '')
                
                if os.path.exists(basetools_bin):
                    os.environ['PATH'] = f"{basetools_bin};{current_path}"
                    logging.info(f"Added {basetools_bin} to PATH")
                if os.path.exists(basetools_wrappers):
                    os.environ['PATH'] = f"{basetools_wrappers};{current_path}"
                    logging.info(f"Added {basetools_wrappers} to PATH")
                    
            else:  # Linux/macOS
                logging.info("Building BaseTools on Unix/Linux...")
                
                # Check for essential build tools first
                essential_tools = ['make', 'gcc', 'nasm']
                missing_tools = []
                
                for tool in essential_tools:
                    try:
                        result = subprocess.run([tool, '--version'], capture_output=True, text=True)
                        if result.returncode == 0:
                            logging.info(f"✓ {tool} found")
                        else:
                            missing_tools.append(tool)
                    except FileNotFoundError:
                        missing_tools.append(tool)
                
                if missing_tools:
                    logging.error(f"Missing essential build tools: {missing_tools}")
                    logging.error("Please install missing tools:")
                    logging.error("  Ubuntu/Debian: sudo apt-get install build-essential nasm")
                    logging.error("  CentOS/RHEL: sudo yum install gcc make nasm")
                    logging.error("  macOS: xcode-select --install && brew install nasm")
                    return False
                
                # First run edksetup.sh to set up environment
                setup_result = subprocess.run(['bash', '-c', 'source edksetup.sh BaseTools'], cwd=self.edk2_path)
                if setup_result.returncode != 0:
                    logging.warning("edksetup.sh had issues, continuing with manual build...")
                
                # Build C tools explicitly - this is crucial for GenFw and other tools
                logging.info("Building BaseTools C utilities...")
                c_build_cmd = ['make', '-C', 'BaseTools/Source/C']
                c_result = subprocess.run(c_build_cmd, cwd=self.edk2_path)
                
                if c_result.returncode != 0:
                    logging.warning("Initial C build failed, trying alternative approaches...")
                    
                    # Try building in the C directory directly
                    c_dir = os.path.join(self.edk2_path, 'BaseTools', 'Source', 'C')
                    if os.path.exists(c_dir):
                        logging.info("Trying direct make in BaseTools C directory...")
                        alt_result = subprocess.run(['make'], cwd=c_dir)
                        
                        if alt_result.returncode != 0:
                            # Try make with specific targets
                            logging.info("Trying to build specific BaseTools targets...")
                            targets = ['GenFv', 'GenFfs', 'GenFw', 'GenSec', 'VfrCompile']
                            for target in targets:
                                target_result = subprocess.run(['make', target], cwd=c_dir)
                                if target_result.returncode == 0:
                                    logging.info(f"✓ {target} built successfully")
                                else:
                                    logging.warning(f"Failed to build {target}")
                
                # Verify that GenFw and other critical tools are available
                basetools_bin = os.path.join(self.edk2_path, 'BaseTools', 'Source', 'C', 'bin')
                basetools_wrappers = os.path.join(self.edk2_path, 'BaseTools', 'BinWrappers', 'PosixLike')
                
                # Check for GenFw specifically since it's needed for EFI generation
                genfw_locations = [
                    os.path.join(basetools_bin, 'GenFw'),
                    os.path.join(basetools_wrappers, 'GenFw'),
                    os.path.join(self.edk2_path, 'BaseTools', 'Source', 'C', 'GenFw', 'GenFw')
                ]
                
                genfw_found = False
                for genfw_path in genfw_locations:
                    if os.path.exists(genfw_path) and os.access(genfw_path, os.X_OK):
                        logging.info(f"✓ GenFw found at {genfw_path}")
                        genfw_found = True
                        break
                
                if not genfw_found:
                    logging.error("GenFw tool not found - EFI generation will fail!")
                    logging.info("Attempting to build GenFw specifically...")
                    
                    # Try building GenFw from its source directory
                    genfw_dir = os.path.join(self.edk2_path, 'BaseTools', 'Source', 'C', 'GenFw')
                    if os.path.exists(genfw_dir):
                        logging.info(f"Building GenFw from {genfw_dir}")
                        genfw_result = subprocess.run(['make'], cwd=genfw_dir)
                        if genfw_result.returncode == 0:
                            logging.info("✓ GenFw built successfully")
                            # Check if it's now available
                            genfw_exe = os.path.join(genfw_dir, 'GenFw')
                            if os.path.exists(genfw_exe):
                                # Make sure bin directory exists and copy the executable
                                os.makedirs(basetools_bin, exist_ok=True)
                                shutil.copy2(genfw_exe, os.path.join(basetools_bin, 'GenFw'))
                                logging.info(f"✓ GenFw copied to {basetools_bin}")
                                genfw_found = True
                        else:
                            logging.error("Failed to build GenFw")
                    
                    # If still not found, try a global make in BaseTools/Source/C
                    if not genfw_found:
                        logging.info("Trying global BaseTools C build...")
                        c_result = subprocess.run(['make', 'clean'], cwd=os.path.join(self.edk2_path, 'BaseTools', 'Source', 'C'))
                        c_result = subprocess.run(['make'], cwd=os.path.join(self.edk2_path, 'BaseTools', 'Source', 'C'))
                        
                        if c_result.returncode == 0:
                            # Check again for GenFw
                            for genfw_path in genfw_locations:
                                if os.path.exists(genfw_path) and os.access(genfw_path, os.X_OK):
                                    logging.info(f"✓ GenFw found after global build at {genfw_path}")
                                    genfw_found = True
                                    break
                    
                    if not genfw_found:
                        logging.error("Failed to build GenFw - build will likely fail")
                        logging.error("This is usually caused by missing NASM or build dependencies")
                        logging.error("Please ensure NASM is installed and available in PATH")
                        return False
                
                # Add BaseTools to PATH with multiple possible locations
                current_path = os.environ.get('PATH', '')
                paths_to_add = []
                
                if os.path.exists(basetools_bin):
                    paths_to_add.append(basetools_bin)
                if os.path.exists(basetools_wrappers):
                    paths_to_add.append(basetools_wrappers)
                
                # Also add individual tool directories
                tool_dirs = ['GenFv', 'GenFfs', 'GenFw', 'GenSec', 'VfrCompile']
                for tool_dir in tool_dirs:
                    tool_path = os.path.join(self.edk2_path, 'BaseTools', 'Source', 'C', tool_dir)
                    if os.path.exists(tool_path):
                        paths_to_add.append(tool_path)
                
                if paths_to_add:
                    new_path = ':'.join(paths_to_add) + ':' + current_path
                    os.environ['PATH'] = new_path
                    logging.info(f"Added BaseTools directories to PATH: {paths_to_add}")
                
                # Verify tools are now accessible
                critical_tools = ['GenFw', 'GenFv', 'GenFfs']
                for tool in critical_tools:
                    try:
                        result = subprocess.run(['which', tool], capture_output=True, text=True)
                        if result.returncode == 0:
                            logging.info(f"✓ {tool} available at {result.stdout.strip()}")
                        else:
                            logging.warning(f"⚠ {tool} not found in PATH")
                    except FileNotFoundError:
                        logging.warning(f"⚠ 'which' command not available, cannot verify {tool}")
                
            logging.info("✓ BaseTools build process completed")
            return True
            
        finally:
            os.chdir(original_cwd)
            
    def build_acpi_patcher(self):
        """Build ACPIPatcher package"""
        logging.info("Building ACPIPatcher...")
        
        # Ensure EDK2 environment is set up
        self.setup_edk2_environment()
        
        if not self.check_edk2_workspace():
            return False
            
        # Detect toolchain
        toolchain = self.detect_toolchain()
        logging.info(f"Using toolchain: {toolchain}")
        
        # Change to EDK2 directory
        original_cwd = os.getcwd()
        os.chdir(self.edk2_path)
        
        try:
            # Build BaseTools if needed
            basetools_success = self.build_basetools()
            if not basetools_success:
                logging.warning("BaseTools build had issues, but continuing with build attempt...")
                logging.warning("Some functionality may be limited")
            
            # Set up configuration files
            conf_dir = os.path.join(self.edk2_path, 'Conf')
            os.makedirs(conf_dir, exist_ok=True)
            
            # Copy template files if they don't exist
            template_files = [
                ('target.template', 'target.txt'),
                ('tools_def.template', 'tools_def.txt'),
                ('build_rule.template', 'build_rule.txt')
            ]
            
            basetools_conf = os.path.join(self.edk2_path, 'BaseTools', 'Conf')
            for template, target in template_files:
                template_path = os.path.join(basetools_conf, template)
                target_path = os.path.join(conf_dir, target)
                
                if os.path.exists(template_path) and not os.path.exists(target_path):
                    shutil.copy2(template_path, target_path)
                    logging.info(f"Copied {template} to {target}")
                    
            # Ensure critical BaseTools are available before building
            if not self.verify_critical_tools():
                logging.warning("Some critical tools are missing, build may fail")
            
            # Run the build
            if os.name == 'nt':  # Windows
                # Use edksetup.bat and then build
                build_cmd = f'call edksetup.bat && build -a {self.arch} -b {self.build_type} -t {toolchain} -p ACPIPatcherPkg/ACPIPatcherPkg.dsc'
                logging.info(f"Running: {build_cmd}")
                result = subprocess.run(build_cmd, shell=True, cwd=self.edk2_path)
            else:  # Unix/Linux/macOS
                # Use edksetup.sh and then build
                build_cmd = f'source edksetup.sh && build -a {self.arch} -b {self.build_type} -t {toolchain} -p ACPIPatcherPkg/ACPIPatcherPkg.dsc'
                logging.info(f"Running: {build_cmd}")
                result = subprocess.run(build_cmd, shell=True, executable='/bin/bash', cwd=self.edk2_path)
            
            if result.returncode != 0:
                logging.error("Build failed")
                return False
                
            # Copy output files
            build_output_dir = os.path.join(self.edk2_path, 'Build', 'ACPIPatcher', f'{self.build_type}_{toolchain}', self.arch)
            
            output_files = [
                'ACPIPatcher.efi',
                'ACPIPatcherDxe.efi'
            ]
            
            for output_file in output_files:
                src_path = os.path.join(build_output_dir, output_file)
                dst_path = os.path.join(self.workspace, output_file)
                
                if os.path.exists(src_path):
                    shutil.copy2(src_path, dst_path)
                    file_size = os.path.getsize(dst_path)
                    logging.info(f"✓ {output_file} copied ({file_size:,} bytes)")
                else:
                    logging.warning(f"Output file not found: {output_file}")
                    
            logging.info("✓ Build completed successfully")
            return True
            
        finally:
            os.chdir(original_cwd)
            
    def verify_critical_tools(self):
        """Verify that critical BaseTools are available and attempt to build them if missing"""
        logging.info("Verifying critical BaseTools availability...")
        
        system = platform.system()
        critical_tools = ['GenFw', 'GenFv', 'GenFfs', 'GenSec']
        
        if system == "Windows":
            # Windows tool names have .exe extension
            critical_tools = [tool + '.exe' for tool in critical_tools]
            basetools_bin = os.path.join(self.edk2_path, 'BaseTools', 'Bin', 'Win32')
        else:
            # Unix/Linux tools
            basetools_bin = os.path.join(self.edk2_path, 'BaseTools', 'Source', 'C', 'bin')
        
        missing_tools = []
        for tool in critical_tools:
            tool_path = os.path.join(basetools_bin, tool)
            if not os.path.exists(tool_path):
                missing_tools.append(tool)
            else:
                logging.info(f"✓ {tool} found at {tool_path}")
        
        if missing_tools:
            logging.warning(f"Missing critical tools: {missing_tools}")
            logging.info("Attempting to build missing tools...")
            
            if system != "Windows":
                # Try to build missing tools individually on Unix/Linux
                c_source_dir = os.path.join(self.edk2_path, 'BaseTools', 'Source', 'C')
                for tool in missing_tools:
                    tool_name = tool  # Remove .exe if present
                    tool_dir = os.path.join(c_source_dir, tool_name)
                    
                    if os.path.exists(tool_dir):
                        logging.info(f"Building {tool_name}...")
                        result = subprocess.run(['make'], cwd=tool_dir)
                        if result.returncode == 0:
                            logging.info(f"✓ {tool_name} built successfully")
                            # Check if the tool is now available
                            built_tool_path = os.path.join(tool_dir, tool_name)
                            if os.path.exists(built_tool_path):
                                # Copy to bin directory
                                os.makedirs(basetools_bin, exist_ok=True)
                                shutil.copy2(built_tool_path, os.path.join(basetools_bin, tool_name))
                                logging.info(f"✓ {tool_name} copied to {basetools_bin}")
                        else:
                            logging.warning(f"Failed to build {tool_name}")
                
                # Re-check availability
                still_missing = []
                for tool in missing_tools:
                    tool_path = os.path.join(basetools_bin, tool)
                    if not os.path.exists(tool_path):
                        still_missing.append(tool)
                
                if still_missing:
                    logging.error(f"Still missing critical tools: {still_missing}")
                    return False
                else:
                    logging.info("✓ All critical tools are now available")
                    return True
            else:
                # On Windows, tools should be built by the earlier BaseTools build
                logging.error("Critical tools missing on Windows - BaseTools build likely failed")
                return False
        else:
            logging.info("✓ All critical tools are available")
            return True

def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(description='Build ACPIPatcher UEFI application')
    parser.add_argument('--build', action='store_true', help='Build the project')
    parser.add_argument('--clean', action='store_true', help='Clean build artifacts')
    parser.add_argument('--verbose', '-v', action='store_true', help='Verbose output')
    parser.add_argument('--arch', '-a', default='X64', choices=['X64', 'IA32', 'AARCH64'], 
                        help='Target architecture (default: X64)')
    parser.add_argument('--build-type', '-b', default='RELEASE', choices=['RELEASE', 'DEBUG'],
                        help='Build type (default: RELEASE)')
    parser.add_argument('--toolchain', '-t', help='Toolchain to use (auto-detected if not specified)')
    
    args = parser.parse_args()
    
    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)
        
    builder = ACPIPatcherBuilder(arch=args.arch, build_type=args.build_type, toolchain=args.toolchain)
    
    if args.clean:
        # Clean build artifacts
        build_dir = os.path.join(builder.edk2_path, 'Build')
        if os.path.exists(build_dir):
            shutil.rmtree(build_dir)
            logging.info("Build artifacts cleaned")
        return
        
    if args.build:
        success = builder.build_acpi_patcher()
        sys.exit(0 if success else 1)
    else:
        parser.print_help()

if __name__ == "__main__":
    main()

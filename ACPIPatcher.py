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
        
        for nasm_path in nasm_locations:
            try:
                if nasm_path == 'nasm':
                    result = subprocess.run(['nasm', '-v'], capture_output=True, text=True)
                    if result.returncode == 0:
                        logging.info("✓ NASM found in PATH")
                        break
                elif os.path.exists(nasm_path):
                    os.environ['NASM_PREFIX'] = os.path.dirname(nasm_path) + os.sep
                    logging.info(f"✓ NASM found at {nasm_path}")
                    break
            except FileNotFoundError:
                continue
        else:
            logging.warning("NASM not found - assembly compilation may fail")
            
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
                # Run edksetup.bat
                cmd = ['cmd', '/c', 'edksetup.bat', 'ForceRebuild']
                if 'BASETOOLS_CYGWIN_BUILD' in os.environ:
                    logging.info("Building BaseTools with Cygwin...")
            else:
                # Run edksetup.sh and build C tools
                cmd = ['bash', '-c', 'source edksetup.sh BaseTools']
                
            result = subprocess.run(cmd, cwd=self.edk2_path)
            
            if result.returncode != 0:
                logging.error("Failed to build BaseTools")
                return False
            
            # For Unix systems, explicitly build C tools to ensure GenFw is available
            if system != "Windows":
                logging.info("Building BaseTools C utilities...")
                c_build_cmd = ['make', '-C', 'BaseTools/Source/C']
                c_result = subprocess.run(c_build_cmd, cwd=self.edk2_path)
                
                if c_result.returncode != 0:
                    logging.warning("BaseTools C compilation had issues, trying alternative...")
                    # Try building in the C directory directly
                    c_dir = os.path.join(self.edk2_path, 'BaseTools', 'Source', 'C')
                    alt_result = subprocess.run(['make'], cwd=c_dir)
                    if alt_result.returncode != 0:
                        logging.warning("BaseTools C compilation failed, some tools may be missing")
                
                # Add BaseTools to PATH
                basetools_bin = os.path.join(self.edk2_path, 'BaseTools', 'Source', 'C', 'bin')
                basetools_wrappers = os.path.join(self.edk2_path, 'BaseTools', 'BinWrappers', 'PosixLike')
                
                current_path = os.environ.get('PATH', '')
                if os.path.exists(basetools_bin):
                    os.environ['PATH'] = f"{basetools_bin}:{current_path}"
                    logging.info(f"Added {basetools_bin} to PATH")
                elif os.path.exists(basetools_wrappers):
                    os.environ['PATH'] = f"{basetools_wrappers}:{current_path}"
                    logging.info(f"Added {basetools_wrappers} to PATH")
                
            logging.info("✓ BaseTools built successfully")
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
            if not self.build_basetools():
                return False
                
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

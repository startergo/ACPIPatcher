#!/usr/bin/env python3
"""
Simple EDK2 Build Script for ACPIPatcher
This script uses Python-only tools to avoid MinGW path issues
"""

import os
import sys
import subprocess
import shutil
from pathlib import Path

def main():
    print("=" * 60)
    print("ACPIPatcher Simple Python Build")
    print("=" * 60)
    
    # Find EDK2 directory
    edk2_paths = [
        Path(r"C:\Users\ivelin\Downloads\edk2"),
        Path("temp_edk2"),
        Path(r"C:\edk2"),
        Path.home() / "edk2"
    ]
    
    edk2_path = None
    for path in edk2_paths:
        if path.exists():
            edk2_path = path
            print(f"Found EDK2 at: {edk2_path}")
            break
    
    if not edk2_path:
        print("ERROR: No EDK2 installation found!")
        return 1
    
    # Change to EDK2 directory
    os.chdir(edk2_path)
    
    # Set up environment variables
    os.environ["WORKSPACE"] = str(edk2_path)
    os.environ["EDK_TOOLS_PATH"] = str(edk2_path / "BaseTools")
    os.environ["PYTHONPATH"] = str(edk2_path / "BaseTools" / "Source" / "Python")
    
    # Copy ACPIPatcher package if needed
    acpi_src = Path(__file__).parent / "ACPIPatcherPkg"
    acpi_dst = edk2_path / "ACPIPatcherPkg"
    
    if not acpi_dst.exists() and acpi_src.exists():
        print(f"Copying ACPIPatcher package...")
        shutil.copytree(acpi_src, acpi_dst)
    
    # Run EDK2 setup using Python
    print("Setting up EDK2 environment...")
    
    # Import EDK2 build tools
    sys.path.insert(0, str(edk2_path / "BaseTools" / "Source" / "Python"))
    
    try:
        # Try to use Python-based build system
        from build.build import main as build_main
        
        # Set up build arguments
        build_args = [
            "-p", "ACPIPatcherPkg/ACPIPatcherPkg.dsc",
            "-a", "X64",
            "-t", "GCC5",
            "-b", "RELEASE",
            "--python-only"  # Force Python-only mode
        ]
        
        print("Starting Python-based build...")
        print(f"Build command: build {' '.join(build_args)}")
        
        # Override sys.argv for the build system
        original_argv = sys.argv
        sys.argv = ["build"] + build_args
        
        result = build_main()
        sys.argv = original_argv
        
        if result == 0:
            print("Build completed successfully!")
            return 0
        else:
            print("Build failed!")
            return 1
            
    except ImportError as e:
        print(f"Could not import EDK2 build system: {e}")
        print("Falling back to command-line build...")
        
        # Fall back to command line
        try:
            cmd = [
                sys.executable, 
                str(edk2_path / "BaseTools" / "Source" / "Python" / "build" / "build.py"),
                "-p", "ACPIPatcherPkg/ACPIPatcherPkg.dsc",
                "-a", "X64", 
                "-t", "GCC5",
                "-b", "RELEASE"
            ]
            
            print(f"Running: {' '.join(cmd)}")
            result = subprocess.run(cmd, cwd=edk2_path)
            return result.returncode
            
        except Exception as e:
            print(f"Build failed: {e}")
            return 1

if __name__ == "__main__":
    sys.exit(main())

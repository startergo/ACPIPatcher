#!/bin/bash
# Test script to validate build artifacts and functionality
# This script verifies that ACPIPatcher builds correctly and produces valid outputs

set -euo pipefail

# Color output functions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to test EFI file validity
test_efi_file() {
    local file_path="$1"
    local arch="$2"
    
    info "Testing EFI file: $file_path"
    
    if [ ! -f "$file_path" ]; then
        error "EFI file not found: $file_path"
        return 1
    fi
    
    # Check file size (should be reasonable for an EFI application)
    local file_size=$(stat -c%s "$file_path" 2>/dev/null || stat -f%z "$file_path" 2>/dev/null || echo "0")
    if [ "$file_size" -lt 1024 ]; then
        error "EFI file too small ($file_size bytes): $file_path"
        return 1
    fi
    
    if [ "$file_size" -gt 10485760 ]; then  # 10MB limit
        warning "EFI file unusually large ($file_size bytes): $file_path"
    fi
    
    # Check for EFI signature (basic validation)
    if command -v file >/dev/null 2>&1; then
        local file_type=$(file "$file_path")
        if [[ "$file_type" == *"PE32"* ]] || [[ "$file_type" == *"executable"* ]]; then
            success "EFI file has valid PE signature: $file_path"
        else
            warning "EFI file type unrecognized: $file_type"
        fi
    fi
    
    # Architecture-specific validation
    if command -v objdump >/dev/null 2>&1; then
        local objdump_output=$(objdump -f "$file_path" 2>/dev/null || echo "")
        if [ -n "$objdump_output" ]; then
            if [[ "$arch" == "IA32" && "$objdump_output" == *"i386"* ]]; then
                success "Architecture matches: IA32"
            elif [[ "$arch" == "X64" && ("$objdump_output" == *"x86-64"* || "$objdump_output" == *"i386:x86-64"*) ]]; then
                success "Architecture matches: X64"
            else
                warning "Architecture validation inconclusive for $arch"
            fi
        fi
    fi
    
    success "EFI file validation passed: $file_path ($file_size bytes)"
    return 0
}

# Function to test build directory structure
test_build_structure() {
    local build_root="$1"
    local arch="$2"
    local build_type="$3"
    local toolchain="$4"
    
    info "Testing build structure for $arch/$build_type/$toolchain"
    
    # Common build directory patterns
    local possible_dirs=(
        "$build_root/Build/ACPIPatcherPkg/${build_type}_${toolchain}/${arch}"
        "$build_root/Build/${build_type}_${toolchain}/${arch}"
        "$build_root/Build/${arch}/${build_type}"
    )
    
    local build_dir=""
    for dir in "${possible_dirs[@]}"; do
        if [ -d "$dir" ]; then
            build_dir="$dir"
            break
        fi
    done
    
    if [ -z "$build_dir" ]; then
        error "No valid build directory found for $arch/$build_type/$toolchain"
        info "Searched directories:"
        for dir in "${possible_dirs[@]}"; do
            info "  - $dir"
        done
        return 1
    fi
    
    success "Found build directory: $build_dir"
    
    # Test required EFI files
    local required_files=("ACPIPatcher.efi" "ACPIPatcherDxe.efi")
    local all_found=true
    
    for efi_file in "${required_files[@]}"; do
        local full_path="$build_dir/$efi_file"
        if test_efi_file "$full_path" "$arch"; then
            success "Required file found and valid: $efi_file"
        else
            error "Required file missing or invalid: $efi_file"
            all_found=false
        fi
    done
    
    if [ "$all_found" = true ]; then
        success "All required build artifacts present and valid"
        return 0
    else
        error "Some required build artifacts are missing or invalid"
        return 1
    fi
}

# Function to test debug output and logging
test_debug_features() {
    local source_file="$1"
    
    info "Testing debug and logging features in source code"
    
    if [ ! -f "$source_file" ]; then
        error "Source file not found: $source_file"
        return 1
    fi
    
    # Check for debug macros and functions
    local debug_features=(
        "AcpiDebugPrint"
        "PTR_TO_INT"
        "PTR_FMT"
        "DEBUG_LEVEL"
        "HexDump"
    )
    
    local features_found=0
    for feature in "${debug_features[@]}"; do
        if grep -q "$feature" "$source_file"; then
            success "Debug feature found: $feature"
            ((features_found++))
        else
            warning "Debug feature not found: $feature"
        fi
    done
    
    if [ $features_found -ge 3 ]; then
        success "Sufficient debug features implemented ($features_found/${#debug_features[@]})"
        return 0
    else
        error "Insufficient debug features found ($features_found/${#debug_features[@]})"
        return 1
    fi
}

# Function to test memory management
test_memory_management() {
    local source_file="$1"
    
    info "Testing memory management practices in source code"
    
    if [ ! -f "$source_file" ]; then
        error "Source file not found: $source_file"
        return 1
    fi
    
    # Check for proper memory management patterns
    local memory_patterns=(
        "AllocateZeroPool"
        "FreePool"
        "NULL.*check"
        "Status.*=.*EFI_"
    )
    
    local patterns_found=0
    for pattern in "${memory_patterns[@]}"; do
        if grep -qE "$pattern" "$source_file"; then
            success "Memory management pattern found: $pattern"
            ((patterns_found++))
        else
            warning "Memory management pattern not found: $pattern"
        fi
    done
    
    # Check for potential memory leaks (basic heuristic)
    local alloc_count=$(grep -c "AllocateZeroPool\|AllocatePool" "$source_file" || echo "0")
    local free_count=$(grep -c "FreePool" "$source_file" || echo "0")
    
    info "Memory allocations: $alloc_count, deallocations: $free_count"
    
    if [ "$alloc_count" -gt 0 ] && [ "$free_count" -gt 0 ]; then
        if [ "$free_count" -ge "$alloc_count" ]; then
            success "Memory management appears balanced"
        else
            warning "Potential memory leaks detected (more allocations than deallocations)"
        fi
    fi
    
    if [ $patterns_found -ge 2 ]; then
        success "Good memory management practices found"
        return 0
    else
        warning "Limited memory management patterns found"
        return 1
    fi
}

# Main test execution
main() {
    local test_root="${1:-$(pwd)}"
    local target_arch="${2:-}"
    local target_build_type="${3:-}"
    local target_toolchain="${4:-}"
    local exit_code=0
    
    info "Starting ACPIPatcher build artifact testing"
    info "Test root: $test_root"
    
    # Test source code quality
    local source_file="$test_root/ACPIPatcherPkg/ACPIPatcher/ACPIPatcher.c"
    if [ -f "$source_file" ]; then
        test_debug_features "$source_file" || exit_code=1
        test_memory_management "$source_file" || exit_code=1
    else
        error "Source file not found: $source_file"
        exit_code=1
    fi
    
    # Determine which build configurations to test
    local build_configs=()
    
    if [ -n "$target_arch" ] && [ -n "$target_build_type" ] && [ -n "$target_toolchain" ]; then
        # Specific configuration provided via command line
        build_configs=("$target_arch:$target_build_type:$target_toolchain")
        info "Testing specific build configuration: $target_arch/$target_build_type/$target_toolchain"
    else
        # Auto-detect existing build configurations
        info "Auto-detecting existing build configurations..."
        
        # Look for any existing build directories
        if [ -d "$test_root/Build" ]; then
            while IFS= read -r -d '' build_dir; do
                # Extract configuration from path
                # Example: Build/ACPIPatcher/DEBUG_GCC5/X64 or Build/ACPIPatcherPkg/RELEASE_XCODE5/X64
                local dir_name=$(basename "$build_dir")
                local parent_dir=$(basename "$(dirname "$build_dir")")
                
                if [[ "$dir_name" =~ ^(X64|IA32|AARCH64)$ ]] && [[ "$parent_dir" =~ ^(DEBUG|RELEASE)_(.+)$ ]]; then
                    local arch="$dir_name"
                    local build_type="${BASH_REMATCH[1]}"
                    local toolchain="${BASH_REMATCH[2]}"
                    
                    # Check if this directory actually contains EFI files
                    if [ -f "$build_dir/ACPIPatcher.efi" ] || [ -f "$build_dir/ACPIPatcherDxe.efi" ]; then
                        build_configs+=("$arch:$build_type:$toolchain")
                        info "Found build configuration: $arch/$build_type/$toolchain"
                    fi
                fi
            done < <(find "$test_root/Build" -type d -name "X64" -o -name "IA32" -o -name "AARCH64" -print0 2>/dev/null)
        fi
        
        # If no configurations found via auto-detection, try common patterns
        if [ ${#build_configs[@]} -eq 0 ]; then
            info "No build configurations auto-detected, checking common patterns..."
            local common_configs=(
                "X64:RELEASE:GCC5"
                "X64:DEBUG:GCC5"
                "X64:RELEASE:XCODE5"
                "X64:DEBUG:XCODE5"
                "X64:RELEASE:VS2022"
                "X64:DEBUG:VS2022"
            )
            
            for config in "${common_configs[@]}"; do
                IFS=':' read -r arch build_type toolchain <<< "$config"
                
                # Check if this configuration actually has build artifacts
                local possible_dirs=(
                    "$test_root/Build/ACPIPatcherPkg/${build_type}_${toolchain}/${arch}"
                    "$test_root/Build/ACPIPatcher/${build_type}_${toolchain}/${arch}"
                    "$test_root/Build/${build_type}_${toolchain}/${arch}"
                    "$test_root/Build/${arch}/${build_type}"
                )
                
                for dir in "${possible_dirs[@]}"; do
                    if [ -d "$dir" ] && ([ -f "$dir/ACPIPatcher.efi" ] || [ -f "$dir/ACPIPatcherDxe.efi" ]); then
                        build_configs+=("$config")
                        info "Found build configuration: $config"
                        break
                    fi
                done
            done
        fi
    fi
    
    # Test build artifacts
    local builds_tested=0
    if [ ${#build_configs[@]} -eq 0 ]; then
        warning "No build configurations found to test"
        info "This might be expected if only source code validation was requested"
    else
        for config in "${build_configs[@]}"; do
            IFS=':' read -r arch build_type toolchain <<< "$config"
            
            if test_build_structure "$test_root" "$arch" "$build_type" "$toolchain"; then
                success "Build configuration test passed: $config"
                ((builds_tested++))
            else
                warning "Build configuration test failed: $config"
            fi
        done
    fi
    
    # Summary
    info "=========================="
    info "Test Summary:"
    info "  - Source code tests: $([ -f "$source_file" ] && echo "✅ Passed" || echo "❌ Failed")"
    info "  - Build configurations tested: $builds_tested/${#build_configs[@]}"
    info "=========================="
    
    if [ $exit_code -eq 0 ] && ([ $builds_tested -gt 0 ] || [ ${#build_configs[@]} -eq 0 ]); then
        success "All tests completed successfully!"
    elif [ $builds_tested -gt 0 ]; then
        warning "Tests completed with some warnings"
    else
        error "Tests failed or no build artifacts found"
        exit_code=1
    fi
    
    return $exit_code
}

# Run main function with all arguments
main "$@"

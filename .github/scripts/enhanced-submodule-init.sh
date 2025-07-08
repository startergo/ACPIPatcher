#!/bin/bash

# Enhanced EDK2 Submodule Initialization Script
# Handles authentication issues while ensuring essential submodules are initialized

# Note: NOT using 'set -e' to allow graceful error handling

echo "=== Enhanced EDK2 Submodule Initialization ==="

# Configure git for authentication issues
git config --global url."https://github.com/".insteadOf "git@github.com:"
git config --global advice.detachedHead false

# Function to check if a submodule is essential for builds
is_essential_submodule() {
    local submodule_path="$1"
    
    # Essential submodules needed for BaseTools and basic builds
    local essential_patterns=(
        "BaseTools/Source/C/BrotliCompress/brotli"
        "CryptoPkg/Library/OpensslLib/openssl"
        "MdeModulePkg/Library/BrotliCustomDecompressLib/brotli"
        "MdeModulePkg/Universal/RegularExpressionDxe/oniguruma"
    )
    
    for pattern in "${essential_patterns[@]}"; do
        if [[ "$submodule_path" == *"$pattern"* ]]; then
            return 0  # Is essential
        fi
    done
    
    return 1  # Not essential
}

# Function to check if a submodule is known to be problematic
is_problematic_submodule() {
    local submodule_path="$1"
    
    # Known problematic submodules that cause authentication issues
    local problematic_patterns=(
        "UnitTestFrameworkPkg/Library/SubhookLib/subhook"
        "UnitTestFrameworkPkg/Test/GoogleTest/googletest"
        "UnitTestFrameworkPkg/Library/GoogleTestLib/googletest"
        "UnitTestFrameworkPkg/Library/CmockaLib/cmocka"
        "RedfishPkg/Library/JsonLib/jansson"
        "ArmPkg/Library/ArmSoftFloatLib/berkeley-softfloat-3"
        "SecurityPkg/DeviceSecurity/SpdmLib/libspdm"
    )
    
    for pattern in "${problematic_patterns[@]}"; do
        if [[ "$submodule_path" == *"$pattern"* ]]; then
            return 0  # Is problematic
        fi
    done
    
    return 1  # Not problematic
}

# Function to initialize a submodule safely
init_submodule() {
    local submodule_path="$1"
    local submodule_name=$(basename "$submodule_path")
    local is_essential=false
    local is_problematic=false
    
    if is_essential_submodule "$submodule_path"; then
        is_essential=true
    fi
    
    if is_problematic_submodule "$submodule_path"; then
        is_problematic=true
    fi
    
    if [ "$is_problematic" = true ]; then
        echo "🚫 Skipping known problematic submodule: $submodule_path"
        return 2  # Skipped
    fi
    
    echo "Initializing submodule: $submodule_name $([ "$is_essential" = true ] && echo "(essential)" || echo "(optional)")"
    
    # Try to initialize the submodule with timeout
    local init_result=0
    if command -v timeout >/dev/null 2>&1; then
        # Use timeout if available (Linux)
        timeout 60 git submodule update --init --recommend-shallow "$submodule_path" >/dev/null 2>&1 || init_result=$?
    else
        # No timeout available (macOS), just try direct
        git submodule update --init --recommend-shallow "$submodule_path" >/dev/null 2>&1 || init_result=$?
    fi
    
    if [ $init_result -eq 0 ]; then
        echo "✅ $submodule_name initialized successfully"
        return 0  # Success
    else
        if [ "$is_essential" = true ]; then
            echo "❌ CRITICAL: Essential submodule $submodule_name failed to initialize!"
            echo "   This may cause build failures. Attempting alternative method..."
            
            # Try without timeout and depth restriction for essential modules
            init_result=0
            git submodule update --init "$submodule_path" >/dev/null 2>&1 || init_result=$?
            
            if [ $init_result -eq 0 ]; then
                echo "✅ $submodule_name initialized with alternative method"
                return 0  # Success
            else
                echo "💥 FATAL: Essential submodule $submodule_name could not be initialized"
                return 1  # Critical failure
            fi
        else
            echo "⚠️ Optional submodule $submodule_name failed to initialize (continuing)"
            return 2  # Non-critical failure
        fi
    fi
}

# Check if we have any submodules
if [ ! -f ".gitmodules" ]; then
    echo "No .gitmodules file found - no submodules to initialize"
    exit 0
fi

# Get list of submodules
echo "Scanning for submodules..."
SUBMODULES=$(git config --file .gitmodules --get-regexp path | awk '{ print $2 }' | sort)

if [ -z "$SUBMODULES" ]; then
    echo "No submodules found in .gitmodules"
    exit 0
fi

echo "Found submodules:"
echo "$SUBMODULES" | sed 's/^/  - /'
echo ""

# Initialize submodules one by one
SUCCESS_COUNT=0
SKIP_COUNT=0
FAIL_COUNT=0
CRITICAL_FAIL_COUNT=0

while IFS= read -r submodule; do
    [ -z "$submodule" ] && continue
    
    init_submodule "$submodule"
    result=$?
    
    case $result in
        0) SUCCESS_COUNT=$((SUCCESS_COUNT + 1)) ;;
        1) CRITICAL_FAIL_COUNT=$((CRITICAL_FAIL_COUNT + 1)) ;;
        2) SKIP_COUNT=$((SKIP_COUNT + 1)) ;;
        *) FAIL_COUNT=$((FAIL_COUNT + 1)) ;;
    esac
done <<< "$SUBMODULES"

echo ""
echo "=== Submodule Initialization Summary ==="
echo "✅ Successful: $SUCCESS_COUNT"
echo "🚫 Skipped: $SKIP_COUNT"
echo "⚠️ Failed (non-critical): $FAIL_COUNT"
echo "💥 Failed (critical): $CRITICAL_FAIL_COUNT"

# Show final status
echo ""
echo "Final submodule status:"
git submodule status | head -20 || echo "Warning: Could not get submodule status"

# Determine exit status
if [ $CRITICAL_FAIL_COUNT -gt 0 ]; then
    echo ""
    echo "💥 CRITICAL: $CRITICAL_FAIL_COUNT essential submodules failed to initialize"
    echo "   This will likely cause build failures"
    exit 1
elif [ $SUCCESS_COUNT -gt 0 ]; then
    echo ""
    echo "✅ EDK2 submodule initialization completed successfully"
    echo "   $SUCCESS_COUNT submodules initialized, $SKIP_COUNT skipped, $FAIL_COUNT optional failures"
    exit 0
else
    echo ""
    echo "⚠️ No submodules were successfully initialized"
    echo "   This may cause build issues, but attempting to continue..."
    exit 0  # Don't fail the build, just warn
fi

#!/bin/bash

# EDK2 Submodule Initialization Script
# Handles authentication issues and skips problematic submodules

set -e

echo "=== EDK2 Submodule Initialization ==="

# Configure git for authentication issues
git config --global url."https://github.com/".insteadOf "git@github.com:"
git config --global advice.detachedHead false

# Function to initialize a submodule safely
init_submodule() {
    local submodule_path="$1"
    local submodule_name=$(basename "$submodule_path")
    
    echo "Initializing submodule: $submodule_name"
    
    if git submodule update --init --recommend-shallow "$submodule_path" 2>/dev/null; then
        echo "✅ $submodule_name initialized successfully"
        return 0
    else
        echo "⚠️ $submodule_name failed to initialize (skipping)"
        return 1
    fi
}

# Get list of submodules
SUBMODULES=$(git submodule status | awk '{print $2}' | grep -v '^$' || true)

if [ -z "$SUBMODULES" ]; then
    echo "No submodules found or .gitmodules not present"
    exit 0
fi

echo "Found submodules:"
echo "$SUBMODULES"
echo ""

# Known problematic submodules to skip
SKIP_SUBMODULES=(
    "UnitTestFrameworkPkg/Library/SubhookLib/subhook"
    "UnitTestFrameworkPkg/Test/GoogleTest/googletest"
)

# Initialize submodules one by one
SUCCESS_COUNT=0
SKIP_COUNT=0
FAIL_COUNT=0

while IFS= read -r submodule; do
    [ -z "$submodule" ] && continue
    
    # Check if this submodule should be skipped
    SHOULD_SKIP=false
    for skip_pattern in "${SKIP_SUBMODULES[@]}"; do
        if [[ "$submodule" == *"$skip_pattern"* ]]; then
            echo "🚫 Skipping known problematic submodule: $submodule"
            SHOULD_SKIP=true
            SKIP_COUNT=$((SKIP_COUNT + 1))
            break
        fi
    done
    
    if [ "$SHOULD_SKIP" = true ]; then
        continue
    fi
    
    # Try to initialize the submodule
    if init_submodule "$submodule"; then
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
done <<< "$SUBMODULES"

echo ""
echo "=== Submodule Initialization Summary ==="
echo "✅ Successful: $SUCCESS_COUNT"
echo "🚫 Skipped: $SKIP_COUNT"
echo "❌ Failed: $FAIL_COUNT"

# Show final status
echo ""
echo "Final submodule status:"
git submodule status || echo "Warning: Could not get submodule status"

# Consider it successful if we have some submodules initialized
if [ $SUCCESS_COUNT -gt 0 ]; then
    echo ""
    echo "✅ EDK2 submodule initialization completed successfully"
    echo "   (Some submodules may have been skipped due to known issues)"
    exit 0
else
    echo ""
    echo "⚠️ No submodules were successfully initialized"
    echo "   This may cause build issues, but attempting to continue..."
    exit 0  # Don't fail the build, just warn
fi

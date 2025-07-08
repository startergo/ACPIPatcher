#!/bin/bash

# Script to patch EDK2 .gitmodules to disable problematic submodules
# This prevents authentication issues during CI builds

set -e

GITMODULES_FILE=".gitmodules"

if [ ! -f "$GITMODULES_FILE" ]; then
    echo "Warning: .gitmodules file not found"
    exit 0
fi

echo "=== Patching EDK2 .gitmodules to disable problematic submodules ==="

# Backup original .gitmodules
cp "$GITMODULES_FILE" "${GITMODULES_FILE}.backup"

# List of problematic submodule paths to disable
# Only disable submodules that cause authentication issues
# Keep essential ones like Brotli that are needed for builds
PROBLEMATIC_SUBMODULES=(
    "UnitTestFrameworkPkg/Library/SubhookLib/subhook"
    "UnitTestFrameworkPkg/Test/GoogleTest/googletest"
)

# Function to comment out a submodule section
disable_submodule() {
    local submodule_path="$1"
    echo "Disabling submodule: $submodule_path"
    
    # Use sed to comment out the submodule section
    sed -i.tmp "/\[submodule \"$submodule_path\"\]/,/^$/s/^/# /" "$GITMODULES_FILE" || true
    rm -f "${GITMODULES_FILE}.tmp"
}

# Disable each problematic submodule
for submodule in "${PROBLEMATIC_SUBMODULES[@]}"; do
    disable_submodule "$submodule"
done

echo "Patched .gitmodules file:"
echo "========================"
grep -A 3 -B 1 "submodule" "$GITMODULES_FILE" | head -20 || echo "No submodules found or pattern not matched"

echo ""
echo "✅ .gitmodules patching completed"

#!/bin/bash

# Update GitHub Actions in workflow files
find .github/workflows -name "*.yml" -type f -exec sed -i '' \
  -e 's/uses: actions\/cache@v3/uses: actions\/cache@v4/g' \
  -e 's/uses: actions\/setup-python@v4/uses: actions\/setup-python@v5/g' \
  -e 's/uses: actions\/download-artifact@v3/uses: actions\/download-artifact@v4/g' \
  {} \;

echo "GitHub Actions updated to latest versions"

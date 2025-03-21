#!/bin/bash

# Script to remove trailing whitespace from Swift and shell script files

# Find all Swift and shell script files and remove trailing whitespace
find . -type f \( -name "*.swift" -o -name "*.sh" \) -exec sed -i '' 's/[[:space:]]*$//' {} \;

echo "Trailing whitespace removed from all Swift and shell script files."
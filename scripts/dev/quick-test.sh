#!/bin/bash
# Quick test script to verify project structure

echo "🧪 Quick Project Test"
echo "===================="

# Check required files exist
echo "📋 Checking required files..."
REQUIRED_FILES=(
    "README.md"
    "LICENSE"
    "hacs.json"
    "addon/config.yaml"
    "addon/package.json"
    "addon/src/server.js"
    "custom_components/todoist_voice_ha_integration/manifest.json"
    "custom_components/todoist_voice_ha_integration/__init__.py"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file"
    else
        echo "❌ Missing: $file"
    fi
done

# Check JSON syntax
echo ""
echo "🔍 Checking JSON syntax..."
for json_file in hacs.json addon/package.json custom_components/*/manifest.json custom_components/*/strings.json; do
    if [ -f "$json_file" ]; then
        if python3 -m json.tool "$json_file" > /dev/null 2>&1; then
            echo "✅ $json_file"
        else
            echo "❌ Invalid JSON: $json_file"
        fi
    fi
done

# Check Python syntax
echo ""
echo "🐍 Checking Python syntax..."
find custom_components -name "*.py" -exec python3 -m py_compile {} \; 2>/dev/null && echo "✅ Python syntax OK" || echo "❌ Python syntax errors"

echo ""
echo "✅ Quick test complete!"

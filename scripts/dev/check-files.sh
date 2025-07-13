#!/bin/bash
# Check which implementation files still need content

echo "📋 Implementation Status Check"
echo "=============================="

echo ""
echo "🔍 Checking implementation files..."

# Check if files contain placeholder text
check_file() {
    local file="$1"
    local description="$2"
    
    if [ ! -f "$file" ]; then
        echo "❌ Missing: $file"
        return
    fi
    
    if grep -q "TODO.*artifact" "$file" 2>/dev/null; then
        echo "📝 Needs implementation: $file ($description)"
    elif [ -s "$file" ]; then
        echo "✅ Implemented: $file"
    else
        echo "📄 Empty: $file"
    fi
}

# Check key implementation files
check_file "addon/src/server.js" "Main server"
check_file "custom_components/todoist_voice_ha_integration/__init__.py" "Integration setup"
check_file "custom_components/todoist_voice_ha_integration/config_flow.py" "Config flow"
check_file "custom_components/todoist_voice_ha_integration/const.py" "Constants"
check_file "custom_components/todoist_voice_ha_integration/sensor.py" "Sensors"
check_file "custom_components/todoist_voice_ha_integration/services.py" "Services"

echo ""
echo "✅ File check complete!"

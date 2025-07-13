#!/bin/bash
# Update all YOUR-USERNAME placeholders with actual username

set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <github-username>"
    echo "Example: $0 john-doe"
    exit 1
fi

USERNAME="$1"

echo "🔄 Updating all YOUR-USERNAME placeholders to: $USERNAME"

# Files to update
find . -type f -name "*.md" -o -name "*.yaml" -o -name "*.yml" -o -name "*.json" | \
    xargs sed -i "s/YOUR-USERNAME/$USERNAME/g"

# Update specific configuration files
sed -i "s/{username}/$USERNAME/g" addon/config.yaml

echo "✅ Updated all username placeholders"
echo ""
echo "📝 Files updated:"
echo "   - README.md"
echo "   - addon/config.yaml"
echo "   - custom_components/*/manifest.json"
echo "   - Documentation files"

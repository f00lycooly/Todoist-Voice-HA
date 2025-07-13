#!/bin/bash
# Local testing before GitHub commit

set -e

echo "🧪 Local Development Test"
echo "========================"

# Test 1: Check file structure
echo "📁 Checking file structure..."
if [ ! -f "README.md" ]; then
    echo "❌ Missing README.md"
    exit 1
fi
echo "✅ Basic files exist"

# Test 2: Check Node.js setup
echo ""
echo "📦 Testing Node.js setup..."
cd addon
if [ ! -f "package.json" ]; then
    echo "❌ Missing package.json"
    exit 1
fi

echo "Installing Node.js dependencies..."
npm install

echo "Testing Node.js syntax..."
if [ -f "src/server.js" ]; then
    node -c src/server.js && echo "✅ server.js syntax OK" || echo "❌ server.js syntax error"
else
    echo "⚠️  server.js not implemented yet"
fi

cd ..

# Test 3: Check Python syntax
echo ""
echo "🐍 Testing Python files..."
if find custom_components -name "*.py" | grep -q .; then
    find custom_components -name "*.py" -exec python3 -m py_compile {} \; && echo "✅ Python syntax OK" || echo "❌ Python syntax errors"
else
    echo "⚠️  No Python files implemented yet"
fi

# Test 4: Check JSON syntax
echo ""
echo "📋 Testing JSON files..."
for json_file in hacs.json addon/package.json custom_components/*/manifest.json; do
    if [ -f "$json_file" ]; then
        python3 -m json.tool "$json_file" > /dev/null && echo "✅ $json_file" || echo "❌ $json_file invalid"
    fi
done

# Test 5: Check for placeholder content
echo ""
echo "🔍 Checking for unfinished implementations..."
if grep -r "YOUR-USERNAME" . --exclude-dir=.git 2>/dev/null; then
    echo "⚠️  Found YOUR-USERNAME placeholders - update these!"
else
    echo "✅ No username placeholders found"
fi

if grep -r "TODO.*artifact" . --exclude-dir=.git 2>/dev/null; then
    echo "⚠️  Found TODO placeholders - implement these!"
else
    echo "✅ No TODO placeholders found"
fi

echo ""
echo "🎉 Local tests complete!"
echo ""
echo "💡 To fix GitHub workflow issues:"
echo "   1. Make sure package-lock.json exists (run 'npm install' in addon/)"
echo "   2. Implement missing files before committing"
echo "   3. Update YOUR-USERNAME placeholders"

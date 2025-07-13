#!/bin/bash
# debug-ci.sh - Debug CI workflow issues

echo "🔍 DEBUGGING CI WORKFLOW ISSUES"
echo "================================"

echo "1. 📄 Checking ci.yml content..."
if [ -f ".github/workflows/ci.yml" ]; then
    echo "✅ ci.yml exists"
    echo "📝 Content:"
    echo "----------------------------------------"
    cat .github/workflows/ci.yml
    echo "----------------------------------------"
else
    echo "❌ ci.yml not found"
fi

echo ""
echo "2. 📁 Checking current repository structure..."
echo "Root directory contents:"
ls -la

echo ""
echo "3. 🔍 Looking for test-related files..."
echo "Checking for test files and directories..."
find . -name "*test*" -type f 2>/dev/null | head -10
find . -name "*spec*" -type f 2>/dev/null | head -5

echo ""
echo "4. 📦 Checking package.json scripts..."
if [ -f "package.json" ]; then
    echo "✅ package.json exists"
    echo "Scripts section:"
    grep -A 10 '"scripts"' package.json 2>/dev/null || echo "No scripts section found"
else
    echo "❌ package.json not found in root"
fi

echo ""
echo "5. 📋 Checking what the CI is trying to do..."
if [ -f ".github/workflows/ci.yml" ]; then
    echo "CI workflow run commands:"
    grep -E "(run:|npm|test|build)" .github/workflows/ci.yml | sed 's/^/   /'
fi

echo ""
echo "6. 🎯 Common CI issues and fixes:"
echo "   • Missing test script in package.json"
echo "   • Wrong working directory"
echo "   • Missing dependencies"
echo "   • Outdated file paths"
echo ""
echo "💡 Recommendation: Update or disable ci.yml for now"
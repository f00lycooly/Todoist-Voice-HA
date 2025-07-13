#!/bin/bash
# Pre-commit checklist

echo "📋 Pre-Commit Checklist"
echo "======================="

echo ""
echo "✅ Things to check before committing:"
echo ""
echo "1. 📦 Node.js dependencies installed:"
if [ -f "addon/package-lock.json" ]; then
    echo "   ✅ package-lock.json exists"
else
    echo "   ❌ Run: cd addon && npm install"
fi

echo ""
echo "2. 🔧 Username placeholders updated:"
if grep -r "YOUR-USERNAME" . --exclude-dir=.git >/dev/null 2>&1; then
    echo "   ❌ Run: ./scripts/dev/update-usernames.sh f00lycooly"
else
    echo "   ✅ No placeholders found"
fi

echo ""
echo "3. 📝 Implementation files completed:"
if grep -r "TODO.*artifact" . --exclude-dir=.git >/dev/null 2>&1; then
    echo "   ❌ Copy implementations from artifacts"
    echo "   Files needing implementation:"
    grep -r "TODO.*artifact" . --exclude-dir=.git | cut -d: -f1 | sort -u
else
    echo "   ✅ All implementations complete"
fi

echo ""
echo "4. 🧪 Local tests pass:"
echo "   Run: ./scripts/dev/local-test.sh"

echo ""
echo "5. 📁 Files staged for commit:"
git status --porcelain

echo ""
echo "💡 Ready to commit? Run: git add . && git commit -m 'Your message'"

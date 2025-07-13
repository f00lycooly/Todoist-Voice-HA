#!/bin/bash
# cleanup-and-reorganize.sh - Organize the Todoist Voice HA repository structure

set -e

BACKUP_DIR="backup-$(date +%Y%m%d-%H%M%S)"
REPO_ROOT=$(pwd)

echo "🔧 TODOIST VOICE HA - REPOSITORY CLEANUP & REORGANIZATION"
echo "=========================================================="
echo "Starting cleanup process..."
echo "Repository: $REPO_ROOT"
echo ""

# Create backup of current state
echo "1. 📦 Creating backup..."
mkdir -p "$BACKUP_DIR"
cp -r addon "$BACKUP_DIR/" 2>/dev/null || true
cp -r todoist-voice-ha "$BACKUP_DIR/" 2>/dev/null || true
echo "✅ Backup created in: $BACKUP_DIR"
echo ""

# Step 2: Analyze which files to use
echo "2. 🔍 Analyzing files to determine best versions..."

# Create the optimal file selection strategy
echo "   📄 config.yaml: Using addon/ version (1901 bytes vs 444 bytes)"
echo "   📄 build.yaml: Using todoist-voice-ha/ version (newer format)"
echo "   📄 package.json: Using addon/ version (658 bytes vs 401 bytes)"
echo "   📄 Dockerfile: Using todoist-voice-ha/ version (newer, 1470 bytes)"
echo "   📄 server.js: Using todoist-voice-ha/ version (most recent)"
echo ""

# Step 3: Move the best files to root
echo "3. 🚚 Moving optimal files to root directory..."

# Copy the better config.yaml (from addon)
cp addon/config.yaml ./config.yaml
echo "   ✅ config.yaml (from addon/)"

# Copy the newer build.yaml (from todoist-voice-ha)
cp todoist-voice-ha/build.yaml ./build.yaml
echo "   ✅ build.yaml (from todoist-voice-ha/)"

# Copy the more complete package.json (from addon)
cp addon/package.json ./package.json
echo "   ✅ package.json (from addon/)"

# Copy the newer Dockerfile (from todoist-voice-ha)
cp todoist-voice-ha/Dockerfile ./Dockerfile
echo "   ✅ Dockerfile (from todoist-voice-ha/)"

# Copy the src directory (from todoist-voice-ha as it's more recent)
cp -r todoist-voice-ha/src ./src
echo "   ✅ src/ directory (from todoist-voice-ha/)"

echo ""

# Step 4: Update the GitHub Actions to point to root
echo "4. ⚙️  Updating GitHub Actions workflow..."

# Update the workflow to use root directory
sed -i 's|context: \./todoist-voice-ha|context: .|g' .github/workflows/build-addon.yml 2>/dev/null || true
sed -i 's|file: \./todoist-voice-ha/Dockerfile|file: ./Dockerfile|g' .github/workflows/build-addon.yml 2>/dev/null || true

echo "   ✅ GitHub Actions updated to use root directory"
echo ""

# Step 5: Update config.yaml with correct image path
echo "5. 🔧 Updating configuration files..."

# Update config.yaml to remove the placeholder username
sed -i 's|ghcr.io/{username}/todoist-voice-ha|ghcr.io/f00lycooly/todoist-voice-ha|g' config.yaml 2>/dev/null || true
sed -i 's|{username}|f00lycooly|g' config.yaml 2>/dev/null || true
sed -i 's|{email}|your-email@example.com|g' config.yaml 2>/dev/null || true

echo "   ✅ config.yaml updated with correct image references"
echo ""

# Step 6: Clean up old directories (after confirmation)
echo "6. 🧹 Cleaning up old directories..."
echo "   ⚠️  This will remove the addon/ and todoist-voice-ha/ directories"
echo "   ⚠️  (Backup is available in $BACKUP_DIR)"
read -p "   Continue with cleanup? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf addon/
    rm -rf todoist-voice-ha/
    echo "   ✅ Old directories removed"
else
    echo "   ⏭️  Skipping directory cleanup (you can do this manually later)"
fi
echo ""

# Step 7: Verify the new structure
echo "7. ✅ Verifying new repository structure..."
echo ""
echo "   Root directory now contains:"
echo "   📁 $(pwd)"

required_files=("Dockerfile" "config.yaml" "build.yaml" "package.json" "src/server.js")
all_good=true

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "0")
        echo "   ✅ $file ($size bytes)"
    else
        echo "   ❌ $file (MISSING)"
        all_good=false
    fi
done

echo ""

if [ "$all_good" = true ]; then
    echo "🎉 SUCCESS! Repository structure is now optimized!"
    echo ""
    echo "📋 Next steps:"
    echo "   1. Review the changes: git status"
    echo "   2. Test the build: docker build -t test ."
    echo "   3. Commit changes: git add . && git commit -m 'Reorganize repository structure'"
    echo "   4. Push to trigger GitHub Actions: git push origin main"
    echo ""
    echo "🏗️  Your repository now follows the standard Home Assistant add-on structure:"
    echo "   ├── .github/workflows/build-addon.yml  (GitHub Actions)"
    echo "   ├── src/server.js                      (Application code)"
    echo "   ├── Dockerfile                         (Container build)"
    echo "   ├── config.yaml                       (Add-on configuration)"
    echo "   ├── build.yaml                        (Build configuration)"
    echo "   ├── package.json                      (Node.js dependencies)"
    echo "   └── repository.yaml                   (Repository metadata)"
else
    echo "⚠️  Some files are missing. Please check the output above."
fi

echo ""
echo "🔒 Backup available in: $BACKUP_DIR"
echo "💾 You can restore from backup if needed:"
echo "   cp -r $BACKUP_DIR/addon/* . # or"
echo "   cp -r $BACKUP_DIR/todoist-voice-ha/* ."
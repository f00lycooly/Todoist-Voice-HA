#!/bin/bash
# directory-audit.sh - Complete directory structure analysis

set -e

OUTPUT_FILE="directory-structure-audit.txt"
REPO_ROOT=$(pwd)

echo "🔍 TODOIST VOICE HA - DIRECTORY STRUCTURE AUDIT" > $OUTPUT_FILE
echo "=================================================" >> $OUTPUT_FILE
echo "Generated: $(date)" >> $OUTPUT_FILE
echo "Repository Root: $REPO_ROOT" >> $OUTPUT_FILE
echo "" >> $OUTPUT_FILE

# Function to check if file exists and show its content preview
check_file() {
    local file="$1"
    local description="$2"
    
    if [ -f "$file" ]; then
        echo "✅ $description: $file" >> $OUTPUT_FILE
        echo "   Size: $(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "unknown") bytes" >> $OUTPUT_FILE
        echo "   First 3 lines:" >> $OUTPUT_FILE
        head -3 "$file" 2>/dev/null | sed 's/^/   | /' >> $OUTPUT_FILE
        echo "" >> $OUTPUT_FILE
    else
        echo "❌ $description: $file (NOT FOUND)" >> $OUTPUT_FILE
    fi
}

# Function to analyze directory contents
analyze_directory() {
    local dir="$1"
    local description="$2"
    
    echo "📁 $description: $dir" >> $OUTPUT_FILE
    if [ -d "$dir" ]; then
        echo "   Contents:" >> $OUTPUT_FILE
        ls -la "$dir" 2>/dev/null | sed 's/^/   /' >> $OUTPUT_FILE
        echo "" >> $OUTPUT_FILE
    else
        echo "   ❌ Directory not found" >> $OUTPUT_FILE
        echo "" >> $OUTPUT_FILE
    fi
}

echo "1. REPOSITORY OVERVIEW" >> $OUTPUT_FILE
echo "=====================" >> $OUTPUT_FILE
echo "Current working directory: $(pwd)" >> $OUTPUT_FILE
echo "Git repository status:" >> $OUTPUT_FILE
git status --porcelain 2>/dev/null | sed 's/^/   /' >> $OUTPUT_FILE || echo "   Not a git repository or git not available" >> $OUTPUT_FILE
echo "" >> $OUTPUT_FILE

echo "2. ROOT DIRECTORY STRUCTURE" >> $OUTPUT_FILE
echo "===========================" >> $OUTPUT_FILE
tree -a -L 3 . 2>/dev/null >> $OUTPUT_FILE || {
    echo "Tree command not available, using ls -la:" >> $OUTPUT_FILE
    find . -maxdepth 3 -type d | sort | sed 's/^/   /' >> $OUTPUT_FILE
}
echo "" >> $OUTPUT_FILE

echo "3. KEY FILES ANALYSIS" >> $OUTPUT_FILE
echo "=====================" >> $OUTPUT_FILE

# Check for Dockerfiles in various locations
check_file "Dockerfile" "Main Dockerfile (root)"
check_file "todoist-voice-ha/Dockerfile" "Dockerfile in todoist-voice-ha folder"
check_file "addon/Dockerfile" "Dockerfile in addon folder"

# Check for configuration files
check_file "config.yaml" "Add-on config (root)"
check_file "todoist-voice-ha/config.yaml" "Add-on config (todoist-voice-ha folder)"
check_file "addon/config.yaml" "Add-on config (addon folder)"

# Check for build files
check_file "build.yaml" "Build config (root)"
check_file "todoist-voice-ha/build.yaml" "Build config (todoist-voice-ha folder)"
check_file "addon/build.yaml" "Build config (addon folder)"

# Check for package.json
check_file "package.json" "Package.json (root)"
check_file "todoist-voice-ha/package.json" "Package.json (todoist-voice-ha folder)"
check_file "addon/package.json" "Package.json (addon folder)"

# Check for repository files
check_file "repository.yaml" "Repository config"
check_file "README.md" "README file"
check_file "CHANGELOG.md" "Changelog"

# Check for GitHub Actions
check_file ".github/workflows/build-addon.yml" "GitHub Actions workflow"
check_file ".github/workflows/build.yml" "Alternative GitHub Actions workflow"

echo "4. DIRECTORY ANALYSIS" >> $OUTPUT_FILE
echo "====================" >> $OUTPUT_FILE

analyze_directory "." "Root directory"
analyze_directory "todoist-voice-ha" "Todoist Voice HA folder"
analyze_directory "addon" "Addon folder"
analyze_directory "src" "Source folder (root)"
analyze_directory "todoist-voice-ha/src" "Source folder (todoist-voice-ha)"
analyze_directory "addon/src" "Source folder (addon)"
analyze_directory ".github" "GitHub folder"
analyze_directory ".github/workflows" "GitHub workflows"
analyze_directory "custom_components" "Custom components"
analyze_directory "scripts" "Scripts folder"
analyze_directory "docs" "Documentation"

echo "5. POTENTIAL ISSUES DETECTED" >> $OUTPUT_FILE
echo "============================" >> $OUTPUT_FILE

# Check for duplicated files
echo "Checking for duplicate configurations:" >> $OUTPUT_FILE

if [ -f "config.yaml" ] && [ -f "todoist-voice-ha/config.yaml" ]; then
    echo "⚠️  WARNING: config.yaml exists in both root and todoist-voice-ha/" >> $OUTPUT_FILE
fi

if [ -f "Dockerfile" ] && [ -f "todoist-voice-ha/Dockerfile" ]; then
    echo "⚠️  WARNING: Dockerfile exists in both root and todoist-voice-ha/" >> $OUTPUT_FILE
fi

if [ -f "package.json" ] && [ -f "todoist-voice-ha/package.json" ]; then
    echo "⚠️  WARNING: package.json exists in both root and todoist-voice-ha/" >> $OUTPUT_FILE
fi

# Check file sizes to identify which are more complete
echo "" >> $OUTPUT_FILE
echo "File size comparison (to identify most complete versions):" >> $OUTPUT_FILE

for file in config.yaml build.yaml package.json Dockerfile; do
    echo "Comparing $file:" >> $OUTPUT_FILE
    
    if [ -f "$file" ]; then
        size1=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "0")
        echo "   Root: $size1 bytes" >> $OUTPUT_FILE
    fi
    
    if [ -f "todoist-voice-ha/$file" ]; then
        size2=$(stat -f%z "todoist-voice-ha/$file" 2>/dev/null || stat -c%s "todoist-voice-ha/$file" 2>/dev/null || echo "0")
        echo "   todoist-voice-ha/: $size2 bytes" >> $OUTPUT_FILE
    fi
    
    if [ -f "addon/$file" ]; then
        size3=$(stat -f%z "addon/$file" 2>/dev/null || stat -c%s "addon/$file" 2>/dev/null || echo "0")
        echo "   addon/: $size3 bytes" >> $OUTPUT_FILE
    fi
    echo "" >> $OUTPUT_FILE
done

echo "6. RECOMMENDED ACTIONS" >> $OUTPUT_FILE
echo "=====================" >> $OUTPUT_FILE

# Determine the best structure based on what we find
echo "Based on the analysis above, here are the recommended actions:" >> $OUTPUT_FILE
echo "" >> $OUTPUT_FILE

# Check which directory has the most complete set of files
main_files=("Dockerfile" "config.yaml" "build.yaml" "package.json")
root_score=0
todoist_score=0
addon_score=0

for file in "${main_files[@]}"; do
    [ -f "$file" ] && ((root_score++))
    [ -f "todoist-voice-ha/$file" ] && ((todoist_score++))
    [ -f "addon/$file" ] && ((addon_score++))
done

echo "File completeness scores:" >> $OUTPUT_FILE
echo "   Root directory: $root_score/4 files" >> $OUTPUT_FILE
echo "   todoist-voice-ha/: $todoist_score/4 files" >> $OUTPUT_FILE
echo "   addon/: $addon_score/4 files" >> $OUTPUT_FILE
echo "" >> $OUTPUT_FILE

if [ $todoist_score -gt $root_score ] && [ $todoist_score -gt $addon_score ]; then
    echo "🎯 RECOMMENDATION: Move files FROM 'todoist-voice-ha/' TO root" >> $OUTPUT_FILE
    echo "   The todoist-voice-ha/ folder has the most complete set of files." >> $OUTPUT_FILE
elif [ $addon_score -gt $root_score ] && [ $addon_score -gt $todoist_score ]; then
    echo "🎯 RECOMMENDATION: Move files FROM 'addon/' TO root" >> $OUTPUT_FILE
    echo "   The addon/ folder has the most complete set of files." >> $OUTPUT_FILE
elif [ $root_score -ge $todoist_score ] && [ $root_score -ge $addon_score ]; then
    echo "🎯 RECOMMENDATION: Root directory structure is already correct" >> $OUTPUT_FILE
    echo "   Clean up the subdirectories if they contain duplicates." >> $OUTPUT_FILE
else
    echo "🤔 UNCLEAR: Manual review needed" >> $OUTPUT_FILE
    echo "   Multiple directories have files - need to manually compare content." >> $OUTPUT_FILE
fi

echo "" >> $OUTPUT_FILE
echo "7. CLEANUP SCRIPT SUGGESTIONS" >> $OUTPUT_FILE
echo "=============================" >> $OUTPUT_FILE
echo "After reviewing this audit, I can generate specific cleanup scripts." >> $OUTPUT_FILE

# End of audit
echo "" >> $OUTPUT_FILE
echo "Audit completed at: $(date)" >> $OUTPUT_FILE
echo "Review the file: $OUTPUT_FILE" >> $OUTPUT_FILE

# Display the audit file
echo "📊 Directory structure audit completed!"
echo "📄 Results saved to: $OUTPUT_FILE"
echo ""
echo "🔍 Quick preview:"
echo "=================="
head -50 "$OUTPUT_FILE"
echo ""
echo "💡 To see the full audit:"
echo "   cat $OUTPUT_FILE"
echo ""
echo "📋 Next steps:"
echo "   1. Review the audit file above"
echo "   2. Let me know what you see"
echo "   3. I'll create a cleanup script based on the findings"

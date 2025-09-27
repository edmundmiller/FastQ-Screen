#!/bin/bash
# Test script to validate GitHub Copilot configuration
set -e

echo "🔍 Validating GitHub Copilot Setup for FastQ-Screen..."

# Check if required files exist
echo "✅ Checking configuration files..."
required_files=(
    ".copilotignore"
    ".vscode/settings.json"
    ".vscode/extensions.json"
    ".vscode/nextflow.code-snippets"
    "docs/COPILOT_GUIDE.md"
    "CONTRIBUTING.md"
)

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo "  ✓ $file exists"
    else
        echo "  ✗ $file missing"
        exit 1
    fi
done

# Validate JSON files
echo "✅ Validating JSON syntax..."
json_files=(
    ".vscode/settings.json"
    ".vscode/extensions.json" 
    ".vscode/nextflow.code-snippets"
)

for file in "${json_files[@]}"; do
    if python3 -m json.tool "$file" > /dev/null 2>&1; then
        echo "  ✓ $file has valid JSON syntax"
    else
        echo "  ✗ $file has invalid JSON syntax"
        exit 1
    fi
done

# Check that copilotignore has appropriate patterns
echo "✅ Checking .copilotignore patterns..."
patterns_to_check=("*.png" "*.fastq" "*.fastq.gz" "results/" ".nextflow/" "node_modules/")
for pattern in "${patterns_to_check[@]}"; do
    if grep -q "$pattern" .copilotignore; then
        echo "  ✓ Pattern '$pattern' found in .copilotignore"
    else
        echo "  ✗ Pattern '$pattern' missing from .copilotignore"
        exit 1
    fi
done

# Check that VS Code settings include important configurations
echo "✅ Checking VS Code settings..."
if grep -q "github.copilot" .vscode/settings.json; then
    echo "  ✓ GitHub Copilot settings found"
else
    echo "  ✗ GitHub Copilot settings missing"
    exit 1
fi

if grep -q "nextflow" .vscode/settings.json; then
    echo "  ✓ Nextflow file associations found"
else
    echo "  ✗ Nextflow file associations missing"
    exit 1
fi

# Check that extensions include copilot
echo "✅ Checking recommended extensions..."
if grep -q "github.copilot" .vscode/extensions.json; then
    echo "  ✓ GitHub Copilot extensions recommended"
else
    echo "  ✗ GitHub Copilot extensions not recommended"
    exit 1
fi

# Check that code snippets exist
echo "✅ Checking code snippets..."
if grep -q "nf-process" .vscode/nextflow.code-snippets; then
    echo "  ✓ Nextflow process snippet found"
else
    echo "  ✗ Nextflow process snippet missing"
    exit 1
fi

echo ""
echo "🎉 GitHub Copilot setup validation complete!"
echo "   All configuration files are properly set up for bioinformatics development."
echo ""
echo "Next steps for developers:"
echo "1. Open this repository in VS Code"
echo "2. Install recommended extensions when prompted"
echo "3. Start coding with Copilot assistance!"
echo "4. Read docs/COPILOT_GUIDE.md for best practices"
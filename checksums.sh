#!/bin/bash
# WordPress Core Checksums Verifier with Table Export
# Source: https://raw.githubusercontent.com/ledoAc/domain/main/checksums.sh

echo "🔍 WordPress Core Checksums Verifier"
echo "====================================="

# Check if WP-CLI is installed
if ! command -v wp &> /dev/null; then
    echo "❌ WP-CLI is not installed."
    echo "📥 Installing WP-CLI..."
    curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    php wp-cli.phar --info
    chmod +x wp-cli.phar
    sudo mv wp-cli.phar /usr/local/bin/wp
    echo "✅ WP-CLI installed successfully"
fi

# Change to WordPress directory if provided
if [ -n "$1" ]; then
    if [ -d "$1" ]; then
        cd "$1" || exit 1
        echo "📁 Changed to directory: $1"
    else
        echo "❌ Directory $1 does not exist"
        exit 1
    fi
fi

# Verify if it's a WordPress installation
if [ ! -f "wp-config.php" ] && [ ! -f "wp-admin/admin.php" ]; then
    echo "❌ This doesn't appear to be a WordPress installation"
    echo "💡 Usage: ./checksums.sh /path/to/wordpress"
    exit 1
fi

echo "✅ WordPress installation detected"

# Get WordPress version
WP_VERSION=$(wp core version 2>/dev/null)
if [ -z "$WP_VERSION" ]; then
    echo "❌ Could not determine WordPress version"
    exit 1
fi

echo "🔢 WordPress Version: $WP_VERSION"

# Create results directory
RESULTS_DIR="wp_checksum_results"
mkdir -p "$RESULTS_DIR"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RESULTS_FILE="$RESULTS_DIR/checksum_report_$TIMESTAMP.txt"
TABLE_FILE="$RESULTS_DIR/checksum_table_$TIMESTAMP.txt"
SUMMARY_FILE="$RESULTS_DIR/summary_$TIMESTAMP.txt"

echo "📊 Running core files verification..."

# Run checksum verification and capture output
{
    echo "WORDPRESS CORE VERIFICATION REPORT"
    echo "==================================="
    echo "Date: $(date)"
    echo "WordPress Version: $WP_VERSION"
    echo "Directory: $(pwd)"
    echo ""
    echo "DETAILED FILE ANALYSIS:"
    echo "======================="
    
    # Run verify-checksums and format as table manually
    wp core verify-checksums 2>&1 | while IFS= read -r line; do
        if [[ $line == *"should be"* ]]; then
            # Extract filename and status
            filename=$(echo "$line" | sed 's/.*File \(.*\) does not.*/\1/')
            echo "│ $(printf '%-60s' "$filename") │ ❌ MODIFIED │"
        elif [[ $line == *"Success:"* ]]; then
            echo "│ $(printf '%-60s' "All files")            │ ✅ VERIFIED │"
        elif [[ $line == *"Error:"* ]]; then
            echo "│ $(printf '%-60s' "Verification")         │ ❌ FAILED │"
        fi
    done
    
    echo ""
    echo "FILE STATUS SUMMARY:"
    echo "===================="
    
    # Count different file statuses
    CHECK_RESULT=$(wp core verify-checksums 2>&1)
    if [[ $CHECK_RESULT == *"Success:"* ]]; then
        echo "✅ All core files are verified and intact"
        ERROR_FILES=0
        OK_FILES="All"
    else
        ERROR_FILES=$(echo "$CHECK_RESULT" | grep -c "should be" || true)
        echo "❌ Modified/Corrupted files: $ERROR_FILES"
        OK_FILES="Some files modified"
    fi
    
} | tee "$RESULTS_FILE"

# Create a clean table version for export
{
    echo "WordPress Core Checksums Report"
    echo "==============================="
    echo "Date: $(date)"
    echo "WordPress Version: $WP_VERSION"
    echo ""
    echo "┌────────────────────────────────────────────────────────────┬─────────────┐"
    echo "│ File                                                       │ Status      │"
    echo "├────────────────────────────────────────────────────────────┼─────────────┤"
    
    # Get the table output
    wp core verify-checksums 2>&1 | while IFS= read -r line; do
        if [[ $line == *"should be"* ]]; then
            filename=$(echo "$line" | sed 's/.*File \(.*\) does not.*/\1/')
            echo "│ $(printf '%-60s' "$filename") │ ❌ MODIFIED │"
        elif [[ $line == *"Success:"* ]]; then
            echo "│ $(printf '%-60s' "All core files")         │ ✅ VERIFIED │"
        fi
    done
    
    echo "└────────────────────────────────────────────────────────────┴─────────────┘"
    
} > "$TABLE_FILE"

# Create summary file
{
    echo "WORDPRESS CORE VERIFICATION SUMMARY"
    echo "==================================="
    echo "Scan Date: $(date)"
    echo "WordPress Version: $WP_VERSION"
    echo "Scan Directory: $(pwd)"
    echo ""
    
    # Get summary
    CHECK_RESULT=$(wp core verify-checksums 2>&1)
    if [[ $CHECK_RESULT == *"Success:"* ]]; then
        echo "🎉 STATUS: ALL CORE FILES ARE INTACT"
        echo "✅ No modified or corrupted files found"
    else
        echo "⚠️  STATUS: CORE FILES MODIFIED"
        echo "❌ Some core files have been modified or corrupted"
        echo ""
        echo "Modified files:"
        echo "$CHECK_RESULT" | grep "should be" | head -20
    fi
    
} > "$SUMMARY_FILE"

# Check if there are errors and provide appropriate exit code
if wp core verify-checksums --quiet &>/dev/null; then
    echo "🎉 SCAN RESULT: ALL CORE FILES ARE VALID"
    exit 0
else
    echo "⚠️  SCAN RESULT: CORE FILES MODIFIED - Review reports above"
    exit 1
fi

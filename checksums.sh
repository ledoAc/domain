#!/bin/bash
# WordPress Core Checksums Verifier with Error Descriptions

echo "Checking WordPress core files integrity..."

wp core verify-checksums 2>&1 | while IFS= read -r line; do
    if [[ $line == *"should be"* ]]; then
        filename=$(echo "$line" | sed 's/.*File \(.*\) does not.*/\1/')
        echo "❌ MODIFIED: $filename"
        
        # Додаємо опис залежно від файлу
        case "$filename" in
            *"wp-config.php"*)
                echo "   ⚠️  Critical: Main configuration file - could contain malicious code"
                ;;
            *"wp-admin/"*)
                echo "   🔧 Admin area file - check for backdoors"
                ;;
            *"wp-includes/"*)
                echo "   📚 Core library file - possible malware injection"
                ;;
            *"index.php"*)
                echo "   🏠 Main entry point - common target for redirects"
                ;;
            *".htaccess"*)
                echo "   🔐 Server configuration - check for malicious rules"
                ;;
            *"xmlrpc.php"*)
                echo "   🌐 API endpoint - often abused for brute force attacks"
                ;;
            *)
                echo "   🔍 Core WordPress file - verify authenticity"
                ;;
        esac
    fi
done

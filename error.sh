find . -type f -name "error_log" 2>/dev/null -exec sh -c '
  for f do
    dir=$(dirname "$f")
    wp_config="$dir/wp-config.php"

    # Тільки WordPress
    [ -f "$wp_config" ] || continue

    # Домен із бази через WP-CLI
    domain=$(wp option get siteurl --path="$dir" 2>/dev/null)
    domain=${domain#*://}
    domain=${domain:-"UNKNOWN_DOMAIN"}

    printf "\033[31m=== %s — %s ===\033[0m\n" "$domain" "$dir"
    tail -n 5 "$f"
    echo ""
  done
' sh {} +

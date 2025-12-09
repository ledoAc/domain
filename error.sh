find . -type f -name "error_log" 2>/dev/null -exec sh -c '
  extract_domain_from_path() {
    echo "$1" | grep -oE "[A-Za-z0-9.-]+\.[A-Za-z]{2,}" | head -n 1
  }

  for f do
    dir=$(dirname "$f")
    wp_config="$dir/wp-config.php"

    # Тільки WordPress
    [ -f "$wp_config" ] || continue

    domain=""

    # 1) спроба взяти домен з wp-config (WP_HOME / WP_SITEURL)
    domain=$(grep -E "WP_HOME|WP_SITEURL" "$wp_config" \
      | grep -oE "https?://[^\"'\'' ]+" \
      | head -n 1)
    domain=${domain#*://}

    # 2) fallback: домен із шляху
    if [ -z "$domain" ]; then
      domain=$(extract_domain_from_path "$dir")
    fi

    domain=${domain:-"UNKNOWN_DOMAIN"}

    # Червоний заголовок як в оригіналі
    printf "\033[31m=== %s — %s ===\033[0m\n" "$domain" "$dir"

    # Виводимо останні 5 рядків error_log (як в оригіналі)
    tail -n 5 "$f"
    echo ""

  done
' sh {} +

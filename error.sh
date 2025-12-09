find . -type f -name "error_log" 2>/dev/null -exec sh -c '
  extract_domain_from_path() {
    echo "$1" | grep -oE "[A-Za-z0-9.-]+\.[A-Za-z]{2,}" | head -n 1
  }

  extract_domain_from_wpcli() {
    local dir="$1"

    if command -v wp >/dev/null 2>&1; then
      # запускаємо wp-cli у тій директорії
      domain=$(wp option get siteurl --path="$dir" 2>/dev/null)
      if [ -n "$domain" ]; then
        domain=${domain#*://}
        echo "$domain"
        return
      fi
    fi
    echo ""
  }

  for f do
    dir=$(dirname "$f")
    wp_config="$dir/wp-config.php"
    domain=""

    # 1) Спроба з wp-config.php
    if [ -f "$wp_config" ]; then
      domain=$(grep -E "WP_HOME|WP_SITEURL" "$wp_config" \
        | grep -oE "https?://[^\"'\'' ]+" \
        | head -n 1)
      domain=${domain#*://}
    fi

    # 2) Якщо немає → wp-cli
    if [ -z "$domain" ]; then
      domain=$(extract_domain_from_wpcli "$dir")
    fi

    # 3) Якщо немає → з директорії
    if [ -z "$domain" ]; then
      domain=$(extract_domain_from_path "$dir")
    fi

    # 4) Якщо все одно порожньо
    domain=${domain:-"UNKNOWN_DOMAIN"}

    printf "\033[31m%s — %s\033[0m\n" "$domain" "$dir"

    # Дата останньої помилки
    last_date=$(tail -n 200 "$f" \
      | grep -E "\[[0-9]{2}-[A-Za-z]{3}-[0-9]{4}" \
      | tail -n 1)

    if [ -n "$last_date" ]; then
      echo "Last error date:"
      echo "$last_date"
    else
      echo "No date found in last entries"
    fi

    echo ""
    tail -n 5 "$f"
    echo ""

  done
' sh {} +

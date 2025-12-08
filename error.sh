find -type f -name "error_log" 2>/dev/null -exec sh -c '
  for f do
    dir=$(dirname "$f")
    if [ -f "$dir/wp-config.php" ]; then
      echo -e "\e[31m=== $dir ===\e[0m"
      tail -n 5 "$f"
      echo ""
    fi
  done
' sh {} +

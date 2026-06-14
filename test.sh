┌─────────────────────────────────────────────────────────────────┐
│  #!/usr/bin/env bash                                           │
│  set -euo pipefail                                             │
│  IFS=$'\n\t'                                                   │
│                                                                 │
│  ###########################################################   │
│  #  🔍 DNS RECORDS CHECKER v1.0                                │
│  #  Перевіряє A, MX та TXT записи для домену                   │
│  ###########################################################   │
│                                                                 │
│  # ==================== КОНФІГУРАЦІЯ =======================   │
│  readonly SCRIPT_NAME="DNS Checker"                            │
│  readonly VERSION="1.0"                                        │
│                                                                 │
│  # Кольори для виводу                                           │
│  readonly RED='\033[0;31m'                                     │
│  readonly GREEN='\033[0;32m'                                   │
│  readonly YELLOW='\033[1;33m'                                  │
│  readonly BLUE='\033[0;34m'                                    │
│  readonly NC='\033[0m' # No Color                              │
│                                                                 │
│  # ==================== ФУНКЦІЇ ============================   │
│                                                                 │
│  # Вивід допомоги                                              │
│  show_help() {                                                 │
│      cat << EOF                                                │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  📖 ВИКОРИСТАННЯ                                         │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│      $0 <домен> [тип_запису]                                   │
│                                                                 │
│      Типи записів (необов'язково):                             │
│        all   - перевірити всі (за замовчуванням)               │
│        a     - тільки A записи                                 │
│        mx    - тільки MX записи                                │
│        txt   - тільки TXT записи                               │
│                                                                 │
│      Приклади:                                                  │
│        $0 example.com                                          │
│        $0 example.com a                                        │
│        $0 example.com mx                                       │
│        $0 google.com all                                       │
│                                                                 │
│  EOF                                                           │
│  }                                                             │
│                                                                 │
│  # Логування з кольорами                                        │
│  log_info() {                                                  │
│      echo -e "${BLUE}ℹ️${NC} $1"                               │
│  }                                                             │
│                                                                 │
│  log_success() {                                               │
│      echo -e "${GREEN}✅${NC} $1"                              │
│  }                                                             │
│                                                                 │
│  log_error() {                                                 │
│      echo -e "${RED}❌${NC} $1" >&2                            │
│  }                                                             │
│                                                                 │
│  log_warning() {                                               │
│      echo -e "${YELLOW}⚠️${NC} $1"                             │
│  }                                                             │
│                                                                 │
│  # Перевірка A записів                                          │
│  check_a_records() {                                           │
│      local domain="$1"                                         │
│      echo ""                                                   │
│      echo "┌─────────────────────────────────────────────────┐"│
│      echo "│  🌐 A RECORDS (IPv4 адреси)                     │"│
│      echo "└─────────────────────────────────────────────────┘"│
│                                                                 │
│      local records                                            
│      records=$(dig +short "$domain" A)                         │
│                                                                 │
│      if [[ -z "$records" ]]; then                              │
│          log_warning "A записи не знайдено для $domain"        │
│          return 1                                              │
│      fi                                                         │
│                                                                 │
│      local count=0                                             │
│      while IFS= read -r record; do                             │
│          ((count++))                                           │
│          echo "  $count. $record"                              │
│      done <<< "$records"                                       │
│                                                                 │
│      log_success "Знайдено $count A запис(ів)"                 │
│  }                                                             │
│                                                                 │
│  # Перевірка MX записів                                         │
│  check_mx_records() {                                          │
│      local domain="$1"                                         │
│      echo ""                                                   │
│      echo "┌─────────────────────────────────────────────────┐"│
│      echo "│  📧 MX RECORDS (поштові сервери)                │"│
│      echo "└─────────────────────────────────────────────────┘"│
│                                                                 │
│      local records                                            │
│      records=$(dig +short "$domain" MX | sort -n)              │
│                                                                 │
│      if [[ -z "$records" ]]; then                              │
│          log_warning "MX записи не знайдено для $domain"       │
│          return 1                                              │
│      fi                                                         │
│                                                                 │
│      local count=0                                             │
│      while IFS= read -r record; do                             │
│          ((count++))                                           │
│          local priority=$(echo "$record" | awk '{print $1}')   │
│          local server=$(echo "$record" | awk '{print $2}')     │
│          printf "  %d. [Пріоритет: %d] → %s\n" "$count" "$priority" "$server" │
│      done <<< "$records"                                       │
│                                                                 │
│      log_success "Знайдено $count MX запис(ів)"                │
│  }                                                             │
│                                                                 │
│  # Перевірка TXT записів                                        │
│  check_txt_records() {                                         │
│      local domain="$1"                                         │
│      echo ""                                                   │
│      echo "┌─────────────────────────────────────────────────┐"│
│      echo "│  📝 TXT RECORDS (текстові записи)               │"│
│      echo "└─────────────────────────────────────────────────┘"│
│                                                                 │
│      local records                                            │
│      records=$(dig +short "$domain" TXT)                       │
│                                                                 │
│      if [[ -z "$records" ]]; then                              │
│          log_warning "TXT записи не знайдено для $domain"      │
│          return 1                                              │
│      fi                                                         │
│                                                                 │
│      local count=0                                             │
│      while IFS= read -r record; do                             │
│          ((count++))                                           │
│          # Прибираємо лапки навколо TXT значення                │
│          local clean_record=$(echo "$record" | sed 's/^"//;s/"$//') │
│          echo "  $count. $clean_record"                        │
│      done <<< "$records"                                       │
│                                                                 │
│      log_success "Знайдено $count TXT запис(ів)"               │
│  }                                                             │
│                                                                 │
│  # Перевірка всіх записів                                       │
│  check_all_records() {                                         │
│      local domain="$1"                                         │
│      echo ""                                                   │
│      echo "╔═════════════════════════════════════════════════╗"│
│      echo "║  🔍 DNS CHECKER FOR: $domain                     ║"│
│      echo "╚═════════════════════════════════════════════════╝"│
│                                                                 │
│      check_a_records "$domain"                                 │
│      check_mx_records "$domain"                                │
│      check_txt_records "$domain"                               │
│                                                                 │
│      echo ""                                                   │
│      echo "┌─────────────────────────────────────────────────┐"│
│      echo "│  ✅ ПЕРЕВІРКУ ЗАВЕРШЕНО                         │"│
│      echo "└─────────────────────────────────────────────────┘"│
│  }                                                             │
│                                                                 │
│  # ==================== ГОЛОВНА ФУНКЦІЯ ====================   │
│  main() {                                                     │
│      local domain="${1:-}"                                    │
│      local record_type="${2:-all}"                            │
│                                                                 │
│      # Перевірка аргументів                                    │
│      if [[ -z "$domain" ]]; then                              │
│          log_error "Домен не вказано!"                         │
│          show_help                                            │
│          exit 1                                               │
│      fi                                                         │
│                                                                 │
│      # Перевірка наявності dig                                 │
│      if ! command -v dig &> /dev/null; then                    │
│          log_error "Команда 'dig' не знайдена!"                │
│          log_info "Встановіть dnsutils (apt) або bind-tools (yum)" │
│          exit 1                                               │
│      fi                                                         │
│                                                                 │
│      # Вибір типу перевірки                                     │
│      case "$record_type" in                                    │
│          a|A)                                                  │
│              check_a_records "$domain"                         │
│              ;;                                                │
│          mx|MX)                                                │
│              check_mx_records "$domain"                        │
│              ;;                                                │
│          txt|TXT)                                              │
│              check_txt_records "$domain"                       │
│              ;;                                                │
│          all|ALL|"")                                           │
│              check_all_records "$domain"                       │
│              ;;                                                │
│          *)                                                    │
│              log_error "Невідомий тип запису: $record_type"    │
│              show_help                                         │
│              exit 1                                            │
│              ;;                                                │
│      esac                                                       │
│  }                                                             │
│                                                                 │
│  # ==================== ЗАПУСК =============================   │
│  main "$@"                                                     │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘

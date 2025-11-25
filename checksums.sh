<?php
WP_CLI::add_command( 'core verify-explain', function() {

    // Запускаємо стандартну команду
    $result = WP_CLI::launch_self( 'core verify-checksums', [], [], false, true );
    $output = explode("\n", $result->stdout);

    foreach ( $output as $line ) {

        // Червоний — попередження
        if (strpos($line, 'Warning: File doesn\'t verify') !== false) {
            WP_CLI::line("\033[31m$line\033[0m");
            WP_CLI::line("  → Цей файл не збігається з оригінальною версією WordPress. Його або змінили, або він заражений.\n");

        // Червоний — зайві файли
        } elseif (strpos($line, 'Warning: File should not exist') !== false) {
            WP_CLI::line("\033[31m$line\033[0m");
            WP_CLI::line("  → Цього файлу немає в офіційній збірці WordPress. Його додали сторонньо — ймовірно, шкідливий.\n");

        // Червоний — загальний Error
        } elseif (strpos($line, 'Error:') !== false) {
            WP_CLI::line("\033[31m$line\033[0m");
            WP_CLI::line("  → WordPress core має змінені або зайві файли — інсталяція не чиста.\n");

        // Зелений — Success
        } elseif (strpos($line, 'Success:') !== false) {
            WP_CLI::line("\033[32m$line\033[0m");
            WP_CLI::line("  → Усі файли WordPress збігаються з оригіналом. Зміни відсутні.\n");

        // Інше — без змін
        } else {
            WP_CLI::line($line);
        }
    }
});

#!/bin/bash

# Скрипт: disk_monitor.sh
# Автор: Кирилл Матков
# Назначение: Мониторинг свободного места на дисках сервера
# Порог предупреждения: менее 20% свободного места
# Лог: /var/log/disk_monitor.log

LOG_FILE="/var/log/disk_monitor.log"
THRESHOLD=20  # Процент свободного места, ниже которого выдаём предупреждение

# Создаём лог-файл, если он не существует
if [ ! -f "$LOG_FILE" ]; then
    touch "$LOG_FILE"
    chmod 644 "$LOG_FILE"
fi

# Записываем начало проверки
echo "$(date '+%Y-%m-%d %H:%M:%S') — Начало мониторинга дисков" >> "$LOG_FILE"

# Флаг для определения, были ли предупреждения
WARNING_FOUND=0

# Получаем информацию о дисках, исключая временные и виртуальные ФС
df -h -x tmpfs -x devtmpfs -x squashfs | tail -n +2 | while read -r filesystem size used avail percent mountpoint; do
    # Убираем знак % из значения
    percent_value=${percent//%/}
    
    # Вычисляем свободное место в процентах
    free_percent=$((100 - percent_value))
    
    # Записываем информацию о каждом диске в лог
    echo "$(date '+%Y-%m-%d %H:%M:%S') — Диск $filesystem ($mountpoint): свободно $free_percent%" >> "$LOG_FILE"
    
    # Проверяем порог
    if [ "$free_percent" -lt "$THRESHOLD" ]; then
        WARNING_MESSAGE="ПРЕДУПРЕЖДЕНИЕ: На диске $filesystem ($mountpoint) свободно только $free_percent%!"
        echo "$WARNING_MESSAGE" | tee -a "$LOG_FILE"
        WARNING_FOUND=1
    fi
done

# Итоговое сообщение
if [ "$WARNING_FOUND" -eq 0 ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') — Все диски в норме (свободно ≥ $THRESHOLD%)" >> "$LOG_FILE"
    echo "Мониторинг завершён. Все диски в норме."
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') — Обнаружены диски с низким свободным местом" >> "$LOG_FILE"
    echo "Мониторинг завершён. Обнаружены предупреждения (см. $LOG_FILE)."
fi
#!/bin/bash
# slow-query-report.sh — 每日慢查询报告

LOG_FILE="/var/log/mysql/slow.log"
REPORT_DIR="/opt/reports/slow-query"
DATE=$(date +%Y-%m-%d)

mkdir -p "$REPORT_DIR"

# 生成报告
pt-query-digest \
  --since "$(date -d 'yesterday' +%Y-%m-%d)" \
  --until "$DATE" \
  --limit 20 \
  "$LOG_FILE" > "$REPORT_DIR/report-$DATE.txt"

# 统计关键指标
echo "=== 慢查询日报 $DATE ===" >> "$REPORT_DIR/summary-$DATE.txt"
echo "慢查询总数: $(grep -c '^# Time:' "$LOG_FILE")" >> "$REPORT_DIR/summary-$DATE.txt"
echo "详细报告: $REPORT_DIR/report-$DATE.txt" >> "$REPORT_DIR/summary-$DATE.txt"
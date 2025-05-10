#!/bin/bash

# Set the log file name
LOG_FILE="access_log.txt"

# Check if the log file exists
if [[ ! -f "$LOG_FILE" ]]; then
  echo "Log file not found: $LOG_FILE"
  exit 1
fi

echo "===== Log File Analysis Report ====="

# Count total requests, GET requests, and POST requests
total_requests=$(wc -l < "$LOG_FILE")
get_requests=$(grep "GET" "$LOG_FILE" | wc -l)
post_requests=$(grep "POST" "$LOG_FILE" | wc -l)

echo "Total Requests: $total_requests"
echo "GET Requests: $get_requests"
echo "POST Requests: $post_requests"

# Count unique IP addresses and their GET/POST activity
echo
echo "===== Unique IP Addresses ====="
awk '{print $1}' "$LOG_FILE" | sort | uniq -c | sort -nr > unique_ips.txt
total_unique_ips=$(wc -l < unique_ips.txt)
echo "Total Unique IPs: $total_unique_ips"

echo "Requests per IP (GET/POST):"
while read -r line; do
    ip=$(echo "$line" | awk '{print $2}')
    get_count=$(grep "^$ip " "$LOG_FILE" | grep "GET" | wc -l)
    post_count=$(grep "^$ip " "$LOG_FILE" | grep "POST" | wc -l)
    echo "$ip - GET: $get_count, POST: $post_count"
done < unique_ips.txt

# Count failed requests (4xx and 5xx) and calculate their percentage
failures=$(awk '$9 ~ /^4|^5/ {count++} END {print count}' "$LOG_FILE")
fail_pct=$(awk -v f="$failures" -v t="$total_requests" 'BEGIN {printf "%.2f", (f/t)*100}')
echo
echo "===== Failures ====="
echo "Failed Requests (4xx/5xx): $failures"
echo "Failure Percentage: $fail_pct%"

# Find the most active IP
top_ip=$(awk '{print $1}' "$LOG_FILE" | sort | uniq -c | sort -nr | head -n 1)
echo
echo "===== Top User ====="
echo "Most Active IP: $top_ip"

# Calculate average number of requests per day
avg_per_day=$(awk -F[ '{print $2}' "$LOG_FILE" | cut -d: -f1 | uniq -c | awk '{sum+=$1; count++} END {printf "%.2f", sum/count}')
echo
echo "Average Requests per Day: $avg_per_day"

# Show days with most failures
echo
echo "===== Failure Analysis by Date ====="
awk '$9 ~ /^4|^5/ {split($4, dt, ":"); gsub("\\[", "", dt[1]); fails[dt[1]]++}
     END {for (d in fails) print d, fails[d]}' "$LOG_FILE" | sort -k2 -nr | head -n 5

# Requests per hour
echo
echo "===== Requests per Hour ====="
awk -F[ '{print $2}' "$LOG_FILE" | cut -d: -f2 | sort | uniq -c

# Status codes breakdown
echo
echo "===== Status Code Breakdown ====="
awk '{print $9}' "$LOG_FILE" | sort | uniq -c | sort -nr

# Most active user by method
echo
echo "===== Most Active User by Method ====="
echo "GET:"
grep "GET" "$LOG_FILE" | awk '{print $1}' | sort | uniq -c | sort -nr | head -n 1
echo "POST:"
grep "POST" "$LOG_FILE" | awk '{print $1}' | sort | uniq -c | sort -nr | head -n 1

# Failures by hour
echo
echo "===== Failure Patterns by Hour ====="
awk '$9 ~ /^4|^5/ {split($4, t, ":"); print t[2]}' "$LOG_FILE" | sort | uniq -c | sort -nr

echo
echo "===== End of Report ====="

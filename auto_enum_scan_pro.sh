#!/bin/bash

# =========================
# 🔧 Configuration
# =========================
read -p "Enter target domain (e.g. example.com): " domain
webhook_url="https://hooks.slack.com/services/XXXXX/XXXXX/XXXXXX"  # Change this

output_dir="output/${domain}_scan_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$output_dir"

subdomains_file="$output_dir/subdomains.txt"
live_file="$output_dir/live_subdomains.txt"
nuclei_csv="$output_dir/nuclei_results.csv"
nuclei_json="$output_dir/nuclei_results.json"
nuclei_txt="$output_dir/nuclei_results.txt"

# =========================
# 1️⃣ Subdomain Enumeration
# =========================
echo "[*] Enumerating subdomains..."
subfinder -d "$domain" -silent -o "$subdomains_file"

# =========================
# 2️⃣ Live Host Detection
# =========================
echo "[*] Checking live domains with httpx..."
httpx -l "$subdomains_file" -silent -status-code -title -o "$live_file"

# =========================
# 3️⃣ Nuclei Scan
# =========================
echo "[*] Scanning for vulnerabilities using nuclei..."
nuclei -l "$live_file" \
  -t nuclei-templates/ \
  -o "$nuclei_txt" \
  -json -json-export "$nuclei_json" \
  -csv -csv-export "$nuclei_csv"

# =========================
# 4️⃣ Slack/Webhook Alert
# =========================
vuln_count=$(wc -l < "$nuclei_txt")

curl -s -X POST -H 'Content-type: application/json' --data "{
  \"text\": \"🛡️ Nuclei Scan for *$domain* complete!\n• Live: $(wc -l < "$live_file")\n• Vulns: $vuln_count\n• Saved in: $output_dir\"
}" "$webhook_url"

# =========================
# ✅ Done
# =========================
echo "[✔] Scan completed. Results in $output_dir"

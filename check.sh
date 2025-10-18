#!/bin/bash
# =======================================================
# 🔍 Golden Miner Proxy - Full Diagnostic Script
# Author: ChatGPT Assistant
# System: Ubuntu 24.04 LTS
# =======================================================

IP=$(hostname -I | awk '{print $1}')
PORT_PROXY=9999
PORT_MONITOR=$((PORT_PROXY+1))
PORT_EXTRA=$((PORT_PROXY+2))
SERVICE_NAME="golden-proxy.service"
LOG_FILE="/var/log/proxy.log"

echo "======================================================="
echo "🔧 Golden Miner Proxy Diagnostic Utility"
echo "======================================================="
echo "🕓 Date: $(date)"
echo "🌐 IP Address: $IP"
echo "======================================================="

# 1️⃣ Проверка статуса службы
echo ""
echo "▶️ Checking systemd service status..."
if systemctl list-units --type=service | grep -q "$SERVICE_NAME"; then
    systemctl --no-pager status "$SERVICE_NAME" | grep -E "Active|Main PID|ExecStart"
else
    echo "❌ Service $SERVICE_NAME not found!"
fi
echo "-------------------------------------------------------"

# 2️⃣ Проверка запущенных процессов
echo "▶️ Checking running process..."
ps aux | grep golden-miner-pool-proxy | grep -v grep || echo "❌ Process not running!"
echo "-------------------------------------------------------"

# 3️⃣ Проверка открытых портов
echo "▶️ Checking listening ports..."
ss -tuln | grep -E "$PORT_PROXY|$PORT_MONITOR|$PORT_EXTRA" || echo "❌ Proxy ports are not listening!"
echo "-------------------------------------------------------"

# 4️⃣ Проверка доступности API (локально)
echo "▶️ Testing local API endpoints..."
echo "→ /api/metrics"
curl -s http://127.0.0.1:$PORT_MONITOR/api/metrics | jq . 2>/dev/null || echo "❌ No response from /api/metrics"
echo "→ /api/rates"
curl -s http://127.0.0.1:$PORT_MONITOR/api/rates | jq . 2>/dev/null || echo "❌ No response from /api/rates"
echo "-------------------------------------------------------"

# 5️⃣ Проверка firewall
echo "▶️ Checking UFW firewall rules..."
ufw status numbered || echo "⚠️ UFW not active or not installed."
echo "-------------------------------------------------------"

# 6️⃣ Проверка логов прокси
echo "▶️ Showing last 20 log lines..."
if [ -f "$LOG_FILE" ]; then
    tail -n 20 "$LOG_FILE"
else
    echo "⚠️ Log file not found: $LOG_FILE"
fi
echo "-------------------------------------------------------"

# 7️⃣ Проверка автозапуска
echo "▶️ Checking autostart..."
systemctl is-enabled "$SERVICE_NAME" 2>/dev/null && echo "✅ Autostart is enabled." || echo "❌ Autostart is disabled."
echo "-------------------------------------------------------"

# 8️⃣ Итоговый результат
echo ""
echo "✅ Diagnostic completed."
echo "🌍 Web Monitor: http://$IP:$PORT_MONITOR"
echo "📡 API Endpoints:"
echo "   - http://$IP:$PORT_MONITOR/api/metrics"
echo "   - http://$IP:$PORT_MONITOR/api/rates"
echo "======================================================="

🧾 Что ты получишь в результате:

После выполнения скрипта, он выведет примерно такое:

🔧 Golden Miner Proxy Diagnostic Utility
🕓 Date: Sat Oct 18 13:48:22 UTC 2025
🌐 IP Address: 141.95.73.20

▶️ Checking systemd service status...
Active: active (running) since Sat 2025-10-18 13:31:12 UTC; 15min ago
Main PID: 56241 (golden-miner-poo)

▶️ Checking listening ports...
LISTEN 0 4096 0.0.0.0:9999 ...
LISTEN 0 4096 0.0.0.0:10000 ...
LISTEN 0 4096 0.0.0.0:10001 ...

▶️ Testing local API endpoints...
[{"height":32179,"label":"cluster-A", ... }]

▶️ Showing last 20 log lines...
[INFO] Proxy started on port 9999
[INFO] Connected provers: 25

✅ Diagnostic completed.
🌍 Web Monitor: http://141.95.73.20:10000
📡 API: /api/metrics | /api/rates




# ==============================================
#  Golden Miner Proxy Diagnostic Utility
#  Checks proxy health, workers, metrics & logs
# ==============================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧠 Golden Miner Proxy Diagnostic Utility"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Date: $(date -u)"
IP_ADDR=$(hostname -I | awk '{print $1}')
echo "IP Address: ${IP_ADDR}"
echo ""

# --- 1. Systemd service status ---
echo "🔍 Checking systemd service status..."
if systemctl is-active --quiet golden-proxy.service; then
  systemctl status golden-proxy.service | grep "Active:" | head -n1
else
  echo "❌ golden-proxy.service not running!"
fi
echo ""

# --- 2. Running process check ---
echo "🔍 Checking running process..."
ps aux | grep golden-miner-pool-proxy | grep -v grep || echo "❌ Process not found"
echo ""

# --- 3. Listening ports ---
echo "🔍 Checking listening ports..."
ss -tulnp | grep -E "9999|10000|10001" || echo "❌ Proxy ports not open"
echo ""

# --- 4. Testing local API endpoints ---
echo "🔍 Testing local API endpoints..."
if ! command -v jq &>/dev/null; then
  echo "Installing jq for JSON formatting..."
  apt-get update -y >/dev/null 2>&1 && apt-get install -y jq >/dev/null 2>&1
fi
curl -s http://127.0.0.1:10000/api/metrics | jq || echo "⚠️  No response or empty data"
echo ""

# --- 5. Checking UFW rules ---
echo "🔍 Checking UFW firewall rules..."
ufw status | grep -E "9999|10000|10001" || echo "⚠️  No firewall rules for proxy ports"
echo ""

# --- 6. Showing last log lines ---
LOG_FILE="/var/log/proxy.log"
if [ -f "$LOG_FILE" ]; then
  echo "📜 Showing last 20 log lines..."
  tail -n 20 "$LOG_FILE"
else
  echo "⚠️  Log file not found ($LOG_FILE)"
  journalctl -u golden-proxy.service -n 20 --no-pager
fi
echo ""

# --- 7. Check autostart ---
echo "🔍 Checking autostart..."
if systemctl is-enabled golden-proxy.service >/dev/null 2>&1; then
  echo "✅ Autostart is enabled"
else
  echo "⚠️  Autostart is disabled"
fi
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Diagnostic completed."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"





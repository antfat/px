#!/bin/bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧠 Golden Miner Proxy Diagnostic Utility"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Date: $(date -u)"
IP_ADDR=$(hostname -I | awk '{print $1}')
echo "IP Address: ${IP_ADDR}"
echo ""

echo "🔍 Checking systemd service status..."
systemctl status golden-proxy.service | grep "Active:" || echo "❌ Not running"
echo ""

echo "🔍 Checking running process..."
ps aux | grep golden-miner-pool-proxy | grep -v grep || echo "❌ Process not found"
echo ""

echo "🔍 Checking listening ports..."
ss -tulnp | grep -E "9999|10000|10001" || echo "❌ Proxy ports not open"
echo ""

echo "🔍 Testing local API endpoints..."
apt install -y jq -qq >/dev/null 2>&1
echo "API /metrics:"
curl -s http://127.0.0.1:10000/api/metrics | jq
echo "API /rates:"
curl -s http://127.0.0.1:10000/api/rates | jq
echo ""

echo "🔍 Checking UFW firewall rules..."
sudo ufw status | grep -E "9999|10000|10001" || echo "⚠️  No rules for proxy ports"
echo ""

LOG_FILE="/var/log/proxy.log"
if [ -f "$LOG_FILE" ]; then
  echo "📜 Last 20 log lines:"
  tail -n 20 "$LOG_FILE"
else
  echo "⚠️  Log not found — showing systemd logs:"
  journalctl -u golden-proxy.service -n 20 --no-pager
fi
echo ""

echo "🔍 Checking autostart..."
systemctl is-enabled golden-proxy.service >/dev/null 2>&1 && echo "✅ Autostart is enabled" || echo "⚠️  Autostart disabled"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Diagnostic completed."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
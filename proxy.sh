#!/bin/bash
# ==========================================================
# 🟡 Golden Miner Proxy - Full Auto Setup for Ubuntu 24.04 LTS
# Works on OVH dedicated servers (e.g. Ryzen 5 5600X / 32 GB / 1 Gbps)
# ==========================================================

set -e

# === CONFIGURATION ===
PUBKEY="3bfNk9C3iT8VFT1hjg1w8hwASXXaL1HcyKsQCR8t7H8Xnp25My2s1oYhs6XwtKk9D8Ku2fvbnAC7yx7Xfse65a1atCQJmMG62S1tkJkgzJuJpKXQUA8ELX5ifCevEcv7iHGb"
PROXY_NAME="golden-proxy"
PROXY_LABEL="proxy"
PROXY_PORT=9999
WORKDIR="/opt/golden-proxy"
BIN_URL="https://github.com/GoldenMinerNetwork/golden-miner-nockchain-gpu-miner/releases/download/v0.1.4/golden-miner-pool-proxy"
LOG_FILE="$WORKDIR/proxy.log"
ERR_FILE="$WORKDIR/proxy.err"

echo "🚀 Starting full server & proxy setup..."

# ----------------------------------------------------------
# 1. System preparation
# ----------------------------------------------------------
apt update -y && apt upgrade -y
apt install -y curl wget unzip tar ufw jq htop net-tools vim

# Set timezone to UTC
timedatectl set-timezone UTC

# ----------------------------------------------------------
# 2. Optimize system limits and network parameters
# ----------------------------------------------------------
ulimit -n 20000
echo "ulimit -n 20000" >> /etc/profile

cat <<EOF >> /etc/security/limits.conf
* soft nofile 20000
* hard nofile 20000
EOF

cat <<EOF >> /etc/sysctl.conf
net.core.somaxconn = 65535
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 15
EOF
sysctl -p

# ----------------------------------------------------------
# 3. Configure firewall
# ----------------------------------------------------------
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp              # SSH
ufw allow ${PROXY_PORT}/tcp
ufw allow $((PROXY_PORT+1))/tcp
ufw allow $((PROXY_PORT+2))/tcp
ufw --force enable

# ----------------------------------------------------------
# 4. Create working directory
# ----------------------------------------------------------
mkdir -p $WORKDIR && cd $WORKDIR

# ----------------------------------------------------------
# 5. Download and prepare Golden Miner Proxy binary
# ----------------------------------------------------------
echo "⬇️ Downloading proxy binary..."
wget -q $BIN_URL -O golden-miner-pool-proxy
chmod +x golden-miner-pool-proxy

# ----------------------------------------------------------
# 6. Create systemd service
# ----------------------------------------------------------
cat <<EOF > /etc/systemd/system/golden-proxy.service
[Unit]
Description=Golden Miner Proxy Service
After=network.target

[Service]
User=root
WorkingDirectory=$WORKDIR
ExecStart=$WORKDIR/golden-miner-pool-proxy --pubkey=$PUBKEY --name=$PROXY_NAME --label=$PROXY_LABEL --port=$PROXY_PORT
Restart=always
RestartSec=5
LimitNOFILE=20000
StandardOutput=append:$LOG_FILE
StandardError=append:$ERR_FILE

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable golden-proxy
systemctl start golden-proxy

# ----------------------------------------------------------
# 7. Setup log rotation and cleanup
# ----------------------------------------------------------
cat <<EOF > /usr/local/bin/clean_proxy_logs.sh
#!/bin/bash
find $WORKDIR -name "*.log" -size +50M -delete
EOF
chmod +x /usr/local/bin/clean_proxy_logs.sh
echo "0 3 * * * root /usr/local/bin/clean_proxy_logs.sh" >> /etc/crontab

# ----------------------------------------------------------
# 8. Display status
# ----------------------------------------------------------
echo "✅ Proxy service status:"
systemctl status golden-proxy --no-pager || true

echo "✅ Firewall status:"
ufw status

echo "✅ Installation complete!"
echo "Monitor at:  http://$(hostname -I | awk '{print $1}'):$((PROXY_PORT+1))"
echo "API:         /api/metrics  /api/rates"
echo "Logs:        tail -f $LOG_FILE"
echo "-----------------------------------------------------------"
echo "Proxy listening on port $PROXY_PORT"
echo "Monitoring: ports $((PROXY_PORT+1)) and $((PROXY_PORT+2))"
echo "-----------------------------------------------------------"

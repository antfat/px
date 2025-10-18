#!/bin/bash
# ==== НАСТРОЙКИ ====
WORKDIR="$HOME/work"
WORKER="$WORKDIR/worker"
MINER_URL="https://github.com/GoldenMinerNetwork/golden-miner-nockchain-gpu-miner/releases/download/v0.1.5/golden-miner-pool-prover"

# Константы для запуска майнера
LABEL="workers"
PROXY="141.95.73.20:9999"  # адрес твоего прокси-сервера

SUFFIX="$1"
if [ -z "$SUFFIX" ]; then
  echo "❌ Использование: $0 <SUFFIX>"
  exit 1
fi

# ==== ОБНОВЛЕНИЕ ПАПКИ ====
if [ -d "$WORKDIR" ]; then
  rm -rf "$WORKDIR"
fi
mkdir -p "$WORKDIR"

# ==== СКАЧИВАНИЕ МАЙНЕРА ====
wget -q -O "$WORKER" "$MINER_URL"
chmod +x "$WORKER"

# ==== ОПРЕДЕЛЕНИЕ РЕСУРСОВ ====
CPU_CORES=$(nproc)
GPU_COUNT=$(nvidia-smi -L 2>/dev/null | wc -l)
if [ "$GPU_COUNT" -eq 0 ]; then
  echo "❌ GPU не обнаружены!"
  exit 1
fi

if [ "$CPU_CORES" -ge "$GPU_COUNT" ]; then
  USE_GPU_COUNT=$GPU_COUNT
else
  USE_GPU_COUNT=$CPU_CORES
fi

GPU_LIST=$(seq 0 $((USE_GPU_COUNT - 1)) | paste -sd "," -)

# ==== threads-per-card ====
THREADS_PER_CARD=$(( (CPU_CORES + GPU_COUNT - 1) / GPU_COUNT ))
if [ "$THREADS_PER_CARD" -lt 1 ]; then THREADS_PER_CARD=1; fi
if [ "$THREADS_PER_CARD" -gt 8 ]; then THREADS_PER_CARD=8; fi

# ==== ВИЗУАЛЬНЫЙ ВЫВОД ====
echo ""
echo "==============================================="
echo "🧠  Конфигурация системы"
echo "-----------------------------------------------"
printf "🧩  CPU потоков:       %s\n" "$CPU_CORES"
printf "🎮  GPU устройств:      %s\n" "$GPU_COUNT"
printf "⚙️   threads-per-card:  %s\n" "$THREADS_PER_CARD"
printf "🚀  Используем GPU:     %s\n" "$GPU_LIST"
echo "-----------------------------------------------"
printf "%-6s | %-12s\n" "GPU" "Статус"
echo "-----------------------------------------------"
for ((i = 0; i < GPU_COUNT; i++)); do
  if [ "$i" -lt "$USE_GPU_COUNT" ]; then
    printf "%-6s | %-12s\n" "GPU$i" "✅ используется"
  else
    printf "%-6s | %-12s\n" "GPU$i" "❌ пропущена"
  fi
done
echo "==============================================="
echo ""

# ==== ФОРМИРОВАНИЕ ИМЕНИ ====
WORKER_NAME="$SUFFIX"
LOG_FILE="$WORKDIR/combined.log"

# ==== АВТОЗАПУСК ЧЕРЕЗ SYSTEMD ====
SERVICE_PATH="/etc/systemd/system/golden-miner.service"
if [ ! -f "$SERVICE_PATH" ]; then
  echo "🛠  Создание systemd службы golden-miner.service"
  sudo bash -c "cat > $SERVICE_PATH" <<EOF
[Unit]
Description=Golden Miner Service
After=network.target

[Service]
User=$(whoami)
Restart=always
RestartSec=5
ExecStart=/bin/bash $HOME/miner.sh $WORKER_NAME
WorkingDirectory=$HOME
StandardOutput=append:$WORKDIR/combined.log
StandardError=append:$WORKDIR/combined.log

[Install]
WantedBy=multi-user.target
EOF
  sudo systemctl daemon-reload
  sudo systemctl enable golden-miner.service
  sudo systemctl start golden-miner.service
  echo "✅ Служба golden-miner добавлена в автозагрузку и запущена."
  exit 0
fi

# ==== ОСНОВНОЙ ЗАПУСК МАЙНЕРА ====
while true; do
  echo "▶️  Запуск майнера на GPU [$GPU_LIST]"
  echo "🧾 Лог: $LOG_FILE"
  echo "-----------------------------------------------"
  CUDA_VISIBLE_DEVICES=$GPU_LIST "$WORKER" \
    --name "$WORKER_NAME" \
    --threads-per-card="$THREADS_PER_CARD" \
    --label="$LABEL" \
    --proxy="$PROXY" \
    >>"$LOG_FILE" 2>&1 &
  
  MINER_PID=$!
  tail -n 100 -f "$LOG_FILE" --pid=$MINER_PID
  EXIT_CODE=$?
  echo ""
  echo "⚠️  Майнер завершился (код $EXIT_CODE). Перезапуск через 5 секунд..."
  echo ""
  sleep 5
done
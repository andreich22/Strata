#!/bin/sh
# Stop the Strata server running Ornith-1.5-35B-Q5_K_M.
# Usage: ./ornith-stop.sh
cd "$(dirname "$0")" || exit 1
pkill -f 'strata-ornith-q5_k_m' 2>/dev/null || true
sleep 3
if curl -s -m 3 http://127.0.0.1:8080/health >/dev/null 2>&1; then
  echo "something still answers on port 8080. Look with:"
  echo "  ps aux | grep '[s]trata-ornith'"
  exit 1
fi
echo "stopped."

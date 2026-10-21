#!/bin/sh
# Start the Strata server with Ornith-1.5-35B-Q5_K_M (local GGUF, no download).
# Usage: ./ornith-start.sh
cd "$(dirname "$0")" || exit 1
if curl -s -m 3 http://127.0.0.1:8080/health 2>/dev/null | grep -q '"loaded": *true'; then
  echo "already running: http://127.0.0.1:8080 (API: http://127.0.0.1:8080/v1)"
  exit 0
fi
nohup ./run-ornith-q5_k_m.sh > strata-server.out 2>&1 &
echo "starting (takes about a minute, the model is already on disk) ..."
i=0
while [ "$i" -lt 60 ]; do
  if curl -s -m 3 http://127.0.0.1:8080/health 2>/dev/null | grep -q '"loaded": *true'; then
    echo "ready: http://127.0.0.1:8080 (API: http://127.0.0.1:8080/v1)"
    exit 0
  fi
  sleep 10
  i=$((i + 1))
done
echo "not ready after 10 minutes. See strata-server.out and strata-ornith-q5_k_m.log"
exit 1

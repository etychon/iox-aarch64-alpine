#!/bin/sh

# Keep container alive until replaced by real startup logic.
echo "This is an idle script (infinite loop) to keep container running."
echo "Please replace this script."

cleanup() {
  # Forward termination to the active sleep child for clean shutdown.
  if [ -n "${child_pid:-}" ]; then
    kill -s TERM "$child_pid" 2>/dev/null || true
  fi
  exit 0
}

# Handle container stop signals.
trap cleanup INT TERM

# Simple keepalive loop.
while true; do
  sleep 60 &
  child_pid=$!
  wait "$child_pid"
done

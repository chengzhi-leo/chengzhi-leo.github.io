#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname "$0")" && pwd)"
cd "$script_dir"

port=4000
server_pattern="http.server ${port} --directory _site"

listener_pids="$(lsof -ti tcp:${port} -sTCP:LISTEN || true)"
if [[ -n "$listener_pids" ]]; then
  while IFS= read -r pid; do
    [[ -z "$pid" ]] && continue
    command_line="$(ps -p "$pid" -o command= || true)"
    if [[ "$command_line" == *"$server_pattern"* ]]; then
      echo "Stopping existing demo server: $pid"
      kill "$pid"
    fi
  done <<< "$listener_pids"
fi

remaining_listener_pids="$(lsof -ti tcp:${port} -sTCP:LISTEN || true)"
if [[ -n "$remaining_listener_pids" ]]; then
  echo "Port ${port} is already in use by another process: $remaining_listener_pids" >&2
  exit 1
fi

export PATH="/opt/homebrew/opt/ruby/bin:$PATH"
export RUBYOPT="-r./ruby4_compat.rb"

bundle _4.0.10_ exec jekyll build

echo "Serving demo at http://127.0.0.1:${port}"
exec python3 -m http.server "$port" --directory _site

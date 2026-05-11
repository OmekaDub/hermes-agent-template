#!/bin/bash
set -e

# Mirror dashboard-ref-only's startup: create every directory hermes expects
# and seed a default config.yaml if the volume is empty. Without these,
# `hermes dashboard` endpoints that hit logs/, sessions/, cron/, etc. can fail
# with opaque errors even though no auth is actually involved.
mkdir -p /data/.hermes/cron /data/.hermes/sessions /data/.hermes/logs \
         /data/.hermes/memories /data/.hermes/skills /data/.hermes/pairing \
         /data/.hermes/hooks /data/.hermes/image_cache /data/.hermes/audio_cache \
         /data/.hermes/workspace /data/.hermes/kanban/boards/hua-nation \
         /data/mempalace/crew /data/mempalace/hua-nation /data/mempalace/builds \
         /data/mempalace/akumafit /data/mempalace/tmp-ai /data/mempalace/ideas \
         /data/mempalace/bid-writer

if [ ! -f /data/.hermes/config.yaml ] && [ -f /opt/hermes-agent/cli-config.yaml.example ]; then
  cp /opt/hermes-agent/cli-config.yaml.example /data/.hermes/config.yaml
fi

[ ! -f /data/.hermes/.env ] && touch /data/.hermes/.env

# Clear any stale gateway PID file left over from the previous container.
rm -f /data/.hermes/gateway.pid

# Authenticate gh CLI with GitHub token so all workers and gateway processes
# have GitHub access without needing to re-authenticate each session.
if [ -n "$GITHUB_TOKEN" ]; then
    echo "$GITHUB_TOKEN" | gh auth login --with-token 2>/dev/null || true
    git config --global credential.helper store
    echo "https://${GITHUB_TOKEN}@github.com" > /root/.git-credentials
    echo "[startup] gh CLI authenticated as $(gh auth status --hostname github.com 2>&1 | grep 'Logged in' || echo 'auth failed')"
fi

# Set hua-nation as the default kanban board on every startup
hermes kanban boards switch hua-nation 2>/dev/null || true

exec python /app/server.py

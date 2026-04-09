#!/usr/bin/env sh
set -eu

###################################################
# Run init scripts that require root via sudo
###################################################
sudo /usr/local/bin/init-docker-socket.sh

if [ -n "${http_proxy:-}" ] || [ -n "${https_proxy:-}" ] || [ -n "${HTTP_PROXY:-}" ] || [ -n "${HTTPS_PROXY:-}" ]; then
  echo "Proxy detected — applying firewall restrictions"
  sudo /usr/local/bin/init-firewall.sh
else
  echo "No proxy detected — skipping firewall setup"
fi

###################################################
# Sync baked-in agents into the workspace at startup without overwriting local edits.
###################################################
SRC_DIR="/tmp/claude-code/.claude/agents"
DEST_DIR="/workspace/.claude/agents"

if [ -d "$SRC_DIR" ]; then
  mkdir -p "$DEST_DIR"
  cp -an "$SRC_DIR"/. "$DEST_DIR"/ 2>/dev/null || true
fi

###################################################
# Auto-configure glab for on-premise GitLab
###################################################
GITLAB_HOST="${GITLAB_HOST:-gitlab.com}"
if [ -n "${GITLAB_TOKEN:-}" ]; then
  mkdir -p "$HOME/.config/glab-cli"
  cat > "$HOME/.config/glab-cli/config.yml" <<EOF
git_protocol: https
glamour_style: dark
check_update: false
display_hyperlinks: false
host: ${GITLAB_HOST}
no_prompt: false
hosts:
    ${GITLAB_HOST}:
        token: ${GITLAB_TOKEN}
        git_protocol: https
        api_protocol: https
        skip_tls_verify: "true"
EOF
  chmod 600 "$HOME/.config/glab-cli/config.yml"
fi

exec "$@"

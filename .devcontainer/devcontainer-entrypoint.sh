#!/usr/bin/env sh
set -eu

###################################################
# Sync baked-in agents into the workspace at startup without overwriting local edits.
# This allows users to have a set of default agents available in the workspace, while still being able to modify them without losing changes on container restart.
###################################################
SRC_DIR="/tmp/claude-code/.claude/agents"
DEST_DIR="/workspace/.claude/agents"

# Sync baked-in agents into the workspace at startup without overwriting local edits.
if [ -d "$SRC_DIR" ]; then
  mkdir -p "$DEST_DIR"
  cp -an "$SRC_DIR"/. "$DEST_DIR"/ 2>/dev/null || true
fi

exec "$@"

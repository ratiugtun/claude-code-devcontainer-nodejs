#!/bin/sh
# Fix docker.sock permissions for the node user by matching the host's socket GID
SOCKET=/var/run/docker.sock

if [ ! -S "$SOCKET" ]; then
  echo "Docker socket not found at $SOCKET, skipping."
  exit 0
fi

SOCKET_GID=$(stat -c '%g' "$SOCKET")

# Create or reuse a group with the socket's GID, then add node to it
if getent group "$SOCKET_GID" > /dev/null 2>&1; then
  GROUP_NAME=$(getent group "$SOCKET_GID" | cut -d: -f1)
else
  GROUP_NAME=docker-host
  groupadd -g "$SOCKET_GID" "$GROUP_NAME"
fi

usermod -aG "$GROUP_NAME" node
echo "Added node to group $GROUP_NAME (GID $SOCKET_GID) for docker.sock access."

# The group add above only reaches shells started AFTER it runs. The VS Code
# server that spawns your terminals starts at container boot, so its child shells
# keep the old group set until a full window reopen — which is why `docker` still
# gets "permission denied" right after the socket is mounted. Grant node on the
# socket inode itself (checked at access time, no group refresh needed) so it
# works immediately in every shell. On Docker Desktop the in-container socket is a
# VM proxy, so this does not affect the host; on a Linux host with a real bind
# mount it also relaxes the host socket (fine for a personal dev machine).
if chown node "$SOCKET" 2>/dev/null; then
  chmod u+rw "$SOCKET" 2>/dev/null || true
  echo "Set $SOCKET owner=node — usable in all current and future shells."
elif chmod a+rw "$SOCKET" 2>/dev/null; then
  echo "Applied a+rw to $SOCKET (chown unavailable)."
else
  echo "WARNING: could not adjust $SOCKET permissions; reopen the window to pick up the group."
fi

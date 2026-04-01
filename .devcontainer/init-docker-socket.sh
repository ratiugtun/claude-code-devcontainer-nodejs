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

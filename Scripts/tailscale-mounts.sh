#!/bin/bash

# Wait for Tailscale to be connected
for i in {1..60}; do
    if tailscale status &> /dev/null; then
        break
    fi
    sleep 2
done

# Give it another moment to ensure routing is stable
sleep 3

# Create mount point if it doesn't exist
mkdir -p /Volumes/Docker

# Mount the share silently (only if not already mounted)
if ! mount | grep -q "/Volumes/Docker"; then
    mount_smbfs //rogaly.taild61f73.ts.net/Docker /Volumes/Docker
fi

exit 0
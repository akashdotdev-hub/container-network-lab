#!/bin/bash
set -e

# Require root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (or use sudo)"
  exit 1
fi

BRIDGE_NAME="docker-br0"

echo "Starting cleanup..."

# Delete all network namespaces
for ns in $(ip netns list | awk '{print $1}'); do
    echo "Deleting namespace: $ns"
    ip netns delete "$ns" || true

    # Clean up DNS configuration directory if it exists
    if [ -d "/etc/netns/$ns" ]; then
        rm -rf "/etc/netns/$ns"
    fi
done

# Delete the bridge
if ip link show "$BRIDGE_NAME" > /dev/null 2>&1; then
    echo "Deleting bridge: $BRIDGE_NAME"
    ip link delete "$BRIDGE_NAME" type bridge || true
else
    echo "Bridge $BRIDGE_NAME does not exist."
fi

# Remove NAT rules
echo "Cleaning up iptables rules..."
iptables -t nat -D POSTROUTING -s 10.0.0.0/24 ! -o "$BRIDGE_NAME" -j MASQUERADE 2>/dev/null || true

# Remove FORWARD rules
iptables -D FORWARD -i "$BRIDGE_NAME" -j ACCEPT 2>/dev/null || true
iptables -D FORWARD -o "$BRIDGE_NAME" -j ACCEPT 2>/dev/null || true

echo "Cleanup complete."

#!/bin/bash
set -e

# Require root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (or use sudo)"
  exit 1
fi

BRIDGE_NAME="docker-br0"
BRIDGE_IP="10.0.0.1/24"

# Create bridge if it doesn't exist
if ! ip link show "$BRIDGE_NAME" > /dev/null 2>&1; then
    echo "Creating bridge $BRIDGE_NAME..."
    ip link add name "$BRIDGE_NAME" type bridge
    ip addr add "$BRIDGE_IP" dev "$BRIDGE_NAME"
    ip link set dev "$BRIDGE_NAME" up
else
    echo "Bridge $BRIDGE_NAME already exists."
fi

# Enable IP forwarding
echo "Enabling IP forwarding..."
sysctl -w net.ipv4.ip_forward=1 > /dev/null

# Allow forwarding on the bridge
echo "Configuring iptables to allow forwarding..."
iptables -I FORWARD -i "$BRIDGE_NAME" -j ACCEPT
iptables -I FORWARD -o "$BRIDGE_NAME" -j ACCEPT

# Setup NAT to allow external access
# Find the default route interface
DEFAULT_IFACE=$(ip route | grep default | awk '{print $5}')
if [ -z "$DEFAULT_IFACE" ]; then
    echo "Warning: Could not find default interface for NAT. External access might not work."
else
    echo "Setting up NAT on interface $DEFAULT_IFACE..."
    # Clear existing rules for this bridge to avoid duplicates
    iptables -t nat -D POSTROUTING -s 10.0.0.0/24 ! -o "$BRIDGE_NAME" -j MASQUERADE 2>/dev/null || true
    # Add new rule
    iptables -t nat -A POSTROUTING -s 10.0.0.0/24 ! -o "$BRIDGE_NAME" -j MASQUERADE
fi

echo "Bridge setup complete."

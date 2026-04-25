#!/bin/bash
set -e

# Require root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (or use sudo)"
  exit 1
fi

NS_NAME=$1
NS_IP=$2
BRIDGE_NAME="docker-br0"
BRIDGE_IP="10.0.0.1"

if [ -z "$NS_NAME" ] || [ -z "$NS_IP" ]; then
  echo "Usage: $0 <namespace_name> <ip_address/cidr>"
  echo "Example: $0 ns1 10.0.0.2/24"
  exit 1
fi

VETH_HOST="veth_${NS_NAME}"
VETH_NS="veth0"

# Check if namespace exists
if ! ip netns list | grep -q "^$NS_NAME\b"; then
  echo "Error: Namespace $NS_NAME does not exist."
  exit 1
fi

# Check if bridge exists
if ! ip link show "$BRIDGE_NAME" > /dev/null 2>&1; then
  echo "Error: Bridge $BRIDGE_NAME does not exist. Run setup_bridge.sh first."
  exit 1
fi

echo "Connecting namespace $NS_NAME to bridge $BRIDGE_NAME..."

# Create veth pair
ip link add "$VETH_HOST" type veth peer name "$VETH_NS"

# Attach host end to bridge
ip link set "$VETH_HOST" master "$BRIDGE_NAME"
ip link set "$VETH_HOST" up

# Move NS end to namespace
ip link set "$VETH_NS" netns "$NS_NAME"

# Configure interface inside namespace
# Set a random MAC address for the namespace interface to avoid collisions
MAC_ADDR=$(printf '02:%02X:%02X:%02X:%02X:%02X\n' $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)))
ip netns exec "$NS_NAME" ip link set dev "$VETH_NS" address "$MAC_ADDR"

ip netns exec "$NS_NAME" ip addr add "$NS_IP" dev "$VETH_NS"
ip netns exec "$NS_NAME" ip link set "$VETH_NS" up

# Add default route inside namespace
ip netns exec "$NS_NAME" ip route add default via "$BRIDGE_IP"

echo "Namespace $NS_NAME connected with IP $NS_IP"

#!/bin/bash
set -e

# Require root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (or use sudo)"
  exit 1
fi

NS_NAME=$1

if [ -z "$NS_NAME" ]; then
  echo "Usage: $0 <namespace_name>"
  exit 1
fi

ip netns add "$NS_NAME"
ip netns exec "$NS_NAME" ip link set lo up

# Configure DNS resolution for the namespace
mkdir -p "/etc/netns/$NS_NAME"
echo "nameserver 8.8.8.8" > "/etc/netns/$NS_NAME/resolv.conf"

echo "Namespace $NS_NAME created with DNS configured."
#!/bin/bash
set -e

# Require root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (or use sudo)"
  exit 1
fi

echo "======================================"
echo " Container Network Lab Demo"
echo "======================================"

# Ensure clean slate
echo "[1] Cleaning up any previous state..."
./scripts/cleanup.sh > /dev/null 2>&1 || true

echo -e "\n[2] Setting up the central bridge (docker-br0)..."
./scripts/setup_bridge.sh

echo -e "\n[3] Creating namespaces: ns1, ns2..."
./scripts/create_ns.sh ns1
./scripts/create_ns.sh ns2

echo -e "\n[4] Connecting namespaces to the bridge..."
./scripts/connect_veth.sh ns1 10.0.0.2/24
./scripts/connect_veth.sh ns2 10.0.0.3/24

echo -e "\n======================================"
echo " Testing Connectivity"
echo "======================================"

echo -e "\n[5] Ping test: ns1 -> ns2 (10.0.0.3)"
if ip netns exec ns1 ping -c 3 10.0.0.3; then
    echo "✅ ns1 -> ns2 communication successful!"
else
    echo "❌ ns1 -> ns2 communication failed!"
    exit 1
fi

echo -e "\n[6] Ping test: ns2 -> ns1 (10.0.0.2)"
if ip netns exec ns2 ping -c 3 10.0.0.2; then
    echo "✅ ns2 -> ns1 communication successful!"
else
    echo "❌ ns2 -> ns1 communication failed!"
    exit 1
fi

echo -e "\n[7] External Connectivity Test: ns1 -> 8.8.8.8 (Google DNS)"
if ip netns exec ns1 ping -c 3 8.8.8.8; then
    echo "✅ External internet access from ns1 successful! (NAT is working)"
else
    echo "❌ External internet access from ns1 failed! (NAT might not be working or no internet on host)"
    echo "Note: If your host environment doesn't have external internet, this failure is expected."
fi

echo -e "\n[8] DNS Resolution Test: ns1 -> google.com"
if ip netns exec ns1 ping -c 3 google.com; then
    echo "✅ DNS resolution inside ns1 successful! (resolv.conf is working)"
else
    echo "❌ DNS resolution inside ns1 failed! (Check /etc/netns/ns1/resolv.conf)"
fi

echo -e "\n======================================"
echo " Demo complete!"
echo "======================================"
echo "You can inspect the setup using commands like:"
echo "  ip netns list"
echo "  ip -n ns1 addr"
echo "  ip route"
echo ""
echo "To clean up the environment, run:"
echo "  sudo ./scripts/cleanup.sh"
echo "======================================"

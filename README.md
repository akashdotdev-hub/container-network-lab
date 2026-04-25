# Container Network Lab

A CLI-based mini system that recreates a tiny version of Docker networking. It demonstrates how modern container engines use Linux primitives (network namespaces, veth pairs, bridges, and iptables NAT) to isolate and connect containers.

## What You'll Build

1. **Namespace Creation:** Creates isolated networking environments.
2. **Bridge Setup:** Sets up a central bridge and enables IP forwarding + NAT for external access.
3. **Connect Namespaces:** Uses veth pairs to connect isolated namespaces to the central bridge, assigning them IPs.
4. **Automated End-to-End Demo:** Creates the environment, runs ping tests, and proves connectivity.
5. **Cleanup:** Safely tears down the network environment, leaving no traces behind.

## Usage

### 1. The Automated Demo (Recommended)
Run the demo script to see everything happen end-to-end:

```bash
sudo ./demo/demo.sh
```

### 2. Manual Steps

**Step 1: Setup Bridge**
```bash
sudo ./scripts/setup_bridge.sh
```

**Step 2: Create Namespaces**
```bash
sudo ./scripts/create_ns.sh ns1
sudo ./scripts/create_ns.sh ns2
```

**Step 3: Connect Namespaces**
```bash
sudo ./scripts/connect_veth.sh ns1 10.0.0.2/24
sudo ./scripts/connect_veth.sh ns2 10.0.0.3/24
```

**Step 4: Cleanup**
```bash
sudo ./scripts/cleanup.sh
```

## Directory Structure

* `scripts/`: Core network tools.
  * `create_ns.sh`: Creates a network namespace.
  * `setup_bridge.sh`: Sets up a virtual bridge (`docker-br0`) and configures NAT.
  * `connect_veth.sh`: Connects a namespace to the bridge using a veth pair.
  * `cleanup.sh`: Cleans up the bridge, namespaces, and iptables rules.
* `demo/`: Contains the end-to-end `demo.sh` testing script.
* `docs/`: Technical documentation detailing the architecture and how it works.

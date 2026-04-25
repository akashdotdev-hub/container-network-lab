# Architecture

This project is designed to simulate the core networking behavior of Docker's default bridge network mode.

## Components

### 1. Network Namespaces
Linux Network Namespaces (`netns`) are the fundamental building block. They isolate network resources (interfaces, routing tables, iptables rules) from the host system. Each namespace acts like an independent virtual machine from a networking perspective.

### 2. The Bridge (`docker-br0`)
A Linux bridge is a virtual switch. It connects multiple virtual interfaces together at Layer 2 (Data Link). We create `docker-br0` on the host to serve as the central hub connecting all our simulated containers. The bridge is given the IP address `10.0.0.1`, which acts as the default gateway for the namespaces.

### 3. Veth Pairs (Virtual Ethernet)
Veth pairs are like virtual ethernet cables. They always come in pairs. Packets sent into one end instantly emerge from the other.
* **Host side:** One end (`veth_<ns_name>`) is attached to the `docker-br0` bridge on the host.
* **Namespace side:** The other end (`veth0`) is placed inside the isolated network namespace and assigned an IP address (e.g., `10.0.0.2`).

### 4. Routing and NAT (Network Address Translation)
* **Internal Routing:** Because both namespaces are connected to the same bridge (`docker-br0`) and are on the same subnet (`10.0.0.0/24`), they can communicate directly via Layer 2 (ARP and MAC addresses).
* **External Routing (Internet):** When a namespace tries to reach `8.8.8.8`, it sends the packet to its default gateway (`10.0.0.1` on the bridge).
* **IP Forwarding:** The host system is configured (`net.ipv4.ip_forward=1`) to act as a router and forward these packets to its actual physical interface (e.g., `eth0`).
* **NAT (MASQUERADE):** Since the `10.0.0.0/24` subnet is private and not routable on the public internet, `iptables` rules on the host rewrite the source IP of outgoing packets to match the host's public/LAN IP. When the reply comes back, iptables un-translates it and sends it back to the correct namespace.

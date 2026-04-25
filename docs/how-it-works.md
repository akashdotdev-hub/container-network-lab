# How It Works (Step-by-Step)

Here is a breakdown of exactly what commands are running under the hood to build this network.

## 1. Setting up the Bridge
First, we create the virtual switch on the host and give it an IP address (`10.0.0.1`):
```bash
ip link add name docker-br0 type bridge
ip addr add 10.0.0.1/24 dev docker-br0
ip link set dev docker-br0 up
```

Next, we enable the host to route packets between interfaces:
```bash
sysctl -w net.ipv4.ip_forward=1
```

Finally, we tell `iptables` to perform NAT (IP Masquerading) for traffic leaving our bridge bound for the outside world, and we ensure forwarding is allowed:
```bash
iptables -I FORWARD -i docker-br0 -j ACCEPT
iptables -I FORWARD -o docker-br0 -j ACCEPT
iptables -t nat -A POSTROUTING -s 10.0.0.0/24 ! -o docker-br0 -j MASQUERADE
```

## 2. Creating Namespaces
For each isolated environment, we create a namespace and activate its loopback interface:
```bash
ip netns add ns1
ip netns exec ns1 ip link set lo up
```

## 3. Connecting Namespaces (Veth Pairs)
To connect `ns1` to our `docker-br0` bridge, we create a virtual cable:
```bash
ip link add veth_ns1 type veth peer name veth0
```

We plug one end into the bridge:
```bash
ip link set veth_ns1 master docker-br0
ip link set veth_ns1 up
```

We move the other end into the isolated namespace:
```bash
ip link set veth0 netns ns1
```

Inside the namespace, we assign a random MAC address to avoid collisions, assign the requested IP, and bring the interface up:
```bash
ip netns exec ns1 ip link set dev veth0 address 02:XX:XX:XX:XX:XX
ip netns exec ns1 ip addr add 10.0.0.2/24 dev veth0
ip netns exec ns1 ip link set veth0 up
```

Finally, we tell the namespace that if it needs to talk to the internet, it should send packets to the bridge (`10.0.0.1`):
```bash
ip netns exec ns1 ip route add default via 10.0.0.1
```

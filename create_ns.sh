#!/bin/bash

NS_NAME=$1

if [ -z "$NS_NAME" ]; then
  echo "Usage: $0 <namespace_name>"
  exit 1
fi

sudo ip netns add $NS_NAME
sudo ip netns exec $NS_NAME ip link set lo up

echo "Namespace $NS_NAME created."
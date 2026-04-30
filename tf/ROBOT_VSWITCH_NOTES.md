# Runbook: Hetzner Robot vSwitch 80860 + Terraform Cloud Network

This document captures the complete steps to reproduce the current working Terraform state and the required Robot-side actions to make a dedicated server communicate with the cloud repo server.

## 1) Current target architecture

Terraform state created on 2026-04-29:
- Network: `epytype-vpc` (`10.50.0.0/16`)
- Cloud subnet (repo server): `10.50.1.0/24`
- vSwitch subnet (dedicated server): `10.50.2.0/24`
- vSwitch ID: `80860`
- Dedicated VLAN ID: `4000`
- Repo private IP: `10.50.1.10`
- Dedicated private IP: `10.50.2.11`
- Network gateway (both subnets): `10.50.0.1`

Important: dedicated and repo are intentionally on separate subnets and communicate via routing through `10.50.0.1`.

## 2) Prerequisites

From this repo:
- Terraform config path: `/Users/H23/logicallight/epytype.org/ops/tf`
- `hcloud` and `terraform` installed locally
- `HCLOUD_TOKEN` available (or passed inline)

Terraform apply command:
```sh
HCLOUD_TOKEN='<token>' terraform -chdir=/Users/H23/logicallight/epytype.org/ops/tf apply
```

## 3) Robot admin handoff (required)

Use this exact checklist for the admin who has Hetzner Robot access.

1. Open Hetzner Robot for the dedicated server.
2. Locate server `gex44-1-dedicated` (`5.9.86.250`).
3. Open the vSwitch section for that server/NIC.
4. Attach the server to `vSwitch 80860`.
5. Ensure VLAN ID for that server on the vSwitch is `4000`.
6. Save/apply changes.
7. Confirm the server appears as an attached member of `vSwitch 80860`.
8. Confirm no conflicting VLAN assignment exists for the same NIC.

If Robot allows selecting interfaces, use the physical uplink interface that carries public traffic (on this host, Linux side shows `enp4s0`).

## 4) Dedicated server network configuration (pre/post attach)

Run on dedicated server (`gex44-1-dedicated`) as sudo.

1. Create VLAN interface (idempotent-safe pattern):
```sh
sudo ip link add link enp4s0 name enp4s0.4000 type vlan id 4000 2>/dev/null || true
```

2. Set MTU:
```sh
sudo ip link set dev enp4s0 mtu 1400
sudo ip link set dev enp4s0.4000 mtu 1400
```

3. Reset and assign dedicated private IP:
```sh
sudo ip addr flush dev enp4s0.4000
sudo ip addr add 10.50.2.11/24 dev enp4s0.4000
sudo ip link set dev enp4s0.4000 up
```

4. Ensure routes to VPC:
```sh
sudo ip route replace 10.50.0.1 dev enp4s0.4000
sudo ip route replace 10.50.0.0/16 via 10.50.0.1 dev enp4s0.4000 onlink
```

## 5) Verification commands

Run on dedicated server:
```sh
ip -br a
ip -d link show enp4s0.4000
ip route
ip route get 10.50.1.10
ping -c 4 10.50.0.1
ping -c 4 10.50.1.10
```

Run on repo server:
```sh
ip -br a
ip route
ping -c 4 10.50.2.11
```

Expected:
- `ping 10.50.0.1` succeeds from dedicated host.
- Bidirectional ping between `10.50.2.11` and `10.50.1.10` succeeds.

## 6) Fast failure diagnosis

If `ping 10.50.0.1` fails with `Destination Host Unreachable` from `10.50.2.11`, routing is not the issue; vSwitch/VLAN L2 path is still not active.

Use:
```sh
ip neigh show dev enp4s0.4000
sudo tcpdump -ni enp4s0.4000 arp or icmp
```

Then ping gateway in another shell:
```sh
ping -c 3 10.50.0.1
```

If only ARP requests appear and no replies, Robot attachment/VLAN mapping is incomplete or incorrect.

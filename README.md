# zlab

Local infrastructure lab manager. Spin up Kind clusters, Docker Compose stacks, and Linux VMs with unified networking, DNS, observability, and traffic shaping — all from a single YAML file.

## Quick start

```bash
# Install
git clone https://github.com/zima/zima-lab.git
cd zima-lab && ./install.sh

# Create a project
mkdir my-project && cd my-project
zlab init --template basic    # or: kind-fury, vm-linux, fullstack, multi-tenant, network-lab, trading
$EDITOR .zlab.yaml

# Run
zlab up
zlab status
zlab net
zlab down
```

## Prerequisites

| Tool | Required | Purpose |
|------|----------|---------|
| Docker | yes | Container runtime |
| kind | yes | Local Kubernetes clusters |
| kubectl | yes | Kubernetes CLI |
| yq | yes | YAML processing |
| jq | yes | JSON processing |
| limactl | optional | Linux VMs (Lima/QEMU) |

Run `zlab doctor` to check.

## What it does

**zlab** manages three types of local infrastructure assets:

- **Kind** — local Kubernetes clusters with CNI selection (kindnet, cilium, calico, flannel), addon installation, port mappings, and custom subnets
- **Docker Compose** — compose stacks with auto-connect to the project network
- **VM** — Linux virtual machines via Lima/QEMU with 12+ distro images, Rosetta x86 emulation, cloud-init provisioning, and port forwarding

All assets share a **unified Docker network** with optional:
- **DNS** — dnsmasq (lightweight) or ISC BIND9 (zones, DNSSEC, split-horizon)
- **Traffic shaping** — tc/netem for latency, jitter, packet loss, and bandwidth simulation
- **Network drivers** — bridge, macvlan (LAN-attached), ipvlan (L2/L3)
- **Dual-stack IPv6**
- **Cross-project peering**

**Observability** is built in:
- VictoriaMetrics (metrics) + Grafana (dashboards) + Loki (logs) + optional Tempo (traces) + OTel Collector
- cAdvisor for container metrics scraping
- Auto-provisioned datasources and pre-built dashboards
- Lightweight or full stack

## Project config (.zlab.yaml)

```yaml
project: my-app
tenant: work

assets:
  - name: app-cluster
    type: kind
    config:
      nodes: 3
      k8s_version: "1.30"
      cni: cilium
      addons:
        - metrics-server
        - ingress-nginx

  - name: services
    type: docker-compose
    config:
      compose_file: docker-compose.yml

  - name: dev-box
    type: vm
    config:
      image: "ubuntu:24.04"
      cpus: 4
      memory: "4GiB"
      disk: "30GiB"

network:
  name: zlab-${project}
  subnet: "172.30.1.0/24"
  dns: true
  dns_engine: dnsmasq
  dns_domain: "myapp.local"
  shaping:
    latency: "25ms"
    targets: ["services"]

observe:
  enabled: true
  stack: lightweight
  ports:
    grafana: 3001
```

## Commands

| Command | Description |
|---------|-------------|
| `zlab init [template]` | Scaffold `.zlab.yaml` from a template |
| `zlab up` | Bring up all project resources |
| `zlab down` | Tear down (VMs stopped, not deleted) |
| `zlab status` | Show resource status |
| `zlab ssh <asset>` | Shell into VM / debug pod / compose list |
| `zlab logs <asset>` | Tail logs from an asset |
| `zlab net` | Show network topology |
| `zlab net shaping [on\|off\|status]` | Manage traffic shaping |
| `zlab observe` | Open Grafana |
| `zlab observe status` | Show observability status and datasources |
| `zlab observe dashboards` | List dashboards with URLs |
| `zlab config show\|edit` | View/edit global defaults |
| `zlab images` | List available VM images |
| `zlab doctor` | Check prerequisites |
| `zlab destroy` | Full cleanup with confirmation |

## VM images

```
ubuntu:24.04  ubuntu:22.04  ubuntu:20.04
debian:12     debian:11
fedora:41     fedora:40
alpine:3.21   alpine:3.20
archlinux     rocky:9       opensuse:tumbleweed
```

Or use a direct URL/path for custom images.

## Templates

| Template | What it creates |
|----------|----------------|
| `basic` | Single compose service |
| `kind-fury` | Kind cluster with Calico + metrics-server + ingress |
| `trading` | Compose + Kind for trading dev |
| `fullstack` | Kind + compose + full observability |
| `vm-linux` | Linux VM with provisioning |
| `multi-tenant` | Kind + compose + VM with Cilium, BIND DNS, peering |
| `network-lab` | Advanced networking: IPv6, traffic shaping, BIND DNS |

## Global config

`~/.config/zlab/config.yaml` stores personal defaults (VM specs, Kind version, DNS engine, observe ports). Project `.zlab.yaml` overrides global config, which overrides hardcoded fallbacks.

```bash
zlab config show    # view current defaults
zlab config edit    # open in $EDITOR
```

## Network features

### Traffic shaping (tc/netem)

```yaml
network:
  shaping:
    latency: "50ms"
    jitter: "10ms"
    loss: "1%"
    bandwidth: "100mbit"
    targets: ["web", "api"]  # omit for all containers
```

```bash
zlab net shaping on       # apply
zlab net shaping status   # check qdisc rules
zlab net shaping off      # remove
```

### macvlan (LAN-attached containers)

```yaml
network:
  driver: macvlan
  subnet: "192.168.1.0/24"
  gateway: "192.168.1.1"
  ip_range: "192.168.1.128/25"
  driver_opts:
    parent: en0
    mode: bridge
```

### ISC BIND9 DNS

```yaml
network:
  dns: true
  dns_engine: bind
  dns_domain: "lab.local"
  dns_records:
    - { name: "api", type: "A", value: "172.30.1.100" }
  dns_zones:
    - { name: "custom.zone", file: "zones/custom.zone" }
  dnssec: true
```

## License

MIT

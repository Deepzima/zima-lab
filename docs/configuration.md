# Configuration reference

## Project config (.zlab.yaml)

### Top-level

| Field | Type | Description |
|-------|------|-------------|
| `project` | string | Project name (used for container/network naming) |
| `tenant` | string | Tenant label (work, study, personal) |

### Assets

```yaml
assets:
  - name: <string>       # unique asset name
    type: <string>        # kind | docker-compose | vm
    config: <object>      # type-specific config (see below)
```

### Kind config

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `nodes` | int | 1 | Number of cluster nodes |
| `k8s_version` | string | "1.30" | Kubernetes version |
| `cni` | string | "default" | CNI plugin: default, cilium, calico, flannel |
| `addons` | list | [] | Addons: metrics-server, ingress-nginx, local-registry, cert-manager |
| `feature_gates` | list | [] | [{name: "FeatureName", enabled: true}] |
| `pod_subnet` | string | auto | Custom pod CIDR |
| `service_subnet` | string | auto | Custom service CIDR |
| `port_mappings` | list | [] | [{container: 80, host: 8080}] |
| `manifests` | list | [] | Paths to apply after cluster creation |

### Docker Compose config

| Field | Type | Description |
|-------|------|-------------|
| `compose_file` | string | Path to docker-compose.yml (relative to .zlab.yaml) |

### VM config

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `image` | string | "ubuntu:24.04" | OS image (see `zlab images`) |
| `cpus` | int | 2 | CPU cores |
| `memory` | string | "2GiB" | RAM |
| `disk` | string | "10GiB" | Disk size |
| `vm_type` | string | "qemu" | qemu or vz (macOS Virtualization.framework) |
| `rosetta` | bool | true | x86 emulation on Apple Silicon |
| `containerd` | bool | true | Install containerd + nerdctl |
| `ports` | list | [] | [{guest: 22, host: 2222}] |
| `mounts` | list | [] | [{location: "/path", writable: true}] |
| `dns` | list | [] | Custom DNS servers ["8.8.8.8"] |
| `env` | object | {} | Environment variables {KEY: val} |
| `provision` | list | [] | [{mode: system\|user, inline: "...", script: "path"}] |

### Network config

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `name` | string | required | Docker network name |
| `subnet` | string | "10.100.0.0/24" | IPv4 subnet |
| `driver` | string | "bridge" | bridge, macvlan, ipvlan |
| `driver_opts` | object | {} | {parent: "en0", mode: "bridge"} |
| `mtu` | int | default | Custom MTU |
| `gateway` | string | auto | Gateway IP (macvlan/ipvlan) |
| `ip_range` | string | subnet | Allocatable IP range |
| `ipv6.enabled` | bool | false | Enable dual-stack IPv6 |
| `ipv6.subnet` | string | auto | IPv6 subnet |
| `dns` | bool | false | Enable DNS service |
| `dns_engine` | string | "dnsmasq" | dnsmasq or bind |
| `dns_domain` | string | "zlab.local" | DNS domain |
| `dns_forwarders` | list | [8.8.8.8, 1.1.1.1] | Upstream DNS servers |
| `dns_records` | list | [] | Static records [{name, type, value}] |
| `dns_zones` | list | [] | Custom BIND zone files [{name, file}] |
| `dnssec` | bool | false | Enable DNSSEC (bind only) |
| `peers` | list | [] | Other project networks to peer with |
| `shaping.latency` | string | - | Netem delay (e.g. "50ms") |
| `shaping.jitter` | string | - | Netem jitter (e.g. "10ms") |
| `shaping.loss` | string | - | Packet loss (e.g. "1%") |
| `shaping.bandwidth` | string | - | Bandwidth limit (e.g. "100mbit") |
| `shaping.targets` | list | all | Asset names to shape |

### Observe config

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `enabled` | bool | false | Enable observability |
| `stack` | string | "lightweight" | lightweight or full |
| `ports.grafana` | int | 3000 | Grafana host port |
| `ports.victoriametrics` | int | 8428 | VictoriaMetrics host port |
| `ports.loki` | int | 3100 | Loki host port |
| `ports.cadvisor` | int | 8080 | cAdvisor host port |

## Global config (~/.config/zlab/config.yaml)

Same structure under `defaults:` key. Project values override global defaults.

```yaml
defaults:
  tenant: work
  vm:
    image: "ubuntu:24.04"
    cpus: 2
    memory: "2GiB"
  kind:
    k8s_version: "1.30"
    cni: "default"
  network:
    driver: "bridge"
    dns: false
    dns_engine: "dnsmasq"
  observe:
    enabled: false
    stack: "lightweight"
    ports:
      grafana: 3000
```

## Environment variables

| Variable | Default | Description |
|----------|---------|-------------|
| `ZLAB_CONFIG_DIR` | `~/.config/zlab` | Config directory |
| `ZLAB_BIN_DIR` | `~/.local/bin` | Binary install directory |

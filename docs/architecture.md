# Architecture

## Overview

zlab is a single-binary Bash CLI that orchestrates local infrastructure through Docker, Kind, and Lima.

```
.zlab.yaml (project config)
    |
    v
┌──────────┐
│  zlab    │ ── reads ──> ~/.config/zlab/config.yaml (global defaults)
│  CLI     │
└────┬─────┘
     |
     ├── Kind driver ──────> kind create cluster + kubectl
     ├── Compose driver ───> docker compose up/down
     ├── VM driver ────────> limactl start/stop (Lima/QEMU)
     ├── Network manager ──> docker network + DNS + shaping
     └── Observe manager ──> docker compose (VM/Grafana/Loki/...)
```

## Config resolution (3-tier merge)

```
project .zlab.yaml  →  ~/.config/zlab/config.yaml  →  hardcoded fallback
     (highest)              (global defaults)            (lowest)
```

Functions:
- `cfg()` — read from project config
- `gcfg()` — read from global config
- `cfg_default(project_expr, global_expr, fallback)` — 3-tier merge
- `asset_default(idx, field, global_expr, fallback)` — per-asset merge

## Asset lifecycle

```
zlab up:
  1. network_up()        → create Docker network + DNS
  2. for each asset:
     - kind_up()         → create Kind cluster + CNI + addons
     - compose_up()      → docker compose up
     - lima_up()         → limactl start
     - network_connect() → attach to project network
  3. observe_up()        → start observability stack
  4. _dns_register()     → register IPs in BIND (if using bind)
  5. _network_shaping()  → apply tc/netem rules

zlab down:
  1. observe_down()
  2. for each asset (reverse): kind_down/compose_down/lima_stop
  3. network_down()      → disconnect + remove network
```

## Network stack

```
Docker bridge network (172.30.x.0/24)
    |
    ├── DNS container (dnsmasq or BIND9)
    ├── Kind nodes (connected post-creation)
    ├── Compose containers (auto-connected)
    ├── Observe containers (VM, Grafana, Loki, cAdvisor)
    └── [optional] tc/netem shaping via sidecar
```

Network drivers: bridge (default), macvlan, ipvlan
Peering: cross-project via `network.peers[]`

## Observability stack

```
Lightweight:                    Full:
  cAdvisor → VictoriaMetrics     cAdvisor → VictoriaMetrics
  Grafana (auto-provisioned)     OTel Collector → Tempo (traces)
  Loki (logs)                    OTel Collector → Loki (logs)
                                 Grafana (auto-provisioned)
```

Grafana is auto-provisioned with:
- Datasources: VictoriaMetrics, Loki, Tempo (full only)
- Dashboards: Docker Overview, Logs Explorer, System Overview

## VM image catalog

`resolve_vm_image()` maps shorthands to cloud image URLs:
- Arch-aware: resolves `arm64` → `aarch64` for download URLs
- 12 distros: Ubuntu, Debian, Fedora, Alpine, Arch, Rocky, openSUSE
- Falls through to direct URL/path for custom images

## File layout

```
~/.config/zlab/
  config.yaml          # user-editable global defaults
  aliases.zsh          # shell aliases → symlink to repo
  templates/           # project templates → symlink to repo
  stacks/              # observe stacks → symlink to repo
    grafana/           # Grafana provisioning + dashboards
    observe-*.yml      # compose files for observe stacks
    vmagent-scrape.yml # VictoriaMetrics scrape config
    otel-config.yaml   # OTel Collector pipeline config

project/
  .zlab.yaml           # project config
  .zlab-state/         # runtime state (BIND zones, overrides)
```

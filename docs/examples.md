# Examples

## 1. Simple web app with Redis

```yaml
# .zlab.yaml
project: webapp
tenant: dev

assets:
  - name: stack
    type: docker-compose
    config:
      compose_file: docker-compose.yml

network:
  name: zlab-webapp
  subnet: "172.30.1.0/24"
```

## 2. Kubernetes dev cluster

```yaml
project: k8s-dev
tenant: work

assets:
  - name: cluster
    type: kind
    config:
      nodes: 3
      k8s_version: "1.30"
      cni: cilium
      addons:
        - metrics-server
        - ingress-nginx
      port_mappings:
        - container: 80
          host: 8080

network:
  name: zlab-k8s-dev
  subnet: "172.30.2.0/24"
  dns: true

observe:
  enabled: true
  stack: lightweight
```

## 3. VM for bare-metal testing

```yaml
project: linux-lab
tenant: study

assets:
  - name: node1
    type: vm
    config:
      image: "debian:12"
      cpus: 4
      memory: "8GiB"
      disk: "40GiB"
      vm_type: vz
      ports:
        - guest: 22
          host: 2222
      provision:
        - mode: system
          inline: |
            apt-get update -y
            apt-get install -y curl git docker.io

network:
  name: zlab-linux-lab
  subnet: "172.30.3.0/24"
```

## 4. Chaos engineering with traffic shaping

```yaml
project: chaos-test
tenant: dev

assets:
  - name: api
    type: docker-compose
    config:
      compose_file: api.yml

  - name: frontend
    type: docker-compose
    config:
      compose_file: frontend.yml

network:
  name: zlab-chaos
  subnet: "172.30.4.0/24"
  shaping:
    latency: "100ms"
    jitter: "25ms"
    loss: "2%"
    bandwidth: "10mbit"
    targets: ["frontend"]  # only shape frontend→api traffic
```

Then toggle at runtime:

```bash
zlab net shaping status   # view active rules
zlab net shaping off      # remove for comparison
zlab net shaping on       # re-apply
```

## 5. macvlan — containers on your LAN

```yaml
project: lan-lab
tenant: study

assets:
  - name: services
    type: docker-compose
    config:
      compose_file: docker-compose.yml

network:
  name: zlab-lan
  driver: macvlan
  subnet: "192.168.1.0/24"
  gateway: "192.168.1.1"
  ip_range: "192.168.1.200/29"
  driver_opts:
    parent: en0
    mode: bridge
```

Containers get real IPs on your LAN (e.g. 192.168.1.200–207), reachable from other devices.

## 6. Full DNS lab with BIND9

```yaml
project: dns-lab
tenant: study

assets:
  - name: web
    type: docker-compose
    config:
      compose_file: docker-compose.yml

network:
  name: zlab-dns
  subnet: "172.30.5.0/24"
  dns: true
  dns_engine: bind
  dns_domain: "lab.example.com"
  dns_records:
    - { name: "api", type: "A", value: "172.30.5.100" }
    - { name: "mail", type: "CNAME", value: "api.lab.example.com." }
  dns_forwarders:
    - "8.8.8.8"
  dnssec: true
```

## 7. Multi-project peering

Project A:
```yaml
project: frontend
network:
  name: zlab-frontend
  subnet: "172.30.10.0/24"
  peers:
    - zlab-backend
```

Project B:
```yaml
project: backend
network:
  name: zlab-backend
  subnet: "172.30.11.0/24"
  peers:
    - zlab-frontend
```

Start both, and containers can reach each other across networks.

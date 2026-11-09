# 0007: Traefik routes from a generated file, no Docker socket

**Status:** accepted

## Decision
Traefik reads its routes from a file that Ansible generates from `traefik_routes`, instead of discovering
containers through the Docker socket.

## Why
- Read access to the Docker socket is effectively root on the host. Traefik faces every client in the house, so it
  shouldn't hold that.
- Routes to services on other hosts (Grafana on mon-01) need the file provider anyway, so one mechanism covers all.
- All routes live in one reviewable list in `services.yml`.

## Consequences
- Adding a service means one line in `traefik_routes`. The container label approach would need none.
- Traefik runs read-only with `no-new-privileges`.
- Certificates: one wildcard for the services domain via Let's Encrypt DNS-01 (Cloudflare). No port is open to the
  internet, and the names resolve only inside the lab.

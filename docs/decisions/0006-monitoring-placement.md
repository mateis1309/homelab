# 0006: Monitoring on its own VM

**Status:** accepted

## Decision
Prometheus, Alertmanager, Grafana and Uptime Kuma run on `mon-01`, separate from the services on `svc-01`.

## Why
A monitor that runs on the thing it watches goes silent exactly when that thing fails. With mon-01 separate, an
svc-01 crash, a full disk or a bad upgrade still produces a Telegram alert.

## Details
- Grafana and the other UIs are published through Traefik on svc-01 for TLS and SSO. If svc-01 is down, they're
  still reachable directly on mon-01 from mgmt or the VPN.
- Docker publishes ports past UFW, so mon-01 filters them in the `DOCKER-USER` chain: only svc-01, mgmt and the VPN
  get through.
- Alerts go to Telegram, outside the lab, so they arrive even if the house's internet comes back before the
  services do.

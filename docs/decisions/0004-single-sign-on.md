# 0004: authentik for single sign-on and 2FA

**Status:** accepted

## Decision
authentik is the identity provider. Apps that speak OIDC (Grafana, Paperless) use it directly. Apps without
their own login (Prometheus, Alertmanager, Uptime Kuma's status page, the Traefik dashboard, Frigate) sit behind
Traefik forward-auth through authentik's embedded outpost. Every account has TOTP or WebAuthn.

## Why
- One account and one second factor for everything; turning someone's access off is one switch.
- Forward-auth puts a login in front of tools that have none, without exposing them.

## Exceptions
- **Vaultwarden** keeps its own login. Its clients (browser extension, mobile app) don't follow an SSO redirect,
  and the vault is encrypted with the master password anyway. Sign-ups are disabled; accounts are by invitation.

## Consequences
- authentik is a dependency for most UIs. If it's down, Grafana and Paperless still accept their local admin
  accounts (break-glass), and Prometheus/Alertmanager are still reachable on mon-01 from mgmt or the VPN.
- The worker runs without the Docker socket (upstream mounts it for managed outposts, which aren't used here).

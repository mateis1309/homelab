# Power outage

## What happens automatically

1. The UPS switches to battery. The NUT server on the router sees it within 5 s.
2. When the UPS reports **low battery**, NUT tells its clients to shut down:
   - the **Proxmox host** (`nut_client`) shuts down, and Proxmox shuts the VMs down cleanly first,
   - the **DS1815+** (DSM network UPS client) shuts down.
3. The router waits up to 60 s (`HOSTSYNC`) for the clients to log off, then shuts itself down last.

## When power returns

- The BIOS of the router, NUC and NAS should be set to **power on after AC loss** (check this once per device).
- Proxmox starts `svc-01` and `mon-01` (`on_boot = true` in Terraform).
- Check: Uptime Kuma all green, Grafana "Homelab overview", `make audit`.
- If the outage hit during the backup window, the timer catches up (`Persistent=true`).

## Test it (twice a year)

```bash
ssh ops@10.10.10.1 'upsc ups@localhost'                 # battery charge, runtime, status OL
ssh ops@10.10.10.1 'sudo upsmon -c fsd'                  # forced shutdown: runs the whole sequence for real
```

Only run the forced-shutdown test when everyone in the house is fine with the network going down.

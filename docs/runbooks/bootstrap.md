# Bootstrap: first rollout on the real hardware

Order matters: network first, then the hypervisor, then VMs, then services. Plan a two-hour maintenance window
for step 2, because the house is offline during the switch-over.

## 0. Control machine

```bash
git clone --recurse-submodules https://github.com/mateis1309/homelab.git && cd homelab
pip install -r requirements-dev.txt && make deps
cp ansible/vault.example.yml ansible/inventory/group_vars/all/vault.yml   # fill in, then:
ansible-vault encrypt ansible/inventory/group_vars/all/vault.yml
make test   # everything renders and validates
```

Every Linux host needs an `ops` user with your SSH key and sudo. Temper disables password and root SSH logins,
so check key login works **before** the first run.

## 1. Router: stage (no downtime)

On the router, check the port names (`ip -br link`) and fix `router_wan_interface` / `router_lan_bond_members`
in `group_vars/routers.yml` if needed. Then, with `router_network_live_apply: false`:

```bash
make router
```

This applies the baseline and hardening and **stages** the netplan and nftables files
(`/etc/netplan/60-homelab.yaml.staged`, `/etc/nftables.conf.staged`). Nothing changes on the network yet.

## 2. Cut-over (maintenance window, at the router console)

1. **Switches.** Configure the D-Link and Netgear as in [network.md](../network.md#switch-configuration): create
   VLANs 10–60, the LACP group on ports 1–3 tagged with every VLAN, and the access ports. Leave one spare port
   (e.g. 41) untagged on VLAN 10 for your laptop.
2. **Old config off.** On the router:
   ```bash
   sudo systemctl disable --now isc-dhcp-server 2>/dev/null; sudo systemctl disable --now dnsmasq 2>/dev/null
   sudo ufw disable 2>/dev/null; sudo iptables-save > ~/iptables-before-cutover.txt   # old rules, for reference
   ```
   If `iptables-save` shows old filter rules with a DROP policy on FORWARD, flush them (`iptables -F; iptables -P FORWARD ACCEPT`):
   the new nftables table does the filtering from now on.
3. **Commit.**
   ```bash
   sudo homelab-netplan-commit && sudo homelab-nft-commit
   ip -br addr   # bond0 up, vlan10..vlan60 with .1 addresses
   ```
4. **Laptop** on the VLAN 10 spare port with a static `10.10.10.50/24`, gateway `10.10.10.1`, then
   `ssh ops@10.10.10.1`.
5. Set `router_network_live_apply: true` in `group_vars/routers.yml`, then:
   ```bash
   make router   # dnsmasq, chrony, mDNS reflector, WireGuard, NUT; firewall now under safe_apply
   ```
6. **Check from each zone.** A phone on trusted gets a `10.10.30.x` lease and internet; a guest device can't
   reach `10.10.20.10`; `sudo nft list ruleset` shows the homelab table; `journalctl -k | grep 'nft forward drop'`
   shows what gets blocked.

From now on every firewall/network change goes through `make router` with automatic rollback.

## 3. Proxmox

1. Install Proxmox VE 9 from the ISO on the NUC: address `10.10.10.20/24`, gateway `10.10.10.1`, DNS
   `10.10.10.1`, hostname `pve.home.arpa`.
2. Create the Ansible user:
   ```bash
   apt install -y sudo && adduser --disabled-password --gecos "" ops && usermod -aG sudo ops
   echo 'ops ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/ops
   install -d -m 700 -o ops -g ops /home/ops/.ssh   # then add your public key to /home/ops/.ssh/authorized_keys
   ```
3. Node → System → Network → `vmbr0` → tick **VLAN aware** → Apply. (Or let Ansible manage the file: set
   `pve_nic` and `pve_manage_network: true`.)
4. `make hypervisor`. It prints the Terraform API token **once**; put it in `terraform/terraform.tfvars`.

## 4. VMs

```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars   # paste the token
make vms
```

## 5. NAS units and UPS

- DS1815+ and NAS326: [backup.md → NAS setup](../backup.md#nas-setup-dsm-and-nas326-web-uis).
- DS1815+ UPS: Control Panel → Hardware & Power → UPS → *Synology UPS server* → **Network UPS server**, address
  `10.10.20.1` (the router's address on the servers VLAN).

## 6. Services

1. Cloudflare: an API token with **Zone → DNS → Edit** on the services domain only → `vault_cloudflare_dns_token`.
   Set `services_domain` in `group_vars/all/main.yml`.
2. `make services`. On the first run it prints the restic SSH public key: add it to the NAS `restic` user, then run
   it again.
3. authentik: open `https://auth.<domain>/if/flow/initial-setup/`, create the admin, **enable MFA**, and create the
   group `admins`. Then:
   - Provider *Proxy, forward auth (domain level)* for `<domain>`, application "lab", and add the provider to the
     **embedded outpost**.
   - OAuth2/OIDC provider + application `grafana`: redirect `https://grafana.<domain>/login/generic_oauth`; copy
     the secret to `vault_grafana_oauth_client_secret`.
   - OAuth2/OIDC provider + application `paperless`: redirect
     `https://docs.<domain>/accounts/oidc/authentik/login/callback/`; copy the secret to
     `vault_paperless_oidc_client_secret`.
   - `make services` again to load the secrets.
4. Vaultwarden: open `https://vault.<domain>/admin` with the admin token and invite users.
5. `make restore-test-now` after the first nightly backup, then `make audit`.

Tick the steps off in the README status table as they go live.

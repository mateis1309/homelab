# docker_host

Docker engine + compose from Ubuntu packages, with DOCKER-USER filtering for published ports.

| Variable | Default | Notes |
|---|---|---|
| `docker_host_published_allow` | `[]` | Source CIDRs allowed to reach ports published by containers. Empty list = no filtering (the router's zone firewall still applies). |
| `docker_host_external_interface` | `"{{ ansible_facts['default_ipv4']['interface'] }}"` |  |
| `docker_host_log_max_size` | `10m` |  |

Lab-wide values (zones, hosts, firewall rules, routes) are set in `ansible/inventory/group_vars/`, not here.

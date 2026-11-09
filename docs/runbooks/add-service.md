# Add a service

Example: adding `freshrss` on svc-01.

1. Create `ansible/roles/stacks/templates/freshrss/compose.yml.j2`. Join the external `proxy` network, set a
   `container_name`, bind-mount data under `./data`, and pin the image version in
   `group_vars/all/versions.yml` with a `# renovate:` comment.
2. If it needs secrets: add `.env.j2` (rendered with mode 0600), with the values in the vault and dummy values
   in `ansible/vault.example.yml`.
3. Add data directories to `stacks_data_dirs` (with the UID the image runs as).
4. Add `freshrss` to `stacks_enabled` and a route to `traefik_routes` in `group_vars/services.yml`
   (`forward_auth: true` if it has no login of its own).
5. Backups: anything under `/opt/stacks` is included. If it has a database, add it to `restic_db_dumps`, and add
   a key path to `restic_restore_test_paths`.
6. Monitoring: add a check in Uptime Kuma for `https://freshrss.<domain>`.
7. `make test` (renders it and runs `docker compose config`), open a PR, then `make services`.

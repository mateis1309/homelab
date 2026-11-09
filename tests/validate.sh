#!/usr/bin/env bash
# Validate the files rendered by ansible/tests/render.yml with the tools that will consume them.
# Tools that are not installed are reported as SKIP; CI installs all of them.
set -uo pipefail
cd "$(dirname "$0")/../build/render" || { echo "run: cd ansible && ansible-playbook tests/render.yml"; exit 2; }

failures=0
pass() { printf '  \033[32mPASS\033[0m %s\n' "$1"; }
fail() { printf '  \033[31mFAIL\033[0m %s\n' "$1"; failures=$((failures + 1)); }
skip() { printf '  \033[33mSKIP\033[0m %s (%s not installed)\n' "$1" "$2"; }
check() { # check <label> <tool> <command...>
  local label="$1" tool="$2"; shift 2
  if ! command -v "$tool" >/dev/null 2>&1; then skip "$label" "$tool"; return; fi
  if out="$("$@" 2>&1)"; then pass "$label"; else fail "$label"; printf '%s\n' "$out" | sed 's/^/       /'; fi
}
sudo_if_needed() { if [ "$(id -u)" -eq 0 ]; then "$@"; else sudo "$@"; fi; }

echo "router"
check "nftables ruleset (nft -c)" nft sudo_if_needed nft -c -f router/nftables.conf
check "dnsmasq config (dnsmasq --test)" dnsmasq dnsmasq --test --conf-file=router/dnsmasq/homelab.conf
if command -v netplan >/dev/null 2>&1; then
  root="$(mktemp -d)"; mkdir -p "$root/etc/netplan"
  install -m 0600 router/netplan/60-homelab.yaml "$root/etc/netplan/"
  check "netplan config (netplan generate)" netplan sudo_if_needed netplan generate --root-dir "$root"
  sudo_if_needed rm -rf "$root"
else
  skip "netplan config" netplan
fi

echo "compose stacks"
for dir in */stacks/*/; do
  check "${dir%/} (docker compose config)" docker docker compose --project-directory "$dir" -f "$dir/compose.yml" config --quiet
done

echo "monitoring"
mon=mon-01/stacks/monitoring
if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
  img=$(grep -oE 'prom/prometheus:[^"[:space:]]+' "$mon/compose.yml" | head -1)
  am=$(grep -oE 'prom/alertmanager:[^"[:space:]]+' "$mon/compose.yml" | head -1)
  check "prometheus config (promtool)" docker docker run --rm -v "$PWD/$mon/prometheus:/etc/prometheus:ro" \
    --entrypoint promtool "docker.io/$img" check config /etc/prometheus/prometheus.yml
  check "alert rules (promtool)" docker docker run --rm -v "$PWD/$mon/prometheus:/etc/prometheus:ro" \
    --entrypoint promtool "docker.io/$img" check rules /etc/prometheus/alerts.yml
  check "alertmanager config (amtool)" docker docker run --rm -v "$PWD/$mon/alertmanager:/etc/alertmanager:ro" \
    --entrypoint amtool "docker.io/$am" check-config /etc/alertmanager/alertmanager.yml
else
  skip "promtool / amtool" "docker daemon"
fi
check "grafana dashboard is valid JSON" python3 python3 -m json.tool "$mon/grafana/provisioning/dashboards/homelab-overview.json"

echo "shell scripts"
for f in */sbin/* */lib/*.sh; do
  check "$f (shellcheck)" shellcheck shellcheck -s bash "$f"
done

echo
if [ "$failures" -gt 0 ]; then echo "$failures check(s) failed"; exit 1; fi
echo "all checks passed"

#!/usr/bin/env bash
set -euo pipefail
if [[ $(id -u) -ne 0 ]]; then
  printf '%s\n' 'Run this installer as root on the deployment server.' >&2
  exit 1
fi
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source_dir=$(dirname -- "$script_dir")
command -v python3 >/dev/null
command -v systemctl >/dev/null
# Validate the package before touching the service.
(cd "$source_dir" && python3 -m unittest -v test_server.py)
if [[ -e /opt/cricx/tripo-dashboard && ! -e /opt/cricx/tripo-dashboard/.cricx-managed ]]; then
  printf '%s\n' 'Existing Cricx directory is not managed by this installer; inspect it before proceeding.' >&2
  exit 1
fi
if ! id cricx >/dev/null 2>&1; then
  useradd --system --home-dir /nonexistent --shell /usr/sbin/nologin cricx
fi
install -d -m 0755 /opt/cricx/tripo-dashboard
install -d -m 0750 -o root -g cricx /etc/cricx
for file in server.py index.html app.js style.css README.md TESTING.md; do
  install -m 0644 "$source_dir/$file" "/opt/cricx/tripo-dashboard/$file"
done
touch /opt/cricx/tripo-dashboard/.cricx-managed
if [[ ! -e /etc/cricx/tripo.env ]]; then
  install -m 0640 -o root -g cricx /dev/null /etc/cricx/tripo.env
  printf '%s\n' '# Configure TRIPO_API_KEY securely here; do not commit or share this file.' > /etc/cricx/tripo.env
fi
install -m 0644 "$script_dir/cricx-tripo-dashboard.service" /etc/systemd/system/cricx-tripo-dashboard.service
systemctl daemon-reload
systemctl enable --now cricx-tripo-dashboard
systemctl restart cricx-tripo-dashboard
systemctl is-active --quiet cricx-tripo-dashboard
python3 - <<'PY'
import json,time,urllib.request
for attempt in range(10):
 try:
  with urllib.request.urlopen('http://127.0.0.1:8876/api/status',timeout=2) as response:
   data=json.load(response)
  print('Cricx service responded. API key configured:',data['key_configured'])
  break
 except OSError:
  if attempt==9:raise
  time.sleep(.5)
PY

# Server deployment for Cricx

Prepared for the user-authorized server deployment. Not yet executed on the server.

This installs a separate service and dedicated `cricx` user under `/opt/cricx/tripo-dashboard`. It binds loopback port 8876. No shared web routing, public listener, existing project service, firewall rule or database is changed.

## Local connection workflow

Use the existing iCompass deployment SSH key and pinned known-hosts file from the user's local project. Do not copy private keys into Git or send them through chat. Verify the server identity using the existing known-hosts file; do not disable strict host checks.

Upload and extract `cricx-tripo-dashboard.zip` to a temporary directory on the server. Inspect the installer and service, then run:

```sh
sudo bash cricx-tripo-dashboard/deploy/install.sh
```

Provision the API key securely in `/etc/cricx/tripo.env`, owned by root and mode 0640. Restart `cricx-tripo-dashboard` after provisioning. Do not print the file or key, place it in shell history, or include it in deployment logs.

For private browser access, establish an SSH tunnel with the saved connection, forwarding **local port 8876 to server loopback port 8876**. Open the dashboard on the local computer using that port. The dashboard is intentionally private; public HTTPS access requires an authenticated reverse proxy and a user-selected domain, which this package does not configure.

Use the dashboard's read-only connection test to verify the API key/account. A provider request rejection must be distinguished from missing credentials or network denial. Never auto-submit paid tasks as an authentication test.

## Verification

Check the service state, local dashboard/status routes and read-only balance request. Confirm existing project websites still respond. Report deployed and tested outcomes only after executing these checks on the server.

Installer syntax and package tests are checked in the cloud; service installation, SSH access, server-side balance request and tunnel/browser behavior remain unverified.

# Cricx asset workshop

Local dashboard for verified Tripo v2 API operations. Python 3.10+; no third-party runtime dependencies.

## Start

Configure `TRIPO_API_KEY` securely in the process environment, using the Tripo **API platform** key. Never put it in the browser, Git or chat. Studio subscription access does not establish API credit entitlement.

From the repository root:

```sh
python3 tools/tripo-dashboard/server.py
```

On the same computer, open `http://127.0.0.1:8765`. This is a local address, not a remotely accessible cloud preview. To use on your computer, download the dashboard source and start the server there with Python and your secure environment configuration. Restart the server after setting credentials.

Click **Test API connection**. This performs `GET /user/balance`, not a generation request. Task submission remains disabled until the read-only check succeeds. Each Create click submits one potentially chargeable task; nothing is generated automatically. Account errors and connection failures are shown explicitly.

The workbench supports text-to-model (P1, 3.1 or 2.5), biped rigging, idle/walk/run/jump/turn presets, manual status refresh and output download links. Source task IDs must belong to an accessible API task, not an arbitrary studio URL. Importing local assets is not implemented in this first dashboard. It does not replace or upload the existing user bowler automatically.

Rigging requests a Mixamo-style skeleton and FBX because those are documented API options. The studio's Unity-Humanoid export option is not assumed to exist in the API. Unity avatar mapping must still be validated. Custom multi-stage text-to-bowling animation and H3 generation are not verified and are not exposed as pretend working controls.

No automatic retries for paid requests. Duplicate submission IDs are blocked until the server restarts. If a submission fails after reaching Tripo, inspect the API account/task history before manually submitting again; this local deduplication is not provider-side idempotency and does not survive server restart.

## Validation

```sh
cd tools/tripo-dashboard
python3 -m unittest -v test_server.py
```

Tests run the real HTTP handler with mocked Tripo responses; they verify missing credentials, same-origin enforcement, duplicate-paid-request protection, documented operation payloads, task lookup and static content. They do **not** establish live API authentication or generation success.

## API evidence

- Official SDK: https://github.com/VAST-AI-Research/tripo-python-sdk
- Reviewed distribution: `tripo3d` 0.4.2, `client.py` and `models.py`.
- API host: `https://api.tripo3d.ai/v2/openapi`.
- Authentication: bearer token on the server only.

Live validation is blocked in the current cloud instance by an absent key binding and denied egress to Tripo. Required secret and network destinations have been saved in the environment draft. No paid generation was attempted.

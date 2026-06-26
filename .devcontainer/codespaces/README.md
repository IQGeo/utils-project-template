# Running in GitHub Codespaces

This folder holds a **Codespaces-specific** dev container config
([`devcontainer.json`](./devcontainer.json)). It is a **second, separate** config
from the local VS Code one at [`../devcontainer.json`](../devcontainer.json) and
leaves it untouched. Both reuse the same
[`../docker-compose.yml`](../docker-compose.yml) stack — **no base service
definitions were modified.** The only additions are this `codespaces/` folder.

The stack is the template's standard one: **postgis, iqgeo, keycloak, redis,
pgadmin, rq-dashboard** (plus `openbao` and `centrifugo` in disabled profiles).
This config adds one extra container, the **`keycloak-tls`** nginx sidecar
(explained below), and the `docker-outside-of-docker` feature for stack
inspection.

## Selecting this config when creating a Codespace

The config a Codespace uses is fixed at creation and **cannot be changed
afterward**. When you create a Codespace you **must** pick this config:

**Code ▸ Codespaces ▸ ⋯ ▸ New with options…** → in the **"Dev container
configuration"** dropdown choose **"Project for customer MyProject
(Codespaces)"**, not the default local config.

**Confirm you're on the right config** once it's up:
```bash
env | grep MYW_EXT_BASE_URL   # should show https://<codespace>-80.app.github.dev, NOT localhost
```
If it shows `localhost`, you picked the default config — delete the Codespace and
recreate with the correct one.

## Required org-level secrets

The platform images live in a **private Harbor registry**
(`harbor.delivery.iqgeo.cloud`). Codespaces cannot log in interactively, so it
authenticates using specially-named **Codespaces secrets**. Create these at the
**organization** level (Org Settings ▸ Secrets and variables ▸ Codespaces) and
grant them to this repository:

| Secret name | Value |
| --- | --- |
| `HARBOR_CONTAINER_REGISTRY_SERVER` | `harbor.delivery.iqgeo.cloud` |
| `HARBOR_CONTAINER_REGISTRY_USER` | your Harbor username |
| `HARBOR_CONTAINER_REGISTRY_PASSWORD` | your Harbor **CLI secret** (from your Harbor user profile) |

The `*_CONTAINER_REGISTRY_SERVER` / `_USER` / `_PASSWORD` naming is recognized by
Codespaces automatically — it runs `docker login` against that registry during
container build **and during prebuilds**. No login script, no credentials in the
repo.

> The `HARBOR_*` prefix is arbitrary; only the `_CONTAINER_REGISTRY_*` suffixes
> matter. Keep all three consistent.

**No other secrets are required.** DB password, Keycloak admin password, and the
OIDC client secret all have non-sensitive dev defaults baked into the Compose
file (`${VAR:-default}`). Do **not** commit a `.env`.

## Prebuilds (caching the pull/build on push)

Enable a prebuild so the expensive image pull/build is cached and Codespaces
start in seconds:

1. Repo Settings ▸ Codespaces ▸ **Set up prebuild**.
2. Branch: `dev` (and/or `main`).
3. Dev container configuration: **`.devcontainer/codespaces/devcontainer.json`**.
4. Trigger: **On push**.

What gets cached: the built `iqgeo` service image, the sibling images pulled when
Compose comes up during the prebuild, and the `onCreateCommand` result
(`myw_product fetch node_modules`, which runs inside the prebuild). Per-start work
(`git config safe.directory`, docker socket perms) is in `postStartCommand` and
runs every time, including resume-from-prebuild.

## Architecture: PRIVATE Keycloak via the nginx TLS sidecar

This is the key design point of this config: **Keycloak is never exposed on a
public port.** No port in this config should be made Public.

In Codespaces the browser reaches each service at a per-port HTTPS URL like
`https://<codespace>-<port>.app.github.dev`, not `localhost`/`keycloak.local`.
OIDC login needs **two** things to agree on Keycloak's issuer URL:

1. the **browser**, which redirects to Keycloak's login page, and
2. the **app server**, which does **server-side discovery** — it fetches
   Keycloak's `.well-known/openid-configuration` to load the token-signing keys.
   (This version of the OIDC client populates its key store via dynamic
   discovery; skipping it fails ID-token verification with `Unknown issuer`.)

Both must use the **same** issuer (`https://<codespace>-8080.app.github.dev`), but
we do not want to make 8080 Public to satisfy the server-side fetch. The
`keycloak-tls` sidecar resolves this:

- It is an **`nginx:alpine`** container that, on start, generates a self-signed
  cert (`openssl req -x509 … -subj '/CN=keycloak'`) and runs
  `nginx -g 'daemon off;'`.
- [`nginx-keycloak.conf`](./nginx-keycloak.conf) listens on **443 with TLS** and
  reverse-proxies to the internal `keycloak:8080`, forwarding
  `X-Forwarded-Proto: https` / `X-Forwarded-Host` so Keycloak (running
  `KC_PROXY=edge`) builds correct absolute URLs.
- Crucially, the sidecar declares a **Docker network alias** equal to the
  external Keycloak hostname
  (`${CODESPACE_NAME}-8080.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}`). So when
  the **app server** resolves that hostname for its server-side discovery, Docker
  DNS points it at **nginx inside the network** — not out to the public internet.
  nginx terminates TLS and proxies to Keycloak.

Meanwhile the **browser** uses the same hostname via the **Private** forwarded
port 8080: Codespaces authenticates the request at its edge and tunnels it to the
container. Both paths see the same issuer URL, so discovery and login agree —
**with no public port.**

This relies on two settings that are **already in the template**:

- `httpc_params.verify=false` in
  [`../devserver_config/oidc/conf.json`](../devserver_config/oidc/conf.json), so
  the app accepts the sidecar's self-signed cert during server-side discovery.
- `KC_PROXY=edge` on Keycloak (also set in
  [`docker-compose.codespaces.yml`](./docker-compose.codespaces.yml)), so
  Keycloak trusts the `X-Forwarded-*` headers from nginx.

Because the back-channel goes through nginx and the browser goes through the
Private forwarded port, **ROPC, API tokens, internal service-to-service auth, and
interactive web login all work without exposing anything publicly** — the right
posture for both humans and headless/remote agents.

> Forwarded ports are HTTPS, single-host. Server-to-server calls inside the
> Docker network (app → keycloak via the sidecar alias, app → postgis, etc.) are
> unaffected.

## How to test the stack starts cleanly

1. Push this branch; ensure the three Harbor secrets exist at the org level.
2. Create a Codespace on this branch, selecting the "…(Codespaces)" config.
3. Watch the creation log — it should pull from Harbor without an auth error,
   build the `iqgeo` image, and bring the stack up.
4. You are working *inside* the `iqgeo` service container, so check services by
   network (same hostnames the app uses):
   ```bash
   curl -s -o /dev/null -w "app:      %{http_code}\n" http://localhost:8080
   pg_isready -h postgis -p 5432
   # discovery through the nginx sidecar (self-signed cert, so -k):
   curl -sk -o /dev/null -w "keycloak: %{http_code}\n" \
     "https://${CODESPACE_NAME}-8080.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}/realms/iqgeo/.well-known/openid-configuration"
   (exec 3<>/dev/tcp/redis/6379) && echo "redis:    open"
   ```
   The `docker-outside-of-docker` feature also gives you the Docker CLI, so you
   can inspect the stack directly:
   ```bash
   docker compose -f .devcontainer/docker-compose.yml \
     -f .devcontainer/codespaces/docker-compose.codespaces.yml ps
   ```
   All services should be `running` (including `keycloak-tls`).
5. Open the **Ports** tab → open the **IQGeo App** (port 80) URL. The app should
   load, and OIDC login should complete without making any port Public.

## Programmatic / agentic spin-up

For remote agents or scripts, create Codespaces from the CLI instead of the UI.
Passing `--devcontainer-path` removes the "wrong config" trap entirely.

Helper: [`new-codespace.sh`](./new-codespace.sh) creates the Codespace with the
right config + machine and blocks until the stack is healthy:
```bash
# requires: gh auth refresh -h github.com -s codespace
CS=$(.devcontainer/codespaces/new-codespace.sh agent-001)   # prints codespace name
gh codespace ssh -c "$CS" -- 'cd /opt/iqgeo/platform/WebApps/myworldapp/modules && myw_product test'
gh codespace delete -c "$CS"
```
Override `REPO` / `BRANCH` / `MACHINE` / `IDLE` via env vars. Under the hood it's
just `gh codespace create --devcontainer-path .devcontainer/codespaces/devcontainer.json …`
plus a readiness poll (`curl localhost:8080` + `pg_isready`). Set up a
**prebuild** (above) so each spin-up is fast instead of a cold start.

## Recommended machine size

**8-core / 16 GB** (`premiumLinux`). 4-core/8GB is the bare minimum and risky:
under Codespaces there is no host headroom, and the stack runs Postgres,
Keycloak (JVM), the IQGeo appserver, redis, pgAdmin, rq-dashboard and the nginx
sidecar.

## Caveats

- **Postgres data (`pgdata` volume) does not survive a full _rebuild_.** Named
  Docker volumes persist across stop/start, but a "Rebuild container" recreates
  them — you'll get a fresh DB (auto-rebuilt by the entrypoint when
  `MYW_DB_UPGRADE=YES`). Keycloak realm config is re-imported on every start.
- **OpenBao is dev-mode / in-memory** (disabled profile by default). If you
  enable it, it starts unsealed with a static root token and **loses all data on
  every restart** — re-seed any secrets after a restart/rebuild.

# Changelog

#### v1.3.0 (06/29/2026)

- DX-37: devcontainer: add copilot cli with instructions on how to configure it.
- DX-74: fix PRODUCT_REPOSITORY_PREFIX overwriting PRODUCT_REGISTRY in BUILD_ARGS

#### v1.2.0 (05/28/2026)

- DX-44: deployment: add Kubernetes overlay for standalone OpenBao
- DX-40: docker-compose: added OpenBao and Centrifugo services, disabled by default
- SRE-869: deployment: add Centrifugo deployment overlays and documentation;
- Docs: add PostGIS image version guidance to devcontainer READMEs
- Docs: add guidance on building WFM dev database (#100)

#### v1.1.0 (04/02/2026)

- PLAT-13664: Cleans npm manifests from dev dependencies and removes node_modules in build
- deployment tools: use PY_VERSION for site packages copy
- docker-compose: Added .ai mount directory for use with ai-toolkit

#### v1.0.1 (02/18/2026)

- fix initial value for PROJECT_REPOSITORY in deployment/.env.example
- deployment: docker-compose: configure keycloak for local http deployment
- github action: include arg to allow product repository override
- deployment appserver: handle Python 3.12 base images by using MYW_PYTHON_SITE_DIRS env var
- build_images: remove hardcoding platform to amd64

#### v1.0.0 (02/13/2026)

- PLAT-11613: deployment: add Kubernetes related files and instructions
- deployment: added github action to automate image building
- devcontainer: added pgadmin service to list in devcontainer.json so it's now available when using the vscode extension
- update example configuration to NMT 3.5

#### v0.8.2 (10/21/2025)

- iqgeorc.jsonc updated default to platform 7.4
- PLAT-12000: Added RQ_REDIS_URL to deployments app server setup to match worker/tools setup
- PLAT-12007: Added 610_upgrade_db.sh to include module upgrade commands.

#### v0.8.1 (07/16/2025)

- .devcontainer: fixed permission issues with anywhere script.
- .devcontainer: added SSL_REQUIRED environment variable to keycloak service to fix HTTPs required issue.
- .devcontainer: Added support for developers to override the Apache port used inside the container via configuration.

#### v0.8.0 (06/16/2025)

**Fixes:**

- .devcontainer: rq-dashboard changed to trigger on container start
- .devcontainer: tsconfig: add missing myWorld path
- deployment: fix keycloak address in sed command

**Changes:**

- PLAT-10007: devcontainer: Add ROPC_ENABLE as an optional environment varialble
- PLAT-10597: enable debugging of LRT tasks
- PLAT-11630: improvements for anywhere development with running dev container.
- .devcontainer: add REDIS_PORT to .env.example
- .devcontainer: Removed the `910_start_worker.sh` entrypoint script as this is now provided by the platform denenv image.

#### v0.7.2 (04/10/2025)

**Fixes:**

- Fixed missing `PROJ_PREFIX` usage in deployment compose (#49)

**Changes:**

- Updated reference to platform from version 7.2 to 7.3 (#52)
- Removed volume in `devcontainer` to keep JavaScript bundles (#48)

#### v0.7.1 (02/26/2025)

**Changes:**

- Align files with the initial state of `.iqgeorc.jsonc` (#47)
- Added `tsconfig` (#46)

#### v0.7.0 (02/24/2025)

**Changes:**

- Updated container registry paths for new registry organization (#43)

#### v0.6.0 (01/31/2025)

**Changes:**

- Updated `docker-compose` to use PostGIS version 15-3.5

#### v0.5.0 (01/13/2025)

**Fixes:**

- Fixed incorrect `redis_url` environment variable defined for `rq-dashboard` in `docker-compose` (#39)
- Fixed `KEYCLOAK_HOST` URL in `docker-compose` for remote hosts (#34)

**Changes:**

- Added "Restart LRT task worker" task (#38)
- Added port forwarding for the `rq-dashboard` container in `devcontainer.json` for remote hosts (#40)
- Updated `devcontainer` README with a link to developing on Windows documentation (#37)
- Removed use of `COPY --link` in `dockerfile` when using `--from` (#36)
- Updated `rq-dashboard` in `docker-compose` with parameterized name (#33)
- Updated `.gitignore` to ignore new `tsconfig` files (#32)
- Improved support for `KEYCLOAK_HOST` environment variable usage in Keycloak (#29)
- Removed `memcached` from `remote_host` shared services (#31)
- Updated `iqgeorc` version to 0.5.0 (#30)
- Added long-running task configurations (#23)

# Changelog

#### v0.8.2 (10/21/2025)

-   iqgeorc.jsonc updated default to platform 7.4
-   PLAT-12000: Added RQ_REDIS_URL to deployments app server setup to match worker/tools setup
-   PLAT-12007: Added 610_upgrade_db.sh to include module upgrade commands.

#### v0.8.1 (07/16/2025)

-   .devcontainer: fixed permission issues with anywhere script.
-   .devcontainer: added SSL_REQUIRED environment variable to keycloak service to fix HTTPs required issue.
-   .devcontainer: Added support for developers to override the Apache port used inside the container via configuration.

#### v0.8.0 (06/16/2025)

**Fixes:**

-   .devcontainer: rq-dashboard changed to trigger on container start
-   .devcontainer: tsconfig: add missing myWorld path
-   deployment: fix keycloak address in sed command

**Changes:**

-   PLAT-10007: devcontainer: Add ROPC_ENABLE as an optional environment varialble
-   PLAT-10597: enable debugging of LRT tasks
-   PLAT-11630: improvements for anywhere development with running dev container.
-   .devcontainer: add REDIS_PORT to .env.example
-   .devcontainer: Removed the `910_start_worker.sh` entrypoint script as this is now provided by the platform denenv image.

#### v0.7.2 (04/10/2025)

**Fixes:**

-   Fixed missing `PROJ_PREFIX` usage in deployment compose (#49)

**Changes:**

-   Updated reference to platform from version 7.2 to 7.3 (#52)
-   Removed volume in `devcontainer` to keep JavaScript bundles (#48)

#### v0.7.1 (02/26/2025)

**Changes:**

-   Align files with the initial state of `.iqgeorc.jsonc` (#47)
-   Added `tsconfig` (#46)

#### v0.7.0 (02/24/2025)

**Changes:**

-   Updated container registry paths for new registry organization (#43)

#### v0.6.0 (01/31/2025)

**Changes:**

-   Updated `docker-compose` to use PostGIS version 15-3.5

#### v0.5.0 (01/13/2025)

**Fixes:**

-   Fixed incorrect `redis_url` environment variable defined for `rq-dashboard` in `docker-compose` (#39)
-   Fixed `KEYCLOAK_HOST` URL in `docker-compose` for remote hosts (#34)

**Changes:**

-   Added "Restart LRT task worker" task (#38)
-   Added port forwarding for the `rq-dashboard` container in `devcontainer.json` for remote hosts (#40)
-   Updated `devcontainer` README with a link to developing on Windows documentation (#37)
-   Removed use of `COPY --link` in `dockerfile` when using `--from` (#36)
-   Updated `rq-dashboard` in `docker-compose` with parameterized name (#33)
-   Updated `.gitignore` to ignore new `tsconfig` files (#32)
-   Improved support for `KEYCLOAK_HOST` environment variable usage in Keycloak (#29)
-   Removed `memcached` from `remote_host` shared services (#31)
-   Updated `iqgeorc` version to 0.5.0 (#30)
-   Added long-running task configurations (#23)

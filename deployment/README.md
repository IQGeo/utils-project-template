# Deployment images

This folder contains the docker image definitions optimised for deployment.
Theese images contain only runtime dependencies and are not suitable for development as they do not contain source or build dependencies.

An example docker compose file to start the containers locally is also included.

> **Deploying to Kubernetes?** See the [Helm deployment guide](helm/README.md) for complete instructions on deploying to Kubernetes clusters using Helm, including Minikube for local testing.

## Prerequisites

### Platform image

Authenticate with harbor so docker can download the IQGeo image(s)

```shell
docker login harbor.delivery.iqgeo.cloud
```

To use the docker CLI to login, you will need to obtain your CLI secret (password) from your user profile found in harbor:
https://harbor.delivery.iqgeo.cloud

## Deploying to Kubernetes

For Kubernetes deployments, see the [Helm deployment guide](helm/README.md).

## Running the containers locally with docker-compose

This folder includes an example docker-compose that allows running the containers locally. There are two steps: build the images and run docker compose up.

### Building the images

Use the provided script to build all required images:

```bash
cd deployment
./build_images.sh
```

Optionally, specify a custom product registry:
```bash
./build_images.sh harbor.delivery.iqgeo.cloud/engineering/
```

This will build three images:
- `iqgeo-myproj-build` (intermediate build image)
- `iqgeo-myproj-appserver` (web server)
- `iqgeo-myproj-tools` (workers and cron jobs)

The build downloads base images (postgis and platform) and includes product module injectors. It should take a few minutes depending on network connection and caches.

### Running with docker-compose

Once images are built, start the containers:

```bash
docker compose -f deployment/docker-compose.yml up -d
```

Database name, ports and containers names are defined in docker-compose.yml file and can be adjusted via environment variables. Copy the `.env.example` file to `.env` and update the values as required.

The dev database should be built the first time the platform container starts. This takes a few minutes minutes. Once this completes the applications should be accessible in http://localhost.

_Note1:_ Authentication is via Keycloak, ensure you have an entry in your hosts as per the instructions in the .devcontainer/README.md file.

_Note2:_ There are some instances when the Comms database will fail to build upon the first start. If this occurs, follow the appropriate steps using `myw_db` to create and install the comms module.

You can connect to a shell in the container by running

```
docker exec -it iqgeo bash
```

If you'd like to rebuild the database you can:

-   remove the containers, remove the corresponding volume and execute the compose up command as above

To create an image to run tools commands

```
docker build . -f dockerfile.tools -t iqgeo-myproj-tools
```

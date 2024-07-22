# Deployment images

This folder contains the docker image definitions optimised for deployment.
Theese images contain only runtime dependencies and are not suitable for development as they do not contain source or build dependencies.

An example docker compose file to start the containers locally is also included

## Prerequisites

### Platform image

Authenticate with harbor so docker can download the IQGeo image(s)

```shell
docker login harbor.delivery.iqgeo.cloud
```

To use the docker CLI to login, you will need to obtain your CLI secret (password) from your user profile found in harbor:
https://harbor.delivery.iqgeo.cloud

## Running the containers locally

This folder includes an example docker-compose that allows running the containers locally, there are two steps: build an intermediate image and execute a docker compose up.

From the parent folder run the following commands:

```
docker build . -f deployment/dockerfile.build -t iqgeo-myproj-build
docker compose -f deployment/docker-compose.yml up -d --build
```

This will download the base images (postgis and platform:7) and built the image with the Comms injector images. It should take a few minutes depending on network connection and caches.

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

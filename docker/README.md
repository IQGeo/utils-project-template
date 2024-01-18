
# Example-docker-platform: Network Manager Comms

This folder contains the docker image definitions for deploying an a project.
Also contains an example docker compose file to start the containers locally.

## Prerequisites

### Platform image

Authenticate with harbor so docker can download the Platform image  

```shell
docker login harbor.delivery.iqgeo.cloud
```

To use the docker CLI to login, you will need to obtain your CLI secret (password) from your user profile found in harbor:
https://harbor.delivery.iqgeo.cloud


## Start the containers

To start the containers locally, there are two steps: build an intermediate image and execute a docker compose up.
From this folder run the following commands
```
docker build . -f dockerfile.build -t iqgeo-myproj-build
docker compose -f docker-compose.yml up -d --build 
```

This will download the base images (postgis and platform:7) and built the image with the Comms injector images. It should take a few minutes depending on network connection and caches.

The Comms database should be built the first time the platform container starts. This takes a few minutes minutes. Once this completes the applications should be accessible in http://localhost. 

*Note:* There are some instances when the Comms database will fail to build upon the first start. If this occurs, follow the appropriate steps using `myw_db` to create and install the comms module.

You can connect to a shell in the container by running
```
docker exec -it iqgeo bash
```

If you'd like to rebuild the database you can:
 - remove the containers, remove the corresponding volume and execute the compose up command as above



To create an image to run tools commands
```
docker build . -f dockerfile.tools -t iqgeo-tools
```
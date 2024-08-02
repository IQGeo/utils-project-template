# Remote dev containers

This folder contains the definitions and instructions to run dev environments hosted on a Development server.

## Configure and Start shared Service Containers

Note: This step need only be done once as all developers will make user of the same services. If the services are
running on a separate system then this step is unnecessary.

From this folder execute:

```shell
docker compose -f docker-compose-shared.yml up -d
```

If you override the default Keycloak port using the `KEYCLOAK_PORT` environment variable, update the `forwardPorts` in `devcontainer.json` to match the new port. By default, Keycloak runs on port 8081.

## Configure the IQGeo dev container

The **Remote Development** extension pack for Visual Studio Code lets you use a Docker container as a full-featured development environment hosted on a remote server. It allows you to open any folder inside (or mounted into) a container and take advantage of Visual Studio Code's full feature set.

This section assumes you've authenticated to Harbor as per the parent readme and the repo you'll be working on has been cloned to your user's home on the development server.

It also assumes you've performed the [keycloak configuration](../README.md#authentication)

### Open Dev Container in VS Code

Using the **Remote Explore** extension in VS Code, connect via SSH to the server using your credentials.
You can then perform the following steps using VSCode as an editor.

### Overriding ENV variables

Overriding of environment variables in the `docker-compose.yml` can be done via `.env` file in this folder. Copy the `.env.example` file from the parent folder to `.env` and modify the values as described in its comments.

In particular, each developer needs to be assigned to their own port on the server and have a unique project and container name this needs to be configured before
starting any containers. Navigate to the directory and open the .env file for editing. It should look something like this

```
PROJ_PREFIX=_myname
APP_PORT=8081
```

Edit the entries to give each developer unique values.

### Open Dev Container in VS Code

You can now run the VS Code command "dev containers: Reopen in Container". (This can be done by clicking the blue button on bottom left corner of the window and chosing that command from the list or by pressing Cmd/Ctrl+P and typing in the command)

### Troubleshooting

(to complete)

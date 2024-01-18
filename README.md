# Template IQGeo project/product/module repo

This template provides a starting point for creating a new IQGeo project/product/module.
It includes the following:

- local development container definition
- VSCode tasks and settings.
- dockerfiles for deployment containers
- docker-compose files to run environment

## Contents

- [Setup Project Directory](#setup-project-directory)
- [Update Project Files](#update-project-files) - [Update README.md](#devcontainerreadmemd) - [Update devcontainer.json](#devcontainerdevcontainerjson) - [Update docker-compose.json](#devcontainerdocker-composeyml) - [Update dockerfile](#devcontainerdockerfile) - [Configure VSCode launch.json](#vscodelaunchjson) - [Configure VSCode tasks.json](#vscodetasksjson)
  &nbsp;

---

## Setup Project Directory

Copy the contents of this folder to the root of your git folder. This should include:

- `.devcontainer`
- `.vscode`
- `.gitignore`

Create a folder for the module being developed.
Edit `.gitignore` and add the name of the module. Example:

```
# Exclude everything except module under development
/*
!my_module
!.devcontainer
!.vscode
```

## Review Project Files

After copying the project directory and all the template files to their correct destinations, you should review and update the following files to ensure that the project is properly configured for your needs:

### .devcontainer/README.md

1. Within the `.devcontainer/README.md `, Update the module name and database name to match your project's module and database name.
2. If there are any specific tasks that need to be run to build the database once the development container is running, add them to the `.devcontainer/README.md` file. This will ensure that other developers working on the project know how to build the database.

### .devcontainer/devcontainer.json

Update the the container name so that it's specific to your project

### .devcontainer/docker-compose.yml

Add module specific volumes in the `docker-compose.yml`. A volume will be needed for every module that is included in your project directory.

Example:

```
# define custom module volumes here that you want to mount into the container
- ../my_module:/opt/iqgeo/platform/WebApps/myworldapp/modules/my_module:delegated
```

Update ENV variables as needed.

### .devcontainer/dockerfile

1. Adjust module configuration section in `.devcontainer/dockerfile`
2. If additional modules are required for development, uncomment the injector image sections and add the appropriate injector images to `.devcontainer/dockerfile`.

### .vscode/launch.json

Adjust test suites in `.vscode/launch.json`

### .vscode/tasks.json

Add a task for building the database in `.vscode/tasks.json`

Create a README.md file at the root of your project to provide general information and direct people looking for dev environment instructions to `.devcontainer/README.md`

## Running a dev environment on windows.

Using host-bound volumes when running linux containers on a windows host comes with considerable overhead. Using **myw_product build** and **myw_product watch** within a container becomes impractical. By following these steps, you will be able to checkout and access your source code within WSL2, and cut on the need to access the windows host at all.

[Developing with Containers on Windows](https://github.com/IQGeo/example-docker-platform/blob/master/.readme/windows/0-developing-with-containers-windows.md)

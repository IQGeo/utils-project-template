# Template repo for an IQGeo project/product/module

This template provides a starting point for creating a new IQGeo project/product/module.
It includes the following:

-   Development environment
    -   dev container definitions
    -   VSCode tasks, settings and recommended extensions.
-   Deployment configuration
    -   container image definitions optimised for deployment
    -   example docker-compose and instructions to build and run deployment docker containers

## Contents

-   [Template Usage](#template-usage)
-   [Module Dependencies](#module-dependencies)
-   [Update Project Files](#update-project-files) - [Update README.md](#devcontainerreadmemd) - [Update devcontainer.json](#devcontainerdevcontainerjson) - [Update docker-compose.json](#devcontainerdocker-composeyml) - [Update dockerfile](#devcontainerdockerfile) - [Configure VSCode launch.json](#vscodelaunchjson) - [Configure VSCode tasks.json](#vscodetasksjson)
    &nbsp;

---

## Template Usage

To use this template repository, follow these steps:

Click the "Use this template" button at the top of the repository page.
Provide a name and description for your new repository.
Clone your new repository to your local machine.
Update the existing files for your project/product/module (see sections below for guidance).
Commit and push your changes to the new repository.

## Module Dependencies

There are two options for importing external module dependencies into your project. The method chosen will depend on the needs of the project development team.

1.  **Utilizing Injector Images for Dependency Management**

    If a module is a dependency of your project, then it's preferred to use injector images. Using injector images offers several benefits. They provide consistency, as each build will use the exact same version of the module, ensuring that all developers are working with the same dependencies. Additionally, each injector image is versioned, which provides an easy way to switch between different versions. Please review [Update dockerfile](#devcontainerdockerfile) for additional information on using injector images.

2.  **Mounting Locally Cloned Modules from the Host Machine**

    If your project requires more flexibility with its module dependencies, one approach is to mount a locally cloned Git repository containing the module directly from your host machine into your Docker container. This method can be particularly useful in several scenarios:

    -   **Feature Development**: If you're developing a new feature that requires updates to a module only found in a feature branch, you can checkout the feature branch from your cloned repository. By mounting the locally cloned repository, you can work off this feature branch directly from within your Docker container, ensuring that the changes in the module are immediately reflected in your project.

    -   **Simultaneous Development**: If your project and the module are being developed simultaneously, mounting the module's repository can help streamline the development process. Any changes made to the module on your host machine will be immediately reflected in the Docker container. This eliminates the need to rebuild the container or manually copy changes every time the module is updated.

    Mounting modules external to your project will need to be configured through the [docker-compose.yml](#devcontainerdocker-composeyml) file.

## Review Provided Files

After your initial setup you should review and update the following files to ensure that the project is properly configured for your needs:

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

## Updating this Readme

Once you have followed the instructions above, you can edit this file so it becomes a Readme for your project/module/product:

-   update the sections below to describe your project
-   Remove all content up to and including this line leaving only the sections below

# Project Name

Project description

## Development

Check out the [development README](.devcontainer/README.md) for instructions on how to build and run the development environment.

### Running a dev environment on windows.

Using host-bound volumes when running linux containers on a windows host comes with considerable overhead. Using **myw_product build** and **myw_product watch** within a container becomes impractical. By following these steps, you will be able to checkout and access your source code within WSL2, and cut on the need to access the windows host at all.

[Developing with Containers on Windows](https://github.com/IQGeo/example-docker-platform/blob/master/.readme/windows/0-developing-with-containers-windows.md)

## Deployment

Check out the [deployment README](deployment/README.md) for instructions on how to build and run the deployment environment.

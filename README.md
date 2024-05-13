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

This template is intended to be used when creating a new repository for an IQGeo project/product/module but can also be applied to existing repositories.

Check the appropriate section below depending on your use case.

### Create a new repository from this template

To use this template when creating a new repository, follow these steps:

1. Click the "Use this template" button at the top of the repository page.
1. Provide a name and description for your new repository.
1. Clone your new repository to your local machine.

    - Alternatively, you can download the repository as a zip file and extract it to your local machine.

1. Create an initial commit.
1. Review and update the `.iqgeorc.jsonc` file to match your project settings and dependencies.
1. Ensure you have the IQGeo VSCode extension installed. It's available in the Extensions Marketplace.
1. Run the IQGeo VSCode extension command "IQGeo Update Project Files". You can right click the `.iqgeorc.jsonc` file or its contents to get the command in the context menu.
1. Review the changes made by the tool, adjust them if required, and commit them to your repository.
1. Update other files for your project/product/module (see sections below for guidance).
1. Test the changes and make required adjustments by executing the dev environment
    - The dev environment is configured to use Keycloak for authentication. This requires you to add an entry to your hosts file to resolve the Keycloak URL to your local machine. Add the following line to your system's `hosts` file:
      `127.0.0.1    keycloak`
    - execute the dev environment by running: `docker compose -f ".devcontainer/docker-compose.yml" up -d --build `.
    - add any necessary entrypoints to `.devcontainer/entrypoint.d` and `deployment/entrypoint.d` for your modules or the product modules
1. Commit and push your changes to the new repository.

### Apply this template to an existing repository

The following steps assume the repository has a folder for any IQGeo module, for example `custom`, if not, first make this adjustment to the structure of the repo.

To apply this template to an existing repository, follow these steps:

1. Make sure you repository is pushed to a remote repository and you don't have any uncommitted changes.
1. You probably want to create a new branch to apply the template to.
1. Download the zip file of this repository and extract it to a temporary location.
1. Copy the contents from the extracted folder to the root of your repository, with the exception of the `custom` folder (you should already have a folder for the module you're working with).
    - Depending on what you already have, this will overwrite some files in your repository, and it will discard some configuration you might want to keep, but we'll review those in a later step and recover them if necessary using git.
1. Review and update the `.iqgeorc.jsonc` file to match your project settings and dependencies.
1. Ensure you have the IQGeo VSCode extension installed. It's available in the Extensions Marketplace.
1. Run the IQGeo VSCode extension command "IQGeo Update Project Files". You can right click the `.iqgeorc.jsonc` file or its contents to get the command in the context menu.
1. Review the changes made by the tool, adjust them if required.
1. Using a git client, review the changes made to the repository
    - recover (discard changes) that remove lines required for your specific project, like specific environment variables or specific commands in dockerfiles
    - recover (discard the removel) additional entrypoint files you still need for you project
    - try to keep as close to the template as possible, as this will make it easier to update the project in the future
1. Update other files for your project/product/module (see sections below for guidance).
1. Test the changes and make required adjustments by executing the dev environment
    - The dev environment is configured to use Keycloak for authentication. This requires you to add an entry to your hosts file to resolve the Keycloak URL to your local machine. Add the following line to your system's `hosts` file:
      `keycloak 127.0.0.1`
    - execute the dev environment by running: `docker compose -f ".devcontainer/docker-compose.yml" up -d --build `.
    - add any necessary entrypoints to `.devcontainer/entrypoint.d` and `deployment/entrypoint.d` for your modules or the product modules
1. Commit and push your changes to the branch and ask others to review and/or test.

## Review Additional Files

After your initial setup you should review and update the following files to ensure that the project is properly configured for your needs:

### .devcontainer/README.md

1. Within the `.devcontainer/README.md `, Update the module name and database name to match your project's module and database name.
2. If there are any specific tasks that need to be run to build the database once the development container is running, add them to the `.devcontainer/README.md` file. This will ensure that other developers working on the project know how to build the database.

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

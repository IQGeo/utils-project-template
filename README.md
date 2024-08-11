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
1. Review and update the `.iqgeorc.jsonc` file to match your project settings and dependencies. Check section [Notes on Product modules](#notes-on-product-modules) for additional requirements for some modules.
1. Ensure you have the IQGeo VSCode extension installed. It's available in the Extensions Marketplace.
1. Run the IQGeo VSCode extension command "IQGeo Update Project Files". You can right click the `.iqgeorc.jsonc` file or its contents to get the command in the context menu.
1. Review the changes made by the tool, adjust them if required, and commit them to your repository.
1. Update other files for your project/product/module (see sections below for guidance).
1. Test the changes and make required adjustments by executing the dev environment
    - The dev environment is configured to use Keycloak for authentication. This requires you to add an entry to your hosts file to resolve the Keycloak URL to your local machine. Add the following line to your system's `hosts` file:
      `127.0.0.1    keycloak.local`
    - authenticate with docker registry: `docker login harbor.delivery.iqgeo.cloud`
        - you will need to obtain your CLI secret (password) from your user profile found in harbor: https://harbor.delivery.iqgeo.cloud
    - execute the dev environment by running: `docker compose -f ".devcontainer/docker-compose.yml" --profile iqgeo up -d --build `.
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
1. Review and update the `.iqgeorc.jsonc` file to match your project settings and dependencies. Check section [Notes on Product modules](#notes-on-product-modules) for additional requirements for some 
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
      `127.0.0.1    keycloak.local`
    - execute the dev environment by running: `docker compose -f ".devcontainer/docker-compose.yml" --profile iqgeo up -d --build `.
    - add any necessary entrypoints to `.devcontainer/entrypoint.d` and `deployment/entrypoint.d` for your modules or the product modules
1. Commit and push your changes to the branch and ask others to review and/or test.

## Notes on Product modules

The `.iqgeorc.jsonc` provides a way to specify IQGeo products to be included in the project. This is done by adding entries to the `modules` array. The file includes comments detailing the options that can be set when specifying a module.

Some modules will have additional requirements, see the following list for the requirements of each module:
### comsof:

- requires `comms` module

### comms_dev_db:

- to be used in dev environments only.  include `"devOnly": true`
- requires both `comms` and `comsof` modules
- to create the db on startup of the container (if there's no db with NMT schema) replace the contents of the file `.devcontainer/entrypoint.d/600_init_db.sh` with the following:
  
      `#!/bin/bash
      if ! myw_db $MYW_DB_NAME list versions --layout keys | grep myw_comms_schema | grep version=; then $MODULES/comms_dev_db/utils/comms_build_dev_db --database $MYW_DB_NAME fi
`

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

[Developing with Containers on Windows](https://github.com/IQGeo/utils-project-template/wiki/Developing-with-containers-on-Windows)

## Deployment

Check out the [deployment README](deployment/README.md) for instructions on how to build and run the deployment environment.

## Container images hierarchy

The following diagram illustrates the container images generated generate and used by their dependencies. Images in blue are provided by Engineering. Images in red are to be used in the deployment of the project.

```mermaid
flowchart TD
 subgraph subgraph_hd9f8vtkt["Project"]
    H["`project_build
    (intermediate)`"]
    M["`project_devenv
    (devcontainer)`"]
    K["`project_appserver
    (web server)`"]
    L["`project_tools
    (workers)`"]
    J(["Project code"])
  end
    E["platform_appserver"]
    F["platform_tools"]
    N["platform_build"]
    G["devenv"]
    I[["Product Modules"]]
    N --> H
    I --> H & M
    J --> H & M
    E --> K
    H --> K & L
    F --> L
    G --> M
    style E fill:#2962FF,color:#FFFFFF
    style F fill:#2962FF,color:#FFFFFF
    style N fill:#2962FF,color:#FFFFFF
    style G fill:#2962FF,color:#FFFFFF
    style I fill:#2992FF,color:#FFFFFF,stroke-width:2px,stroke-dasharray: 2
    style H fill:#FFAD60,color:#FFFFFF
    style M fill:#FF6D00,color:#FFFFFF
    style J fill:#FF6D00,color:#FFFFFF
    style K fill:#D50000,color:#FFFFFF
    style L fill:#D50000,color:#FFFFFF

```

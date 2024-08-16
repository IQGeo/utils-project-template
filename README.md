# Template repo for an IQGeo project/product/module

This template provides a starting point for creating a new IQGeo project/product/module.
It includes the following:

-   Development environment
    -   dev container definitions
    -   VSCode tasks, settings and recommended extensions.
-   Deployment configuration
    -   container image definitions optimised for deployment
    -   example docker-compose and instructions to build and run deployment docker containers

## Table of Contents

- [Template repo for an IQGeo project/product/module](#template-repo-for-an-iqgeo-projectproductmodule)
  - [Table of Contents](#table-of-contents)
  - [Template Usage](#template-usage)
    - [Create a new repository from this template](#create-a-new-repository-from-this-template)
    - [Apply this template to an existing repository](#apply-this-template-to-an-existing-repository)
  - [Configuring the project](#configuring-the-project)
    - [Notes on Product modules](#notes-on-product-modules)
      - [comsof:](#comsof)
      - [comms\_dev\_db:](#comms_dev_db)
    - [Updating the project files using the IQGeo VSCode extension](#updating-the-project-files-using-the-iqgeo-vscode-extension)
    - [Testing the configuration](#testing-the-configuration)
      - [Keycloak configuration](#keycloak-configuration)
      - [Harbor authentication](#harbor-authentication)
      - [Launching the containers of the dev environment](#launching-the-containers-of-the-dev-environment)
      - [Adjust entrypoints](#adjust-entrypoints)
      - [Launching the container connected to VSCode](#launching-the-container-connected-to-vscode)
      - [Commit and push](#commit-and-push)
  - [Review Additional Files](#review-additional-files)
    - [.devcontainer/README.md](#devcontainerreadmemd)
  - [Updating this Readme](#updating-this-readme)
  - [Container images hierarchy](#container-images-hierarchy)



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
1. Skip to section [Configuring the project](#configuring-the-project) to configure the project.

### Apply this template to an existing repository

The following steps assume the repository has a folder for any IQGeo module, for example `custom`, if not, first make this adjustment to the structure of the repo.

To apply this template to an existing repository, follow these steps:

1. Make sure you repository is pushed to a remote repository and you don't have any uncommitted changes.
1. You probably want to create a new branch to apply the template to.
2. Apply the template to your repository:
    - If you have the IQGeo VSCode extension installed, you can use the command "IQGeo Pull and merge files from project-template" to apply the template to your repository.
    - If you don't have the extension installed, you can download the zip file of this repository and extract it to a temporary location. Then copy the contents from the extracted folder to the root of your repository, with the exception of the `custom` folder (you should already have a folder for the module you're working with).
1. Review changes. Depending on what you already have, this will overwrite some files in your repository, and it will discard some configuration you might want to keep, but we'll review those in a later step and recover them if necessary using git.
1. Follow the steps in following section [Configuring the project](#configuring-the-project) to configure the project.


## Configuring the project

To configure the project you'll review and update the `.iqgeorc.jsonc` file to match your project settings and dependencies. 
First check the following section for additional requirements for some modules.


### Notes on Product modules

The `.iqgeorc.jsonc` provides a way to specify IQGeo products to be included in the project. This is done by adding entries to the `modules` array. The file includes comments detailing the options that can be set when specifying a module.

Some modules will have additional requirements, see the following list for the requirements of each module:

#### comsof:

- requires `comms` module to be included in the project as well

#### comms_dev_db:

- to be used in dev environments only.  include `"devOnly": true` in the properties for this module in the `.iqgeorc.jsonc` file
- requires both `comms` and `comsof` modules to be included in the project as well
- to create the db on startup of the container (if there's no db with NMT schema) replace the contents of the file `.devcontainer/entrypoint.d/600_init_db.sh` with the following:
  
      #!/bin/bash
      if ! myw_db $MYW_DB_NAME list versions --layout keys | grep myw_comms_schema | grep version=; then $MODULES/comms_dev_db/utils/comms_build_dev_db --database $MYW_DB_NAME; fi

### Updating the project files using the IQGeo VSCode extension

1. Ensure you have the [IQGeo VSCode extension](https://marketplace.visualstudio.com/items?itemName=IQGeo.iqgeo-utils-vscode) installed. It's available in the Extensions Marketplace.
1. Run the IQGeo VSCode extension command "IQGeo Update Project Files". You can right click the `.iqgeorc.jsonc` file or its contents to get the command in the context menu.
1. Using a git client, review the changes made to the repository
    - recover (discard changes) that remove lines required for your specific project, for example, specific environment variables or specific commands in dockerfiles
    - recover (discard the removal of) additional entrypoint files you still need for you project
    - try to keep as close to the template as possible, as this will make it easier to update the project in the future
1. Commit the changes to the repository
2. Test the changes and make required adjustments  - follow section [Testing the configuration](#testing-the-configuration)
   

### Testing the configuration

This section describes how to test the configuration using the development environment. 
Note: when using a remote host (development server), you'll need to follow the [instructions for the development environment on the remote host](.devcontainer/remote_host/README.md). 

#### Keycloak configuration

The dev environment is configured to use Keycloak for authentication. This requires you to add an entry to your hosts file to resolve the Keycloak URL to your local machine. Add the following line to your system's `hosts` file:
      `127.0.0.1    keycloak.local`

#### Harbor authentication

Authenticate with docker registry: `docker login harbor.delivery.iqgeo.cloud`
You will need to obtain your CLI secret (password) from your user profile found in harbor: https://harbor.delivery.iqgeo.cloud

#### Launching the containers of the dev environment

To launch the containers of the dev environment run: 

        `docker compose -f ".devcontainer/docker-compose.yml" --profile iqgeo up -d --build `.

The main process of the container runs as the `www-data` user but to run commands you should use the `iqgeo` user. To do this run: 

        `docker exec -u iqgeo -it <container_name>  bash`

<container_name> will be `iqgeo_<prefix>` where `<prefix>` is the value of prefix in the `.iqgeorc.jsonc` file. If you haven't updated it, it will be `iqgeo_myproj`


#### Adjust entrypoints

Add any necessary entrypoints to `.devcontainer/entrypoint.d` and `deployment/entrypoint.d` for your modules or the product modules

#### Launching the container connected to VSCode

To launch the container connected to VSCode, open the command palette in VSCode. Then search for and select `Remote-Containers: Reopen in Container`. This will open a new VSCode window connected to the container.


#### Commit and push

After successfully testing the configuration, commit and push your changes to the new repository. If this was an existing repository, ask others to review the changes and test the configuration before merging the changes to the main branch.

## Review Additional Files

After your initial setup you should review and update the following files to ensure that the project is properly configured for your needs:

### .devcontainer/README.md

1. Within the `.devcontainer/README.md `, Update the module name and database name to match your project's module and database name.
2. If there are any specific tasks that need to be run to build the database once the development container is running, add them to the `.devcontainer/README.md` file. This will ensure that other developers working on the project know how to build the database.

## Updating this Readme

Once you have followed the instructions above, you can edit this file so it becomes a Readme for your project/module/product:

-   update the sections below to describe your project
-   Replace the content of this file with the contents of the `PROJECT_README.md` file in the root of the repository, delete that file and commit the changes.
  

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
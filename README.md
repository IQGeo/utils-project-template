# Template repo for an IQGeo project/product/module

This template provides a starting point for creating a new IQGeo project/product/module.
It includes the following:

-   Development environment
    -   Dev container definitions
    -   VS Code tasks, settings and recommended extensions
-   Deployment configuration 
    -   Container image definitions optimised for deployment
    -   Example docker-compose and instructions to build and run deployment docker containers

The  `.iqgeorc.jsonc` file is used to configure both the development environment and the deployment setup.

>**Note:** The root folder contains two readme files.
>- The README.md file (this file) is intended for the person creating a new project from the template. It explains how to clone the repo and configure the project.
>- The PROJECT_README.md file is meant to replace the initial README after you customize your project. In the PROJECT_README.md file, describe your environment and customizations, and save it as README.md. Use the new README as an onboarding guide for other team members who join the project. It should include:
>    - Project-specific details (such as included modules and environment settings).
>    - Links to deployment instructions and customization information.
>    - Context for ongoing development.

## Contents

[Template repo for an IQGeo project/product/module](#template-repo-for-an-iqgeo-projectproductmodule)
  
  - [Template Usage](#template-usage)
    - [Create a new repository from this template](#create-a-new-repository-from-this-template)
    - [Apply this template to an existing repository](#apply-this-template-to-an-existing-repository)
  - [Configure the project](#configure-the-project)
    - [Product module requirements](#product-module-requirements)
    - [Update the project files using the IQGeo Utils VS Code extension](#update-the-project-files-using-the-iqgeo-utils-vs-code-extension)
    - [Test the configuration](#test-the-configuration)
      - [Keycloak configuration](#keycloak-configuration)
      - [Harbor authentication](#harbor-authentication)
      - [Launch the development environment containers](#launch-the-development-environment-containers)
      - [Adjust entrypoints (optional)](#adjust-entrypoints-optional)
      - [Launch the container connected to VS Code](#launch-the-container-connected-to-vs-code)
      - [Commit and push changes](#commit-and-push)
  - [Review other README files](#review-other-readme-files)
  - [Update this Readme](#update-this-readme)
  - [Container images hierarchy](#container-images-hierarchy)



---

## Template usage

You can use this template to:
- Create a new repository for an IQGeo project/product/module.
- Apply the template to an existing repository.

### Create a new repository from this template

1. Click **Use this template** at the top of the repository page.
1. Select **Create a new repository**.
1. Provide a name and description for your new repository.
1. Clone your new repository to your local machine.

    Alternatively, download the repository as a zip file and extract it to your local machine.

1. Create an initial commit.
1. Follow the steps in the section [Configure the project](#configure-the-project).

### Apply this template to an existing repository

>**Note:** Your repository must have a folder for IQGeo modules, for example `custom`. Set up this structure *before* you apply the template.

1. Make sure your repository is pushed to a remote repository and that all changes are committed.
1. We recommend that you create a new branch to apply the template to.
1. Install the VS Code extension IQGeo Utils (optional). The extension is available from the Visual Studio Marketplace: [IQGeo Utils extension](https://marketplace.visualstudio.com/items?itemName=iqgeo.utils)
1. Do you have the IQGeo Utils VS Code extension installed?
   - If *yes*, use the command **IQGeo Pull and merge files from project-template** to apply the template to your repository.
   - If *no*, you can download the zip file of the project repository and extract it to a temporary location. Copy the contents from the extracted folder to the root of your repository, *except* the `custom` folder (you should already have a folder for the module you're working with in your existing repository).
1. Applying the template might overwrite some files in your repository. Review all changes. If there is configuration that you want to keep, you can recover it using git (described in the section [Update the project files using the IQGeo Utils VS Code extension](#update-the-project-files-using-the-iqgeo-utils-vs-code-extension)).
1. Go to the section [Configure the project](#configure-the-project).


## Configure the project

To configure the project, review and update the `.iqgeorc.jsonc` file to match your project settings and dependencies. 
Before you update the file, check the following section for module requirements.


### Product module requirements

The `.iqgeorc.jsonc` file provides a way to specify the IQGeo products to include in the project. To do this, you add entries to the `modules` array. 

For a list of product modules, their versions, and the required dependencies, see the topic:
[Module dependencies](https://github.com/IQGeo/utils-project-template/wiki/Module-dependencies).

The comms_dev_db module has additional requirements.

**comms_dev_db**

- For development environments only. In the `.iqgeorc.jsonc` file, include `"devOnly": true` in the properties for this module. 
- You must include both the `comms` and `comsof` modules in the project.
- If there's no db with an NMT schema, and you want to create the comms_dev_db on startup of the container (following deployment), replace the contents of the file `.devcontainer/entrypoint.d/600_init_db.sh` with:
  
      #!/bin/bash
      if ! myw_db $MYW_DB_NAME list versions --layout keys | grep myw_comms_schema | grep version=; then $MODULES/comms_dev_db/utils/comms_build_dev_db --database $MYW_DB_NAME; fi

### Update the project files using the IQGeo Utils VS Code extension

After you edit the `.iqgeorc.jsonc` file to make it specific to your project, run the command to update project files. This automatically updates all related deployment files and maintains consistency across your project.

1. If you haven't already, install the VS Code extension IQGeo Utils (optional). The extension is available from the Visual Studio Marketplace: [IQGeo Utils extension](https://marketplace.visualstudio.com/items?itemName=iqgeo.utils)
1. Run the IQGeo Utils extension command **IQGeo Update Project from iqgeorc.jsonc**. You can right-click the `.iqgeorc.jsonc` file or its contents to get the command in the context menu.
1. Using a git client, review the changes made to the repository.
    - Recover (discard changes) that remove lines required for your specific project, for example, specific environment variables or specific commands in Dockerfiles.
    - Recover (discard the removal of) additional entrypoint files you need for your project.
    - Keep your repository as close to the template as possible. This makes it easier to update the project in the future.
1. Commit the changes.
1. Test the changes as described in the section [Test the configuration](#test-the-configuration).
   

### Test the configuration

This section describes how to test the configuration using the development environment. 
>**Note:** When using a remote host (development server), follow the [instructions for the development environment on the remote host](.devcontainer/remote_host/README.md). 

#### Keycloak configuration

The dev environment uses Keycloak for authentication. You must add an entry to your hosts file to resolve the Keycloak URL to your local machine.

Add the following line to your system's `hosts` file:

    127.0.0.1    keycloak.local

#### Harbor authentication

1. Find your CLI secret in your Harbor user profile at https://harbor.delivery.iqgeo.cloud.
1. Log in to the Harbor docker registry and enter your CLI secret when prompted:

```
docker login harbor.delivery.iqgeo.cloud
```

#### Launch the development environment containers

Run: 

    docker compose -f ".devcontainer/docker-compose.yml" --profile iqgeo up -d --build

The container runs as the `www-data` user. To run commands, you need to use the `iqgeo` user:

1. Find the prefix value in your `.iqgeorc.jsonc` file. If you haven't changed the prefix, the default value is `myproj`.
1. Run the following command, replacing `<prefix>` with the value from your `.iqgeorc.jsonc` file:

    ```
    docker exec -u iqgeo -it iqgeo_<prefix> bash
    ```



#### Adjust entrypoints (optional)

If your custom or product modules require special initialization steps on container startup (like database setup or service configuration), add those commands as scripts to the following directories:
- `.devcontainer/entrypoint.d`
- `deployment/entrypoint.d` 

#### Launch the container connected to VS Code

1. Open the Command Palette (Ctrl+Shift+P or Cmd+Shift+P).
1. Search for and select `Remote-Containers: Reopen in Container`.

   A new VS Code window opens that's connected to the container.


#### Commit and push changes

After successfully testing the configuration, commit and push your changes to the new repository. If this was an existing repository, ask others to review the changes and test the configuration before merging the changes to the main branch.

## Review other README files

After your initial setup, review and update the following files to ensure that the project is properly configured for your needs.

### .devcontainer/README.md

1. Within the `.devcontainer/README.md `, change the module name and database name to match your project.
2. If there are any specific tasks that need to be run to build the database once the development container is running, add them to the `.devcontainer/README.md` file. This ensures that other developers working on the project know how to build the database.

### deployment/README.md

This guide covers building Docker images for IQGeo Platform and deploying them using either Docker Compose (for local testing) or Kubernetes/Helm (for production and test environments).

## Update this Readme

Once you have followed all the previous instructions, edit this file so it becomes a Readme for your project/module/product. Replace the content of this file with the contents of the `PROJECT_README.md` file in the root of this repository, then delete that file and commit the changes.
  

## Container images hierarchy

The following diagram illustrates the container images generated and used by their dependencies. Images in blue are provided by Engineering. Images in red are used to deploy the project.

- The appserver image provides the runtime environment for application services.
- The tools image serves as a container for executing command line instructions and also for hosting workers for long-running tasks.

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

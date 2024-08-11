

# Project Name

Project description

- [Project Name](#project-name)
  - [Development](#development)
    - [Running a dev environment on windows.](#running-a-dev-environment-on-windows)
  - [Deployment](#deployment)
  - [Container images hierarchy](#container-images-hierarchy)

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
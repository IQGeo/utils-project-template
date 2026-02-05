>**Note:** The PROJECT_README.md file is meant to replace the initial README after you customize your project. In the PROJECT_README.md file, describe your environment and customizations, and save it as README.md. Use the new README as an onboarding guide for other team members who join the project. It should include:
> - Project-specific details (such as included modules and environment settings).
> - Links to deployment instructions and customization information.
> - Context for ongoing development.

The following content serves as a template for your own project information.



# Project Name

Project description

- [Project Name](#project-name)
  - [Development](#development)
    - [Build and run a development environment](#build-and-run-a-development-environment)
    - [Running a dev environment on Windows](#running-a-dev-environment-on-windows)
  - [Deployment](#deployment)
    - [Kubernetes/Helm deployment](#kuberneteshelm-deployment)
    - [Docker Compose deployment](#docker-compose-deployment)
  - [Container images hierarchy](#container-images-hierarchy)

## Development

### Build and run a development environment

See the [development README](.devcontainer/README.md) for instructions on how to build and run the development environment.

### Running a dev environment on Windows

Using host-bound volumes when running Linux containers on a Windows host comes with considerable overhead, to the point that using `myw_product build` and `myw_product watch` within a container becomes impractical.

We recommend instead that you **check out and access your source code within WSL2**. The following Wiki topic provides detailed steps.

[Developing with Containers on Windows](https://github.com/IQGeo/utils-project-template/wiki/Developing-with-containers-on-Windows)

This is the most efficient way to work in a Windows environment without the need to access the Windows host.



## Deployment

For comprehensive deployment instructions, including Kubernetes/Helm and Docker Compose deployment options, see the [deployment README](deployment/README.md).

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
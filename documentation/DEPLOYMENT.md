# Application Deployment

## Steps

The workflow sequence for files under `.github/workflows` is as follows:

1. `packer.yml` builds the base NixOS image and pushes it to DigitalOcean
2. `terraform.yml` provisions cloud infrastructure on DigitalOcean
3. `nixos.yml` ensurse the desired NixOS configuration is deployed to the prod instance
4. `application.yml` deploys the application code to prod

## Flow

``` mermaid
graph TD
    A[Packer.yml] -->|Build and Deploy Image| B[Terraform.yml]
    B -->|Provision DigitalOcean Infrastructure| C[Nixos.yml]
    C -->|Configure NixOS on Prod Instance| D[Application.yml]
    D -->|Deploy Application Code| E[Deployment Complete!]
```

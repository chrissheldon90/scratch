# Automating The Creation Of Azure DevOps Service Connections.

## Problem

An Azure Devops Service Connection is a great way of connecting securely to 3rd party services or Azure Subscriptions from Azure Devops Pipelines, this is a very common and essential use of CI/CD tools and is generally overlooked and taken for granted. In a large organisation, it is normal to have multiple projects, multiple 3rd party resources and multiple subscriptions. The problems this cretes are;

1. Multiple people need to share credentials to set up these Service Connections.
2. If people have owner on an Azure Subscription, a Service Connection can be created with an automated and unmanaged Service Principle (Azure Application)
3. If the creation of Service Connections arnt managed, then it can be hard to know who has access to what and be a security problem.

## Solution

To solve this problen, we can do the following;

1. Lock down the creation of Service Connections via AD Groups
2. Store all service connecions in a "central" GIT repository
3. Create a PR Approval process for the creation of additional Service Connections
4. Create a process and pipeline to "manage" the service connections.

##Tools

### Azure Devops Permissions 

This allows us to create group based privelages to Lockdown the Service Connections via AD groups. Policies can then be configured to secure Pull Requests and who can approve them in the GIT repository.

### GIT

A GIT repository is created to store JSON based Service Connections - No secrets are stored here, just Service Connection information and references to retrieve the secrets.

### Keyvault

Keyvaults are required to securly store secrets (3rd party services and Service Principals)

### Module

A code module (Based in Powershell) is created to hand the following;

1. Parse the JSON in the GIT repository.
2. Retrieve secrets for 3rd party services and resources from Keyvault
3. Create the Service Connections

### Azure Devops Pipeline

An Azure Devops Pipeline can be used to create a process to run the powershell module.
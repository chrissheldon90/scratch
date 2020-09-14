# Deploy A Containerized Azure WebApp Using Azure Pipelines & ARM

The purpose of this guide is to guide you through setting up a basic pipeline to build and deploy a containerised WebApp securely. Making use of Git, Azure Pipelines (Yaml), ARM Templates, Dotnet, Docker and giving you an idea of how you can integrate securely with Azure Resources such as SQL, Storage Accounts and KeyVault.

There are 3 parts to this;

1.  [01 - Setup-Instructions-WebApp.md] - WebApp
2.  [02 - Setup-Instructions-Database.md] - WebApp with Database
3.  [03 - Setup-Instructions-CDN.md] - WebApp with Database and CDN


Tools
-----

Before you begin, it is recommended to install and use the following tools;

1.  [GIT](https://git-scm.com/downloads) - [https://git-scm.com/downloads](https://git-scm.com/downloads)
    
2.  [VS Code](https://code.visualstudio.com/download) - [https://code.visualstudio.com/download](https://code.visualstudio.com/download) - Install the Azure Pipelines and GIT Extensions
    
3.  [Powershell Core (Version 7)](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-core-on-windows?view=powershell-7) - [https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-core-on-windows?view=powershell-7](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-core-on-windows?view=powershell-7)
    
4.  [Dotnet (Version 3.1)](https://dotnet.microsoft.com/download) - [https://dotnet.microsoft.com/download](https://dotnet.microsoft.com/download)
    
5.  [Docker](https://docs.docker.com/engine/install/) - [https://docs.docker.com/engine/install/](https://docs.docker.com/engine/install/)
    
6.  [Azure Powershell](https://docs.microsoft.com/en-us/powershell/azure/install-az-ps?view=azps-4.6.0) - [https://docs.microsoft.com/en-us/powershell/azure/install-az-ps?view=azps-4.6.0](https://docs.microsoft.com/en-us/powershell/azure/install-az-ps?view=azps-4.6.0)
    
7.  [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest) - [https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
    

Pre-Requisites
--------------

### Azure Container Registry

A container registry allows us to store our images, then our consumers can easily access the images when required. To create an Azure Container Registry follow these simple steps using the Azure CLI;

*   Open a command or terminal window
    
*   Login to Azure
    

> az login

*   Select your subscription
    

> az account set -s ‘SubscriptionName’

*   Create your Azure Container Registry
    

> az acr create --name ‘ProvideAName’ --resource-group ‘ProvideAName-rg’ --sku Basic

### Service Connections

Service Connections are a great way for Azure Devops to securely connect to external tools, such as container registries and Azure Subscriptions. For our process, we need 2 service connections. For each service connection, do the following;

1.  In a Web Browser, go to Azure Devops - [https://dev.azure.com/](https://dev.azure.com/)\[Org Name\]
    
2.  Click on the project.
    
3.  Click the settings (gear) icon on the bottom left hand corner of the web page.
    
4.  Under Pipelines, click “Service connections”
    
5.  Click New service connection.
    

For the Azure Subscription service connection, in the new window choose “Azure Resource Manager” and click next, for Authentication method, choose “Service principal (automatic)” and click next.

Before you fill in the next details, you need to know the subscription name you are deploying your resources to. You also need to be logged into Azure DevOps with a user account which has “Owner” privileges at subscription level.

Now choose the subscription in the drop down, leave resource group blank. Give the service connection a name (same as the subscription is fine). “Grant access permission to all pipelines” will be ticked by default, you may untick this if you want to be prompted when you use this in a pipeline for the first time. Click save.

For the Container Registry service connection, repeat the steps above. In the new window, choose “Docker Registry” and click next, set Registry Type to “Azure Container Registry” choose the subscription you create the ACR in above and then choose the ACR you created above. Give the service connection a name (same as the the ACR is fine). “Grant access permission to all pipelines” will be ticked by default, you may untick this if you want to be prompted when you use this in a pipeline for the first time. Click save.

Code Repository
---------------

To start with, we will need a code repository. Azure Devops comes with it’s own version of GIT, which is what we will use.

1.  In a Web Browser, go to Azure Devops - [https://dev.azure.com/](https://dev.azure.com/)\[Org Name\]
    
2.  Click on the project.
    
3.  Click Repos - Files. At the top there is a path, click the arrow at the end of the path and click “New Repository”
    
    ![](https://automitgroup.atlassian.net/wiki/download/attachments/229382/2020-08-28%20(2).png?api=v2)
4.  A window will pop up;
    
    1.  Repository type - This should be “Git”
        
    2.  Repository name - This is your choice, a good naming convention could be “\[org\_name\]-\[project\_name\]-\[app\_name\]” this is good as its the folder name used when people clone the repository, and what you will see in Azure Devops.
        
    3.  Add a README - Tick this box, we can use this later on.
        
    4.  Click create
        
5.  Clone the repository, by clicking Clone. A window will pop up. You can copy the URL manually, is click “Clone in VS Code”
    
6.  You may be asked to run a downloaded file, or it may bring VS Code straight up. You should then be asked to select a folder. Feel free to select “Documents” or create your own folder and click “Select Repository Location” and click ok
    
7.  VS Code will then clone the repository and ask you if you would like to Open. Click “Open”
    

We are now ready to start adding our code. This tutorial does not go into details about created a dotnet core app, it assumes you already have one. Therefore the next part of the tutorial will carry on after the dotnet app source code has been copied to this repository.

Further Learning
----------------

There are a lot more considerations for this type process which are not in the scope of this walkthrough, in order to get full advantage of Azure Devops and Azure itself. Feel free to look into the following to improve the process;

1.  Lint testing - For the pipeline process / ARM Templates
    
2.  Code Coverage Checks
    
3.  Acceptance / Integration / Performance Tests - These can be introduced for further environment deployments
    
4.  Azure Devops Pipeline Templates - For Steps & Variables
    
5.  Git branching.
    
6.  Slot Deployments - To allow an uninterruptible deployment
    
7.  Container Security Scanning - Using tools like Snyk or Aquasec, we can scan our image in our pipeline prior to it being pushed to the Azure Container Registry
    
8.  Application Level Logging - With Log Analytics
    
9.  Managed Identities - With Web Apps and Keyvault

10. Azure Application Gateway or Azure Frontdoor for securing your applications further
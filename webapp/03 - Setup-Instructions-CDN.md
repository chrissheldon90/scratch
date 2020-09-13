The purpose of this guide is to guide you through adding an Azure CDN to your deployment to give your WebApp a gateway / frontend. This follows directly on from "01 - Setup-Instructions-WebApp.md" and is a pre-requisite.

*   [Tools](#DeployAContainerizedDotnetAzureWebAppUsingAzurePipelines-Tools)
*   [Pre-Requisites](#DeployAContainerizedDotnetAzureWebAppUsingAzurePipelines-Pre-Requisites)
    *   [Azure Container Registry](#DeployAContainerizedDotnetAzureWebAppUsingAzurePipelines-AzureContainerRegistry)
    *   [Service Connections](#DeployAContainerizedDotnetAzureWebAppUsingAzurePipelines-ServiceConnections)
*   [Code Repository](#DeployAContainerizedDotnetAzureWebAppUsingAzurePipelines-CodeRepository)
*   [Create Dockerfile](#DeployAContainerizedDotnetAzureWebAppUsingAzurePipelines-CreateDockerfile)
    *   [Dockerfile](#DeployAContainerizedDotnetAzureWebAppUsingAzurePipelines-Dockerfile)
    *   [Initialise.sh](#DeployAContainerizedDotnetAzureWebAppUsingAzurePipelines-Initialise.sh)
*   [Pipeline](#DeployAContainerizedDotnetAzureWebAppUsingAzurePipelines-Pipeline)
    *   [Pipeline Start](#DeployAContainerizedDotnetAzureWebAppUsingAzurePipelines-PipelineStart)
    *   [Build Pipeline](#DeployAContainerizedDotnetAzureWebAppUsingAzurePipelines-BuildPipeline)
    *   [Deployment Pipeline](#DeployAContainerizedDotnetAzureWebAppUsingAzurePipelines-DeploymentPipeline)
*   [Azure Resource Manager Template](#DeployAContainerizedDotnetAzureWebAppUsingAzurePipelines-AzureResourceManagerTemplate)
    *   [Template.json](#DeployAContainerizedDotnetAzureWebAppUsingAzurePipelines-Template.json)
    *   [Parameters.json](#DeployAContainerizedDotnetAzureWebAppUsingAzurePipelines-Parameters.json)
*   [Commit Your Code](#DeployAContainerizedDotnetAzureWebAppUsingAzurePipelines-CommitYourCode)
*   [Create Your Pipeline](#DeployAContainerizedDotnetAzureWebAppUsingAzurePipelines-CreateYourPipeline)
*   [Further Learning](#DeployAContainerizedDotnetAzureWebAppUsingAzurePipelines-FurtherLearning)
*   [Related articles](#DeployAContainerizedDotnetAzureWebAppUsingAzurePipelines-Relatedarticles)

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
    

Pipeline
--------

A pipeline is what does all the work so you don't have to, from; building your dotnet app, building the dockerfile, testing and finally deploying your code from Dev to Production. It’s the bread and butter of DevOps. In this tutorial we are making use of Azure Pipelines Yaml based pipelines only.

This is a rather large part of the tutorial, so it is split. We will be working on the same part in both stages as there is no need for two separate pipelines.

### Pipeline Start


### Build Pipeline


### Deployment Pipeline


### Template.json


### Parameters.json



Commit Your Code
----------------

Finally, it is time to commit your code, before doing this, it is advisable to go through all the files to ensure there are no typos. If you installed the pre-requisites, they have built in Lint checking tools which should highlight any issues to you. To commit your code, do the following;

1.  Open a command or terminal window
    
2.  Change directory to the folder you clones your Git repository to at the start of this tutorial - “cd \[PATH\]”
    
3.  Now type and enter the following commands to commit the code.
    

> git add .
> 
> git commit -m “A commit message, this can be a simple explanation of what your are adding”
> 
> git push

Create Your Pipeline
--------------------

Now the code is committed, we are ready to create our pipeline, do the following;

1.  In a Web Browser, go to Azure Devops - [https://dev.azure.com/](https://dev.azure.com/)\[Org Name\]
    
2.  Click on the project.
    
3.  Click Pipelines
    
4.  Click “New pipeline”
    
5.  Choose “Azure Repos Git”
    
6.  Click the Git repository you created above.
    
7.  Click “Existing Azure Pipelines YAML file”
    
8.  In the new window, the default branch should be selected by default, then in the Path dropdown choose your pipeline file (azure-pipeline.yaml) and click continue.
    
9.  Now click Run. This will save your pipeline for easy reuse and kick off the process of building your code, deploying and provisioning of your brand new web app.
    
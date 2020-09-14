# WebApp Instructions

*   [Tools](#Tools)
*   [Create Dockerfile](#CreateDockerfile)
    *   [Dockerfile](#Dockerfile)
    *   [Initialise.sh](#Initialise.sh)
*   [Pipeline](#Pipeline)
    *   [Pipeline Start](#PipelineStart)
    *   [Build Pipeline](#BuildPipeline)
    *   [Deployment Pipeline](#DeploymentPipeline)
*   [Azure Resource Manager Template](#AzureResourceManagerTemplate)
    *   [web-template.json](#web-template.json)
    *   [web-parameters.json](#web-parameters.json)
*   [Commit Your Code](#CommitYourCode)
*   [Create Your Pipeline](#CreateYourPipeline)
*   [Further Learning](#FurtherLearning)

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
    

Create Dockerfile
-----------------

A Dockerfile is what we use to create our dotnet image and any other pre-requisites we need to run our application.

1.  In VS Code, click View - Explorer, you should now see the root of your repository on the left hand side.
    
2.  Right click, click New File and call it “Dockerfile”
    
3.  Feel free to copy the sample below Dockerfile, there may be more we want to do in the future, but for now, this will support the scope of this tutorial.
    
4.  There are two ways of doing the next bit. We can either add a `ENTRYPOINT ["dotnet", "aspnetapp.dll"]` to replace line 10-13 of the Dockefile, or we can create a separate file described in step 5 and 6
    
5.  Right click, click New File and call it “initialise.sh” this way, we can easily write further commands which will run at startup of the contain.
    
6.  Feel free to copy the sample below Initialise.sh
    

### Dockerfile

```
FROM mcr.microsoft.com/dotnet/core/sdk:3.1

EXPOSE 80 443
ENV ASPNETCORE_URLS http://+:80
ENV ASPNETCORE_ENVIRONMENT Production
ENV DOTNET_RUNNING_IN_CONTAINER=true

WORKDIR /app
COPY src/.build/release .
COPY init.sh .

RUN chmod +x ./initialise.sh
CMD /bin/bash ./initialise.sh
```

### Initialise.sh

```
#!/bin/bash
dotnet aspnetapp.dll
```

Pipeline
--------

A pipeline is what does all the work so you don't have to, from; building your dotnet app, building the dockerfile, testing and finally deploying your code from Dev to Production. It’s the bread and butter of DevOps. In this tutorial we are making use of Azure Pipelines Yaml based pipelines only.

This is a rather large part of the tutorial, so it is split. We will be working on the same part in both stages as there is no need for two separate pipelines.

### Pipeline Start

1.  In VS Code, click View - Explorer, you should now see the root of your repository on the left hand side.
    
2.  Right click, click New Folder and call it “pipeline”
    
3.  Click click on the pipeline folder and click New File, call this “azure-pipeline.yaml”
    
4.  Copy the following segment of code into your yaml file.
    

```
name: 0.1.$(Rev:r) # Sets a name of the build run, incrementing for every build
trigger:
- none # Ensures nothing triggeres automatically yet

pool:
  vmImage: 'ubuntu-latest' # Ensures the build runs on the latest of Microsoft own agent pool

variables:
  - appName: 'learn-demo-webapp' # Sets a variable we can use throughout the pipeline
```

### Build Pipeline

Add the following code to the end of the same file “azure-pipeline.yaml”

```
stages: # Splits the pipeline into stages
- stage: Build # First Stage
  displayName: 'Build'
  jobs: # Splits the stage into jobs
  - job: Build_Test_DotNet_Docker # First Job
    displayName: 'Build, Test'
    steps:
    - task: DotNetCoreCLI@2
      displayName: 'Restore Dependencies'
      inputs:
        command: restore
    - task: DotNetCoreCLI@2
      displayName: 'Build Project'
      inputs:
        arguments: '-c Release'
    - task: DotNetCoreCLI@2
      displayName: 'Run Unit Tests'
      inputs:
        command: test
    - task: Docker@2
      displayName: 'Docker Build'
      inputs:
        containerRegistry: '[Name of Docker Registry Service Connection]'
        repository: '$(appName)'
        command: 'build'
        Dockerfile: '**/Dockerfile'
        tags: '$(Build.BuildNumber)'
    - task: Docker@2
      displayName: 'Push Image'
      inputs:
        containerRegistry: '[Name of Docker Registry Service Connection]'
        repository: '$(appName)'
        command: 'push'
        tags: '$(Build.BuildNumber)'
```

This is the very first part of our pipeline which performs actions on an Azure Devops Agent;

*   Firstly we restore our project dependency packages using ‘dotnet restore’.
    
*   Then build our project by running ‘dotnet build . -c Release'.
    
*   Then run any unit tests by running ‘dotnet test’.
    
*   Then we build our docker image, by running 'docker build -f Dockerfile -t \[repository name value\]:\[tag value\].
    
*   Then we push our docker image to the Azure Container Registry by running ‘docker push \[repository name value\]:\[tag value\]’
    

### Deployment Pipeline

Add the following code to the end of the same file “azure-pipeline.yaml”

```
- stage: Deploy
  displayName: Deploy
  variables:
    ResourceGroupName: $(appName)-rg
    AcrName: [Name of your Azure Container Registry]
    AcrRGName: [Name of your Azure Container Registry Resource Group]
    parameters.image.value: "DOCKER|$(AcrName).azurecr.io/$(appName):$(Build.BuildNumber)"
    parameters.hostingPlanName.value: $(appName)-sp
    parameters.name.value: $(appName)
    parameters.dockerRegistryUrl.value: https://$(AcrName).azurecr.io
    parameters.dockerRegistryUsername.value: $(AcrName)
  jobs:
  - deployment: Deploy ARM Template
    displayName: 'Deploy Web App ARM Template'
    environment: [Environment Name]
    strategy:
      runOnce:
        deploy:
          steps:
          - task: AzureCLI@2
            displayName: 'Get Docker Registry Key'
            inputs:
              azureSubscription: '[Name of your subscription Service Connection]'
              scriptType: 'pscore'
              scriptLocation: 'inlineScript'
              inlineScript: |
                $key = az acr credential show --name $(AcrName) --resource-group $(AcrRGName) --query passwords[0].value
                $key = $key.Replace('"','')
                echo "##vso[task.setvariable variable=parameters.dockerRegistryPassword.value; issecret=true;]$key"
          - task: FileTransform@2
            displayName: 'Transform Arm Template Parameters'
            inputs:
              folderPath: '$(Pipeline.Workspace)/'
              xmlTransformationRules: 
              jsonTargetFiles: '**/web-parameters.json'
          - task: AzureResourceManagerTemplateDeployment@3
            displayName: 'Deploy WebApp'
            inputs:
              deploymentScope: 'Resource Group'
              ConnectedServiceName: '[Name of your subscription Service Connection]'
              action: 'Create Or Update Resource Group'
              resourceGroupName: '$(ResourceGroupName)'
              location: 'North Europe'
              templateLocation: 'Linked artifact'
              csmFile: '$(Pipeline.Workspace)/arm/web-web-template.json'
              csmParametersFile: '$(Pipeline.Workspace)/arm/web-web-parameters.json'
              deploymentMode: 'Incremental'
```

Once our build stage completes in our build process, the next part is the deployment. The above performs actions on an Azure Devops Agent;

*   We get the the Azure Container Registry key dynamically, allowing us to securely store and use it in the pipeline process steps only.
    
*   Then we perform a transformation on the ARM Template parameters.
    
*   Finally we deploy our ARM template.
    

Click File > Save once your pipeline changes are complete, don’t forget to update the areas in square brackets.

Azure Resource Manager Template
-------------------------------

An ARM (Azure Resource Manager) Template is a made up of JSON based files which is used to roll out resources across Azure. This is defined as Infrastructure as code. We need to create these to be able to deploy our Web App.

Firstly, we need to create a folder structure. There is no enforced rule for how you want to structure any of these files. But it can be easier to manage later down the line.

1.  In VS Code, click View - Explorer, you should now see the root of your repository on the left hand side.
    
2.  Right click, click New Folder and call it “arm”
    
3.  Click click on the arm folder and click New File, call this “web-template.json”
    
4.  Then open the file to edit.
    

This is another large part to our tutorial, so I have split the assembly of the template into sections.

### web-template.json

First of all, the top of our ARM Template defines the scheme, version and parameters. Add the following code to the start of the file “web-template.json”

```
{
    "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentweb-template.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
      "image" : {
        "type": "string",
      },
      "location": {
        "type": "string",
        "defaultValue": "[resourceGroup().location]",
        "metadata": {
          "description": "Location for all resources."
        }
      },
      "hostingPlanName": {
        "type": "string"
      },
      "name": {
        "type": "string"
      },
      "dockerRegistryUrl": {
        "type": "string"
      },
      "dockerRegistryUsername": {
        "type": "string"
      },
      "dockerRegistryPassword": {
        "type": "securestring"
      }
    },
```

We the need to start adding resources to our ARM Template, it doesn't really matter which order these resources go in, as we add dependencies to each resource, which determines the order for us.

Add the following code to the end of the same file “web-template.json”

```
  "resources": [
    {
      "apiVersion": "2018-02-01",
      "type": "Microsoft.Web/serverfarms",
      "kind": "linux",
      "name": "[parameters('hostingPlanName')]",
      "location": "[parameters('location')]",
      "properties": {
          "name": "[parameters('hostingPlanName')]",
          "numberOfWorkers": 1,
          "reserved": true
      }
      "sku": {
        "name": "[parameters('sku')]"
      }
    },
```

This is the resource code for the app service plan.

Add the following code to the end of the same file “web-template.json”

```
  {
  "apiVersion": "2018-11-01",
  "type": "Microsoft.Web/sites",
  "kind": "app,linux,container",
  "name": "[parameters('name')]",
  "location": "[parameters('location')]",
  "identity": {
    "type": "SystemAssigned"
  },
  "properties": {
    "serverFarmId": "[resourceId('Microsoft.Web/serverfarms', parameters('hostingPlanName'))]",
    "siteConfig": {
      "appSettings": [{
        "name": "DOCKER_REGISTRY_SERVER_URL",
        "value": "[parameters('dockerRegistryUrl')]"
      },
      {
        "name": "DOCKER_REGISTRY_SERVER_USERNAME",
        "value": "[parameters('dockerRegistryUsername')]"
      },
      {
        "name": "DOCKER_REGISTRY_SERVER_PASSWORD",
        "value": "[parameters('dockerRegistryPassword')]"
      },],
      "linuxFxVersion": "[parameters('image')]",
      "alwaysOn": false
    }
  },
  "dependsOn": [
    "[resourceId('Microsoft.Web/serverfarms', parameters('hostingPlanName'))]"
  ]
},
{
  "type": "Microsoft.Web/sites/config",
  "apiVersion": "2018-02-01",
  "name": "[concat(parameters('name'), '/web')]",
  "location": "[parameters('location')]",
  "dependsOn": [
    "[resourceId('Microsoft.Web/sites', parameters('name'))]"
  ],
  "properties": {
    "ipSecurityRestrictions": [
      {
        "ipAddress": "[Your IP Address]/32",
        "action": "Allow",
        "tag": "Default",
        "priority": 65000,
        "name": "Internal Access Control"
      },
      {
        "ipAddress": "Any",
        "action": "Deny",
        "priority": 2147483647,
        "name": "Deny all",
        "description": "Deny All"
      }
    ],
    "linuxFxVersion": "[parameters('image')]",
  }
},
```

In this code we are adding 2 resources, the web app itself and web app config. The config includes IP Whitelisting and is one of various ways of restricting access to a web app. This whitelist can be changed or removed, for now, add your external IP address. You can get that here - [http://ipv4.plain-text-ip.com/](http://ipv4.plain-text-ip.com/)

Finally add the following code to the end of the same file “web-template.json”

```
      {
      "name": "[concat(parameters('name'), '-kv')]",
      "type": "Microsoft.KeyVault/vaults",
      "apiVersion": "2019-09-01",
      "location": "[parameters('location')]",
      "dependsOn": [
        "[resourceId('Microsoft.Web/sites', parameters('name'))]"
      ],
      "properties": {
        "tenantId": "[subscription().tenantid]",
        "sku": {
          "family": "A",
          "name": "Standard"
        },
        "accessPolicies": [
          {
          "tenantId": "[subscription().tenantid]",
          "objectId": "[reference(concat('Microsoft.Web/sites/', parameters('name')), '2016-03-01', 'Full').identity.principalId]",
          "permissions": {
              "keys": [
                "Get",
              ],
              "secrets": [
                "Get",
              ],
              "certificates": [
                "Get",
              ]
            }
          }],
        "enabledForDeployment": "false",
        "enabledForDiskEncryption": "false",
        "enabledForTemplateDeployment": "true"
      }
    }
  ]
}
```

This last part of the ARM Template is optional, but it is a very good way of securely storing secrets which the app may need. For example, certificates or connection strings. Having the KeyVault in place like this enabled us to take advantage of managed identities and automatically gives access to the web app to the KeyVault. Save the file

### web-parameters.json

Now we need to create a parameters file.

1.  Click click on the arm folder and click New File, call this “web-parameters.json”
    
2.  Then open the file to edit.
    
3.  Add the following code and save the file.
    

```
{
    "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentweb-parameters.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "image": {
            "value": "WILL BE REPLACED"
        },
        "name": {
            "value": "WILL BE REPLACED"
        },
        "hostingPlanName": {
            "value": "WILL BE REPLACED"
        },
        "dockerRegistryUrl": {
            "value": "WILL BE REPLACED"
        },
        "dockerRegistryUsername": {
            "value": "WILL BE REPLACED"
        },
        "dockerRegistryPassword": {
            "value": "WILL BE REPLACED"
        }
    }
}
```

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
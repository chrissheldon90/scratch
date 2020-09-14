# CDN Instructions

The purpose of this guide is to guide you through adding an Azure CDN to your deployment to give your WebApp a gateway / frontend. This follows directly on from "01 - Setup-Instructions-WebApp.md" and is a pre-requisite.

*   [Tools](#Tools)
*   [Pipeline](#Pipeline)
    *   [Build Pipeline](#BuildPipeline)
    *   [Deployment Pipeline](#DeploymentPipeline)
*   [Azure Resource Manager Template](#AzureResourceManagerTemplate)
    *   [CDN-Template.json](#CDN-Template.json)
    *   [CDN-Parameters.json](#CDN-Parameters.json)
*   [Commit Your Code](#CommitYourCode)
*   [Create Your Pipeline](#CreateYourPipeline)

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

### Build Pipeline

No changes are required

### Deployment Pipeline

Add the following variables to azure-pipeline.yml

```
parameters.cdnName.value: "CDN_NAME"
parameters.customdomain.value: "YOUR_EXTERNAL_DOMAIN_NAME"
cdnResourceGroup: "YOUR_CDN_RESOURCE_GROUP"
```

Add the following to azure-pipeline.yml after the WebApp task. This is the deploy the CDN Profile and Endpoint

```
- task: AzureResourceManagerTemplateDeployment@3
  displayName: 'Deploy CDN'
  inputs:
    deploymentScope: 'Resource Group'
    ConnectedServiceName: '[Name of your subscription Service Connection]'
    action: 'Create Or Update Resource Group'
    resourceGroupName: '$(cdnResourceGroup)'
    location: 'North Europe'
    templateLocation: 'Linked artifact'
    csmFile: '$(Pipeline.Workspace)/arm/cdn-template.json'
    csmParametersFile: '$(Pipeline.Workspace)/arm/cdn-parameters.json'
    deploymentMode: 'Incremental'
```
### Optional Deployment Pipeline Changes

There are lots of things we can do with the CDN. The below are optional, but are great ways of showing how we automate certain tasks in the Azure Devops pipeline and ensure they are idempotent, outside of the ARM template.

#### Enable Custom Domain HTTPS

Add the following to azure-pipeline.yml at the end, this will enable HTTPS.

```
- task: AzureCLI@2
  displayName: 'Enable CDN Custom Domain HTTPS'
  inputs:
    azureSubscription: '[Name of your subscription Service Connection]'
    scriptType: 'pscore'
    scriptLocation: 'inlineScript'
    inlineScript: |
      $checkCommand = az cdn custom-domain list --profile-name $(cdnName) --resource-group $(cdnResourceGroup) --endpoint $(name)
      $checkMatch = ($checkCommand | ConvertFrom-Json).customHttpsProvisioningState -eq "Enabled"
      if(!$checkMatch) {
        Write-Host "CDN Custom Domain HTTPS for $(name) is not enabled. Script will enable."
        az cdn custom-domain enable-https --endpoint-name $(name) `
          --name "$(name)-$(parameters.customdomain.value)" `
          --profile-name $(cdnName) `
          --resource-group $(cdnResourceGroup)
      } else {
        Write-Host "CDN Custom Domain HTTS for $(name) is enabled."
      }
```

One really neat feature of Azure CDN is the ability to enable HTTPS on your custom domain, it will create you a certificate for your domain at no additional cost. 

#### Purge CDN Endpoint

Another useful feature is to automate purging your CDN endpoint after a deployment. This will ensure the changes deployed will go live instantly.

Add the following to azure-pipeline.yml at the end.

```
- task: AzureCLI@2
  displayName: 'Purge CDN Endpoint'
  inputs:
    azureSubscription: '[Name of your subscription Service Connection]'
    scriptType: 'pscore'
    scriptLocation: 'inlineScript'
    inlineScript: |
      az cdn endpoint purge --name "$(name)" `
          --profile-name $(cdnName) `
          --resource-group $(cdnResourceGroup) `
          --content-paths '/*' `
          --no-wait
```

### CDN-Template.json

1.  In VS Code, click View - Explorer, you should now see the root of your repository on the left hand side.
    
2.  Right click, click New Folder and call it “arm”
    
3.  Click click on the arm folder and click New File, call this "sql-template.json”
    
4.  Then open the file to edit.

First of all, the top of our ARM Template defines the scheme, version and parameters. Add the following code to the start of the file cdn-template.json”

```
{
    "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
      "name": {
        "type": "string"
      },
      "cdnName": {
        "type": "string"
      },
      "customDomain": {
        "type": "string"
      }
    },
```
We the need to start adding resources to our ARM Template, it doesn't really matter which order these resources go in, as we add dependencies to each resource, which determines the order for us.

Add the following code to the end of the same file "cdn-template.json”

```
"resources": [
      {
        "type": "Microsoft.Cdn/profiles",
        "apiVersion": "2019-12-31",
        "name": "[parameters('cdnName')]",
        "location": "Global",
        "sku": {
            "name": "Standard_Microsoft"
        },
        "properties": {}
      },
      {
        "type": "Microsoft.Cdn/profiles/endpoints",
        "apiVersion": "2019-12-31",
        "name": "[concat(parameters('cdnName'), '/', parameters('name'))]",
        "location": "Global",
        "dependsOn": [
            "[resourceId('Microsoft.Cdn/profiles', parameters('cdnName'))]"
        ],
        "properties": {
            "originHostHeader": "[concat(parameters('name'), '.azurewebsites.net')]",
            "isHttpAllowed": true,
            "isHttpsAllowed": true,
            "queryStringCachingBehavior": "IgnoreQueryString",
            "origins": [
                {
                    "name": "[concat(parameters('name'), '-azurewebsites-net)]",
                    "properties": {
                        "hostName": "[concat(parameters('name'), '.azurewebsites.net)]",
                        "originHostHeader": "[concat(parameters('name'), '.azurewebsites.net)]",
                        "priority": 1,
                        "weight": 1000,
                        "enabled": true
                    }
                }
            ],
            "optimizationType": "GeneralWebDelivery"
        }
      },
      {
        "type": "Microsoft.Cdn/profiles/endpoints/customdomains",
        "apiVersion": "2019-12-31",
        "name": "[concat(parameters('cdnName'), '/', parameters('name'), '/', parameters('customDomain'))]",
        "dependsOn": [
            "[resourceId('Microsoft.Cdn/profiles/endpoints', parameters('cdnName'), parameters('name'))]",
            "[resourceId('Microsoft.Cdn/profiles', parameters('cdnName'))]"
        ],
        "properties": {
            "hostName": "[parameters('customDomain')]"
        }
      },
      {
        "type": "Microsoft.Cdn/profiles/endpoints/origins",
        "apiVersion": "2019-12-31",
        "name": "[concat(parameters('cdnName'), '/', parameters('name'), '/', parameters('name'), '-azurewebsites-net')]",
        "dependsOn": [
            "[resourceId('Microsoft.Cdn/profiles/endpoints', parameters('cdnName'), parameters('name'))]",
            "[resourceId('Microsoft.Cdn/profiles', parameters('cdnName'))]"
        ],
        "properties": {
            "hostName": "[concat(parameters('name'), '.azurewebsites.net')]",
            "enabled": true,
            "priority": 1,
            "weight": 1000,
            "originHostHeader": "[concat(parameters('name'), '.azurewebsites.net')]"
        }
      }
    ]
  }
```

### CDN-Parameters.json

Now we need to create a parameters file.

1.  Click click on the arm folder and click New File, call this “cdn-parameters.json”
    
2.  Then open the file to edit.
    
3.  Add the following code and save the file.

```
{
    "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "name": {
            "value": ""
        },
        "cdnName": {
            "value": null
        },
        "customDomain": {
            "value": null
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
    
# Database Instructions

The purpose of this guide is to guide you through adding an Azure SQL Database to your deployment to give your WebApp a database backend. This follows directly on from "01 - Setup-Instructions-WebApp.md" and is a pre-requisite.

*   [Tools](#Tools)
*   [Pipeline](#Pipeline)
    *   [Build Pipeline](#BuildPipeline)
    *   [Deployment Pipeline](#DeploymentPipeline)
*   [Azure Resource Manager Template](#AzureResourceManagerTemplate)
    *   [SQL-Template.json](#SQL-Template.json)
    *   [SQL-Parameters.json](#SQL-Parameters.json)
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

### Build Pipeline

No changes are required

### Deployment Pipeline

Add the following variables to azure-pipeline.yml

```
SqlServerResourceGroup: "SQLSERVERRESOURCEGROUP"
parameters.administratorLogin.value: "SQLUSERNAME"
parameters.serverName.value: "SQLSERVERNAME"
parameters.databaseName.value: "SQLDATABSENAME"
parameters.collation.value:"SQL_Latin1_General_CP1_CI_AS"
parameters.maxSizeBytes.value: "2147483648"
parameters.catalogCollation.value: "SQL_Latin1_General_CP1_CI_AS"
parameters.zoneRedundant.value: "false"
parameters.readScaleOut.value: "Disabled"
parameters.numberOfReplicas.value: "0"
parameters.skuName.value: "Basic"
parameters.tier.value: "Basic"
```

Add the following to azure-pipeline.yml before the WebApp task. This is the deploy the SQL Server & Database

```
- task: AzureResourceManagerTemplateDeployment@3
  displayName: 'Deploy SQL Server & Database'
  inputs:
    deploymentScope: 'Resource Group'
    ConnectedServiceName: '[Name of your subscription Service Connection]'
    action: 'Create Or Update Resource Group'
    resourceGroupName: '$(SqlServerResourceGroup)'
    location: 'North Europe'
    templateLocation: 'Linked artifact'
    csmFile: '$(Pipeline.Workspace)/arm/sql-template.json'
    csmParametersFile: '$(Pipeline.Workspace)/arm/sql-parameters.json'
    deploymentMode: 'Incremental'
```

Add the following to azure-pipeline.yml after the WebApp task. This is to allow the WebApp access to the SQL Server using its managed identity;

```
- task: AzureCLI@2
  displayName: 'Set SQL Server Permissions'
  inputs:
    azureSubscription: ${{ variables.SqlAzureSubscription }}
    scriptType: 'pscore'
    scriptLocation: 'inlineScript'
    inlineScript: |
      $webAppIdentityObjectIdJs = '$(webAppIdentityObjectId)'
      $objectId = ($webAppIdentityObjectIdJs | ConvertFrom-Json).webAppIdentityObjectId.value
      az sql server ad-admin create --resource-group $(SqlServerResourceGroup) --server-name $(serverName) --display-name $(appName) --object-id $objectId
```


### Web-Template.json

Add the following to the web-template.json file, this is to provide an output variable of the WebApp's identity, to set up permissions for resources outside of the WebApp's resource group.

```
,
"outputs": {
  "webAppIdentityObjectId": {
      "value": "[reference(concat('Microsoft.Web/sites/', parameters('name')), '2016-03-01', 'Full').identity.principalId]",
      "type": "string"
  }
}
```

### SQL-Template.json

1.  In VS Code, click View - Explorer, you should now see the root of your repository on the left hand side.
    
2.  Right click, click New Folder and call it “arm”
    
3.  Click click on the arm folder and click New File, call this "sql-template.json”
    
4.  Then open the file to edit.

First of all, the top of our ARM Template defines the scheme, version and parameters. Add the following code to the start of the file “sql-template.json”

```
{
  "$schema": "http://schema.management.azure.com/schemas/2014-04-01-preview/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
      "administratorLogin": {
          "type": "string"
      },
      "administratorLoginPassword": {
          "type": "securestring"
      },
      "location": {
          "type": "string"
      },
      "serverName": {
          "type": "string"
      },
      "databaseName": {
          "type": "string"
      },
      "collation": {
          "type": "string"
      },
      "maxSizeBytes": {
          "type": "string"
      },
      "catalogCollation": {
          "type": "string"
      },
      "zoneRedundant": {
          "type": "string"
      },
      "readScaleOut": {
          "type": "string"
      },
      "numberOfReplicas": {
          "type": "string"
      },
      "skuName": {
          "type": "string"
      },
      "tier": {
          "type": "string"
      }
  },
```

We the need to start adding resources to our ARM Template, it doesn't really matter which order these resources go in, as we add dependencies to each resource, which determines the order for us.

Add the following code to the end of the same file “sql-template.json”

```
,
    "variables": {
        "subscriptionId": "[subscription().subscriptionId]",
        "resourceGroupName": "[resourceGroup().name]",
        "uniqueStorage": "[uniqueString(variables('subscriptionId'), variables('resourceGroupName'), parameters('location'))]",
        "storageName": "[tolower(concat('sqlva', variables('uniqueStorage')))]"
    },
    "resources": [
        {
            "apiVersion": "2015-05-01-preview",
            "type": "Microsoft.Sql/servers"
            "location": "[parameters('location')]",
            "name": "[parameters('serverName')]",
            "properties": {
                "administratorLogin": "[parameters('administratorLogin')]",
                "administratorLoginPassword": "[parameters('administratorLoginPassword')]",
                "version": "12.0"
            }            
        },
        {
          "type": "Microsoft.Sql/servers/databases",
          "apiVersion": "2017-10-01-preview",
          "location": "[parameters('location')]",
          "name": "[concat(parameters('serverName'), '/', parameters('databaseName'))]",
          "dependsOn": [
            "[concat('Microsoft.Sql/servers/', parameters('serverName')))]"
          ],
          "properties": {
              "collation": "[parameters('collation')]",
              "maxSizeBytes": "[parameters('maxSizeBytes')]",
              "catalogCollation": "[parameters('catalogCollation')]",
              "zoneRedundant": "[parameters('zoneRedundant')]",
              "readScale": "[parameters('readScaleOut')]",
              "readReplicaCount": "[parameters('numberOfReplicas')]"
          },
          "sku": {
              "name": "[parameters('skuName')]",
              "tier": "[parameters('tier')]",
              "capacity": 5
          }
        }
    ]
}
```

### SQL-Parameters.json

Now we need to create a parameters file.

1.  Click click on the arm folder and click New File, call this “web-parameters.json”
    
2.  Then open the file to edit.
    
3.  Add the following code and save the file.

```
{
    "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "administratorLogin": {
            "value": ""
        },
        "administratorLoginPassword": {
            "value": null
        },
        "location": {
            "type": "string",
            "defaultValue": "[resourceGroup().location]",
            "metadata": {
              "description": "Location for all resources."
            }
          },
        "serverName": {
            "value": ""
        },
        "databaseName": {
            "value": ""
        },
        "collation": {
            "value": ""
        },
        "maxSizeBytes": {
            "value": ""
        },
        "catalogCollation": {
            "value": ""
        },
        "zoneRedundant": {
            "value": ""
        },
        "readScaleOut": {
            "value": ""
        },
        "numberOfReplicas": {
            "value": ""
        },
        "skuName": {
            "value": ""
        },
        "tier": {
            "value": ""
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
    
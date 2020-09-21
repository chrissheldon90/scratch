# High Availability and Front Door Instructions

The purpose of this guide is to guide you through transforming your deploying to deploy to multiple regions making it highly available, and using Azure Front Door for CDN, Security and Load balancing to give your WebApp a gateway / frontend. By default the pipeline and ARM templates will deploy the webapp to North Europe and West Europe, the load balancer with Azure Front Door will have a backend pool which will point to these WebApps.


This follows directly on from "01 - Setup-Instructions-WebApp.md" and is a pre-requisite.

*   [Tools](#Tools)
*   [Pipeline](#Pipeline)
    *   [Build Pipeline](#BuildPipeline)
    *   [Deployment Pipeline](#DeploymentPipeline)
*   [Azure Resource Manager Template](#AzureResourceManagerTemplate)
    *   [Waffd-Template.json](#Waffd-Template.json)
    *   [Waffd-Parameters.json](#Waffd-Parameters.json)
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
parameters.wafPolicyName.value: "WAF_POLICY_NAME"
parameters.frontDoorName.value: "YOUR_FRONT_DOOR_NAME"
parameters.appNameEun.value: $(appName)-eun
parameters.appNameEuw.value: $(appName)-euw
waffdResourceGroup: "YOUR_WAF_FRONT_DOOR_RESOURCE_GROUP"
```

Remove the existing code for `deployment` for the deployment named `DeployARMTemplate-Web`

Add the following to azure-pipeline.yml to replace the above; This will deploy the WebApp to both regions using the deployment strategy matrix.

```
- deployment: DeployARMTemplate-Web
  displayName: 'Deploy Web App ARM Template'
  environment: [Environment Name]
  strategy:
    maxParallel: 1:
    matrix
      EUN:
        appName: $(parameters.appNameEun.value)
        location: North Europe
      EUW:
        appName: $(parameters.appNameEuw.value)
        location: West Europe
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
          jsonTargetFiles: '**/parameters.json'
      - task: AzureResourceManagerTemplateDeployment@3
        displayName: 'Deploy WebApp'
        inputs:
          deploymentScope: 'Resource Group'
          ConnectedServiceName: '[Name of your subscription Service Connection]'
          action: 'Create Or Update Resource Group'
          resourceGroupName: '$(ResourceGroupName)'
          location: '$(location)'
          templateLocation: 'Linked artifact'
          csmFile: '$(Pipeline.Workspace)/arm/web-template.json'
          csmParametersFile: '$(Pipeline.Workspace)/arm/web-parameters.json'
          deploymentMode: 'Incremental'
```
### Further Deployment Pipeline Changes - Azure Front Door

We now need to add a new resource group deployment for deploying the Front Door. Add the following to the end of azure-pipeline.yml.

```
- deployment: DeployARMTemplate-WAFFD
  displayName: 'Deploy WAF & Front Door ARM Template'
  dependsOn: DeployARMTemplate-Web
  environment: [Environment Name]
  strategy:
  runOnce:
    deploy:
      steps:
      - task: FileTransform@2
        displayName: 'Transform Arm Template Parameters'
        inputs:
          folderPath: '$(Pipeline.Workspace)/'
          xmlTransformationRules: 
          jsonTargetFiles: '**/parameters.json'
      - task: AzureResourceManagerTemplateDeployment@3
        displayName: 'Deploy WAF & Front Door'
        inputs:
          deploymentScope: 'Resource Group'
          ConnectedServiceName: '[Name of your subscription Service Connection]'
          action: 'Create Or Update Resource Group'
          resourceGroupName: '$(waffdResourceGroup)'
          location: 'North Europe'
          templateLocation: 'Linked artifact'
          csmFile: '$(Pipeline.Workspace)/arm/waffd-template.json'
          csmParametersFile: '$(Pipeline.Workspace)/arm/waffd-parameters.json'
          deploymentMode: 'Incremental'
```


### Waffd-Template.json

1.  In VS Code, click View - Explorer, you should now see the root of your repository on the left hand side.
    
2.  Right click, click New Folder and call it “arm”
    
3.  Click click on the arm folder and click New File, call this "waffd-template.json”
    
4.  Then open the file to edit.

First of all, the top of our ARM Template defines the scheme, version and parameters. Add the following code to the start of the file waffd-template.json”

```
{
    "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
      "wafPolicyName": {
        "type": "string"
      },
      "frontDoorName": {
        "type": "string"
      },
      "appNameEun": {
        "type": "string"
      },
      "appNameEuw": {
        "type": "string"
      }
    },
```
We the need to start adding resources to our ARM Template, it doesn't really matter which order these resources go in, as we add dependencies to each resource, which determines the order for us.

Add the following code to the end of the same file "waffd-template.json”

```
"resources": [
      {
          "apiVersion": "2020-04-01",
          "type": "Microsoft.Network/frontDoorWebApplicationFirewallPolicies",
          "name": "[parameters('wafPolicyname')]",
          "location": "global",
          "properties": {
              "policySettings": {
                  "enabledState": "Enabled",
                  "mode": "Detection",
                  "redirectUrl": null,
                  "customBlockResponseStatusCode": 403,
                  "customBlockResponseBody": null
              },
              "customRules": {
                  "rules": []
              },
              "managedRules": {
                  "managedRuleSets": [
                      {
                          "ruleSetType": "DefaultRuleSet",
                          "ruleSetVersion": "1.0",
                          "ruleGroupOverrides": [],
                          "exclusions": []
                      }
                  ]
              }
          }
      },
      {
        "apiVersion": "2020-05-01",
        "type": "Microsoft.Network/frontdoors",
        "name": "[parameters('frontDoorName')]",
        "location": "global",
        "dependsOn": [
          "[resourceId('Microsoft.Network/frontDoorWebApplicationFirewallPolicies', parameters('wafPolicyname'))]"
        ],
        "properties": {
            "frontdoorId": "[concat('/subscriptions/', subscription().subscriptionId, '/resourceGroups/', resourceGroup().name, '/providers/Microsoft.Network/frontdoors/', parameters('frontDoorName'))]",
            "friendlyName": "[parameters('frontDoorName')]",
            "enabledState": "Enabled",
            "healthProbeSettings": [
                {
                    "name": "healthProbeSettings-1600163515023",
                    "properties": {
                        "path": "/",
                        "protocol": "Https",
                        "intervalInSeconds": 30,
                        "healthProbeMethod": "Head",
                        "enabledState": "Enabled"
                    },
                    "id": "[concat('/subscriptions/', subscription().subscriptionId, '/resourceGroups/', resourceGroup().name, '/providers/Microsoft.Network/frontdoors/', parameters('frontDoorName'), '/healthProbeSettings/healthProbeSettings-1600163515023')]"
                }
            ],
            "loadBalancingSettings": [
                {
                    "name": "loadBalancingSettings-1600163515023",
                    "properties": {
                        "sampleSize": 4,
                        "successfulSamplesRequired": 2,
                        "additionalLatencyMilliseconds": 0
                    },
                    "id": "[concat('/subscriptions/', subscription().subscriptionId, '/resourceGroups/', resourceGroup().name, '/providers/Microsoft.Network/frontdoors/', parameters('frontDoorName'), '/loadBalancingSettings/loadBalancingSettings-1600163515023')]"
                }
            ],
            "frontendEndpoints": [
                {
                    "name": "[concat(parameters('frontDoorName'), '-azurefd-net')]",
                    "properties": {
                        "hostName": "[concat(parameters('frontDoorName'), '-azurefd-net')]",
                        "sessionAffinityEnabledState": "Disabled",
                        "sessionAffinityTtlSeconds": 0,
                        "webApplicationFirewallPolicyLink": {
                            "id": "[concat('/subscriptions/', subscription().subscriptionId, '/resourceGroups/', resourceGroup().name, '/providers/Microsoft.Network/frontdoorwebapplicationfirewallpolicies/', parameters('wafPolicyName'))]"
                        },
                        "customHttpsConfiguration": null
                    },
                    "id": "[concat('/subscriptions/', subscription().subscriptionId, '/resourceGroups/', resourceGroup().name, '/providers/Microsoft.Network/frontdoors/', parameters('frontDoorName'), '/frontendEndpoints/', parameters('frontDoorName'), '-azurefd-net')]"
                }
            ],
            "backendPools": [
                {
                    "name": "[concat(parameters('frontDoorName'), '-bk')]",
                    "properties": {
                        "backends": [
                            {
                                "address": "[concat(parameters('appNameEun'), '.azurewebsites.net')]",
                                "privateLinkResourceId": null,
                                "privateLinkLocation": null,
                                "privateEndpointStatus": null,
                                "privateLinkApprovalMessage": null,
                                "enabledState": "Enabled",
                                "httpPort": 80,
                                "httpsPort": 443,
                                "priority": 1,
                                "weight": 50,
                                "backendHostHeader": "[concat(parameters('appNameEun'), '.azurewebsites.net')]"
                            },
                            {
                                "address": "[concat(parameters('appNameEuw'), '-back.azurewebsites.net')]",
                                "privateLinkResourceId": null,
                                "privateLinkLocation": null,
                                "privateEndpointStatus": null,
                                "privateLinkApprovalMessage": null,
                                "enabledState": "Enabled",
                                "httpPort": 80,
                                "httpsPort": 443,
                                "priority": 1,
                                "weight": 50,
                                "backendHostHeader": "[concat(parameters('appNameEuw'), '-back.azurewebsites.net')]"
                            }
                        ],
                        "loadBalancingSettings": {
                            "id": "[concat('/subscriptions/', subscription().subscriptionId, '/resourceGroups/', resourceGroup().name, '/providers/Microsoft.Network/frontdoors/', parameters('frontDoorName'), '/loadBalancingSettings/loadBalancingSettings-1600163515023')]"
                        },
                        "healthProbeSettings": {
                            "id": "[concat('/subscriptions/', subscription().subscriptionId, '/resourceGroups/', resourceGroup().name, '/providers/Microsoft.Network/frontdoors/', parameters('frontDoorName'), '/healthProbeSettings-1600163515023')]"
                        }
                    },
                    "id": "[concat('/subscriptions/', subscription().subscriptionId, '/resourceGroups/', resourceGroup().name, '/providers/Microsoft.Network/frontdoors/', parameters('frontDoorName'), '/backendPools/', parameters('frontDoorName'), '-bk')]"
                }
            ],
            "routingRules": [
                {
                    "name": "[concat(parameters('frontDoorName'), '-rr')]",
                    "properties": {
                        "frontendEndpoints": [
                            {
                                "id": "[concat('/subscriptions/', subscription().subscriptionId, '/resourceGroups/', resourceGroup().name, '/providers/Microsoft.Network/frontdoors/', parameters('frontDoorName'), '/frontendEndpoints/', parameters('frontDoorName'), '-azurefd-net')]"
                            }
                        ],
                        "acceptedProtocols": [
                            "Http",
                            "Https"
                        ],
                        "patternsToMatch": [
                            "/*"
                        ],
                        "enabledState": "Enabled",
                        "routeConfiguration": {
                            "@odata.type": "#Microsoft.Azure.FrontDoor.Models.FrontdoorForwardingConfiguration",
                            "customForwardingPath": null,
                            "forwardingProtocol": "HttpsOnly",
                            "backendPool": {
                                "id": "[concat('/subscriptions/', subscription().subscriptionId, '/resourceGroups/', resourceGroup().name, '/providers/Microsoft.Network/frontdoors/', parameters('frontDoorName'), '/backendPools/', parameters('frontDoorName'), '-bk')]"
                            },
                            "cacheConfiguration": null
                        }
                    },
                    "id": "[concat('/subscriptions/', subscription().subscriptionId, '/resourceGroups/', resourceGroup().name, '/providers/Microsoft.Network/frontdoors/', parameters('frontDoorName'), '/routingRules/', parameters('frontDoorName'), '-rr')]"
                }
            ],
            "backendPoolsSettings": {
                "enforceCertificateNameCheck": "Enabled",
                "sendRecvTimeoutSeconds": 30
            }
        }
    }
  ]
}
```

### Waffd-Parameters.json

Now we need to create a parameters file.

1.  Click click on the arm folder and click New File, call this “waffd-parameters.json”
    
2.  Then open the file to edit.
    
3.  Add the following code and save the file.

```
{
    "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "wafPolicyName": {
            "value": ""
        },
        "frontDoorName": {
            "value": ""
        },
        "appNameEun": {
            "value": ""
        },
        "appNameEuw": {
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
    
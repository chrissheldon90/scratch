# Automating Release Notes In Azure Devops To Confluence - High Level Technical 

## Scenario

When a deployment pipelines completes a release to production, the pipeline will have associated work items (from Pull Requests) we want these associated work items to appear in a "Release Document" in an area on confluence after the release.

## Implementation

### Service Hook

In many CI/CD tools, we have service hooks. These service hooks can be configured to trigger on certain events and send information (generally as JSON) to a 3rd party tool. Azure Devops Service Hooks allow us to trigger based on a stage completing successfully in a pipeline. This can be the "Production Deployment Stage". When this completes, it will send the information to an Azure Service Bus Queue.

### Service Bus

An Azure Service Bus is a commononly used Azure Resource for handling messages and more. This solution makes use of an Azure Service Bus Queue and is implemented via it's own Azure Devops Pipeline using ARM Templates.

### Storage Account

An Azure Storage Account is a commononly used Azure Resource for storing data. This solution makes use of an Azure Storage Account and is implemented via it's own Azure Devops Pipeline using ARM Templates.

### Logic App

An Azure Logic App is an Azure Resource whih allows us to create a logical process definition (in Json) to run a series of events (Example, Read Queue, Talk To Apis). For this solution a Logic App is deployed using an Azure Devops Pipeline using ARM Templates, there are several steps the logic app will do;

1. Trigger on message entering the Service Bus Queue
2. Parse the Json coming from the queue
3. Make API calls to Azure Devops to retrieve related work item information for the release that has entered the queue.
4. Parse the information from Azure Devops, save in the Azure Storage Account.
5. Make API calls to confluence, appending or creating a Release Page, adding the information about the release.
6. Clear up (Storage Account)
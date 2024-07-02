---
page_type: sample
languages:
- csharp
- bicep
- TypeScript
- nodejs
- JavaScript
products:
- azure
- azure-openai
- azure-functions
- static-web-apps
- entra-id
urlFragment: Azure-Functions-OpenAI-Demo
name: "Azure Functions OpenAI triggers and bindings sample"
description: An end to end demo that demonstrates how to use the Azure Functions OpenAI triggers and bindings.
---

# Chat + Enterprise data with Azure OpenAI and Azure Functions

This demo is based on [azure-search-openai-demo](https://github.com/Azure-Samples/azure-search-openai-demo) and uses a static web app for the frontend and Azure functions for the backend API's.

This solution uses the [Azure Functions OpenAI triggers and binding extension](https://github.com/Azure/azure-functions-openai-extension) for the backend capabilities. It includes:

- Ability to upload text files from UI - Delivered by the embeddings and semantic search output bindings
- Ask questions of the uploaded files - Enabled by the semantic search input binding
- Create a chat session and interact with the OpenAI deployed model -  Uses the Assistant bindings to interact wiht the OpenAI model and stores chat history in Azure storage tables automatically
- In the chat session, ask the LLM to store reminders and then later retrieve them. This capability is delivered by the AssistantSkills trigger in the OpenAI extension for Azure Functions
- Create Azure functions in different programming language e.g. (C#, Node, Python, Java, PowerShell) and easily replace using config file
- Static web page is configured with Entra ID auth by default

<img src="docs/uploadscreen.png" width="600">

### High Level Overview of components

<img src="docs/appcomponents.png" width="600">

## Getting Started

> **IMPORTANT:** In order to deploy and run this example, you'll need an **Azure subscription with access enabled for the Azure OpenAI service**. You can request access [here](https://aka.ms/oaiapply). You can also visit [here](https://azure.microsoft.com/free/cognitive-search/) to get some free Azure credits to get you started.

> **AZURE RESOURCE COSTS** by default this sample will create Azure App Service and Azure AI Search resources that have a monthly cost. You can switch them to free versions of each of them if you want to avoid this cost by changing the parameters file under the infra folder (though there are some limits to consider; for example, you can have up to 1 free AI Search resource per subscription.)

### Prerequisites

#### To Run Locally

- [.NET 8](https://dotnet.microsoft.com/en-us/download/dotnet/8.0) - `backend` Functions app is built using .NET 8
- [Node.js](https://nodejs.org/en/download/) - `frontend` is built in TypeScript
- [Azure Functions Core Tools](https://learn.microsoft.com/en-us/azure/azure-functions/functions-run-local?tabs=v4%2Clinux%2Ccsharp%2Cportal%2Cbash#install-the-azure-functions-core-tools) - Run and debug `backend` Functions locally
- [Static Web Apps Cli](https://github.com/Azure/static-web-apps-cli#azure-static-web-apps-cli) - Run and debug `frontend` SWA locally
- [Git](https://git-scm.com/downloads)
- [Azure Developer CLI](https://aka.ms/azure-dev/install) - Provision and deploy Azure Resources
- [Powershell 7+ (pwsh)](https://github.com/powershell/powershell) - For Windows users only.
  - **Important**: Ensure you can run `pwsh.exe` from a PowerShell command. If this fails, you likely need to upgrade PowerShell.


> NOTE: Your Azure Account must have `Microsoft.Authorization/roleAssignments/write` permissions, such as [User Access Administrator](https://learn.microsoft.com/azure/role-based-access-control/built-in-roles#user-access-administrator) or [Owner](https://learn.microsoft.com/azure/role-based-access-control/built-in-roles#owner).

### Initializing and deploying app

This application requires resources like Azure OpenAI and Azure AI Search which must be provisioned in Azure even if the app is run locally.  The following steps make it easy to provision, deploy and configure all resources. 

#### Starting from scratch

Execute the following command in a new terminal, if you don't have any pre-existing Azure services and want to start from a fresh deployment.

1. Ensure your deployment scripts are executable (scripts are currently needed to help AZD deploy your app)

Mac/Linux:
```bash
chmod +x ./scripts/deploy.sh
```
Windows:
```Powershell
set-executionpolicy remotesigned
```
2. Provision required Azure resources (e.g. Azure OpenAI and Azure Search) into a new environment
```bash
azd up
```
> NOTE: For the target location, the regions that currently support the models used in this sample are **East US** or **South Central US**. For an up-to-date list of regions and models, check [here](https://learn.microsoft.com/en-us/azure/cognitive-services/openai/concepts/models).  Make sure that all the intended services for this deployment have availability in your targeted regions.  Note also, it may take a minute for the application to be fully deployed.
3. Navigate to the Azure Static WebApp deployed in step 2. The URL is printed out when azd completes (as "Endpoint"), or you can find it in the Azure portal.

#### Use existing resources

The following steps let you override resource names and other values so you can leverage existing resources (e.g. provided by an admin or in a sandbox environment).

1. Map configuration using Azure resources provided to you:
```bash
azd env set AZURE_OPENAI_SERVICE <Name of existing OpenAI service>
azd env set AZURE_OPENAI_RESOURCE_GROUP <Name of existing resource group with OpenAI resource>
azd env set AZURE_OPENAI_CHATGPT_DEPLOYMENT <Name of existing ChatGPT deployment if not the default `chat`>
azd env set AZURE_OPENAI_GPT_DEPLOYMENT <Name of existing GPT deployment if not `davinci`>
```
2. Deploy all resources (provision any not specified)
```bash
azd up
```

> NOTE: You can also use existing Search and Storage Accounts. See `./infra/main.parameters.json` for list of environment variables to pass to `azd env set` to configure those existing resources.

#### Deploying or re-deploying a local clone of the repo

- Simply run `azd up` again

### Running locally (currently untested/unsupported)

Your frontend and backend apps can run on the local machine using storage emulators + remote AI resources. 

1. Initialize the Azure resources using one of the approaches above.
2. Create a new `app/backend/local.settings.json` file to store Azure resource configuration using values in the .azure/[environment name]
```json
{
  "IsEncrypted": false,
  "Values": {
    "AZURE_OPENAI_ENDPOINT": "<Endpoint of existing OpenAI service>",
    "AZURE_OPENAI_CHATGPT_DEPLOYMENT": "chat",
    "AZURE_OPENAI_EMB_DEPLOYMENT": "embedding",
    "SYSTEM_PROMPT": "You are a helpful assistant. You are responding to requests from a user about internal emails and documents. You can and should refer to the internal documents to help respond to requests. If a user makes a request thats not covered by the documents provided in the query, you must say that you do not have access to the information and not try and get information from other places besides the documents provided. The following is a list of documents that you can refer to when answering questions. The documents are in the format [filename]: [text] and are separated by newlines. If you answer a question by referencing any of the documents, please cite the document in your answer. For example, if you answer a question by referencing info.txt, you should add \"Reference: info.txt\" to the end of your answer on a separate line.",
    "AZURE_SEARCH_ENDPOINT": "<Endpoint of existing Azure AI Search service>",
    "fileShare": "/mounts/openaifiles",
    "ServiceBusConnection__fullyQualifiedNamespace": "<Namespace of existing service bus namespace>",
    "ServiceBusQueueName": "<Name of service bus Queue>",
    "OpenAiStorageConnection__accountName": "<Account name of storage account used by OpenAI extension>",
    "AzureWebJobsStorage__accountName": "<Account name of storage account used by Function runtime>",
    "DEPLOYMENT_STORAGE_CONNECTION_STRING": "<Account name of storage account used by Function deployment>",
    "APPLICATIONINSIGHTS_CONNECTION_STRING": "<Connection for App Insights resource>"
  }
}
```
3. Disable VNET private endpoints in resource group so your function can connect to remote resources (or VPN into VNET)
4. Start Azurite using VS Code extension or run this command in a new terminal window using optional [Docker](www.docker.com)
```bash
docker run -p 10000:10000 -p 10001:10001 -p 10002:10002 \
    mcr.microsoft.com/azure-storage/azurite
```
5. Start the Function app by pressing `F5` in Visual Studio (Code) or run this command:
```bash
func start
```
6. navigate to http://127.0.0.1:5000

### Using the frontend web app:

- Upload .txt files on the Upload screen.  Content is provided in `./sample_content` folder. 
- Try different topics in chat or Q&A context. For chat, try follow up questions, clarifications, ask to simplify or elaborate on answer, etc.
- Explore citations and sources
- Click on "settings" to try different options, tweak prompts, etc.
- Explore the search indexes in the Azure AI Search resource to inspect vector embeddings created by the Upload step

## Resources

- [Primary Repo - azure-search-openai-demo](https://github.com/Azure-Samples/azure-search-openai-demo)
- [Revolutionize your Enterprise Data with ChatGPT: Next-gen Apps w/ Azure OpenAI and AI Search](https://aka.ms/entgptsearchblog)
- [Azure AI Search](https://learn.microsoft.com/azure/search/search-what-is-azure-search)
- [Azure OpenAI Service](https://learn.microsoft.com/azure/cognitive-services/openai/overview)
- [Azure Role-based-access-control](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles)

## How to purge Entra ID auth

To remove your data from Azure Static Web Apps, go to <https://identity.azurestaticapps.net/.auth/purge/aad>

## How to delete all Azure resources

The following command deletes and purges all resources (this cannot be undone!):
```bash
azd down --purge
```

## Upload files failures

Currently only text files are supported.

## Azure Functions troubleshooting

Go to Application Insights and go to the Live metrics view to see real time telemtry information.
Optionally, go to Application Insights and select Logs and view the traces table

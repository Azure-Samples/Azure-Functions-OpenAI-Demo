param name string
param location string = resourceGroup().location
param tags object = {}

// Reference Properties
param appInsightsConnectionString string = ''
param appServicePlanId string
param storageAccountName string
param virtualNetworkSubnetId string = ''
param allowedOrigins array = []

param azureOpenaiService string
param azureOpenaiChatgptDeployment string
param azureOpenaiEmbeddingDeployment string
param azureSearchService string
param azureSearchIndex string
param serviceBusQueueName string
param serviceBusNamespaceFQDN string
param shareName string
param applicationInsightsIdentity string

// Runtime Properties
@allowed([
  'dotnet-isolated', 'node', 'python', 'java', 'powershell', 'custom'
])
param runtimeName string
@allowed(['3.10', '3.11', '7.2', '8.0', '10', '11', '17', '20'])
param runtimeVersion string
param kind string = 'functionapp,linux'

// Microsoft.Web/sites/config
param appSettings object = {}
param instanceMemoryMB int = 2048
param maximumInstanceCount int = 100

var storageConfigProperties = {  
  '${shareName}': {
    type: 'AzureFiles'
    shareName: shareName
    mountPath: '/mounts/${shareName}'
    accountName: stg.name
    accessKey: stg.listKeys().keys[0].value
  }
}

resource stg 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: storageAccountName
}
resource functions 'Microsoft.Web/sites@2023-12-01' = {
  name: name
  location: location
  tags: tags
  kind: kind

  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlanId
    siteConfig: {
      cors: {
        allowedOrigins: union([ 'https://portal.azure.com', 'https://ms.portal.azure.com' ], allowedOrigins)
      }
    }
    functionAppConfig: {
      deployment: {
        storage: {
          type: 'blobContainer'
          value: '${stg.properties.primaryEndpoints.blob}deploymentpackage'
          authentication: {
            type: 'SystemAssignedIdentity'
          }
        }
      }
      scaleAndConcurrency: {
        instanceMemoryMB: instanceMemoryMB
        maximumInstanceCount: maximumInstanceCount
      }
      runtime: {
        name: runtimeName
        version: runtimeVersion
      }
    }
    virtualNetworkSubnetId: virtualNetworkSubnetId == '' ? null : virtualNetworkSubnetId
  }
  resource configAppSettings 'config' = {
    name: 'appsettings'
    properties: union(appSettings,
      {
        AzureWebJobsStorage__accountName: stg.name
        DEPLOYMENT_STORAGE_CONNECTION_STRING: stg.name
        APPLICATIONINSIGHTS_CONNECTION_STRING: appInsightsConnectionString
        AZURE_OPENAI_SERVICE: azureOpenaiService
        AZURE_OPENAI_ENDPOINT: 'https://${azureOpenaiService}.openai.azure.com/'
        AZURE_OPENAI_CHATGPT_DEPLOYMENT: azureOpenaiChatgptDeployment
        AZURE_OPENAI_EMB_DEPLOYMENT: azureOpenaiEmbeddingDeployment
        SYSTEM_PROMPT: 'You are a helpful assistant. You are responding to requests from a user about internal emails and documents. You can and should refer to the internal documents to help respond to requests. If a user makes a request thats not covered by the documents provided in the query, you must say that you do not have access to the information and not try and get information from other places besides the documents provided. The following is a list of documents that you can refer to when answering questions. The documents are in the format [filename]: [text] and are separated by newlines. If you answer a question by referencing any of the documents, please cite the document in your answer. For example, if you answer a question by referencing info.txt, you should add "Reference: info.txt" to the end of your answer on a separate line.'
        AZURE_SEARCH_SERVICE: azureSearchService
        AZURE_SEARCH_ENDPOINT: 'https://${azureSearchService}.search.windows.net'
        AZURE_SEARCH_INDEX: azureSearchIndex
        fileShare : '/mounts/${shareName}'
        //OpenAI extension not yet supports MSI for the table storage connection
        OpenAiStorageConnection: 'DefaultEndpointsProtocol=https;AccountName=${stg.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${stg.listKeys().keys[0].value}'
        ServiceBusConnection__fullyQualifiedNamespace: serviceBusNamespaceFQDN
        ServiceBusQueueName: serviceBusQueueName
        APPLICATIONINSIGHTS_AUTHENTICATION_STRING: applicationInsightsIdentity
      })
  }
  resource configStorageSetting 'config' = {
    name: 'azurestorageaccounts'
    properties: union(storageConfigProperties, {})
  }
}

output name string = functions.name
output uri string = 'https://${functions.properties.defaultHostName}'
output identityPrincipalId string = functions.identity.principalId
output id string = functions.id

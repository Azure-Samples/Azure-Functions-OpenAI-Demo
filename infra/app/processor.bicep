param name string
param location string = resourceGroup().location
param tags object = {}
param appServicePlanId string
param appSettings object = {}
param runtimeName string 
param runtimeVersion string 
param serviceName string = 'processor'
param storageAccountName string
param virtualNetworkSubnetId string = ''
param instanceMemoryMB int = 2048
param maximumInstanceCount int = 100
param azureOpenaiService string
param appInsightsConnectionString string
param azureOpenaiChatgptDeployment string
param azureOpenaigptDeployment string
param azureSearchService string
param serviceBusQueueName string
param serviceBusNamespaceFQDN string
param shareName string

resource stg 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: storageAccountName
}

module processor '../core/host/functions-flexconsumption.bicep' = {
  name: '${serviceName}-functions-module'
  params: {
    name: name
    location: location
    tags: union(tags, { 'azd-service-name': serviceName })
    appSettings: union(appSettings,
      {
        AZURE_OPENAI_ENDPOINT: 'https://${azureOpenaiService}.openai.azure.com/'
        CHAT_MODEL_DEPLOYMENT_NAME: azureOpenaiChatgptDeployment
        EMBEDDING_MODEL_DEPLOYMENT_NAME: azureOpenaigptDeployment
        SYSTEM_PROMPT: 'You are a helpful assistant. You are responding to requests from a user about internal emails and documents. You can and should refer to the internal documents to help respond to requests. If a user makes a request thats not covered by the documents provided in the query, you must say that you do not have access to the information and not try and get information from other places besides the documents provided. The following is a list of documents that you can refer to when answering questions. The documents are in the format [filename]: [text] and are separated by newlines. If you answer a question by referencing any of the documents, please cite the document in your answer. For example, if you answer a question by referencing info.txt, you should add "Reference: info.txt" to the end of your answer on a separate line.'
        AISearchEndpoint: 'https://${azureSearchService}.search.windows.net'
        fileShare : '/mounts/${shareName}'
        //OpenAI extension not yet supports MSI for the table storage connection
        OpenAiStorageConnection: 'DefaultEndpointsProtocol=https;AccountName=${stg.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${stg.listKeys().keys[0].value}'
        ServiceBusConnection__fullyQualifiedNamespace: serviceBusNamespaceFQDN
        ServiceBusQueueName: serviceBusQueueName
      })
    storageConfigProperties: {
      '${shareName}': {
        type: 'AzureFiles'
        shareName: shareName
        mountPath: '/mounts/${shareName}'
        accountName: stg.name
        accessKey: stg.listKeys().keys[0].value
      }
    }
    appInsightsConnectionString: appInsightsConnectionString
    appServicePlanId: appServicePlanId
    runtimeName: runtimeName
    runtimeVersion: runtimeVersion
    storageAccountName: storageAccountName
    virtualNetworkSubnetId: virtualNetworkSubnetId
    instanceMemoryMB: instanceMemoryMB 
    maximumInstanceCount: maximumInstanceCount
  }
}

output SERVICE_PROCESSOR_NAME string = processor.outputs.name
output SERVICE_PROCESSOR_IDENTITY_PRINCIPAL_ID string = processor.outputs.identityPrincipalId
output id string = processor.outputs.id 

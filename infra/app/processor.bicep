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
param azureOpenaiEmbeddingDeployment string
param azureSearchService string
param azureSearchIndex string
param serviceBusQueueName string
param serviceBusNamespaceFQDN string
param shareName string

var applicationInsightsIdentity = 'Authorization=AAD'

resource stg 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: storageAccountName
}

module processor '../core/host/functions-flexconsumption.bicep' = {
  name: '${serviceName}-functions-module'
  params: {
    name: name
    location: location
    tags: union(tags, { 'azd-service-name': serviceName })
    appInsightsConnectionString: appInsightsConnectionString
    appServicePlanId: appServicePlanId
    runtimeName: runtimeName
    runtimeVersion: runtimeVersion
    storageAccountName: storageAccountName
    virtualNetworkSubnetId: virtualNetworkSubnetId
    instanceMemoryMB: instanceMemoryMB 
    maximumInstanceCount: maximumInstanceCount
    azureOpenaiService: azureOpenaiService
    azureOpenaiChatgptDeployment: azureOpenaiChatgptDeployment
    azureOpenaiEmbeddingDeployment: azureOpenaiEmbeddingDeployment
    azureSearchService: azureSearchService
    azureSearchIndex: azureSearchIndex
    serviceBusQueueName: serviceBusQueueName
    serviceBusNamespaceFQDN: serviceBusNamespaceFQDN
    shareName: shareName
    applicationInsightsIdentity: applicationInsightsIdentity
  }
}

output SERVICE_PROCESSOR_NAME string = processor.outputs.name
output SERVICE_PROCESSOR_IDENTITY_PRINCIPAL_ID string = processor.outputs.identityPrincipalId
output id string = processor.outputs.id 

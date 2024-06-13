param name string
param location string = resourceGroup().location
param tags object = {}

// Reference Properties
param appInsightsConnectionString string = ''
param appServicePlanId string
param storageAccountName string
param virtualNetworkSubnetId string = ''
param allowedOrigins array = []

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
param storageConfigProperties object = {}
param instanceMemoryMB int = 2048
param maximumInstanceCount int = 100

resource stg 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: storageAccountName
}
resource functions 'Microsoft.Web/sites@2023-12-01' = {
  name: '${name}-functions'
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

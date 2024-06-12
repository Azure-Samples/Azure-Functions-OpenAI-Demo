param principalId string
param roleDefinitionIds array
param openAiAccountResourceName string

resource account 'Microsoft.CognitiveServices/accounts@2023-05-01' existing = {
  name: openAiAccountResourceName
}

resource role 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for roleDefinitionId in roleDefinitionIds: {
  name: guid(subscription().id, resourceGroup().id, principalId, roleDefinitionId)
  scope: account
  properties: {
    principalId: principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
  }
}]

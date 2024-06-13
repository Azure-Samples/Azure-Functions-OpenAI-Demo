@description('Specifies the name of the virtual network.')
param vNetName string

@description('Specifies the location.')
param location string = resourceGroup().location

@description('Specifies the name of the subnet for the Cognitive Services private endpoint.')
param openaiSubnetName string = 'openai'

@description('Specifies the name of the subnet for Function App virtual network integration.')
param appSubnetName string = 'functionapp'

param tags object = {}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: vNetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    encryption: {
      enabled: false
      enforcement: 'AllowUnencrypted'
    }
    subnets: [
      {
        name: openaiSubnetName
        id: resourceId('Microsoft.Network/virtualNetworks/subnets', vNetName, 'openai')
        properties: {
          addressPrefixes: [
            '10.0.1.0/24'
          ]
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
        type: 'Microsoft.Network/virtualNetworks/subnets'
      }
      {
        name: appSubnetName
        id: resourceId('Microsoft.Network/virtualNetworks/subnets', vNetName, 'functionapp')
        properties: {
          addressPrefixes: [
            '10.0.2.0/23'
          ]
          delegations: [
            {
              name: 'delegation'
              id: '${resourceId('Microsoft.Network/virtualNetworks/subnets', vNetName, 'app')}/delegations/delegation'
              properties: {
                //Microsoft.App/environments is the correct delegation for Flex Consumption VNet integration
                serviceName: 'Microsoft.App/environments'
              }
              type: 'Microsoft.Network/virtualNetworks/subnets/delegations'
            }
          ]
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
        type: 'Microsoft.Network/virtualNetworks/subnets'
      }
    ]
    virtualNetworkPeerings: []
    enableDdosProtection: false
  }
}

output openaiSubnetName string = virtualNetwork.properties.subnets[0].name
output openaiSubnetID string = virtualNetwork.properties.subnets[0].id
output functionappSubnetName string = virtualNetwork.properties.subnets[1].name
output functionappSubnetID string = virtualNetwork.properties.subnets[1].id
output vNetName string = virtualNetwork.name

@description('Azure region.')
param location string
@description('Short prefix used in resource names.')
param namePrefix string
param vnetAddressPrefix string = '10.20.0.0/16'
param appSubnetPrefix string = '10.20.1.0/24'
param privateEndpointSubnetPrefix string = '10.20.2.0/24'
param agentSubnetPrefix string = '10.20.3.0/24'

resource nsg 'Microsoft.Network/networkSecurityGroups@2023-11-01' = {
  name: 'nsg-${namePrefix}'
  location: location
  properties: {
    securityRules: [
      {
        name: 'deny-inbound-internet'
        properties: {
          priority: 4000
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourceAddressPrefix: 'Internet'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
        }
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: 'vnet-${namePrefix}'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [vnetAddressPrefix]
    }
    subnets: [
      {
        name: 'snet-app'
        properties: {
          addressPrefix: appSubnetPrefix
          delegations: [
            {
              name: 'webapp'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
        }
      }
      {
        name: 'snet-private-endpoints'
        properties: {
          addressPrefix: privateEndpointSubnetPrefix
          privateEndpointNetworkPolicies: 'Disabled'
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
      {
        name: 'snet-agents'
        properties: {
          addressPrefix: agentSubnetPrefix
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
    ]
  }
}

var zoneNames = [
  'privatelink.vaultcore.azure.net'
  'privatelink.azurewebsites.net'
]

resource zones 'Microsoft.Network/privateDnsZones@2020-06-01' = [for z in zoneNames: {
  name: z
  location: 'global'
}]

resource links 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = [for (z, i) in zoneNames: {
  parent: zones[i]
  name: 'link-${namePrefix}'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}]

output vnetId string = vnet.id
output appSubnetId string = '${vnet.id}/subnets/snet-app'
output privateEndpointSubnetId string = '${vnet.id}/subnets/snet-private-endpoints'
output agentSubnetId string = '${vnet.id}/subnets/snet-agents'
output keyVaultZoneId string = zones[0].id
output webAppZoneId string = zones[1].id

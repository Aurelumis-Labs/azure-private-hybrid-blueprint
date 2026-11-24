targetScope = 'resourceGroup'

@description('Short prefix used in resource names, for example contoso.')
param namePrefix string
@description('Environment name, for example dev or prod.')
param environmentName string
param location string = resourceGroup().location

var suffix = '${namePrefix}-${environmentName}'

module network 'modules/network.bicep' = {
  name: 'network'
  params: {
    location: location
    namePrefix: suffix
  }
}

module identity 'modules/identity.bicep' = {
  name: 'identity'
  params: {
    location: location
    name: 'id-${suffix}'
  }
}

module keyVault 'modules/keyvault.bicep' = {
  name: 'keyvault'
  params: {
    location: location
    name: take('kv-${suffix}-${uniqueString(resourceGroup().id)}', 24)
    secretsReaderPrincipalId: identity.outputs.principalId
  }
}

module webApp 'modules/webapp.bicep' = {
  name: 'webapp'
  params: {
    location: location
    planName: 'asp-${suffix}'
    siteName: take('app-${suffix}-${uniqueString(resourceGroup().id)}', 60)
    integrationSubnetId: network.outputs.appSubnetId
    identityId: identity.outputs.id
    identityClientId: identity.outputs.clientId
    keyVaultUri: keyVault.outputs.uri
  }
}

module keyVaultEndpoint 'modules/privateEndpoint.bicep' = {
  name: 'pe-keyvault'
  params: {
    location: location
    name: 'pe-kv-${suffix}'
    subnetId: network.outputs.privateEndpointSubnetId
    targetResourceId: keyVault.outputs.id
    groupId: 'vault'
    privateDnsZoneId: network.outputs.keyVaultZoneId
  }
}

module webAppEndpoint 'modules/privateEndpoint.bicep' = {
  name: 'pe-webapp'
  params: {
    location: location
    name: 'pe-app-${suffix}'
    subnetId: network.outputs.privateEndpointSubnetId
    targetResourceId: webApp.outputs.id
    groupId: 'sites'
    privateDnsZoneId: network.outputs.webAppZoneId
  }
}

output webAppHostName string = webApp.outputs.defaultHostName
output agentSubnetId string = network.outputs.agentSubnetId

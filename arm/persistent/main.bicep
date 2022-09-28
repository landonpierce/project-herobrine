param location string = resourceGroup().location

@description('The DNS label to set on the dynamic IP address. FQDN will be {dnslabel}.{region}.cloudapp.azure.com')
param dnsDomainName string 

@secure()
param vmAdminUserName string = 'minecraftadmin'

@secure()
param vmAdminPassword string

param storageRoleAssignmentId string = newGuid() 


resource virtualNetwork 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: 'mc-vm-vnet-01'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'Subnet-1'
        properties: {
          addressPrefix: '10.0.0.0/24'
        }
      }
    ]
  }
}

resource ipAddress 'Microsoft.Network/publicIPAddresses@2017-06-01' = {
  name: 'IP${uniqueString(resourceGroup().id)}'
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: dnsDomainName
      fqdn: '${dnsDomainName}${location}'
    }
  }
}

resource AppService 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: 'asp-${uniqueString(resourceGroup().id)}'
  location: location
  kind: 'app,linux'
  properties: {
    reserved: true
  }
  sku: {
    tier: 'Dynamic'
    name: 'Y1'
  }
}

var managedIdentityName = 'mc-vm-managed-identity-01'
resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' = {
  name: managedIdentityName
  location: location
}

var storName = 'herobrine${uniqueString(resourceGroup().id)}'
resource worldStorage 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: storName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    encryption: {
      keySource: 'Microsoft.Storage'
      services: {
        blob: {
          enabled: true
        }
        file: {
          enabled: true
        }
        queue: {
          enabled: true
        }
        table: {
          enabled: true
        }
      }
    }
    allowBlobPublicAccess: false
  }
}

@description('This is the built-in Contributor role. See https://docs.microsoft.com/azure/role-based-access-control/built-in-roles#contributor')
resource contributorRoleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  scope: subscription()
  name: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
}

var roleAssignmentGuid = guid(resourceGroup().id, contributorRoleDefinition.id) 
resource storageRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: roleAssignmentGuid
  scope: worldStorage
  properties: {
    principalId: managedIdentity.properties.principalId
    roleDefinitionId: contributorRoleDefinition.id 
    principalType: 'ServicePrincipal'
  }
}

var storName2 = 'funcstor${uniqueString(resourceGroup().id)}'
resource functionStorage 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: storName2
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    encryption: {
      keySource: 'Microsoft.Storage'
      services: {
        blob: {
          enabled: true
        }
        file: {
          enabled: true
        }
        queue: {
          enabled: true
        }
        table: {
          enabled: true
        }
      }
    }
    allowBlobPublicAccess: false
  }
}

var functionName = 'func-${uniqueString(resourceGroup().id)}'
resource Function 'Microsoft.Web/sites@2021-01-15' = {
  name: functionName
  kind: 'functionapp,linux'
  location: location
  properties: {
    enabled: true
    serverFarmId: AppService.id
    siteConfig: {
      numberOfWorkers: 1
      linuxFxVersion: 'python|3.9'
      acrUseManagedIdentityCreds: false
      alwaysOn: false
      http20Enabled: false
      functionAppScaleLimit: 200
      minimumElasticInstanceCount: 0
      appSettings: [
          {
            name: 'AzureWebJobsStorage'
            value: 'DefaultEndpointsProtocol=https;AccountName=${functionStorage.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(functionStorage.id, functionStorage.apiVersion).keys[0].value}'
          }
          {
            name: 'FUNCTIONS_EXTENSION_VERSION'
            value: '~4'
          }
          {
            name: 'FUNCTIONS_WORKER_RUNTIME'
            value: 'python'
          }
          {
            name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
            value: 'DefaultEndpointsProtocol=https;AccountName=${functionStorage.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(functionStorage.id, functionStorage.apiVersion).keys[0].value}'
          }
          {
            name: 'IpAddressResourceId'
            value: ipAddress.id
          }
          {
            name: 'ManagedIdentityResourceId'
            value: managedIdentity.id
          }
          {
            name: 'WorldStorageAccountName'
            value: worldStorage.name
          }
          {
            name: 'VMAdminUserName'
            value: vmAdminUserName
          }
          {
            name: 'VMAdminPassword'
            value: vmAdminPassword
          }
        ]
    }
  }
}


resource msDeploy 'Microsoft.Web/sites/extensions@2021-03-01' = {
  name: 'MSDeploy'
  parent: Function  
  properties: {
    packageUri: 'https://github.com/landonpierce/project-herobrine/releases/download/v0.1/beta.zip'
  }
}


var EventGridName = 'evegridy-${uniqueString(resourceGroup().id)}'
resource EventGrid 'Microsoft.EventGrid/topics@2022-06-15' = {
  name: EventGridName
  location: location
  properties: {
    inputSchema: 'EventGridSchema'
    publicNetworkAccess: 'Enabled'
    inboundIpRules: []
    disableLocalAuth: false
    dataResidencyBoundary: 'WithinGeopair'
  }
}

var eventSubName = 'vmdeploysub'
resource eventSub 'Microsoft.EventGrid/topics/eventSubscriptions@2022-06-15' = {
  name: eventSubName
  parent: EventGrid
  dependsOn: [msDeploy]
  properties: {
    destination: {
        properties: {
            resourceId: '${Function.id}/functions/VMDeployer'
            maxEventsPerBatch: 1
            preferredBatchSizeInKilobytes: 64
        }
        endpointType: 'AzureFunction'
  }
  filter: {
    includedEventTypes: [
      'start-server'
    ]
  }
}
}


// output managedIdentityResourceId string = managedIdentity.id
// output ipAddressResourceId string = ipAddress.id

param rg_location string = resourceGroup().location
param dnsDomainName string = 'herobrine'
param region string = resourceGroup().location

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: 'examplevnet-2'
  location: rg_location
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
  location: rg_location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: dnsDomainName
      fqdn: '${dnsDomainName}${region}'
    }
  }
}

resource AppService 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: 'asp-${uniqueString(resourceGroup().id)}'
  location: rg_location
  kind: 'app,linux'
  properties: {
    reserved: true
  }
  sku: {
    tier: 'Dynamic'
    name: 'Y1'
  }
}

var storName = 'herobrine${uniqueString(resourceGroup().id)}'
resource worldStorage 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: storName
  location: region
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
var storName2 = 'funcstor${uniqueString(resourceGroup().id)}'
resource functionStorage 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: storName2
  location: region
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
  location: rg_location
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
  location: rg_location
  properties: {
    inputSchema: 'EventGridSchema'
    publicNetworkAccess: 'Enabled'
    inboundIpRules: []
    disableLocalAuth: false
    dataResidencyBoundary: 'WithinGeopair'
  }
}

var eventSubName = '${EventGrid.id}/EventSub'
resource eventSub 'Microsoft.EventGrid/topics/eventSubscriptions@2022-06-15' = {
  name: eventSubName
  properties: {
    destination: {
        properties: {
            resourceId: '${Function}/functions/VMDeployer'
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

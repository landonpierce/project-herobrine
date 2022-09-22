@description('The resource id of the public IP address to allocate to the VM')
param ipAddressResourceId string

@description('The name of the storage account that the minecraft worlds will be stored in')
param storageAccountName string

@description('The size of the virtual machine to run the server on. Defaults to B2ms (2 vCPUs, 8 GB RAM)')
param vmSize string = 'Standard_D2ds_v4'

@description('The location to deploy the resources to. Defaults to the location of the resource group')
param location string = resourceGroup().location

@description('The Ubuntu version for the VM. This will pick a fully patched image of this given Ubuntu version.')
param ubuntuOSVersion string = '20_04-lts-gen2'

@description('The username for the admin user of the VM')
param adminUserName string = 'minecraftadmin'

@description('The password for the admin user of the VM')
@secure()
param adminPassword string

resource nic 'Microsoft.Network/networkInterfaces@2021-05-01' = {
  name: 'nic-mc-mv-01' 
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnet.id
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: ipAddressResourceId 
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: nsg.id
    }
  }
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2021-05-01' = {
  name: 'nsg-mc-vm-01'
  location: location
  properties: {
    securityRules: [
      {
        name: 'minecraft'
        properties: {
          priority: 110
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '25565'
        }
      }
      {
        name: 'ssh'
        properties: {
          priority: 100 
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
        }
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: 'mc-vm-vnet-01' 
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16' 
      ]
    }
  }
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2021-05-01' = {
  parent: vnet
  name: 'mc-vm-subnet-01' 
  properties: {
    addressPrefix: '10.0.0.0/24' 
    privateEndpointNetworkPolicies: 'Enabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  }
}


resource vm 'Microsoft.Compute/virtualMachines@2021-11-01' = {
  name: 'mc-vm-01' 
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          
          
          storageAccountType: 'Standard_LRS' 
        }
      }
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-focal'
        sku: ubuntuOSVersion
        version: 'latest'
      }
    }
    billingProfile: {
      maxPrice: -1 
    }
    evictionPolicy: 'Deallocate'
    priority: 'Spot'
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
    osProfile: {
      computerName: 'mc-vm-01' 
      adminUsername: adminUserName
      adminPassword: adminPassword
    }
  }
}

param publisher string = 'MicrosoftWindowsServer'
param vmOffer string = 'WindowsServer'
param vmSKU string = '2019-Datacenter'
param versionSKU string = 'latest'
param VMSize string = 'Standard_D2s_v3'

param oploc string = 'eastus2'
param username string = 'Azure'
param password string = 'Data2022#'
param adfname string = 'afdpe-training'
param adfpename string = 'adf-pe'
param sqladmin string = 'sqladmin'
param azvmname string = 'az-shir'
param azdnsvm string = 'az-dns'
param opvmname string = 'onprem-shir'
param opdnsvm string = 'onprem-dns'
param azbastionpip string = 'azbastion-pip'
param opbastionpip string = 'op-bastion-pip'
param bastioniptype string = 'Static'
param bastionipsku string = 'Standard'
param azbastionname string = 'az-bastion'
param opbastionname string = 'onprem-bastion'
param azgwname string = 'az-vpn-gw'
param opgwname string = 'op-vpn-gw'
param vpngwpip1 string = 'azvpngw01-pip'
param vpngwpip2 string = 'opvpngw02-pip'
param sqlsrvname string = 'netsqlsrv'
param sqldbname string = 'netsqldb'
param AzVnetName string = 'Azure'
param OnpremVnetName string = 'On-premises'
param AzVnetSettings object = {
  addressPrefix: '10.10.0.0/16'
  subnets: [
    {
      name: 'GatewaySubnet'
      addressPrefix: '10.10.0.0/24'
    }
    {
      name: 'AzureBastionSubnet'
      addressPrefix: '10.10.1.0/24'
    }
    {
      name: 'az-pe'
      addressPrefix: '10.10.2.0/24'
    }
    {
      name: 'az-Servers'
      addressPrefix: '10.10.3.0/24'
    }
  ]
}
param OnpremVnetSettings object = {
  addressPrefix: '172.16.0.0/16'
  subnets: [
    {
      name: 'GatewaySubnet'
      addressPrefix: '172.16.0.0/24'
    }
    {
      name: 'AzureBastionSubnet'
      addressPrefix: '172.16.1.0/24'
    }
    {
      name: 'Servers'
      addressPrefix: '172.16.2.0/24'
    }
  ]
}


var aztag = {
  Deployment_type:   'Bicep'
  Project:                    'Data-DU Private Endpoint training'
  Environment:           'Azure'    
}

resource az_vnet 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: AzVnetName
  location: resourceGroup().location
  properties: {
    addressSpace: {
      addressPrefixes:[
        AzVnetSettings.addressPrefix
      ]
    }
    subnets:[
      {
        name: AzVnetSettings.subnets[0].name
        properties:{
          addressPrefix: AzVnetSettings.subnets[0].addressPrefix
        }
      }
      {
        name: AzVnetSettings.subnets[1].name
        properties:{
          addressPrefix: AzVnetSettings.subnets[1].addressPrefix
        }
      }
      {
        name: AzVnetSettings.subnets[2].name
        properties:{
          addressPrefix: AzVnetSettings.subnets[2].addressPrefix
        }
      }
      {
        name: AzVnetSettings.subnets[3].name
        properties:{
          addressPrefix: AzVnetSettings.subnets[3].addressPrefix
        }
      }      
    ]
  }
  tags:aztag
}

resource op_vnet 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: OnpremVnetName
  location:oploc
  properties:{
    addressSpace:{
      addressPrefixes: [
        OnpremVnetSettings.addressPrefix
      ]
    }
    subnets: [
      {
        name: OnpremVnetSettings.subnets[0].name
        properties: {
          addressPrefix: OnpremVnetSettings.subnets[0].addressPrefix
        }
      }
      {
        name: OnpremVnetSettings.subnets[1].name
        properties: {
          addressPrefix: OnpremVnetSettings.subnets[1].addressPrefix
        }
      }
      {
        name: OnpremVnetSettings.subnets[2].name
        properties: {
          addressPrefix: OnpremVnetSettings.subnets[2].addressPrefix
        }
      }
    ]
  }
  tags: aztag  
}

resource sqlserver 'Microsoft.Sql/servers@2021-02-01-preview' = {
  name: sqlsrvname
  location:resourceGroup().location

  properties:{
    administratorLogin: sqladmin
    administratorLoginPassword: password
    version: '12.0'
    publicNetworkAccess: 'Enabled' 
  }
}

resource sqldb 'Microsoft.Sql/servers/databases@2021-02-01-preview' = {
  name: sqldbname
  parent: sqlserver  
  location:resourceGroup().location
  sku: {
    name: 'Basic'
    tier: 'Basic'
  }
  properties:{
    collation: 'SQL_Latin1_General_CP1_CI_AS'    
  }  
}

resource az_bastion_pip 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  name: azbastionpip
  location:resourceGroup().location
  sku:{
    name: bastionipsku
  }
  properties:{
    publicIPAllocationMethod: bastioniptype
  }
  tags:aztag
}

resource op_bastion_pip 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  name: opbastionpip
  location:oploc
  sku:{
    name: bastionipsku
  }
  properties:{
    publicIPAllocationMethod: bastioniptype
  }
  tags:aztag
}

resource vpngw01_pip 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  name: vpngwpip1
  location:resourceGroup().location
  sku: {
    name:'Basic'
    tier: 'Regional'
  }
  properties:{
    publicIPAllocationMethod: 'Dynamic'
  }
  tags: aztag
}

resource vpngw02_pip 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  name: vpngwpip2
  location:oploc
  sku: {
    name:'Basic'
    tier: 'Regional'
  }
  properties:{
    publicIPAllocationMethod: 'Dynamic'
  }
  tags: aztag
}

resource az_bastion 'Microsoft.Network/bastionHosts@2021-02-01' = {
  name: azbastionname
  location: resourceGroup().location
  properties:{
    ipConfigurations:[
      {
        name:'azbastipconf'
        properties:{
          publicIPAddress: {
            id:az_bastion_pip.id
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', az_vnet.name, AzVnetSettings.subnets[1].name)
          }
        }
      }
    ]
  }
  tags:aztag
}

resource op_bastion 'Microsoft.Network/bastionHosts@2021-02-01' = {
  name: opbastionname
  location: oploc
  properties:{
    ipConfigurations:[
      {
        name:'opbastipconf'
        properties:{
          publicIPAddress: {
            id:op_bastion_pip.id
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', op_vnet.name, OnpremVnetSettings.subnets[1].name)
          }
        }
      }
    ]
  }
  tags:aztag
}


resource az_vm_nic 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: 'azvmnic01'
  location:resourceGroup().location
  properties: {
    ipConfigurations:[
      {
        name:'azvmipconf'
        properties:{
          privateIPAllocationMethod: 'Static'
          privateIPAddress: '10.10.3.10'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', az_vnet.name, AzVnetSettings.subnets[2].name)
          }
        }
      }
    ]
  }
  tags:aztag
}
resource az_dns_nic 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: 'azdnsnic01'
  location:resourceGroup().location
  properties: {
    ipConfigurations:[
      {
        name:'azdnsipconf'
        properties:{
          privateIPAllocationMethod: 'Static'
          privateIPAddress: '10.10.3.100'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', hub_vnet.name, AzHubVnetSettings.subnets[3].name)
          }
        }
      }
    ]
  }
  tags:aztag  
}
resource hub_vm 'Microsoft.Compute/virtualMachines@2021-04-01' = {
  name: hubvmname
  location: resourceGroup().location
  properties:{
    hardwareProfile:{
      vmSize:VMSize
    }
    osProfile:{
      adminPassword: password
      adminUsername:username
      computerName:hubvmname
    }
    storageProfile: {
      imageReference:{
        publisher: publisher
        offer: vmOffer
        sku: vmSKU
        version: versionSKU
      }
      osDisk: {
        caching:'ReadWrite'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
      }
      dataDisks: [
        {
          diskSizeGB: 1023
          lun:0
          createOption:'Empty'
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id:hub_vm_nic.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: false
      }
    }          
  }
  tags: aztag
}
resource hub_dns 'Microsoft.Compute/virtualMachines@2021-04-01' = {
  name: hubdnsvm
  location: resourceGroup().location
  properties:{
    hardwareProfile:{
      vmSize:VMSize
    }
    osProfile:{
      adminPassword: password
      adminUsername:username
      computerName:hubdnsvm
    }
    storageProfile: {
      imageReference:{
        publisher: publisher
        offer: vmOffer
        sku: vmSKU
        version: versionSKU
      }
      osDisk: {
        caching:'ReadWrite'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
      }
      dataDisks: [
        {
          diskSizeGB: 1023
          lun:0
          createOption:'Empty'
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id:hub_dns_nic.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: false
      }
    }          
  }
  tags: aztag
}


resource adfpe 'Microsoft.DataFactory/factories@2018-06-01' = {
  name:
}

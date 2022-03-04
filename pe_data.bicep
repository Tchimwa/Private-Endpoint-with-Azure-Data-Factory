param publisher string = 'MicrosoftWindowsServer'
param vmOffer string = 'WindowsServer'
param vmSKU string = '2019-Datacenter'
param versionSKU string = 'latest'
param VMSize string = 'Standard_D2s_v3'

@secure()
param alias string
param oploc string = 'eastus2'
param azloc string = resourceGroup().location
param username string = 'Azure'
param password string = 'Data2022#'
param sharedkey string = '@1wAy$8eKinD!'
param adfname string = 'afdpe-training'
param az2op string = 'Az-to-Onprem'
param op2az string = 'Onprem-to-Az'
param sqladmin string = 'sqladmin'
param azvmname string = 'az-shir'
param azdnsvm string = 'az-dns'
param opvmname string = 'onprem-shir'
param opdnsvm string = 'onprem-dns'
param azbastionpip string = 'azbastion-pip'
param opbastionpip string = 'opbastion-pip'
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
param fileUris string = 'https://raw.githubusercontent.com/Tchimwa/Private-Endpoint-with-Azure-Data-Factory/master/scripts/emp.ps1'
param dnsfileUris string = 'https://raw.githubusercontent.com/Tchimwa/Private-Endpoint-with-Azure-Data-Factory/master/scripts/op-dns.ps1'
param dnsUris string = 'https://raw.githubusercontent.com/Tchimwa/Private-Endpoint-with-Azure-Data-Factory/master/scripts/az-dns.ps1'
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
  location: azloc
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
  name: '${sqlsrvname}${alias}'
  location:azloc

  properties:{
    administratorLogin: sqladmin
    administratorLoginPassword: password
    version: '12.0'
    publicNetworkAccess: 'Enabled' 
  }
}

resource sqldb 'Microsoft.Sql/servers/databases@2021-02-01-preview' = {
  name: '${sqldbname}${alias}'
  parent: sqlserver  
  location:azloc  
  sku: {
    name: 'Basic'
    tier: 'Basic'
  }
  properties:{
    collation: 'SQL_Latin1_General_CP1_CI_AS'        
  }  
}

resource az_bastion_pip 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  name: '${azbastionpip}-${alias}'
  location:azloc
  sku:{
    name: bastionipsku
  }
  properties:{
    publicIPAllocationMethod: bastioniptype
  }
  tags:aztag
}

resource op_bastion_pip 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  name: '${opbastionpip}-${alias}'
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
  name: '${vpngwpip1}-${alias}'
  location:azloc
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
  name: '${vpngwpip2}-${alias}'
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
  name: '${azbastionname}-${alias}'
  location: azloc
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
  name: '${opbastionname}-${alias}'
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
  location:azloc
  properties: {
    ipConfigurations:[
      {
        name:'azvmipconf'
        properties:{
          privateIPAllocationMethod: 'Static'
          privateIPAddress: '10.10.3.10'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', az_vnet.name, AzVnetSettings.subnets[3].name)
          }
        }
      }
    ]
  }
  tags:aztag
}

resource az_dns_nic 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: 'azdnsnic01'
  location:azloc
  properties: {
    ipConfigurations:[
      {
        name:'azdnsipconf'
        properties:{
          privateIPAllocationMethod: 'Static'
          privateIPAddress: '10.10.3.100'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', az_vnet.name, AzVnetSettings.subnets[3].name)
          }
        }
      }
    ]
  }
  tags:aztag  
}

resource op_vm_nic 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: 'opvmnic01'
  location:oploc
  properties: {
    ipConfigurations:[
      {
        name:'opvmipconf'
        properties:{
          privateIPAllocationMethod: 'Static'
          privateIPAddress: '172.16.2.10'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', op_vnet.name, OnpremVnetSettings.subnets[2].name)
          }
        }
      }
    ]
  }
  tags:aztag
}

resource op_dns_nic 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: 'opdnsnic01'
  location: oploc
  properties: {
    ipConfigurations:[
      {
        name:'opdnsipconf'
        properties:{
          privateIPAllocationMethod: 'Static'
          privateIPAddress: '172.16.2.100'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', op_vnet.name, OnpremVnetSettings.subnets[2].name)
          }
        }
      }
    ]
  }
  tags:aztag  
}

resource az_vm 'Microsoft.Compute/virtualMachines@2021-04-01' = {
  name: azvmname
  location: azloc
  properties:{
    hardwareProfile:{
      vmSize:VMSize
    }
    osProfile:{
      adminPassword: password
      adminUsername:username
      computerName:azvmname
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
          id:az_vm_nic.id
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

resource az_dns 'Microsoft.Compute/virtualMachines@2021-04-01' = {
  name: azdnsvm
  location: azloc
  properties:{
    hardwareProfile:{
      vmSize:VMSize
    }
    osProfile:{
      adminPassword: password
      adminUsername:username
      computerName:azdnsvm
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
          id:az_dns_nic.id
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

resource azdnsrole 'Microsoft.Compute/virtualMachines/extensions@2021-04-01' = {
  name: 'azdns_role'
  parent: az_dns
  location: azloc
  properties: {
    publisher : 'Microsoft.Compute'
    type : 'CustomScriptExtension'
    typeHandlerVersion : '1.9'
    autoUpgradeMinorVersion : true
    settings: {
      fileUris: [
        '${dnsUris}'
      ]
    }
    protectedSettings: {
      'commandToExecute': 'powershell -ExecutionPolicy Unrestricted -file az-dns.ps1'
    }
  }
  tags:aztag
}

resource op_vm 'Microsoft.Compute/virtualMachines@2021-04-01' = {
  name: opvmname
  location: oploc
  properties:{
    hardwareProfile:{
      vmSize:VMSize
    }
    osProfile:{
      adminPassword: password
      adminUsername:username
      computerName:opvmname
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
          id:op_vm_nic.id
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

resource opvmfile 'Microsoft.Compute/virtualMachines/extensions@2021-04-01' = {
  name: 'opfileadf'
  parent: op_vm
  location: oploc
  properties: {
    publisher : 'Microsoft.Compute'
    type : 'CustomScriptExtension'
    typeHandlerVersion : '1.9'
    autoUpgradeMinorVersion : true
    settings: {
      fileUris: [
        '${fileUris}'
      ]
    }
    protectedSettings: {
      'commandToExecute': 'powershell -ExecutionPolicy Unrestricted -file emp.ps1'
    }
  }
  tags:aztag
}

resource op_dns 'Microsoft.Compute/virtualMachines@2021-04-01' = {
  name: opdnsvm
  location: oploc
  properties:{
    hardwareProfile:{
      vmSize:VMSize
    }
    osProfile:{
      adminPassword: password
      adminUsername:username
      computerName:azdnsvm
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
          id:op_dns_nic.id
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

resource opdnsrole 'Microsoft.Compute/virtualMachines/extensions@2021-04-01' = {
  name: 'opdns_role'
  parent: op_dns
  location: oploc
  properties: {
    publisher : 'Microsoft.Compute'
    type : 'CustomScriptExtension'
    typeHandlerVersion : '1.9'
    autoUpgradeMinorVersion : true
    settings: {
      fileUris: [
        '${dnsfileUris}'
      ]
    }
    protectedSettings: {
      'commandToExecute': 'powershell -ExecutionPolicy Unrestricted -file op-dns.ps1'
    }
  }
  tags:aztag
}

resource azvpngw 'Microsoft.Network/virtualNetworkGateways@2021-02-01' = {
  name: '${azgwname}-${alias}'
  location: azloc
  properties: {
    activeActive: false
    enableBgp: false
    gatewayType: 'Vpn'
    enablePrivateIpAddress: false
    sku: {
      name: 'VpnGw1'
      tier: 'VpnGw1'
    }
    vpnType: 'RouteBased'
    ipConfigurations: [
      {
        name:'azgwipconfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: vpngw01_pip.id
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', az_vnet.name, AzVnetSettings.subnets[0].name)
          }
        }
      }      
    ]    
    vpnGatewayGeneration: 'Generation1'    
  }
  tags:aztag  
}

resource opvpngw 'Microsoft.Network/virtualNetworkGateways@2021-02-01' = {
  name: '${opgwname}-${alias}'
  location: oploc
  properties: {
    activeActive: false
    enableBgp: false
    gatewayType: 'Vpn'
    enablePrivateIpAddress: false
    sku: {
      name: 'VpnGw1'
      tier: 'VpnGw1'
    }
    vpnType: 'RouteBased'
    ipConfigurations: [
      {
        name:'opgwipconfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: vpngw02_pip.id
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', op_vnet.name, OnpremVnetSettings.subnets[0].name)
          }
        }
      }      
    ]    
    vpnGatewayGeneration: 'Generation1'    
  }
  tags:aztag  
}

resource AztoOnprem 'Microsoft.Network/connections@2021-05-01' = {
  name: az2op
  location: azloc
  properties: {
    connectionType: 'Vnet2Vnet'
    sharedKey: sharedkey
    routingWeight:3
    virtualNetworkGateway1: {
      id: azvpngw.id
      properties: {}
    }
    virtualNetworkGateway2: {
      id: opvpngw.id
      properties: {}
    }
  }  
}

resource OnpremtoAz 'Microsoft.Network/connections@2021-05-01' = {
  name: op2az
  location: oploc
  properties: {
    connectionType: 'Vnet2Vnet'
    sharedKey: sharedkey
    routingWeight:3
    virtualNetworkGateway1: {
      id: opvpngw.id
      properties: {}
    }
    virtualNetworkGateway2: {
      id: azvpngw.id
      properties: {}
    }
  }  
}

resource adfpe 'Microsoft.DataFactory/factories@2018-06-01' = {
  name: '${adfname}-${alias}'
  location: azloc
  identity: {
    type: 'SystemAssigned'
  }  
  properties: {
    publicNetworkAccess: 'Enabled'
  }
}

resource shir_adf 'Microsoft.DataFactory/factories/integrationRuntimes@2018-06-01' = {
  name: 'shir-training'
  parent: adfpe
  properties: {
    type: 'SelfHosted'   
  }  
}  

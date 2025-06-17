@description('Location for resource group and subnet')
param location string = 'North Europe'

@description('Location for Azure OpenAI instance')
param openAiLocation string = 'West Europe'

@description('Name of existing virtual network')
param vnetName string = 'devops-dev'

@description('Name of resource group')
param resourceGroupName string = 'devops-ai-rg-dev'

@description('Subnet name to create')
param subnetName string = 'devops-ai-snet'

var subnetPrefix = '10.37.0.0/24'

// VM configuration
var vmAdminUsername = 'integ-admin'

var vms = [
  {
    name: 'devops-openweb-vm-dev'
    staticIp: '10.37.0.4'
  }
  {
    name: 'devops-llm-vm-dev'
    staticIp: '10.37.0.5'
  }
]

// NSG configs for each VM
var nsgs = [
  {
    name: 'devops-openweb-nsg-dev'
    attachedVm: 'devops-openweb-vm-dev'
    securityRules: [
      {
        name: 'Allow-SSH-To-VM'
        priority: 100
        direction: 'Inbound'
        access: 'Allow'
        protocol: 'Tcp'
        sourceAddressPrefix: '*'
        destinationAddressPrefix: '10.37.0.4'
        sourcePortRange: '*'
        destinationPortRange: '22'
      }
      {
        name: 'Allow-HTTP-To-VM'
        priority: 101
        direction: 'Inbound'
        access: 'Allow'
        protocol: 'Tcp'
        sourceAddressPrefix: '*'
        destinationAddressPrefix: '10.37.0.4'
        sourcePortRange: '*'
        destinationPortRange: '80'
      }
      {
        name: 'Allow-DNS-From-VM'
        priority: 100
        direction: 'Outbound'
        access: 'Allow'
        protocol: 'Udp'
        sourceAddressPrefix: '*'
        destinationAddressPrefixes: [
          '8.8.8.8'
          '4.4.2.2'
        ]
        sourcePortRange: '*'
        destinationPortRange: '53'
      }
      {
        name: 'Allow-Update-From-VM'
        priority: 101
        direction: 'Outbound'
        access: 'Allow'
        protocol: 'Tcp'
        sourceAddressPrefix: '*'
        destinationAddressPrefix: 'Internet'
        sourcePortRange: '*'
        destinationPortRanges: [
          '80'
          '443'
        ]
      }
      {
        name: 'Allow-HTTP-From-VM'
        priority: 102
        direction: 'Outbound'
        access: 'Allow'
        protocol: 'Tcp'
        sourceAddressPrefix: '*'
        destinationAddressPrefix: '10.37.0.5'
        sourcePortRange: '*'
        destinationPortRange: '80'
      }
    ]
  }
  {
    name: 'devops-llm-nsg-dev'
    attachedVm: 'devops-llm-vm-dev'
    securityRules: [
      {
        name: 'Allow-SSH-To-VM'
        priority: 100
        direction: 'Inbound'
        access: 'Allow'
        protocol: 'Tcp'
        sourceAddressPrefix: '*'
        destinationAddressPrefix: '10.37.0.4'
        sourcePortRange: '*'
        destinationPortRange: '22'
      }
      {
        name: 'Allow-HTTP-To-VM'
        priority: 101
        direction: 'Inbound'
        access: 'Allow'
        protocol: 'Tcp'
        sourceAddressPrefix: '10.37.0.4'
        destinationAddressPrefix: '10.37.0.5'
        sourcePortRange: '*'
        destinationPortRange: '80'
      }
      {
        name: 'Allow-DNS-From-VM'
        priority: 100
        direction: 'Outbound'
        access: 'Allow'
        protocol: 'Udp'
        sourceAddressPrefix: '*'
        destinationAddressPrefixes: [
          '8.8.8.8'
          '4.4.2.2'
        ]
        sourcePortRange: '*'
        destinationPortRange: '53'
      }
      {
        name: 'Allow-Update-From-VM'
        priority: 101
        direction: 'Outbound'
        access: 'Allow'
        protocol: 'Tcp'
        sourceAddressPrefix: '*'
        destinationAddressPrefix: 'Internet'
        sourcePortRange: '*'
        destinationPortRanges: [
          '80'
          '443'
        ]
      }
    ]
  }
]

// Existing VNet reference
resource vnet 'Microsoft.Network/virtualNetworks@2022-05-01' existing = {
  name: vnetName
}

// Create Resource Group (if needed)
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
  tags: {
    Owner: 'DevOps'
    Environment: 'Development'
    Function: 'AI Services'
  }
}

// Create subnet
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2022-05-01' = {
  parent: vnet
  name: subnetName
  properties: {
    addressPrefix: subnetPrefix
    privateEndpointNetworkPolicies: 'Disabled' // required for private endpoint
  }
  tags: {
    Owner: 'DevOps'
    Environment: 'Development'
    Function: 'AI Services'
  }
}

// Create NSGs
resource nsgResources 'Microsoft.Network/networkSecurityGroups@2022-05-01' = [for nsg in nsgs: {
  name: nsg.name
  location: location
  properties: {
    securityRules: [for rule in nsg.securityRules: {
      name: rule.name
      properties: {
        priority: rule.priority
        direction: rule.direction
        access: rule.access
        protocol: rule.protocol
        sourceAddressPrefix: contains(rule, 'sourceAddressPrefix') ? rule.sourceAddressPrefix : '*'
        sourceAddressPrefixes: contains(rule, 'sourceAddressPrefixes') ? rule.sourceAddressPrefixes : null
        destinationAddressPrefix: contains(rule, 'destinationAddressPrefix') ? rule.destinationAddressPrefix : null
        destinationAddressPrefixes: contains(rule, 'destinationAddressPrefixes') ? rule.destinationAddressPrefixes : null
        sourcePortRange: contains(rule, 'sourcePortRange') ? rule.sourcePortRange : '*'
        sourcePortRanges: contains(rule, 'sourcePortRanges') ? rule.sourcePortRanges : null
        destinationPortRange: contains(rule, 'destinationPortRange') ? rule.destinationPortRange : null
        destinationPortRanges: contains(rule, 'destinationPortRanges') ? rule.destinationPortRanges : null
      }
    }]
  }
}]

// Create NICs attached to subnet and NSGs
resource nics 'Microsoft.Network/networkInterfaces@2022-05-01' = [for (vm, i) in vms: {
  name: '${vm.name}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: vm.staticIp
          subnet: {
            id: subnet.id
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: nsgResources[i].id
    }
  }
}]

// Generate SSH Key Pair (Public Key output for VM)
resource sshKey 'Microsoft.Compute/sshPublicKeys@2022-11-01' = {
  name: '${resourceGroupName}-sshkey'
  location: location
  properties: {
    publicKey: '' // leave empty to generate new? Actually Azure SSH Public Keys resource expects a key, so generate outside or pass param (alternative is to generate locally and provide)
  }
}

// NOTE: Azure does not support generating SSH key pair directly in Bicep — it must be generated outside and passed in.
// So we will accept SSH public key as a parameter instead:
param sshPublicKey string {
  description: 'SSH RSA Public Key for VM login'
  metadata: {
    format: 'ssh-rsa'
  }
}

// Create VMs
resource vmsResources 'Microsoft.Compute/virtualMachines@2023-03-01' = [for (vm, i) in vms: {
  name: vm.name
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B2s'
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
        name: '${vm.name}-osdisk'
      }
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-focal'
        sku: '24_04-lts'
        version: 'latest'
      }
    }
    osProfile: {
      computerName: vm.name
      adminUsername: vmAdminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              keyData: sshPublicKey
              path: '/home/${vmAdminUsername}/.ssh/authorized_keys'
            }
          ]
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nics[i].id
        }
      ]
    }
  }
  dependsOn: [
    nics[i]
    nsgResources[i]
  ]
}]

// ----------- Azure OpenAI Instance -------------

resource openai 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: 'devops-openai-dev'
  location: openAiLocation
  kind: 'OpenAI'
  sku: {
    name: 'S0'
  }
  tags: {
    Owner: 'DevOps'
    Environment: 'Development'
    Function: 'AI Services'
  }
  properties: {
    networkAcls: {
      defaultAction: 'Deny' // disable network access except private endpoint
      virtualNetworkRules: []
      ipRules: []
    }
  }
  dependsOn: [
    rg
  ]
}

// Private DNS Zone for Azure OpenAI private endpoint
resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.openai.azure.com'
  location: 'global'
}

// Link the private DNS zone to the existing VNet
resource privateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: 'devops-openai-dnslink'
  parent: privateDnsZone
  location: 'global'
  properties: {
    virtualNetwork: {
      id: vnet.id
    }
    registrationEnabled: false
  }
  dependsOn: [
    privateDnsZone
  ]
}

// Private endpoint to connect Azure OpenAI to subnet
resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: 'devops-openai-pe'
  location: openAiLocation
  properties: {
    subnet: {
      id: subnet.id
    }
    privateLinkServiceConnections: [
      {
        name: 'openai-connection'
        properties: {
          privateLinkServiceId: openai.id
          groupIds: [
            'openai'
          ]
        }
      }
    ]
  }
  dependsOn: [
    openai
    subnet
  ]
}

// Private DNS A record for the private endpoint
resource privateDnsARecord 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  name: 'devops-openai-dev.privatelink.openai.azure.com'
  parent: privateDnsZone
  properties: {
    ttl: 3600
    aRecords: [
      {
        ipv4Address: privateEndpoint.properties.ipAddresses[0]
      }
    ]
  }
  dependsOn: [
    privateEndpoint
    privateDnsZone
  ]
}

// AI model deployment
//AI model deployment limited to 10,000 tokens per minute with "tokenLimit": 10000.

resource aiModel 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = {
  parent: openai
  name: 'gpt-4.1-nano'
  properties: {
    model: 'gpt-4.1-nano'
    scaleSettings: {
      scaleType: 'Standard'
    }
    region: openAiLocation
    tokenLimit: 10000
  }
  dependsOn: [
    openai
  ]
}
// load tags for json parameter file
param tagging object
//Creates a deployment date tag
param date object = {
  'Deployment Date': utcNow('yyy-MM-dd')
}
 
// Combines the deployment date tag and the tags provided from json
var tags = union(tagging, date)

param location string = resourceGroup().location
param avdVmSize string
@allowed([
  'windows-11'
  'windows-10'
])
param windowsSKU string
@description('Note the -avd or -ent for Multi Session and Single Session')
@allowed([
  'win11-23h2-avd'
  'win11-23h2-ent'
  'win10-22h2-avd-g2'
  'win10-22h2-ent-g2'
])
param ImagePublisher string
@allowed([
  'windows-11'
  'windows-10'
])
param ImageOffer string

param avdAdminUsername string

@description('Password for the server Virtual Machine.')
@secure()
param avdAdminPassword string

@description('The base URI where artifacts required by this template are located.')
param artifactsLocation string = 'https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_10-27-2022.zip'

@description('This prefix will be used in combination with the VM number to create the VM name. This value includes the dash, so if using “rdsh” as the prefix, VMs would be named “rdsh-0”, “rdsh-1”, etc. You should use a unique prefix to reduce name collisions in Active Directory.')
param rdshPrefix string

@description('Number of session hosts that will be created and added to the hostpool.')
@minValue(1)
@maxValue(10)
param rdshNumberOfInstances int

@description('VM name prefix initial number.')
param rdshInitialNumber int

@description('The name of the hostpool')
param hostpoolName string
param hostpoolToken string

param deleteOption string = 'Delete'
param enableAcceleratedNetworking bool = true
param vnetRG string
param virtualNetworkName string
param subnetName string
var subnetRef = resourceId(vnetRG, 'Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)

@description('IMPORTANT: Please don\'t use this parameter as AAD Join is not supported yet. True if AAD Join, false if AD join')
param aadJoin bool

@description('Domain NetBiosName plus User name of a domain user with sufficient rights to perfom domain join operation. E.g. domain\\username')
@secure()
param domainJoinPassword string
param ouPath string
var domainJoinOptions = 3
param domainFQDN string
param domainJoinUsername string

resource nic 'Microsoft.Network/networkInterfaces@2023-04-01' = [for i in range(0, rdshNumberOfInstances): {
  name: '${rdshPrefix}-${(i + rdshInitialNumber)}-nic'
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetRef
          }
        }
      }
    ]
    enableAcceleratedNetworking: enableAcceleratedNetworking
  }
}]

resource vm 'Microsoft.Compute/virtualMachines@2023-03-01' = [for i in range(0, rdshNumberOfInstances): {
  name: '${rdshPrefix}-${(i + rdshInitialNumber)}'
  location: location
  tags: tags
  properties: {
    hardwareProfile: {
      vmSize: avdVmSize
    }
    additionalCapabilities: {
      hibernationEnabled: false
    }
    storageProfile: {
      imageReference: {
        publisher: ImagePublisher
        offer: ImageOffer
        sku: windowsSKU
        version: 'latest'
      }
      osDisk: {
        osType: 'Windows'
        createOption: 'FromImage'
        deleteOption: deleteOption
      }
      dataDisks: []
      diskControllerType: 'SCSI'
    }
    osProfile: {
      computerName: '${rdshPrefix}-${(i + rdshInitialNumber)}'
      adminUsername: avdAdminUsername
      adminPassword: avdAdminPassword
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: true
        patchSettings: {
          patchMode: 'AutomaticByOS'
          assessmentMode: 'ImageDefault'
        }
        enableVMAgentPlatformUpdates: false
      }
      secrets: []
      allowExtensionOperations: true
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', '${rdshPrefix}${(i + rdshInitialNumber)}-nic')
          properties: {
            primary: true
            deleteOption: deleteOption
          }
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: false
      }
    }
    licenseType: 'Windows_Client'
  }
  zones: null
  dependsOn: [
    nic
  ]
}]

resource vm_DSC 'Microsoft.Compute/virtualMachines/extensions@2023-03-01' = [for i in range(0, rdshNumberOfInstances): {
  name: '${rdshPrefix}${(i + rdshInitialNumber)}/Microsoft.PowerShell.DSC'
  location: location
  tags: tags
  properties: {
    autoUpgradeMinorVersion: true
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.73'
    settings: {
      modulesUrl: artifactsLocation
      configurationFunction: 'Configuration.ps1\\AddSessionHost'
      properties: {
        hostPoolName: hostpoolName
        registrationInfoToken: hostpoolToken
        aadJoin: aadJoin
        UseAgentDownloadEndpoint: true
        aadJoinPreview: false
        mdmId: ''
        sessionHostConfigurationLastUpdateTime: ''
      }
    }
  }
  dependsOn: [
    vm
  ]
}]

resource vm_joindomain 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = [for i in range(0, rdshNumberOfInstances): {
  name: '${rdshPrefix}${(i + rdshInitialNumber)}/joindomain'
  location: location
  properties: {
  publisher: 'Microsoft.Compute'
  type: 'JsonADDomainExtension'
    typeHandlerVersion: '1.3'
    autoUpgradeMinorVersion: true
    settings: {
      Name: domainFQDN
      User: domainJoinUsername
      Restart: 'true'
      Options: domainJoinOptions
      OUPath: ouPath
    }
    protectedSettings: {
      Password: domainJoinPassword
    }
  }
  dependsOn: [
    vm_DSC
  ]
}]

// load tags for json parameter file
param tagging object
//Creates a deployment date tag
param date object = {
  'Deployment Date': utcNow('yyy-MM-dd')
}
 
// Combines the deployment date tag and the tags provided from json
var tags = union(tagging, date)

param hostpool_name string
param location string = resourceGroup().location
param managedPrivateUDP string
param directUDP string
param publicUDP string
param relayUDP string
param managementType string
param friendlyName string
param description string
param hostPoolType string
param customRdpProperty string
param maxSessionLimit int
param loadBalancerType string
param validationEnvironment bool
param vmTemplate string
param preferredAppGroupType string
param startVMOnConnect bool

// Load the workspace ID for the Log Analytics workspace
param logAnalyticsWorkspaceId string
// Create the diagnostics setting name
param diagnosticsSettingName string = '${hostpool_name}/default'

resource hostpool_name_resource 'Microsoft.DesktopVirtualization/hostpools@2024-01-16-preview' = {
  name: hostpool_name
  location: location
  tags: tags
  properties: {
    managedPrivateUDP: managedPrivateUDP
    directUDP: directUDP
    publicUDP: publicUDP
    relayUDP: relayUDP
    managementType: managementType
    friendlyName: friendlyName
    description: description
    hostPoolType: hostPoolType
    customRdpProperty: customRdpProperty
    maxSessionLimit: maxSessionLimit
    loadBalancerType: loadBalancerType
    validationEnvironment: validationEnvironment
    vmTemplate: vmTemplate
    preferredAppGroupType: preferredAppGroupType
    startVMOnConnect: startVMOnConnect
  }
}


resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: diagnosticsSettingName
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'AuditLogs'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
      {
        category: 'ErrorLogs'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
    ]
  }
  dependsOn: [
    hostpool_name_resource
  ]
}

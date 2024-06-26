
// load tags for json parameter file
param tagging object
//Creates a deployment date tag
param date object = {
  'Deployment Date': utcNow('yyy-MM-dd')
}
 
// Combines the deployment date tag and the tags provided from json
var tags = union(tagging, date)

param applicationgroupname string
param location string = resourceGroup().location
param kind string
param description string
param applicationGroupType string
param friendlyName string
param hostPoolArmPath string


resource applicationgroup_name_resource 'Microsoft.DesktopVirtualization/applicationgroups@2024-01-16-preview' = {
  name: applicationgroupname
  location: location
  tags: tags
  kind: kind
  properties: {
    hostPoolArmPath: hostPoolArmPath
    description: description
    friendlyName: friendlyName
    applicationGroupType: applicationGroupType
  }
}

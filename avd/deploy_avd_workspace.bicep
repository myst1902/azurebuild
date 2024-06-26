// load tags for json parameter file
param tagging object
//Creates a deployment date tag
param date object = {
  'Deployment Date': utcNow('yyy-MM-dd')
}
// Combines the deployment date tag and the tags provided from json
var tags = union(tagging, date)


param workspacesname string
param location string = resourceGroup().location
param description string
param friendlyName string
//param applicationGroupReferences string[]

resource workspaces_resource 'Microsoft.DesktopVirtualization/workspaces@2024-01-16-preview' = {
  name: workspacesname
  location: location
  tags: tags
  properties: {
    publicNetworkAccess: 'Enabled'
    description: description
    friendlyName: friendlyName
    applicationGroupReferences: null
    }
}

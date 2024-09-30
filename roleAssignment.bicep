targetScope='subscription'

@description('The principal ID of the system-assigned managed identity to assign the role to.')
param principalId string

@description('Assigns the Virtual Machine Contributor role to the provided principal ID (system-assigned identity).')

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(principalId, 'VirtualMachineContributor')
  //scope: subscription()  // Assigning at the subscription level
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')  // Virtual Machine Contributor role ID
    principalId: principalId  // Assign to the system-assigned identity
    principalType: 'ServicePrincipal'
  }
}
